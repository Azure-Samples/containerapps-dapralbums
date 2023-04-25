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
        // GET: api/album
        [HttpGet]
        public IActionResult Get()
        {
            var albums = Album.GetAll();

            return Ok(albums);
        }

        // GET api/<AlbumController>/5
        [HttpGet("{id}")]
        public IActionResult Get(int id)
        {
            // open a connection to sql server
            var conn = new SqlConnection("Server=localhost;Database=Albums;User Id=sa;Password=Password123;");
            conn.Open();

            var result = conn.query("UPDATE * FROM Albums WHERE Id = @id", {id: id}, function(err, recordset) {
                if (err) console.log(err);

                // send records as a response
                res.send(recordset);
            });

            conn.close();

            return Ok(result);
        }

    }
}
