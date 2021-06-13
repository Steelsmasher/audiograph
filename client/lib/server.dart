import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';

import 'global.dart';
import 'dart:collection';
import 'package:web_socket_channel/io.dart';

const serverURL = 'http://localhost:8080';
const serverAddress = 'localhost:8080'; // TODO phase this out in favour of host and port
const serverHost = 'localhost';
const serverPort = 8080;

const httpOK = 200;

//String get playURL => serverURL + '/play';
//String get importURL => serverURL + '/import?file=';
//String get playCountURL => 'http://' + serverAddress + '/playCount';
String get playsFromListenBrainzURL => 'http://' + serverAddress + '/storePlaysFromListenBrainz?username=';
String get playsFromLastFMURL => 'http://' + serverAddress + '/storePlaysFromLastFM?username=';
String get importURL => 'ws://' + serverAddress + '/importFromListenBrainz';
String get statusURL => 'ws://' + serverAddress + '/status';
String get tasksURL => 'ws://' + serverAddress + '/tasks';

Future<bool> ping() async {
	print("Pinging server");
	final http = HttpClient();
	final uri = Uri.http(serverAddress, "/ping");
	try{
		final request = await http.getUrl(uri).timeout(const Duration(seconds: 3));
		await request.close();
		print("Succesfully pinged server");
		return true;
	} catch (_) {
		print("Failed to ping server");
		return false;
	}

}

Future<List<Play>> getPlays({DateTime startDate, DateTime endDate, int limit, int offset}) async {
	print("Getting plays from server");
	final http = HttpClient();
	final parameters = Map<String, String>();

	// Exclude optional parameters from query string if values are null
	if(startDate != null) parameters["startDate"] = startDate.toIso8601String();
	if(endDate != null) parameters["endDate"] = endDate.toIso8601String();
	if(limit != null) parameters["limit"] = limit.toString();
	if(offset != null) parameters["offset"] = offset.toString();
	final uri = Uri.http(serverAddress, "/play", parameters);

	final request = await http.getUrl(uri);
	final response = await request.close();
	final jsonData = await response.transform(utf8.decoder).join();
	final List<dynamic> data = json.decode(jsonData);
	return data.map<Play>((playMap) => Play.fromMap(playMap)).toList();
}

Future<List<Play>> getTrackPlays(Track track, {DateTime startDate, DateTime endDate, int limit, int offset}) async {
	print("Getting track plays of ${track.title} - ${track.artistsString} from server");
	final http = HttpClient();
	final parameters = Map<String, String>();

	// Exclude optional parameters from query string if values are null
	parameters["trackTitle"] = track.title;
	parameters["artistNames"] = json.encode(track.artistNames);
	if(startDate != null) parameters["startDate"] = startDate.toIso8601String();
	if(endDate != null) parameters["endDate"] = endDate.toIso8601String();
	if(limit != null) parameters["limit"] = limit.toString();
	if(offset != null) parameters["offset"] = offset.toString();
	final uri = Uri.http(serverAddress, "/track-plays", parameters);

	final request = await http.getUrl(uri);
	final response = await request.close();
	final jsonData = await response.transform(utf8.decoder).join();
	final List<dynamic> data = json.decode(jsonData);
	print("Retrieved ${data.length} track plays of ${track.title} - ${track.artistsString} from server");
	return data.map<Play>((playMap) => Play.fromMap(playMap)).toList();
}

Future<List<Play>> getArtistPlays(Artist artist, {DateTime startDate, DateTime endDate, int limit, int offset}) async {
	print("Getting artist plays of ${artist.name} from server");
	final http = HttpClient();
	final parameters = Map<String, String>();

	// Exclude optional parameters from query string if values are null
	parameters["artist-name"] = artist.name;
	if(startDate != null) parameters["startDate"] = startDate.toIso8601String();
	if(endDate != null) parameters["endDate"] = endDate.toIso8601String();
	if(limit != null) parameters["limit"] = limit.toString();
	if(offset != null) parameters["offset"] = offset.toString();
	final uri = Uri.http(serverAddress, "/artist-plays", parameters);

	final request = await http.getUrl(uri);
	final response = await request.close();
	final jsonData = await response.transform(utf8.decoder).join();
	final List<dynamic> data = json.decode(jsonData);
	print("Retrieved ${data.length} artist plays of ${artist.name} from server");
	return data.map<Play>((playMap) => Play.fromMap(playMap)).toList();
}

