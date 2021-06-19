import asyncio
import uvicorn
import json
import database
from datetime import datetime
from fastapi import FastAPI, Query, WebSocket
import sys
import logging
from websockets.exceptions import ConnectionClosedError
from logging.handlers import RotatingFileHandler

from lib import *
import storage
import spotify
import lastFM
import listenBrainz

initialiseDirectory()

FORMATTER = logging.Formatter("%(asctime)s - %(levelname)s:\t%(message)s")
LOG_FILE = getFilePath("server.log")
consoleHandler = logging.StreamHandler(sys.stdout)
fileHandler = RotatingFileHandler(LOG_FILE, maxBytes=2000)
consoleHandler.setFormatter(FORMATTER)
fileHandler.setFormatter(FORMATTER)
logger = logging.getLogger("audiograph")
logger.addHandler(consoleHandler) # Enables logging to console
logger.addHandler(fileHandler) # Enables logging to file
logger.setLevel(logging.DEBUG)

logger.info("Starting server")

app = FastAPI()

serverHost = "127.0.0.1"
serverPort = 8080
spotifyRedirectURI = f'http://{serverHost}:{serverPort}/spotify-callback'


@app.get("/")
async def root():
	return 'This is the homepage'

@app.get('/ping')
async def ping():
	timestamp = datetime.utcnow().isoformat()[:-3]+'Z'
	return {"timestamp": timestamp}

@app.get('/play') # TODO Consider changing to '/plays' ALSO Consider versioning the api i.e. '/v1/plays'
async def getPlays(
		startDate: str = '0000-01-01T00:00:00Z',
		endDate: str = datetime.utcnow().isoformat()[:-3]+'Z',
		limit: int = 1000,
		offset: int = 0
	):
	logger.info('Getting plays')

	logger.debug(f'Start Date: {startDate}\nEnd Date: {endDate}\nLimit: {str(limit)},\nOffset: {str(offset)}')
	plays = await database.getPlays(startDate, endDate, limit, offset)
	return plays

@app.get('/track-plays') # TODO Consider nesting this endpoint i.e. '/track/plays'
async def getTrackPlays(
		trackTitle: str, # TODO Sanitise this
		artistNames: str,
		startDate: str = '0000-01-01T00:00:00Z',
		endDate: str = datetime.utcnow().isoformat()[:-3]+'Z',
		limit: int = 1000,
		offset: int = 0
	):
	logger.info('Getting plays of track')
	artistNames = json.loads(artistNames) # TODO Sanitise this, may come as one string or list
	if(type(artistNames) is str): artistNames = [artistNames] # If artistNames were a string then sanitise to a list

	logger.debug('Track Title: ' + trackTitle + '\nStart Date: ' + startDate + '\nEnd Date: ' + endDate + '\nLimit: ' + str(limit), '\nOffset: ' + str(offset))
	trackPlays = await database.getTrackPlays(trackTitle, artistNames, startDate, endDate, limit, offset)
	logger.debug('Returning plays by track of size: ' + str(len(trackPlays)))
	return trackPlays

@app.get('/artist-plays') # TODO Consider nesting this endpoint i.e. '/track/plays'
async def getArtistPlays(
		artistName: str = Query(None, alias="artist-name"), # TODO Sanitise this
		startDate: str = '0000-01-01T00:00:00Z',
		endDate: str = datetime.utcnow().isoformat()[:-3]+'Z',
		limit: int = 1000,
		offset: int = 0,
	):
	logger.info('Getting plays of artist')
	logger.debug('Artist: ' + artistName + '\nStart Date: ' + startDate + '\nEnd Date: ' + endDate + '\nLimit: ' + str(limit), '\nOffset: ' + str(offset))
	artist = Artist(artistName)
	artistPlays = await database.getArtistPlays(artist, startDate, endDate, limit, offset)
	logger.debug('Returning plays by artist of size: ' + str(len(artistPlays)))
	return artistPlays

