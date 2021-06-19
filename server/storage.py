import os
import json
from lib import *

CONFIG_FILE = getFilePath("config.json")

spotifyUsername: str = None
spotifyClientID: str = None
spotifyClientSecret: str = None
spotifyRefreshToken: str = None

#lastFM_API_Key: str = None
#lastFMUsername: str = None

def readFromFile():
	if os.path.isfile(CONFIG_FILE):
		with open(CONFIG_FILE) as userDataFile:
			jsonData = json.load(userDataFile)
			keys = jsonData.keys()
			global spotifyUsername, spotifyClientID, spotifyClientSecret, spotifyRefreshToken, lastFM_API_Key, lastFMUsername
			if('spotify-username' in keys): spotifyUsername = jsonData['spotify-username']
			if('spotify-client-id' in keys): spotifyClientID = jsonData['spotify-client-id']
			if('spotify-client-secret' in keys): spotifyClientSecret = jsonData['spotify-client-secret']
			if('spotify-refresh-token' in keys): spotifyRefreshToken = jsonData['spotify-refresh-token']
			#if('lastFM-api-key' in keys): lastFM_API_Key = jsonData['lastFM-api-key']
			#if('lastFM-username' in keys): lastFMUsername = jsonData['lastFM-username']
	else: writeToFile()

def writeToFile():
	with open(CONFIG_FILE, 'w') as userDataFile:
		jsonData = {}
		if(spotifyUsername is not None): jsonData['spotify-username'] = spotifyUsername
		if(spotifyClientID is not None): jsonData['spotify-client-id'] = spotifyClientID
		if(spotifyClientSecret is not None): jsonData['spotify-client-secret'] = spotifyClientSecret
		if(spotifyRefreshToken is not None): jsonData['spotify-refresh-token'] = spotifyRefreshToken
		#if(lastFM_API_Key is not None): jsonData['lastFM-api-key'] = lastFM_API_Key
		#if(lastFMUsername is not None): jsonData['lastFM-username'] = lastFMUsername
		json.dump(jsonData, userDataFile)