import aiosqlite
import json
from datetime import datetime
from typing import List
from lib import *

playsTable = 'Play'
artistsTable = 'Artist'
tracksTable = 'Track'

class Batch(): # Enables multiple sql statements in a single transaction
	statements: list

	def __init__(self): self.statements = []

	def add(self, sql: str, params=()):
		if(type(params) is not tuple): params = (params,) # If not a tuple, it's probably a string to be converted into tuple
		self.statements.append((sql, params))

	async def execute(self):
		async with connect() as connection:
			connection.row_factory = aiosqlite.Row
			async with connection.cursor() as cursor:
				await cursor.execute("BEGIN TRANSACTION", ())
				for sql in self.statements:	await cursor.execute(sql[0], sql[1])
				await cursor.execute("END TRANSACTION", ())


def connect():
	try:
		return aiosqlite.connect(getFilePath("data.db"))
	except aiosqlite.Error as e:
		print(e)

async def execute(sql, params=()):
	async with connect() as connection:
		connection.row_factory = aiosqlite.Row
		async with connection.cursor() as cursor:
			await cursor.execute(sql, params)
			return await cursor.fetchall()

async def initialise():
	batch = Batch()
	batch.add(f'''
		CREATE TABLE IF NOT EXISTS {artistsTable} (
			artistName TEXT,
			artistPlayCount INTEGER DEFAULT 0,
			PRIMARY KEY (artistName)
		) WITHOUT ROWID;
	''')
	batch.add(f'''
		CREATE TABLE IF NOT EXISTS {tracksTable} (
			trackTitle TEXT,
			artistNames TEXT,
			PRIMARY KEY(trackTitle, artistNames)
		) WITHOUT ROWID;
	''')
	batch.add(f'''
		CREATE TABLE IF NOT EXISTS {playsTable} (
			timestamp DATETIME,
			artistNames TEXT,
			trackTitle TEXT,
			PRIMARY KEY (timestamp)
			--FOREIGN KEY(trackTitle, artistNames) REFERENCES {tracksTable}(trackTitle, artistNames)
		) WITHOUT ROWID;
	''')

	await batch.execute()

def getStrftimeModifer(period: str):
	if(period == "DAY"): return r'%Y-%m-%d'
	if(period == "WEEKDAY"): return r'%w'
	if(period == "MONTH"): return r'%Y-%m'
	if(period == "YEAR"): return r'%Y'
	return r'%m-%d' # Return day by default

def getAdditionModifier(period: str):
	if(period == "DAY"): return 'day'
	if(period == "WEEKDAY"): return 'day'
	if(period == "MONTH"): return 'month'
	if(period == "YEAR"): return 'year'
	return 'day' # Return day by default

async def insertPlay(timestamp: str, artistNames: List[str], trackTitle: str): # TODO Refactor to accept Play object
	batch = Batch()
	existingTrack = await getTrack(trackTitle, artistNames)
	existingArtistNames = artistNames if(existingTrack is None) else existingTrack.artistNames # This ensures that if the track pre-exists the play will be added with any unspecified guest artists

	artistsList = json.dumps(existingArtistNames) # Convert artists list to be stored as json
	
	for artistName in existingArtistNames:
		batch.add(f'''
			INSERT OR IGNORE INTO {artistsTable}(artistName)  -- Ensures the artist exists in the database
				VALUES (?);
		''', (artistName))
		batch.add(f'''
			UPDATE {artistsTable} SET artistPlayCount = artistPlayCount + 1
				WHERE artistName = ?
		''', (artistName))
	
	batch.add(f'''
		INSERT OR IGNORE INTO {tracksTable}(trackTitle, artistNames)
			VALUES (?, ?);
		''', (trackTitle, artistsList))

	batch.add(f'''
		REPLACE INTO {playsTable} (timestamp, artistNames, trackTitle) VALUES(?, ?, ?)
	''', (timestamp, artistsList, trackTitle))
	await batch.execute()

