using System.Net;
using System.Text;
using System.Text.Json;

var builder = WebApplication.CreateBuilder();

var DefaultHttpPort = Environment.GetEnvironmentVariable("DAPR_HTTP_PORT") ?? "3500";
var AlbumStateStore = "statestore";
var CollectionId = Environment.GetEnvironmentVariable("COLLECTION_ID") ?? "GreatestHits";

// Add services to the container.
// Learn more about configuring Swagger/OpenAPI at https://aka.ms/aspnetcore/swashbuckle
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen();
builder.Services.AddHttpClient();

builder.Services.AddCors(options => {
    options.AddDefaultPolicy(builder =>
    {
        builder.AllowAnyOrigin();
        builder.AllowAnyHeader();
        builder.AllowAnyMethod();
    });
});

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

app.MapGet("/albums", async (HttpContext context, HttpClient client) => 
{
    // Get the albums from the state store.
    var response = await client.GetAsync($"http://127.0.0.1:{DefaultHttpPort}/v1.0/state/{AlbumStateStore}/{CollectionId}");
    var json = await response.Content.ReadAsStringAsync(); 
    
    if (!response.IsSuccessStatusCode)
    {
        throw new Exception($"Exception loading state. StatusCode: {response.StatusCode}. Message: {json}");
    }
    // Collection Id does not exist, therefore the database needs to be seeded 
    else if (response.StatusCode == HttpStatusCode.NoContent)
    {
        // Seed the state store 
        app.Logger.LogInformation("There is no state to retrieve. Seeding the state store with albums."); 
        
        var albumState = new []{
            new 
            {
                key = CollectionId,
                value = Album.GetAll() 
            }
        }; 
        
        var content = new StringContent(JsonSerializer.Serialize(albumState), Encoding.UTF8, "application/json");

        // override the initial response with the resulting data.
        response = await client.PostAsync($"http://127.0.0.1:{DefaultHttpPort}/v1.0/state/{AlbumStateStore}", content);
        
        if (response.IsSuccessStatusCode){
            app.Logger.LogInformation("Successfully seeded the dapr state store.");
        }
        else{
            throw new Exception($"Exception seeding state. StatusCode: {response.StatusCode}. Message: {json}");
        }; 

        // Get the newly seeded albums from the state store
        response = await client.GetAsync($"http://127.0.0.1:{DefaultHttpPort}/v1.0/state/{AlbumStateStore}/{CollectionId}");
    
        json = await response.Content.ReadAsStringAsync();
    }

    var albums = JsonSerializer.Deserialize<Album[]>(json); 
    
    if(albums != null && albums.Length > 0)
        app.Logger.LogInformation($"{albums.Length} albums were retrieved from the state store");
    
    return Results.Ok(albums);
}).WithName("GetAlbums");

app.Run();

record Album(int Id, string Title, string Artist, double Price, string Image_url)
{
     public static List<Album> GetAll(){
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