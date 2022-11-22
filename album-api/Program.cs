using System.Net;
using System.Text;
using System.Text.Json;
using Dapr.Client;

var builder = WebApplication.CreateBuilder();

// Add services to the container.
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen();
builder.Services.AddHttpClient();
builder.Services.AddSingleton<AlbumApiConfiguration>();

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
    var albums = await client.GetStateAsync<List<Album>>($"{config.AlbumStateStore}", $"{config.CollectionId}");

    // Get the albums from the state store.
    //client.GetState

    // var response = await client.GetAsync($"{config.DefaultHttpServer}:{config.DefaultHttpPort}/v1.0/state/{config.AlbumStateStore}/{config.CollectionId}");
    // var albums = await response.ReadAlbumArrayFromResponse(client, config);

    if (albums != null && albums.Count > 0)
        app.Logger.LogInformation($"{albums.Count} albums were retrieved from the state store");

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

// extension methods for requesting,
// deserializing, and returning the
// array of albums
public static class HttpResponseMessageAlbumExtensions
{
    public static async Task<List<Album>> ReadAlbumArrayFromResponse(this HttpResponseMessage response, HttpClient client, DaprClient daprClient, AlbumApiConfiguration config)
    {
        var json = await response.Content.ReadAsStringAsync();
        var albums = new List<Album>();

        if (!response.IsSuccessStatusCode)
        {
            throw new Exception($"Exception loading state. StatusCode: {response.StatusCode}. Message: {json}");
        }
        // Collection Id does not exist, therefore the database needs to be seeded 
        else if (response.StatusCode == HttpStatusCode.NoContent)
        {
            // Seed the state store 
            var albumState = new[] {
                new
                {
                    key = config.CollectionId,
                    value = Album.GetAll()
                }
            };

            //var content = new StringContent(JsonSerializer.Serialize(albumState), Encoding.UTF8, "application/json");

            //paul here
            await daprClient.SaveStateAsync($"{config.AlbumStateStore}", $"{config.CollectionId}", Album.GetAll());
            
            // override the initial response with the resulting data.
            //response = await client.PostAsync($"{config.DefaultHttpServer}:{config.DefaultHttpPort}/v1.0/state/{config.AlbumStateStore}", content);

            // if (!response.IsSuccessStatusCode)
            // {
            //     throw new Exception($"Exception seeding state. StatusCode: {response.StatusCode}. Message: {json}");
            // };

            // Get the newly seeded albums from the state store
            //response = await client.GetAsync($"{config.DefaultHttpServer}:{config.DefaultHttpPort}/v1.0/state/{config.AlbumStateStore}/{config.CollectionId}");
            

            albums = await daprClient.GetStateAsync<List<Album>>($"{config.AlbumStateStore}", $"{config.CollectionId}");
        } else {
            
            albums = JsonSerializer.Deserialize<List<Album>>(json);
        }


        return albums;
    }
}