async def insertPlays(plays: List[Play]):
	for play in plays: await insertPlay(play.timestamp, play.artistNames, play.trackTitle)


async def getTotalPlays() -> int:
	total = await execute(f'SELECT COUNT(*) AS total FROM {playsTable}')
	return total[0]['total']

async def getTotalTracks() -> int:
	total = await execute(f'''
		SELECT
			COUNT(*) AS total
		FROM(
			SELECT DISTINCT {playsTable}.artistNames, {playsTable}.trackTitle FROM {playsTable}
		)'''
	)
	return total[0]['total']

async def getTotalDays() -> int: # TODO This needs to be the total number of days between the first and last ever play, it must include days without plays
	total = await execute(f'''
		SELECT
			COUNT(*) AS total
		FROM(
			SELECT date({playsTable}.timestamp, 'localtime') AS timestamp
			FROM {playsTable}
			GROUP BY strftime('%Y-%m-%d', timestamp)
		)'''
	)
	return total[0]['total']

async def getTotalMonths() -> int:
	total = await execute(f'''
		SELECT
			COUNT(*) AS total
		FROM(
			SELECT date({playsTable}.timestamp, 'localtime') AS timestamp
			FROM {playsTable}
			GROUP BY strftime('%Y-%m', timestamp)
		)'''
	)
	return total[0]['total']

async def getTotalYears() -> int:
	total = await execute(f'''
		SELECT
			COUNT(*) AS total
		FROM(
			SELECT date({playsTable}.timestamp, 'localtime') AS timestamp
			FROM {playsTable}
			GROUP BY strftime('%Y', timestamp)
		)'''
	)
	return total[0]['total']

async def getEarliestPlay() -> Play:
	sql = '''
		SELECT
			min(timestamp) as timestamp,
			trackTitle,
			artistNames
		FROM Play
	'''
	rawPlay = await execute(sql, [])
	timestamp = rawPlay[0]['timestamp']
	trackTitle = rawPlay[0]['trackTitle']
	artistNames = json.loads(str(rawPlay[0]['artistNames']))
	return Play(timestamp, artistNames, trackTitle)

async def getLatestPlay() -> Play:
	sql = '''
		SELECT
			max(timestamp) as timestamp,
			trackTitle,
			artistNames
		FROM Play
	'''
	rawPlay = await execute(sql, [])
	timestamp = rawPlay[0]['timestamp']
	trackTitle = rawPlay[0]['trackTitle']
	artistNames = json.loads(str(rawPlay[0]['artistNames']))
	return Play(timestamp, artistNames, trackTitle)


async def getEarliestTrackPlay(track: Track) -> Play:
	sql = '''
		SELECT
			min(timestamp) as timestamp,
			trackTitle,
			artistNames,
			json_array_length(artistNames) numOfArtists
		FROM Play JOIN json_each(Play.artistNames)
		WHERE trackTitle = trim(?) COLLATE NOCASE
	'''

	for __ in track.artistNames:
		sql += ' AND json_each.value = ? COLLATE NOCASE'
	
	sql += ' ORDER BY numOfArtists ASC -- Ensures matching the track with the fewest artists'

	parameters = [track.title]
	parameters.extend(track.artistNames)

	rawTrackPlay = await execute(sql, parameters)
	timestamp = rawTrackPlay[0]['timestamp']
	trackTitle = rawTrackPlay[0]['trackTitle']
	artistNames = json.loads(str(rawTrackPlay[0]['artistNames']))
	return Play(timestamp, artistNames, trackTitle)

async def getLatestTrackPlay(track: Track) -> Play:
	sql = f'''
		SELECT
			max(timestamp) as timestamp,
			trackTitle,
			artistNames,
			json_array_length(artistNames) numOfArtists
		FROM {playsTable} JOIN json_each({playsTable}.artistNames)
		WHERE trackTitle = trim(?) COLLATE NOCASE

	'''

	for __ in track.artistNames:
		sql += ' AND json_each.value = ? COLLATE NOCASE'
	
	sql += ' ORDER BY numOfArtists ASC -- Ensures matching the track with the fewest artists'

	parameters = [track.title]
	parameters.extend(track.artistNames)

	rawTrackPlay = await execute(sql, parameters)
	timestamp = rawTrackPlay[0]['timestamp']
	trackTitle = rawTrackPlay[0]['trackTitle']
	artistNames = json.loads(str(rawTrackPlay[0]['artistNames']))
	return Play(timestamp, artistNames, trackTitle)