@app.get('/track-count')
async def getTrackCount(
		trackTitle: str, # TODO Sanitise this
		artistNames: str, # TODO Sanitise this, may come as one string or list
		startDate: str = '0000-01-01T00:00:00Z',
		endDate: str = datetime.utcnow().isoformat()[:-3]+'Z',
		limit: int = 1000,
		offset: int = 0
	):
	logger.info('Getting count of track')
	artistNames = json.loads(artistNames)
	if(type(artistNames) is str): artistNames = [artistNames] # If artistNames were a string then sanitise to a list
	logger.debug('Track Title: ' + trackTitle + '\nStart Date: ' + startDate + '\nEnd Date: ' + endDate + '\nLimit: ' + str(limit), '\nOffset: ' + str(offset))
	trackCount = await database.getTrackCount(trackTitle, artistNames, startDate, endDate, limit, offset)
	logger.debug('Returning track count: ' + str(trackCount))
	return trackCount

@app.get('/totalPlays')
async def getTotalPlays():
	logger.info('Getting total number of plays')
	total = await database.getTotalPlays()
	return {"total": total}

@app.get('/totalTracks')
async def getTotalTracks():
	logger.info('Getting total number of tracks')
	total = await database.getTotalTracks()
	return {"total": total}

@app.get('/total-days')
async def getTotalDays():
	logger.info('Getting total number of days')
	total = await database.getTotalDays()
	return {"total": total}

@app.get('/total-months')
async def getTotalMonths():
	logger.info('Getting total number of months')
	total = await database.getTotalMonths()
	return {"total": total}

@app.get('/total-years')
async def getTotalYears():
	logger.info('Getting total number of years')
	total = await database.getTotalYears()
	return {"total": total}

@app.get('/earliest-play')
async def getEarliestPlay():
	logger.info('Getting earliest play')
	play = await database.getEarliestPlay()
	return play.asDict()

@app.get('/latest-play')
async def getLatestPlay():
	logger.info('Getting latest play')
	play = await database.getLatestPlay()
	return play.asDict()

@app.get('/earliest-artist-play')
async def getEarliestArtistPlay(artistName: str = Query(None, alias="artist-name")):
	logger.info('Getting earliest artist play')
	artist = Artist(artistName)
	play = await database.getEarliestArtistPlay(artist)
	return play.asDict()

@app.get('/latest-artist-play')
async def getLatestArtistPlay(artistName: str = Query(None, alias="artist-name")):
	logger.info('Getting latest artist play')
	artist = Artist(artistName)
	play = await database.getLatestArtistPlay(artist)
	return play.asDict()

@app.get('/earliest-track-play')
async def getEarliestTrackPlay(trackTitle:str, artistNames: str):
	logger.info('Getting earliest track play')
	artistNames = json.loads(artistNames) # TODO Sanitise this, may come as one string or list
	track = Track(trackTitle, artistNames)
	play = await database.getEarliestTrackPlay(track)
	return play.asDict()

@app.get('/latest-track-play')
async def getLatestTrackPlay(trackTitle:str, artistNames: str):
	logger.info('Getting latest track play')
	artistNames = json.loads(artistNames) # TODO Sanitise this, may come as one string or list
	track = Track(trackTitle, artistNames)
	play = await database.getLatestTrackPlay(track)
	return play.asDict()

@app.get('/play-period-counts')
async def getPlayPeriodCounts(
		trackTitle: str = None,
		artistName: str = Query(None, alias="artist-name"), # TODO Sanitise this
		artistNames: str = None,
		startDate: str = '0000-01-01T00:00:00Z',
		endDate: str = datetime.utcnow().isoformat()[:-3]+'Z',
		period: str = "DAY",
		limit: int = 100,
		offset: int = 0,
	):
	if(artistNames != None): artistNames = json.loads(artistNames)
	artist = None if(artistName == None) else Artist(artistName)
	track = None if(trackTitle == None or artistNames == None) else Track(trackTitle, artistNames)

	periodCounts = await database.getPlayPeriodCounts(artist, track, startDate, endDate, period, limit, offset)
	return periodCounts

@app.get('/track-play-period-counts')
async def getTrackPlayPeriodCounts(
		trackTitle: str,
		artistNames: str,
		startDate: str = '0000-01-01T00:00:00Z',
		endDate: str = datetime.utcnow().isoformat()[:-3]+'Z',
		period: str = "DAY",
		limit: int = 100,
		offset: int = 0
	):
	artistNames = json.loads(artistNames) # TODO Sanitise this, may come as one string or list

	track = Track(trackTitle, artistNames)
	periodCounts = await database.getTrackPlayPeriodCounts(track, startDate, endDate, period, limit, offset)
	return periodCounts