Future<int> getTrackCount(Track track, {DateTime startDate, DateTime endDate, int limit, int offset}) async {
	print("Getting track count of ${track.title} - ${track.artistsString} from server");
	final http = HttpClient();
	final parameters = Map<String, String>();

	// Exclude optional parameters from query string if values are null
	parameters["trackTitle"] = track.title;
	parameters["artistNames"] = json.encode(track.artistNames);
	if(startDate != null) parameters["startDate"] = startDate.toIso8601String();
	if(endDate != null) parameters["endDate"] = endDate.toIso8601String();
	if(limit != null) parameters["limit"] = limit.toString();
	if(offset != null) parameters["offset"] = offset.toString();
	final uri = Uri.http(serverAddress, "/track-count", parameters);

	final request = await http.getUrl(uri);
	final response = await request.close();
	final jsonData = await response.transform(utf8.decoder).join();
	final int data = json.decode(jsonData);
	print("Retrieved a count of $data for ${track.title} - ${track.artistsString} from server");
	return data;
}

Future<int> getTotalPlays() async {
	print("Getting total plays from server");
	final http = HttpClient();
	final uri = Uri.http(serverAddress, "/totalPlays");

	final request = await http.getUrl(uri);
	final response = await request.close();
	final jsonData = await response.transform(utf8.decoder).join();
	final data = json.decode(jsonData);
	return data['total'];
}

Future<int> getTotalTracks() async {
	print("Getting total tracks from server");
	final http = HttpClient();
	final uri = Uri.http(serverAddress, "/totalTracks");

	final request = await http.getUrl(uri);
	final response = await request.close();
	final jsonData = await response.transform(utf8.decoder).join();
	final data = json.decode(jsonData);
	return data['total'];
}

Future<int> getTotalDays() async {
	print("Getting total days from server");
	final http = HttpClient();
	final uri = Uri.http(serverAddress, "/total-days");

	final request = await http.getUrl(uri);
	final response = await request.close();
	final jsonData = await response.transform(utf8.decoder).join();
	final data = json.decode(jsonData);
	return data['total'];
}

Future<int> getTotalMonths() async {
	print("Getting total months from server");
	final http = HttpClient();
	final uri = Uri.http(serverAddress, "/total-months");

	final request = await http.getUrl(uri);
	final response = await request.close();
	final jsonData = await response.transform(utf8.decoder).join();
	final data = json.decode(jsonData);
	return data['total'];
}

Future<int> getTotalYears() async {
	print("Getting total years from server");
	final http = HttpClient();
	final uri = Uri.http(serverAddress, "/total-years");

	final request = await http.getUrl(uri);
	final response = await request.close();
	final jsonData = await response.transform(utf8.decoder).join();
	final data = json.decode(jsonData);
	return data['total'];
}

Future<Play> getEarliestPlay() async {
	print("Getting earliest play from server");
	final http = HttpClient();

	final uri = Uri.http(serverAddress, "/earliest-play");
	final request = await http.getUrl(uri);
	final response = await request.close();
	final jsonData = await response.transform(utf8.decoder).join();
	final Map<String, dynamic> data = json.decode(jsonData);
	return Play.fromMap(data);
}

Future<Play> getLatestPlay() async {
	print("Getting latest play from server");
	final http = HttpClient();

	final uri = Uri.http(serverAddress, "/latest-play");
	final request = await http.getUrl(uri);
	final response = await request.close();
	final jsonData = await response.transform(utf8.decoder).join();
	final Map<String, dynamic> data = json.decode(jsonData);
	return Play.fromMap(data);
}

Future<Play> getEarliestTrackPlay(Track track) async {
	print("Getting earliest track play from server");
	final http = HttpClient();
	final parameters = Map<String, String>();

	parameters["trackTitle"] = track.title;
	parameters["artistNames"] = json.encode(track.artistNames);

	final uri = Uri.http(serverAddress, "/earliest-track-play", parameters);
	final request = await http.getUrl(uri);
	final response = await request.close();
	final jsonData = await response.transform(utf8.decoder).join();
	final Map<String, dynamic> data = json.decode(jsonData);
	return Play.fromMap(data);
}

Future<Play> getLatestTrackPlay(Track track) async {
	print("Getting latest track play from server");
	final http = HttpClient();
	final parameters = Map<String, String>();

	parameters["trackTitle"] = track.title;
	parameters["artistNames"] = json.encode(track.artistNames);

	final uri = Uri.http(serverAddress, "/latest-track-play", parameters);
	final request = await http.getUrl(uri);
	final response = await request.close();
	final jsonData = await response.transform(utf8.decoder).join();
	final Map<String, dynamic> data = json.decode(jsonData);
	return Play.fromMap(data);
}

