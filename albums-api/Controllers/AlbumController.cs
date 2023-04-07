using albums_api.Models;
using Microsoft.AspNetCore.Mvc;
using System.Net;
using System.Text.Json;
using System.Text;

// For more information on enabling Web API for empty projects, visit https://go.microsoft.com/fwlink/?LinkID=397860

namespace albums_api.Controllers
{
    [Route("albums")]
    [ApiController]
    public class AlbumController : ControllerBase
    {
        private const string CollectionId = "Albums";
        private const string AlbumStateStore = "statestore";
        private const string DefaultHttpPort = "3500";

        // GET: api/album
        [HttpGet]
        public List<Album> Get()
        {
            var albums = Album.GetAll();

            return Results.Ok(albums);
        }

        // GET api/<AlbumController>/5
        [HttpGet("{id}")]
        public string Get(int id)
        {
            return "value";
        }
    }
}
