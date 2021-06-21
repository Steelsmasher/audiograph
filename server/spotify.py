import spotipy
from spotipy.oauth2 import SpotifyOAuth
from spotipy.cache_handler import CacheHandler
from typing import List
import asyncio

import storage
import database
from lib import *

spotifyOAuth: SpotifyOAuth
spotifyClient: spotipy.Spotify = None
task: Task

class SpotipyHandler(CacheHandler):

	tokenInfo = {}

	def get_cached_token(self):
		tokenInfo = self.tokenInfo
		return tokenInfo

	def save_token_to_cache(self, token_info):
		self.tokenInfo = token_info
		storage.spotifyRefreshToken = token_info['refresh_token'] # Refresh token must always be in sync with data stored to file
		storage.writeToFile()

def initialiseAuthorisation(clientID, clientSecret, redirectURI):
	global spotifyOAuth
	spotifyOAuth = SpotifyOAuth(
		client_id=clientID,
		client_secret=clientSecret,
		redirect_uri=redirectURI,
		open_browser=False,
		cache_handler=SpotipyHandler(),
		show_dialog = True,
		scope = 'user-read-recently-played user-read-currently-playing'
	)
	

def getAuthorisationURL(): return spotifyOAuth.get_authorize_url()

def initialiseClient(code: str = None, refreshToken: str = None):
	if(code != None): spotifyOAuth.get_access_token(code) # This is used to retrieve the refresh token during initial authorisation.
	if(refreshToken != None):
		print(f'Refreshing acess token with: ${refreshToken}')
		spotifyOAuth.refresh_access_token(refreshToken)
	global spotifyClient
	spotifyClient = spotipy.Spotify(auth_manager=spotifyOAuth)
	asyncio.create_task( runPlugin() )

def isConfigured() -> bool:	return spotifyClient is not None

def initialise(redirectURI):
	if(None not in [storage.spotifyClientID, storage.spotifyClientSecret, storage.spotifyRefreshToken]):
		initialiseAuthorisation(storage.spotifyClientID, storage.spotifyClientSecret, redirectURI)
		initialiseClient(refreshToken = storage.spotifyRefreshToken)

async def getRecentPlays() -> List[Play]:
	print('Fetching recent plays from Spotify')
	task.status = 'Requesting plays from Spotify'
	data = spotifyClient.current_user_recently_played()
	playHistoryObjects = data['items']
	for playHistoryobject in playHistoryObjects:
		if not task.isRunning(): break
		timestamp = playHistoryobject['played_at']
		simplifiedTrackObject = playHistoryobject['track']
		trackTitle = simplifiedTrackObject['name']
		artistNames: List[str] = []
		for simplifiedArtistObject in simplifiedTrackObject['artists']:
			artistName = simplifiedArtistObject['name']
			artistNames.append(artistName)
		play = Play(timestamp, artistNames, trackTitle)
		task.status = f"Importing {play.artistNames[0]} - {play.trackTitle}"
		await database.insertPlay(timestamp, artistNames, trackTitle)


async def runPlugin():
	print('Starting Spotify Plugin')
	global task
	task = addTask(Task('spotify', total = -1))
	interval = 30
	
	while(task.state == Task.RUNNING):
		await getRecentPlays()
		for count in range(interval):
			task.status = f'Spotify plays will be updated in {interval-count} seconds'
			if(tasks["spotify"].isRunning()): await asyncio.sleep(1)
	tasks["spotify"].state = Task.STOPPED
	print("Spotify plugin has stopped")

async def disconnect():
	print('Disconnecting Spotify Plugin')
	await endTask("spotify")
	storage.spotifyUsername = None
	storage.spotifyClientID = None
	storage.spotifyClientSecret = None
	storage.spotifyRefreshToken = None
	storage.writeToFile()
	global spotifyClient, spotifyOAuth
	spotifyClient = spotifyOAuth = None
	print("Spotify plugin is disconnected")