async def getEarliestArtistPlay(artist: Artist) -> Play:
	sql = '''
		SELECT
			min(timestamp) as timestamp,
			trackTitle,
			artistNames,
			json_array_length(artistNames) numOfArtists
		FROM Play JOIN json_each(Play.artistNames)
		WHERE json_each.value = ? COLLATE NOCASE
	'''

	parameters = [artist.name]

	rawArtistPlay = await execute(sql, parameters)
	timestamp = rawArtistPlay[0]['timestamp']
	trackTitle = rawArtistPlay[0]['trackTitle']
	artistNames = json.loads(str(rawArtistPlay[0]['artistNames']))
	return Play(timestamp, artistNames, trackTitle)

async def getLatestArtistPlay(artist: Artist) -> Play:
	sql = f'''
		SELECT
			max(timestamp) as timestamp,
			trackTitle,
			artistNames,
			json_array_length(artistNames) numOfArtists
		FROM Play JOIN json_each(Play.artistNames)
		WHERE json_each.value = ? COLLATE NOCASE
	'''

	parameters = [artist.name]

	rawArtistPlay = await execute(sql, parameters)
	timestamp = rawArtistPlay[0]['timestamp']
	trackTitle = rawArtistPlay[0]['trackTitle']
	artistNames = json.loads(str(rawArtistPlay[0]['artistNames']))
	return Play(timestamp, artistNames, trackTitle)

async def getPlays(startDate = '0000-01-01T00:00:00Z', endDate = datetime.utcnow().isoformat()[:-3]+'Z', limit = 1000, offset = 0) -> List[Play]:
	rawPlays = await execute(f'''
		SELECT
			PLAYS.timestamp AS timestamp,
			PLAYS.trackTitle AS trackTitle,
			PLAYS.artistNames AS artistNames
		FROM {playsTable} PLAYS
		WHERE PLAYS.timestamp BETWEEN ? AND ?
		ORDER BY timestamp DESC
		LIMIT ? OFFSET ?
	''', (startDate, endDate, limit, offset))

	plays: List[Play] = []
	for row in rawPlays: # Converts rows to Plays
		artistNames = json.loads(str(row['artistNames']))
		play = Play(row['timestamp'], artistNames, row['trackTitle'])
		plays.append(play.asDict())
	return plays

