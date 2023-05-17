var express = require("express");
var router = express.Router();
require("dotenv").config();
const axios = require("axios");

const DAPR_HOST = process.env.DAPR_HOST || "localhost";
const DAPR_HTTP_PORT = process.env.DAPR_HTTP_PORT || "3500";
const Background = process.env.BACKGROUND_COLOR || "black";

/* GET home page. */
router.get("/", async function (req, res, next) {
  try {
    const url = `http://${DAPR_HOST}:${DAPR_HTTP_PORT}/albums`;
    let axiosConfig = {
      headers: {
          "dapr-app-id": "albumapi",
      }
    }
    console.log("Invoking albumapi via dapr:  -H 'dapr-app-id: albumapi' " + url );
    var response = await axios.get(url, axiosConfig);

    data = response.data || [];
    console.log("Response from backend albums api: ", data);
    res.render("index", {
      albums: data,
      background_color: Background,
    });
  } catch (err) {
    console.log("Error: ", err);
    next(err);
  }
});

module.exports = router;