Future<Play> getEarliestArtistPlay(Artist artist) async {
	print("Getting earliest artist play from server");
	final http = HttpClient();
	final parameters = Map<String, String>();

	parameters["artist-name"] = artist.name;

	final uri = Uri.http(serverAddress, "/earliest-artist-play", parameters);
	final request = await http.getUrl(uri);
	final response = await request.close();
	final jsonData = await response.transform(utf8.decoder).join();
	final Map<String, dynamic> data = json.decode(jsonData);
	return Play.fromMap(data);
}

Future<Play> getLatestArtistPlay(Artist artist) async {
	print("Getting latest artist play from server");
	final http = HttpClient();
	final parameters = Map<String, String>();

	parameters["artist-name"] = artist.name;

	final uri = Uri.http(serverAddress, "/latest-artist-play", parameters);
	final request = await http.getUrl(uri);
	final response = await request.close();
	final jsonData = await response.transform(utf8.decoder).join();
	final Map<String, dynamic> data = json.decode(jsonData);
	return Play.fromMap(data);
}

Future<LinkedHashMap<String, int>> getPlayPeriodCounts({Artist artist, Track track, DateTime startDate, DateTime endDate, Period period, int limit, int offset}) async {
	final http = HttpClient();
	final parameters = Map<String, String>();

	// Exclude optional parameters from query string if values are null
	if(startDate != null) parameters["startDate"] = startDate.toIso8601String();
	if(endDate != null) parameters["endDate"] = endDate.toIso8601String();
	if(period != null) parameters["period"] = describeEnum(period);
	if(limit != null) parameters.putIfAbsent("limit", () => limit.toString());
	if(offset != null) parameters.putIfAbsent("offset", () => offset.toString());
	if(artist != null) parameters["artist-name"] = artist.name;
	if(track != null){
		parameters["trackTitle"] = track.title;
		parameters["artistNames"] = json.encode(track.artistNames);
	}

	final uri = Uri.http(serverAddress, "/play-period-counts", parameters);
	final request = await http.getUrl(uri);
	final response = await request.close();
	final jsonData = await response.transform(utf8.decoder).join();
	final data = json.decode(jsonData);

	final mappedEntries = data.map<MapEntry<String, int>>((dataMap){
		final period = dataMap['period'];
		final count = dataMap['count'];
		return MapEntry<String, int>(period, count);
	});

	return LinkedHashMap<String, int>()..addEntries(mappedEntries);
}

Future<LinkedHashMap<String, int>> getTrackPlayPeriodCounts(Track track, {DateTime startDate, DateTime endDate, Period period, int limit, int offset}) async {
	final http = HttpClient();
	final parameters = Map<String, String>();

	parameters["trackTitle"] = track.title;
	parameters["artistNames"] = json.encode(track.artistNames);
	// Exclude optional parameters from query string if values are null
	if(startDate != null) parameters["startDate"] = startDate.toIso8601String();
	if(endDate != null) parameters["endDate"] = endDate.toIso8601String();
	if(period != null) parameters["period"] = describeEnum(period);
	if(limit != null) parameters.putIfAbsent("limit", () => limit.toString());
	if(offset != null) parameters.putIfAbsent("offset", () => offset.toString());

	final uri = Uri.http(serverAddress, "/track-play-period-counts", parameters);
	final request = await http.getUrl(uri);
	final response = await request.close();
	final jsonData = await response.transform(utf8.decoder).join();
	final data = json.decode(jsonData);

	final mappedEntries = data.map<MapEntry<String, int>>((dataMap){
		final period = dataMap['period'];
		final count = dataMap['count'];
		return MapEntry<String, int>(period, count);
	});

	return LinkedHashMap<String, int>()..addEntries(mappedEntries);
}

Future<LinkedHashMap<String, int>> getTrackPeriodCounts({DateTime startDate, DateTime endDate, Period period, int limit}) async {

	final http = HttpClient();
	final parameters = Map<String, String>();

	// Exclude optional parameters from query string if values are null
	if(startDate != null) parameters["startDate"] = startDate.toIso8601String();
	if(endDate != null) parameters["endDate"] = endDate.toIso8601String();
	if(period != null) parameters["period"] = describeEnum(period);
	if(limit != null) parameters.putIfAbsent("limit", () => limit.toString());

	final uri = Uri.http(serverAddress, "/track-period-counts", parameters);
	final request = await http.getUrl(uri);
	final response = await request.close();
	final jsonData = await response.transform(utf8.decoder).join();
	final data = json.decode(jsonData);

	final mappedEntries = data.map<MapEntry<String, int>>((dataMap){
		final period = dataMap['period'];
		final count = dataMap['count'];
		return MapEntry<String, int>(period, count);
	});

	return LinkedHashMap<String, int>()..addEntries(mappedEntries);
}