async def getPlayPeriodCounts(artist: Artist = None, track: Track = None, startDate = '0000-01-01T00:00:00Z', endDate = datetime.utcnow().isoformat()[:-3]+'Z', period = "DAY", limit = 100, offset = 0):
	"""Retrieve the number of plays in a given period"""
	format = getStrftimeModifer(period)
	modifier = getAdditionModifier(period)
	parameters = []

	sql = f'''
		WITH
			RECURSIVE dateRange(indx, period) AS (
				SELECT date('{endDate}'), strftime('{format}', '{endDate}')
				UNION ALL
				SELECT
					date(indx, '-1 {modifier}'),
					strftime('{format}', indx, '-1 {modifier}') AS period
				FROM dateRange
				WHERE indx > date('{startDate}')
				LIMIT {limit} OFFSET {offset}
			),
	'''

	if(artist != None): # If an artist is supplied, query for all plays by that artist
		sql += f'''
			counts(period, count) AS (
				SELECT
					strftime('{format}', timestamp, 'localtime') AS period,
					count(*) AS count
					FROM {playsTable} JOIN json_each({playsTable}.artistNames)
					WHERE period BETWEEN strftime('{format}', '{startDate}') AND strftime('{format}', '{endDate}')
					AND json_each.value = ? COLLATE NOCASE
					GROUP BY period
			)
		'''
		parameters = [artist.name]
	elif(track != None): # If an track is supplied, query for all plays by that track
		sql += f'''
			counts(period, count) AS (
				SELECT
					strftime('{format}', timestamp, 'localtime') AS period,
					count(*) AS count
					FROM {playsTable} JOIN json_each({playsTable}.artistNames)
					WHERE period BETWEEN strftime('{format}', '{startDate}') AND strftime('{format}', '{endDate}')
					AND trackTitle = trim(?) COLLATE NOCASE
		'''
		for __ in track.artistNames: sql += ' AND json_each.value = ? COLLATE NOCASE'
		sql += ' GROUP BY period )'
		parameters = [track.title]
		parameters.extend(track.artistNames)
	else: # If no artist or track is supplied, query for all plays
		sql += f'''
			counts(period, count) AS (
				SELECT
					strftime('{format}', timestamp, 'localtime') AS period,
					count(*) AS count
					FROM {playsTable}
					WHERE period BETWEEN strftime('{format}', '{startDate}') AND strftime('{format}', '{endDate}')
					GROUP BY period
			)
		'''

	sql += f'''
		SELECT
			period,
			ifnull(count, 0) as count
		FROM dateRange LEFT JOIN counts USING(period)
		ORDER BY period DESC
	'''

	playPeriodCounts = await execute(sql, parameters)
	return [dict(row) for row in playPeriodCounts] # Converts row objects to dict

async def getTrackPeriodCounts(startDate = '0000-01-01T00:00:00Z', endDate = datetime.utcnow().isoformat()[:-3]+'Z', period = "DAY", limit = 100):
	"""Get the number of unique tracks played over a period"""
	format = getStrftimeModifer(period)
	modifier = getAdditionModifier(period)

	sql = f'''
		WITH
			RECURSIVE dateRange(indx, period) AS (
				SELECT date('{endDate}'), strftime('{format}', '{endDate}')
				UNION ALL
				SELECT
					date(indx, '-1 {modifier}'),
					strftime('{format}', indx, '-1 {modifier}') AS period
				FROM dateRange
				WHERE indx > date('{startDate}')
				LIMIT {limit}
			),

			counts(period, count) AS (
				SELECT
					period,
					count(*) AS count
				FROM (
					SELECT strftime('{format}', timestamp, 'localtime') AS period
					FROM {playsTable}
					WHERE period BETWEEN strftime('{format}', '{startDate}') AND strftime('{format}', '{endDate}')
					GROUP BY trackTitle, artistNames, period
				)
				GROUP BY period
			)

		SELECT
			period,
			ifnull(count, 0) as count
		FROM dateRange LEFT JOIN counts USING(period)
		ORDER BY period DESC
	'''

	periodCounts = await execute(sql, [])
	return [dict(row) for row in periodCounts] # Converts row objects to dict

async def getArtistPeriodCounts(startDate = '0000-01-01T00:00:00Z', endDate = datetime.utcnow().isoformat()[:-3]+'Z', period = "DAY", limit = 100):
	"""Get the number of unique artists played over a period"""
	format = getStrftimeModifer(period)
	modifier = getAdditionModifier(period)

	sql = f'''
		WITH
			RECURSIVE dateRange(indx, period) AS (
				SELECT date('{endDate}'), strftime('{format}', '{endDate}')
				UNION ALL
				SELECT
					date(indx, '-1 {modifier}'),
					strftime('{format}', indx, '-1 {modifier}') AS period
				FROM dateRange
				WHERE indx > date('{startDate}')
				LIMIT {limit}
			),

			counts(period, count) AS (
				SELECT
					period,
					count(*) AS count
				FROM (
					SELECT strftime('{format}', timestamp, 'localtime') AS period
					FROM {playsTable}, json_each(artistNames)
					WHERE period BETWEEN strftime('{format}', '{startDate}') AND strftime('{format}', '{endDate}')
					GROUP BY json_each.value, period
				)
				GROUP BY period
			)

		SELECT
			period,
			ifnull(count, 0) as count
		FROM dateRange LEFT JOIN counts USING(period)
		ORDER BY period DESC
	'''
	periodCounts = await execute(sql, [])
	return [dict(row) for row in periodCounts] # Converts row objects to dict

