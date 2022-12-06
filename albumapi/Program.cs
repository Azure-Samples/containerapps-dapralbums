using Dapr.Client;
using Microsoft.ApplicationInsights.Channel;
using Microsoft.ApplicationInsights.Extensibility;
using System.Text.Json.Serialization;

var builder = WebApplication.CreateBuilder();

// Add services to the container.
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen();
builder.Services.AddHttpClient();
builder.Services.AddSingleton<AlbumApiConfiguration>();
builder.Services.AddSingleton<DaprClient>(new DaprClientBuilder().Build());
builder.Services.AddWebAppApplicationInsights("Album API");

builder.Services.AddCors(options =>
{
    options.AddDefaultPolicy(builder =>
    {
        builder.AllowAnyOrigin();
        builder.AllowAnyHeader();
        builder.AllowAnyMethod();
    });
});

var client = new DaprClientBuilder().Build();

var app = builder.Build();

// Configure the HTTP request pipeline.
if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI();
}

app.UseCors();

app.MapGet("/", async context =>
{
    await context.Response.WriteAsync("Hit the /albums endpoint to retrieve a list of albums!");
});

app.MapGet("/albums", async (HttpContext context, DaprClient client, AlbumApiConfiguration config) =>
{
    // Get the albums from the Dapr state store
    var albums = await client.GetStateAsync<List<Album>>($"{config.AlbumStateStore}", $"{config.CollectionId}");

    if (albums != null && albums.Count > 0) {
        app.Logger.LogInformation($"{albums.Count} albums were retrieved from the state store");
    } else {
        albums = await StateStoreExtensions.InitializeAlbumState(client, config);
        app.Logger.LogInformation($"Initialized empty state store with {albums.Count} albums.");
    }

    return Results.Ok(albums);
}).WithName("GetAlbums");

app.Run();

// the album model
public record Album([property: JsonPropertyName("id")] int Id, 
                                    [property: JsonPropertyName("title")] string Title, 
                                    [property: JsonPropertyName("artist")] string Artist, 
                                    [property: JsonPropertyName("price")] double Price, 
                                    [property: JsonPropertyName("image_url")] string Image_url)
{
    public static List<Album> DefaultAlbums()
    {
        var albums = new List<Album>(){
            new Album(1, "Sgt. Pepper's Lonely Hearts Club Band", "The Beatles", 10.99, "https://aka.ms/albums-beatles"),
            new Album(2, "Brothers in Arms", "Dire Straits", 13.99, "https://aka.ms/albums-direstraits"),
            new Album(3, "1989", "Taylor Swift", 13.99, "https://aka.ms/albums-taylor"),
            new Album(4, "Legend", "Bob Marley and the Wailers", 12.99,"https://aka.ms/albums-bobmarley"),
            new Album(5, "OK Computer", "Radiohead", 12.99, "https://aka.ms/albums-radiohead"),
            new Album(6, "Appetite for Destruction", "Guns'N'Roses", 14.99, "https://aka.ms/albums-gunsnroses")
         };

        return albums;
    }
}



















// app configuration settings
public class AlbumApiConfiguration
{
    private IConfiguration _config;

    public AlbumApiConfiguration(IConfiguration config)
    {
        _config = config;
    }

    public string CollectionId => _config.GetValue<string>("COLLECTION_ID") ?? "GreatestHits";
    public string AlbumStateStore => "statestore";
}

// extension methods to for data cache and state store initialization
public static class StateStoreExtensions
{
    public static async Task<List<Album>> InitializeAlbumState(DaprClient client, AlbumApiConfiguration config)
    {
        var albums = Album.DefaultAlbums();

        await client.SaveStateAsync($"{config.AlbumStateStore}", $"{config.CollectionId}", albums);

        return albums;
    }
}

public class ApplicationMapNodeNameInitializer : ITelemetryInitializer
{
    public ApplicationMapNodeNameInitializer(string name)
    {
        Name = name;
    }

    public string Name { get; set; }

    public void Initialize(ITelemetry telemetry)
    {
        telemetry.Context.Cloud.RoleName = Name;
    }
}

public static class ApplicationInsightsServiceCollectionExtensions
{
    public static void AddWebAppApplicationInsights(this IServiceCollection services, string applicationName)
    {
        services.AddApplicationInsightsTelemetry();
        services.AddSingleton<ITelemetryInitializer>((services) => new ApplicationMapNodeNameInitializer(applicationName));
    }
}
