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


## Background
I strongly believe that in order to get people caring about data they need to be shown why it is important to them through the things they care about.
However the things people care about aren't always the important stuff, sometimes data can be just for fun. As an example this app was inspired by the annual Spotify Wrapped event. It is one of the rare moments where I've seen the average person genuinely get excited about their data. Which is why I want to develop tools that are easy to use and make it easy to share data because if something is too difficult no one will use it.

## How It Works
PLEASE NOTE: This app is in very early stages and was not developed with open source in mind. Hence the lack of crucial features like unit tests, logs or comments therefore it is not representative of how I would code professionally.

- The core of the app is the uvicorn server found in *server/server.py*. From there all the http endpoints are set up for communicating with the GUI.
- The *client/lib* folder contains all the code for the GUI. This was built using the Flutter framework.
- The file *server/database.py* contains all the code for interacting with the SQLite database where all listening data is stored.
- The files *lastFM.py, spotify.py and listenBrainz.py* contain the code for retrieving data from the various REST API services.

## Screenshots
<p align="center">
  <img src="https://i.ibb.co/6sMkr3K/Capture-2.png">
  <img src="https://i.ibb.co/nR7KXZV/Capture-3.png">
</p>
