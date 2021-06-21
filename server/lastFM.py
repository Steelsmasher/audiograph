import aiohttp
import json
import ijson
from datetime import datetime

import database
from lib import *


taskName = "lastfm-import-plays"

async def importPlays(username: str, apiKey: str):
	task = addTask(Task(taskName))
	task.status = "Getting plays from Last.fm"

	playsImported = 0
	nextPage = 1

	async with aiohttp.ClientSession() as session:
		while(task.isRunning()):
			url = f'http://ws.audioscrobbler.com/2.0/?method=user.getrecenttracks&user={username}&api_key={apiKey}&format=json&limit=200&page={nextPage}'
			task.status = "Requesting plays from Last.fm"
			response = await session.get(url)
			data = await response.text()
			jsonData = json.loads(data)
			currentPage = int(jsonData['recenttracks']['@attr']['page'])
			totalPages = int(jsonData['recenttracks']['@attr']['totalPages'])
			task.total = int(totalPages)

			objects = ijson.items(data, 'recenttracks.track.item')
			for obj in objects:
				if not task.isRunning(): break
				if 'date' not in obj: continue #If the 'date' key does not exist this may be the current playing track
				unixTime = int(obj['date']['uts'])
				timestamp = datetime.utcfromtimestamp(unixTime).strftime('%Y-%m-%dT%H:%M:%SZ')
				artistNames = str(obj['artist']["#text"]).split('; ') # Last.fm artists are delimited by a semi-colon
				trackTitle = obj['name']
				await database.insertPlay(timestamp, artistNames, trackTitle)
				playsImported += 1
				task.status = f"Imported {playsImported} plays. {artistNames[0]} - {trackTitle}"
				task.progress = currentPage
			
			nextPage = currentPage + 1
			if nextPage > totalPages: break

		task.status = f"Last.fm import has stopped. {playsImported} plays were imported."
		task.setState(Task.STOPPED)
		print('Last.fm import has stopped')