async def getArtistCounts(startDate = '0000-01-01T00:00:00Z', endDate = datetime.utcnow().isoformat()[:-3]+'Z'):
	artistCounts = await execute(f'''
		SELECT
			timestamp,
			count(*) AS artistCount
		FROM (
			SELECT date(PLAYS.timestamp, 'localtime') AS timestamp
			FROM Play PLAYS
			WHERE PLAYS.timestamp BETWEEN ? AND ?
			GROUP BY PLAYS.artistNames
		)
		GROUP BY timestamp
		ORDER BY timestamp DESC
	''', (startDate, endDate))
	return [dict(row) for row in artistCounts] # Converts row objects to dict

async def getTrackCounts(startDate = '0000-01-01T00:00:00Z', endDate = datetime.utcnow().isoformat()[:-3]+'Z'):
	trackCounts = await execute(f'''
		SELECT
			timestamp,
			count(*) AS trackCount
		FROM (
			SELECT date(PLAYS.timestamp, 'localtime') AS timestamp
			FROM Play PLAYS
			WHERE PLAYS.timestamp BETWEEN ? AND ?
			GROUP BY PLAYS.artistNames, PLAYS.trackTitle
		)
		GROUP BY timestamp
		ORDER BY timestamp DESC
	''', (startDate, endDate))
	return [dict(row) for row in trackCounts] # Converts row objects to dict

async def getTrack(trackTitle: str, artistNames: List[str]) -> Track:
	sql = '''
		SELECT trackTitle, artistNames, json_array_length(artistNames) numOfArtists
		FROM Track JOIN json_each(Track.artistNames)
		WHERE trackTitle = trim(?) COLLATE NOCASE

	'''

	for __ in artistNames:
		sql += ' AND json_each.value = ? COLLATE NOCASE'
	
	sql += ' ORDER BY numOfArtists ASC -- Ensures matching the track with the fewest artists'
	
	parameters = [trackTitle]
	parameters.extend(artistNames)

	rawTrack = await execute(sql, parameters)
	if(len(rawTrack) == 0): return None # Explicitly returning None tells the caller that no track was found
	artistNames = json.loads(rawTrack[0]['artistNames'])
	return Track(rawTrack[0]['trackTitle'], artistNames)

async def getArtistPlays(artist: Artist, startDate = '0000-01-01T00:00:00Z', endDate = datetime.utcnow().isoformat()[:-3]+'Z', limit = 1000, offset = 0) -> List[Play]:
	sql = '''
		SELECT timestamp, trackTitle, artistNames
		FROM Play JOIN json_each(Play.artistNames)
		WHERE timestamp BETWEEN ? AND ?
		AND json_each.value = ? COLLATE NOCASE
		ORDER BY timestamp DESC
		LIMIT ? OFFSET ?
	'''

	parameters = [startDate, endDate, artist.name, limit, offset]

	rawArtistPlays = await execute(sql, parameters)

	artistPlays: List[Play] = []
	for row in rawArtistPlays: # Converts rows to Plays
		artistNames = json.loads(str(row['artistNames']))
		play = Play(row['timestamp'], artistNames, row['trackTitle'])
		artistPlays.append(play.asDict())
	return artistPlays

