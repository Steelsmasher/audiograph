# Audiograph

A standalone application that tracks the music you are listening to and shows statistics.
All data is stored locally on your machine and not sent anywhere else.

## Setup
1. Download the installer at https://audiograph.app/
2. Once installed you will be presented with the connections page. The easiest source to setup is ListenBrainz
<p align="center">
  <img src="https://i.ibb.co/pLk1Yyc/Capture.png">
</p>
3. If you have a ListenBrainz account you can enter your username. If not you can pick a user from the publically avaible list here: https://listenbrainz.org/recent.
I use "stebe" for testing.

## How It Works

- The core of the app is the uvicorn server found in *server/server.py*. From there all the http endpoints are set up for communicating with the GUI.
- The *client/lib* folder contains all the code for the GUI. This was built using the Flutter framework.
- The file *server/database.py* contains all the code for interacting with the SQLite database where all listening data is stored.
- The files *lastFM.py, spotify.py and listenBrainz.py* contain the code for retrieving data from the various REST API services.

## Screenshots
<p align="center">
  <img src="https://i.ibb.co/6sMkr3K/Capture-2.png">
  <img src="https://i.ibb.co/nR7KXZV/Capture-3.png">
</p>
