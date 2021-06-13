import 'dart:collection';

enum Period { WEEKDAY, DAY, MONTH, YEAR }
enum DateRange { Today, ThisMonth, AllTime, Custom }
enum ViewMode { Tile, Charts }
enum PlayType{ Play, Track, Artist }

const microsecond = const Duration(microseconds: 1);
const oneMinute = const Duration(minutes: 1);
const oneHour = const Duration(hours: 1);
const oneDay = const Duration(days: 1);
const oneWeek = const Duration(days: 7);
Duration get oneMonth => const Duration(days: 32) - microsecond;
Duration get oneYear => const Duration(days: 366) - microsecond;

Future<List<Play>> subHistory; // TODO Remove this as it has now been localised
Future<LinkedHashMap<Track, int>> trackPlays; // TODO Remove this as it has now been localised
Future<LinkedHashMap<Artist, int>> artistPlays; // TODO Remove this as it has now been localised

DateTime latestDate = DateTime.now();
DateTime earliestDate = DateTime(1);
DateTime endDate = latestDate;
DateTime startDate = earliestDate;

const uknown = ['', 0, null];  // Used when data has yet to be retrieved
const notFound = ['_', -1];  // Used when data was searched and not found
dataIsFilled(property) => !uknown.contains(property);
dataNotFound(property) => notFound.contains(property);
dataIsValid(property) => !['', '_', 0, -1, null].contains(property);

setDateRange(DateRange dateRange, {DateTime customStartDate, DateTime customEndDate}){
	final today = DateTime.now();
	switch(dateRange) {
		case DateRange.Today:
			startDate = DateTime(today.year, today.month, today.day);
			endDate = DateTime(today.year, today.month, today.day+1).subtract(microsecond);
			break;
		case DateRange.ThisMonth:
			startDate = DateTime(today.year, today.month);
			endDate = DateTime(today.year, today.month+1).subtract(microsecond);
			break;
		case DateRange.AllTime:
			startDate = earliestDate;
			endDate = latestDate;
			break;
		case DateRange.Custom:
			startDate = customStartDate;
			endDate = customEndDate;
			break;
	}
	reloadDataFromServer();
}

reloadDataFromServer(){
	//subHistory = server.getPlays(startDate: startDate, endDate: endDate);
	//trackPlays = server.getTrackPlayCount(startDate, endDate);
	//artistPlays = server.getArtistPlayCount(startDate, endDate);
}

Map<int, bool> widgetStates = Map<int, bool>();
refreshWidgets() => widgetStates.updateAll((key, value) => false);

class Play {
	final String timestamp;
	final List<String> artistNames;
	final String trackTitle;

	Play(this.timestamp, this.artistNames, this.trackTitle);

	static fromMap(Map<String, dynamic> map) => Play(
		map['timestamp'],
		map['artistNames'].cast<String>(),  // Cast from List<dynamic> to List<String>
		map['trackTitle']
	);

	DateTime get dateTime => DateTime.parse(timestamp).toUtc();
	String get artistsString => artistNames.reduce((current, next) => current + ", " + next);
}

class Artist {
	final String name;

	Artist(this.name);

	static fromMap(Map<String, dynamic> map) => Artist(map['artistName']);
}

class Track implements Comparable {
	final String title;
	final List<String> artistNames;

	Track(this.title, this.artistNames);

	static fromMap(Map<String, dynamic> map) => Track(map['trackTitle'], map['artistNames']);


	static String makeID(title, leadArtist) {  // For external objects that have enough info to make an id
		if(dataNotFound(title) || dataNotFound(leadArtist)) return '_';  // To let caller know data was searched and not found
		if(!dataIsValid(title) || !dataIsValid(leadArtist)) return '';  // To let caller know data was has not been searched yet
		return title + leadArtist;
	}

	String get id => makeID(title, leadArtistName);  // TODO Seriously consider if this is enough to make an ID. ID may not be necessary????
	int compareTo(other) => id.compareTo(other.id);
	bool operator == (object) => object is Track && object.id == id;
	int get hashCode => id.hashCode;
	String get leadArtistName => artistNames[0];
	String get artistsString => artistNames.reduce((current, next) => current + ", " + next);
}

class Task {
	final String name;
	String status;
	int total;
	int progress;

	Task(this.name);

	static const descriptionMap = {
		'spotify': "Spotify",
		'lastfm-import-plays': "Importing plays from Last.fm",
		'listenbrainz-import-plays': "Importing plays from ListenBrainz"
	};

	get description => (descriptionMap.containsKey(name)) ? descriptionMap[name] : "The task $name has no description";
}