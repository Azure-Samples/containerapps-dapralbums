using Dapr.Client;

var builder = WebApplication.CreateBuilder();

// Add services to the container.
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen();
builder.Services.AddHttpClient();
builder.Services.AddSingleton<AlbumApiConfiguration>();
builder.Services.AddSingleton<DaprClient>(new DaprClientBuilder().Build());

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

app.Urls.Add("http://0.0.0.0:${ASPNETCORE_URLS}");

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
public record Album(int Id, string Title, string Artist, double Price, string Image_url)
{
    public static List<Album> GetAll()
    {
        var albums = new List<Album>(){
            new Album(1, "You, Me and an App Id", "Daprize", 10.99, "https://aka.ms/albums-daprlogo"),
            new Album(2, "Seven Revision Army", "The Blue-Green Stripes", 13.99, "https://aka.ms/albums-containerappslogo"),
            new Album(3, "Scale It Up", "KEDA Club", 13.99, "https://aka.ms/albums-kedalogo"),
            new Album(4, "Lost in Translation", "MegaDNS", 12.99,"https://aka.ms/albums-envoylogo"),
            new Album(5, "Lock Down Your Love", "V is for VNET", 12.99, "https://aka.ms/albums-vnetlogo"),
            new Album(6, "Sweet Container O' Mine", "Guns N Probeses", 14.99, "https://aka.ms/albums-containerappslogo")
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
    public string DefaultHttpPort => _config.GetValue<string>("DAPR_HTTP_PORT") ?? "3500";
    public string DefaultHttpServer => _config.GetValue<string>("HTTP_SERVER") ?? "http://127.0.0.1";
    public string AlbumStateStore => "statestore";
}

// extension methods to for data cache and state store initialization
public static class StateStoreExtensions
{
    public static async Task<List<Album>> InitializeAlbumState(DaprClient client, AlbumApiConfiguration config)
    {
        var albums = Album.GetAll();

        await client.SaveStateAsync($"{config.AlbumStateStore}", $"{config.CollectionId}", albums);

        return albums;
    }
}
