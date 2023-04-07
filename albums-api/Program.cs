var builder = WebApplication.CreateBuilder(args);

var DefaultHttpPort = Environment.GetEnvironmentVariable("DAPR_HTTP_PORT") ?? "3500";
var AlbumStateStore = "statestore";
var CollectionId = Environment.GetEnvironmentVariable("COLLECTION_ID") ?? "GreatestHits";

// Add services to the container.

builder.Services.AddControllers();
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

app.UseHttpsRedirection();

app.UseAuthorization();

app.MapGet("/", async context =>
{
    await context.Response.WriteAsync("Hit the /albums endpoint to retrieve a list of albums!");
});

app.MapControllers();

app.Run();