async def getTrackPlays(trackTitle: str, artistNames: List[str], startDate = '0000-01-01T00:00:00Z', endDate = datetime.utcnow().isoformat()[:-3]+'Z', limit = 1000, offset = 0) -> List[Play]:
	sql = '''
		SELECT timestamp, trackTitle, artistNames
		FROM Play JOIN json_each(Play.artistNames)
		WHERE timestamp BETWEEN ? AND ?
		AND trackTitle = trim(?) COLLATE NOCASE
	'''

	for __ in artistNames:
		sql += ' AND json_each.value = ? COLLATE NOCASE'
	
	sql += '''
		ORDER BY timestamp DESC
		LIMIT ? OFFSET ?
	'''

	parameters = [startDate, endDate, trackTitle, limit, offset]
	parameters[3:3] = artistNames # Add the artistNames to between the parameters list

	rawTrackPlays = await execute(sql, parameters)

	trackPlays: List[Play] = []
	for row in rawTrackPlays: # Converts rows to Plays
		artistNames = json.loads(str(row['artistNames']))
		play = Play(row['timestamp'], artistNames, row['trackTitle'])
		trackPlays.append(play.asDict())
	return trackPlays

async def getArtistPlayCounts(startDate = '0000-01-01T00:00:00Z', endDate = datetime.utcnow().isoformat()[:-3]+'Z'):
	rawArtistPlays = await execute(f'''
		SELECT
			artistNames,
			count(*) AS playCount
		FROM ( -- Create a table which splits a play if it contains multiple artist. A play is made for each artist while sharing the same timestamp
			SELECT artistName.value AS artistNames
			FROM {playsTable} JOIN json_each({playsTable}.artistNames) AS artistName
			WHERE timestamp BETWEEN ? AND ?
		)
		GROUP BY artistNames
		ORDER BY playCount DESC
	''', (startDate, endDate))

	artistPlays: List[dict] = []

	for row in rawArtistPlays: # Converts rows to dict
		artistPlay = {
			"artistNames": row['artistNames'],
			"playCount": row['playCount']
		}
		artistPlays.append(artistPlay)
	
	return artistPlays


async def getTrackPlayCounts(startDate = '0000-01-01T00:00:00Z', endDate = datetime.utcnow().isoformat()[:-3]+'Z', limit = 1000, offset = 0):
	rawTrackPlays = await execute(f'''
		SELECT
			artistNames,
			trackTitle,
			count(*) AS playCount
		FROM {playsTable}
		WHERE timestamp BETWEEN ? AND ?
		GROUP BY artistNames, trackTitle
		ORDER BY playCount DESC
		LIMIT ? OFFSET ?
	''', (startDate, endDate, limit, offset))

	trackPlays: List[dict] = []

	for row in rawTrackPlays: # Converts rows to dict
		artistNames = json.loads(str(row['artistNames']))
		trackPlay = {
			"artistNames": artistNames,
			"trackTitle": row['trackTitle'],
			"playCount": row['playCount']
		}
		trackPlays.append(trackPlay)

	return trackPlays

async def getArtistPlayCount(artist: Artist, startDate = '0000-01-01T00:00:00Z', endDate = datetime.utcnow().isoformat()[:-3]+'Z', limit = 1000, offset = 0) -> int:
	sql = f'''
		SELECT COUNT(*) AS count FROM {playsTable} JOIN json_each(Play.artistNames)
		WHERE timestamp BETWEEN ? AND ?
		AND json_each.value = ? COLLATE NOCASE
		LIMIT ? OFFSET ?
	'''

	parameters = [startDate, endDate, artist.name, limit, offset]
	count = await execute(sql, parameters)
	return count[0]['count']

async def getTrackCount(trackTitle: str, artistNames: List[str], startDate = '0000-01-01T00:00:00Z', endDate = datetime.utcnow().isoformat()[:-3]+'Z', limit = 1000, offset = 0) -> int:
	sql = f'''
		SELECT COUNT(*) AS count FROM {playsTable} JOIN json_each(Play.artistNames)
		WHERE timestamp BETWEEN ? AND ?
		AND trackTitle = trim(?) COLLATE NOCASE
	'''

	for __ in artistNames:
		sql += ' AND json_each.value = ? COLLATE NOCASE'
	
	sql += '''
		LIMIT ? OFFSET ?
	'''

	parameters = [startDate, endDate, trackTitle, limit, offset]
	parameters[3:3] = artistNames # Add the artistNames to between the parameters list
	count = await execute(sql, parameters)
	return count[0]['count']