Future<LinkedHashMap<String, int>> getArtistPeriodCounts({DateTime startDate, DateTime endDate, Period period, int limit}) async {

	final http = HttpClient();
	final parameters = Map<String, String>();

	// Exclude optional parameters from query string if values are null
	if(startDate != null) parameters["startDate"] = startDate.toIso8601String();
	if(endDate != null) parameters["endDate"] = endDate.toIso8601String();
	if(period != null) parameters["period"] = describeEnum(period);
	if(limit != null) parameters.putIfAbsent("limit", () => limit.toString());

	final uri = Uri.http(serverAddress, "/artist-period-counts", parameters);
	final request = await http.getUrl(uri);
	final response = await request.close();
	final jsonData = await response.transform(utf8.decoder).join();
	final data = json.decode(jsonData);

	final mappedEntries = data.map<MapEntry<String, int>>((dataMap){
		final period = dataMap['period'];
		final count = dataMap['count'];
		return MapEntry<String, int>(period, count);
	});

	return LinkedHashMap<String, int>()..addEntries(mappedEntries);
}

Future<LinkedHashMap<String, int>> getArtistCount(DateTime _startDate, DateTime _endDate) async {
	final http = HttpClient();
	final uri = Uri.http(serverAddress, "/artistCount", { "startDate" : _startDate.toIso8601String(), "endDate" : _endDate.toIso8601String()});
	final request = await http.getUrl(uri);
	final response = await request.close();
	final jsonData = await response.transform(utf8.decoder).join();
	final data = json.decode(jsonData);

	final mappedEntries = data.map<MapEntry<String, int>>((dataMap){
		final timestamp = dataMap['timestamp'];
		final count = dataMap['artistCount'];
		return MapEntry<String, int>(timestamp, count);
	});

	return LinkedHashMap<String, int>()..addEntries(mappedEntries);
}

Future<int> getArtistPlayCount(Artist artist, {DateTime startDate, DateTime endDate, int limit, int offset}) async {
	print("Getting artist count of ${artist.name} from server");
	final http = HttpClient();
	final parameters = Map<String, String>();

	// Exclude optional parameters from query string if values are null
	parameters["artist-name"] = artist.name;
	if(startDate != null) parameters["startDate"] = startDate.toIso8601String();
	if(endDate != null) parameters["endDate"] = endDate.toIso8601String();
	if(limit != null) parameters["limit"] = limit.toString();
	if(offset != null) parameters["offset"] = offset.toString();
	final uri = Uri.http(serverAddress, "/artist-play-count", parameters);

	final request = await http.getUrl(uri);
	final response = await request.close();
	final jsonData = await response.transform(utf8.decoder).join();
	final int data = json.decode(jsonData);
	print("Retrieved a count of $data for ${artist.name} from server");
	return data;
}

Future<LinkedHashMap<String, int>> getPeriodCounts(DateTime startDate, DateTime endDate) async {
	final http = HttpClient();
	
	final uri = Uri.http(serverAddress, "/trackCount", { "startDate" : startDate.toIso8601String(), "endDate" : endDate.toIso8601String()});
	final request = await http.getUrl(uri);
	final response = await request.close();
	final jsonData = await response.transform(utf8.decoder).join();
	final data = json.decode(jsonData);

	final mappedEntries = data.map<MapEntry<String, int>>((dataMap){
		final timestamp = dataMap['timestamp'];
		final count = dataMap['trackCount'];
		return MapEntry<String, int>(timestamp, count);
	});

	return LinkedHashMap<String, int>()..addEntries(mappedEntries);
}

Future<LinkedHashMap<Artist, int>> getArtistPlayCounts({DateTime startDate, DateTime endDate, int limit, int offset}) async {
	final http = HttpClient();
	final uri = Uri.http(serverAddress, "/artistPlayCount", { "startDate" : startDate.toIso8601String(), "endDate" : endDate.toIso8601String()});
	final request = await http.getUrl(uri);
	final response = await request.close();
	final jsonData = await response.transform(utf8.decoder).join();
	final data = json.decode(jsonData);

	final mappedEntries = data.map<MapEntry<Artist, int>>((dataMap){
		final artistName = dataMap['artistNames'];
		final count = dataMap['playCount'];
		final artist = Artist(artistName);
		return MapEntry<Artist, int>(artist, count);
	});

	return LinkedHashMap<Artist, int>()..addEntries(mappedEntries);
}