@app.get('/artistCount')
async def getArtistCounts(
		startDate: str = '0000-01-01T00:00:00Z',
		endDate: str = datetime.utcnow().isoformat()[:-3]+'Z',
	):
	logger.debug('Getting artist counts\n\tStart Date: ' + startDate + '\n\tEnd Date: ' + endDate)
	counts = await database.getArtistCounts(startDate, endDate)
	return counts

@app.get('/artist-play-count')
async def getArtistPlayCount(
		artistName: str,
		startDate: str = '0000-01-01T00:00:00Z',
		endDate: str = datetime.utcnow().isoformat()[:-3]+'Z',
		limit: int = 1000,
		offset: int = 0
	):
	logger.info('Getting count of artist')
	
	artist = Artist(artistName)
	artistPlayCount = await database.getArtistPlayCount(artist, startDate, endDate, limit, offset)
	return artistPlayCount


@app.get('/trackCount')
async def getTrackCounts(
		startDate: str = '0000-01-01T00:00:00Z',
		endDate: str = datetime.utcnow().isoformat()[:-3]+'Z'
	):
	logger.debug('Getting track counts\n\tStart Date: ' + startDate + '\n\tEnd Date: ' + endDate)
	counts = await database.getTrackCounts(startDate, endDate)
	return counts

@app.get('/artistPlayCount')
async def getArtistPlayCounts(
		startDate: str = '0000-01-01T00:00:00Z',
		endDate: str = datetime.utcnow().isoformat()[:-3]+'Z'
	):
	logger.debug('Getting artist play counts\n\tStart Date: ' + startDate + '\n\tEnd Date: ' + endDate)
	playCounts = await database.getArtistPlayCounts(startDate, endDate)
	return playCounts

@app.get('/trackPlayCount')
async def getTrackPlayCounts(
		startDate: str = '0000-01-01T00:00:00Z',
		endDate: str = datetime.utcnow().isoformat()[:-3]+'Z',
		limit: int = 1000,
		offset: int = 0
	):
	logger.debug('Getting track play counts\n\tStart Date: ' + startDate + '\n\tEnd Date: ' + endDate)
	playCounts = await database.getTrackPlayCounts(startDate, endDate, limit, offset)
	return playCounts

@app.get('/trackPlayCount')
async def getTrackPlayCounts(
		startDate: str = '0000-01-01T00:00:00Z',
		endDate: str = datetime.utcnow().isoformat()[:-3]+'Z',
		limit: int = 1000,
		offset: int = 0
	):
	logger.debug('Getting track play counts\n\tStart Date: ' + startDate + '\n\tEnd Date: ' + endDate)
	playCounts = await database.getTrackPlayCounts(startDate, endDate, limit, offset)
	return playCounts

@app.put('/play') # TODO Consider GET and POST only for 3rd party compatibility
async def insertPlay(
		artistNames: str,
		trackTitle: str,
		timestamp: str = datetime.utcnow().isoformat()[:-3]+'Z'
	):
	await database.insertPlay(timestamp, artistNames, trackTitle)
	return f'Inserted track {artistNames} - {trackTitle} at {timestamp}'

#@app.route('/storePlaysFromListenBrainz', methods=['POST'])
#async def storePlaysFromListenBrainz():
#	if('store-plays-from-listenbrainz' in tasks): return "Task already running"
#	tasks['store-plays-from-listenbrainz'] = Task('store-plays-from-listenbrainz')
#	task = tasks['store-plays-from-listenbrainz']
#	username = request.args.get("username")
#	asyncio.create_task( storePlaysFromListenBrainz(task, username) )
#	return "Getting plays from Listenbrainz"

@app.get('/track-period-counts')
async def getTrackPeriodCounts(
		startDate: str = '0000-01-01T00:00:00Z',
		endDate: str = datetime.utcnow().isoformat()[:-3]+'Z',
		period: str = 'DAY',
		limit: int = 100,
	):
	logger.debug('Getting track period counts\n\tStart Date: ' + startDate + '\n\tEnd Date: ' + endDate)
	trackPeriodCounts = await database.getTrackPeriodCounts(startDate, endDate, period, limit)
	return trackPeriodCounts

@app.get('/artist-period-counts')
async def getArtistPeriodCounts(
		startDate: str = '0000-01-01T00:00:00Z',
		endDate: str = datetime.utcnow().isoformat()[:-3]+'Z',
		period: str = 'DAY',
		limit: int = 100
	):
	logger.debug('Getting artist period counts\n\tStart Date: ' + startDate + '\n\tEnd Date: ' + endDate)
	artistPeriodCounts = await database.getArtistPeriodCounts(startDate, endDate, period, limit)
	return artistPeriodCounts

