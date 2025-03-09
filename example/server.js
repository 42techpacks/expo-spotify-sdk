const axios = require("axios");
const express = require("express");
const { encode } = require("js-base64");
const qs = require("qs");

const app = express();

app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// Replace these with your own values
const CLIENT_ID = "5c2609755e2a456481524ba7e11c44c1";
const CLIENT_SECRET = "3ffc83c7883849c3a400dc04ff89bb0b";

const SPOTIFY_ACCOUNTS_ENDPOINT = "https://accounts.spotify.com";
const CLIENT_CALLBACK_URL = "spotify-login-sdk-test-app-swift://spotify-login-callback";
const AUTH_SECRET = encode(`${CLIENT_ID}:${CLIENT_SECRET}`);
const AUTH_HEADER = `Basic ${AUTH_SECRET}`;

app.post("/swap", async (req, res) => {
  console.log("=== TOKEN SWAP INITIATED ===");
  const { code } = req.body;
  console.log("code", code);

  try {
    const response = await axios.post(
      `${SPOTIFY_ACCOUNTS_ENDPOINT}/api/token`,
      qs.stringify({
        grant_type: "authorization_code",
        redirect_uri: CLIENT_CALLBACK_URL,
        code,
      }),
      {
        headers: {
          Authorization: AUTH_HEADER,
          "Content-Type": "application/x-www-form-urlencoded",
        },
      },
    );

    if (response.status !== 200) {
      console.log("=== TOKEN SWAP FAILED WITH RESPONSE: ", response.data);
      return res.status(response.status).send(response.data);
    }

    console.log("=== TOKEN SWAP SUCCEEDED WITH RESPONSE: ", response.data);
    res.status(response.status).json(response.data);
  } catch (error) {
    console.log("=== TOKEN SWAP FAILED ===");
    console.log({ error });
    res.status(500).send(error.message);
  }
});

app.post("/refresh", async (req, res) => {
  console.log("=== TOKEN REFRESH INITIATED ===");
  const { refresh_token } = req.body;

  try {
    const response = await axios.post(
      `${SPOTIFY_ACCOUNTS_ENDPOINT}/api/token`,
      qs.stringify({
        grant_type: "refresh_token",
        refresh_token,
      }),
      {
        headers: {
          Authorization: AUTH_HEADER,
          "Content-Type": "application/x-www-form-urlencoded",
        },
      },
    );

    if (response.status !== 200) {
      console.log("=== TOKEN REFRESH FAILED WITH RESPONSE: ", response.data);
      return res.status(response.status).send(response.data);
    }

    console.log("=== TOKEN REFRESH SUCCEEDED WITH RESPONSE: ", response.data);
    res.status(response.status).send(response.data);
  } catch (error) {
    console.log({ error });
    res.status(500).send(error.message);
  }
});

app.listen(3000, () => {
  console.log("Server is running on port 3000");
});