Future<LinkedHashMap<Track, int>> getTrackPlayCounts({DateTime startDate, DateTime endDate, int limit, int offset}) async {
	final http = HttpClient();
	final parameters = Map<String, String>();

	// Exclude optional parameters from query string if values are null
	if(startDate != null) parameters.putIfAbsent("startDate", () => startDate.toIso8601String());
	if(endDate != null) parameters.putIfAbsent("endDate", () => endDate.toIso8601String());
	if(limit != null) parameters.putIfAbsent("limit", () => limit.toString());
	if(offset != null) parameters.putIfAbsent("offset", () => offset.toString());

	final uri = Uri.http(serverAddress, "/trackPlayCount", parameters);
	final request = await http.getUrl(uri);
	final response = await request.close();
	final jsonData = await response.transform(utf8.decoder).join();
	final data = json.decode(jsonData);

	final mappedEntries = data.map<MapEntry<Track, int>>((dataMap){
		final artistNames = dataMap['artistNames'].cast<String>(); // Cast from List<dynamic> to List<String>
		final trackTitle = dataMap['trackTitle'];
		final count = dataMap['playCount'];
		final track = Track(trackTitle, artistNames);
		return MapEntry<Track, int>(track, count);
	});

	return LinkedHashMap<Track, int>()..addEntries(mappedEntries);
}

Future storePlaysFromListenBrainz(String username) async {
	final http = HttpClient();
	final url = playsFromListenBrainzURL + Uri.encodeQueryComponent(username);
	final uri = Uri.parse(url);
	final request = await http.postUrl(uri);

	return await request.close();
}

Future importPlaysFromLastFM(String username, String apiKey) async {
	final http = HttpClient();
	final parameters = Map<String, String>();
	parameters['username'] = username;
	parameters['apiKey'] = apiKey;
	final uri = Uri.http(serverAddress, "/lastfm-import-plays", parameters);
	final request = await http.postUrl(uri);
	return await request.close();
}

Future importPlaysFromListenBrainz(String username) async {
	final http = HttpClient();
	final parameters = Map<String, String>();
	parameters['username'] = username;
	final uri = Uri.http(serverAddress, "/listenbrainz-import-plays", parameters);
	final request = await http.postUrl(uri);
	return await request.close();
}

Future cancelTask(String taskName) async {
	final http = HttpClient();
	final uri = Uri.http(serverAddress, "/cancel-task", {"task-name": taskName});
	print('Cancelling the task: $taskName');
	final request = await http.postUrl(uri);

	return await request.close();
}

Stream importListenBrainz(String file) {
	final channel = IOWebSocketChannel.connect(importURL);
	channel.sink.add(file);

	return channel.stream;
}

Future<bool> isSpotifyConnected() async {
	final http = HttpClient();
	final uri = Uri.http(serverAddress, "/plugins");
	final request = await http.getUrl(uri);
	final response = await request.close();
	final jsonData = await response.transform(utf8.decoder).join();
	final bool data = json.decode(jsonData)['Spotify'];
	return data;
}

Future<String> getSpotifyRedirectURI() async {
	final http = HttpClient();
	final uri = Uri.http(serverAddress, "/spotify-redirect-uri");
	final request = await http.getUrl(uri);
	final response = await request.close();

	return await response.transform(utf8.decoder).join();
}

Future<String> getSpotifyAuthorisationURL() async {
	final http = HttpClient();

	final uri = Uri.http(serverAddress, "/spotify-authorisation-url");
	final request = await http.getUrl(uri);
	final response = await request.close();

	return await response.transform(utf8.decoder).join();
}

Future initialiseSpotifyAuthorisation(String clientID, String clientSecret) async {
	final parameters = Map<String, String>();
	parameters['client-id'] = clientID;
	parameters['client-secret'] = clientSecret;

	final http = HttpClient();
	final uri = Uri.http(serverAddress, "/spotify-initialise-authorisation", parameters);
	final request = await http.postUrl(uri);
	return await request.close();
}

Future disconnectSpotify() async {
	final http = HttpClient();
	final uri = Uri.http(serverAddress, "/spotify-disconnect");
	final request = await http.postUrl(uri);

	return await request.close();
}

Stream getStatus() {
	final channel = IOWebSocketChannel.connect(statusURL);
	return channel.stream;
}

Stream<Map<String, Task>> getTasks() {
	final channel = IOWebSocketChannel.connect(tasksURL);

	final taskStream = channel.stream.map((event) {
		final Map<String, dynamic> data = json.decode(event);
		final taskMap = data.map((tag, taskData){
			final Task task = Task(taskData['name']);
			task.status = taskData['status'];
			task.progress = taskData['progress'];
			task.total = taskData['total'];
			return MapEntry<String, Task>(tag, task);
		});
		return taskMap;
	});
	return taskStream;
}