#@app.websocket('/importFromListenBrainz')
#async def importFromListenBrainz():
#	filePath = await websocket.receive()
#	print(f"Importing file: {filePath}")
#	tracksImported = 0
#
#	with open(filePath) as file:
#		trackCount = file.read().count("track_metadata")
#		print("There are " + str(trackCount) + " tracks")
#
#	with open(filePath) as file:
#		objects = ijson.items(file, 'item')
#		for obj in objects:
#			unixTime = obj['listened_at']
#			timestamp = datetime.utcfromtimestamp(unixTime).strftime('%Y-%m-%dT%H:%M:%SZ')
#			artistNames = str(obj['track_metadata']["artist_name"]).split('; ') # Artists from Listenbrainz import are delimited by a semi-colon
#			trackTitle = obj['track_metadata']["track_name"]
#			database.insertPlay(timestamp, artistNames, trackTitle)
#			tracksImported += 1
#			progress = str(tracksImported*100/(trackCount+1))
#
#			message = f'Inserted track {artistNames} - {trackTitle} at {timestamp} on {unixTime}'
##			status = {
#				"message": message,
#				"progress": progress
#			}
#			await websocket.send_json(status)
#			print(f'{progress}\t{message}\r')

@app.get('/tasks')
async def getTasks():
	data = {}
	for key in tasks.keys(): data[key] = vars(tasks[key]) # Convert Tasks to dictionary objects
	return data

@app.websocket('/tasks')
async def streamTasks(websocket: WebSocket):
	await websocket.accept()
	try:
		while True:
			data = {}
			for key in tasks.keys(): data[key] = vars(tasks[key]) # Convert Tasks to dictionary objects
			await websocket.send_json(data)
			await asyncio.sleep(0.25) # TODO Make this bidirectional (websocket.receive) and close websocket if response times out
	except ConnectionClosedError as error:
		logger.debug(f"Client disconnected from tasks websocket with error code: {error.code}")
		await websocket.close()

@app.post('/cancel-task')
async def cancelTask(taskName: str = Query(None, alias='task-name')):
	logger.info(f"The task {taskName} was requested to stop")
	asyncio.create_task( endTask(taskName) )
	return f"The task {taskName} has been requested to stopped"

@app.get('/spotify-callback')
async def getSpotifyCallback(code: str):
	spotify.initialiseClient(code)
	return 'Spotify Authentication Complete!'

@app.get('/spotify-redirect-uri')
async def getSpotifyRedirectURI(): return spotifyRedirectURI

@app.post('/spotify-initialise-authorisation')
async def initialiseSpotifyAuthorisation(
		clientID: str = Query(None, alias="client-id"),
		clientSecret: str = Query(None, alias="client-secret")
	):
	logger.debug(f"Received ClientID: {clientID}, and Client Secret: {clientSecret}")
	spotify.initialiseAuthorisation(clientID, clientSecret, spotifyRedirectURI)
	storage.spotifyClientID = clientID
	storage.spotifyClientSecret = clientSecret
	storage.writeToFile()
	return 'Success'

@app.get('/spotify-authorisation-url')
async def getSpotifyAuthorisationURL():	return spotify.getAuthorisationURL()

@app.post('/spotify-disconnect')
async def disconnectSpotify():
	await spotify.disconnect()
	return 'Success'

@app.post('/lastfm-import-plays')
async def importFromLastFM(
		username: str,
		apiKey: str
	):
	if('lastfm-import-plays' in tasks.keys()): return "Task already running"
	asyncio.create_task( lastFM.importPlays(username, apiKey) )
	return "Getting plays from last.fm"

@app.post('/listenbrainz-import-plays')
async def importFromListenBrainz(username: str):
	if('listenbrainz-import-plays' in tasks.keys()): return "Task already running"
	asyncio.create_task( listenBrainz.importPlays(username) )
	return "Getting plays from ListenBrainz"

@app.get('/plugins')
async def getPlugins(): return {'Spotify': spotify.isConfigured()}

@app.on_event("startup")
async def initialise():
	await database.initialise()
	spotify.initialise(spotifyRedirectURI)

storage.readFromFile()

uvicorn.run(app, host=serverHost, port=serverPort)
