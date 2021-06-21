from datetime import datetime
import asyncio
import aiohttp # TODO Use lighter request library
import ijson
import json

import database
from lib import *

taskName = "listenbrainz-import-plays"

async def importPlays(username):
	task = addTask(Task(taskName))
	task.status = "Getting plays from ListenBrainz"

	playsImported = 0
	currentTime = int(datetime.utcnow().timestamp())
	earliestTime = currentTime

	async with aiohttp.ClientSession() as session:
		url = f'https://api.listenbrainz.org/1/user/{username}/listen-count'
		task.status = "Contacting ListenBrainz server..."
		response = await session.get(url)
		data = await response.json()
		totalPlays = data['payload']['count']
		task.total = int(totalPlays)
		print(f'A total of {totalPlays} have been found')
		while(task.isRunning()):
			if task.state == Task.STOPPING:
				tasks.pop(task.name, None)
				print("Cancelling getting plays from ListenBrainz")
				break
			url = f'https://api.listenbrainz.org/1/user/{username}/listens?max_ts={earliestTime}&count=100'
			task.status = "Requesting plays from ListenBrainz..."
			response = await session.get(url)
			data = await response.text()
			jsonData = json.loads(data)

			if(jsonData['payload']['count'] > 0):
				objects = ijson.items(data, 'payload.listens.item')
				for obj in objects:
					if not task.isRunning(): break
					unixTime = obj['listened_at']
					timestamp = datetime.utcfromtimestamp(unixTime).strftime('%Y-%m-%dT%H:%M:%SZ')
					artistNames = str(obj['track_metadata']["artist_name"]).split(', ') # Listenbrainz artists are delimited by a comma
					trackTitle = obj['track_metadata']["track_name"]
					await database.insertPlay(timestamp, artistNames, trackTitle)
					playsImported += 1
					if(earliestTime > unixTime): earliestTime = unixTime
					task.status = f"Imported {playsImported} plays. {artistNames[0]} - {trackTitle}"
					task.progress = playsImported
			else: break

			requestsRemaining = int(response.headers['x-ratelimit-remaining'])
			timeRemaining = int(response.headers['x-ratelimit-reset-in'])

			if(requestsRemaining <= 1):
				print(f'Waiting for {timeRemaining} seconds')
				await asyncio.sleep(timeRemaining+3)

			if playsImported >= totalPlays: break

		task.status = f"ListenBrainz import has stopped. {playsImported} plays were imported."
		task.setState(Task.STOPPED)
		print('ListenBrainz import has stopped')