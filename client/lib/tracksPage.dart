import 'package:flutter/material.dart';
import 'dart:collection';

import 'global.dart';
import 'server.dart' as server;
import 'blankView.dart';

class TracksPage extends StatefulWidget {
	createState() => _TracksPageState();
}

const _tracksPerPage = 50;

class _TracksPageState extends State<TracksPage> {

	Future<LinkedHashMap<Track, int>> trackPlays;
	ScrollController scrollController;
	int totalPages = 1, currentPage = 1;

	initState() {
		super.initState();
		scrollController = ScrollController();
		trackPlays = refresh();
	}

	Future<LinkedHashMap<Track, int>> refresh() async {
		if (scrollController.hasClients) scrollController.jumpTo(0); // Ensures scrollController has a listView attached before controlling
		final totalTracks = await server.getTotalTracks();
		totalPages = (totalTracks/_tracksPerPage).ceil();
		final offset = (currentPage-1)*_tracksPerPage;
		return await server.getTrackPlayCounts(limit: _tracksPerPage, offset: offset);
	}

	getTrackList(LinkedHashMap<Track, int> trackPlays){
		final trackPlaysList = trackPlays.keys.toList(growable: false);
		return ListView.separated(
			controller: scrollController,
			separatorBuilder: (BuildContext context, int index) => Divider(),
			shrinkWrap: true, // Gives the listView a fixed height
			itemBuilder: (context, index) {
				final track = trackPlaysList[index];
				final trackPlayCount = trackPlays[track];
				final count = '$trackPlayCount plays';

				final artists = track.artistNames.reduce((current, next) => current + ", " + next);

				return ListTile(
					leading: Container( color: Theme.of(context).primaryColor, child: Icon(Icons.music_note, size: 48, color: Colors.white)),
					title: Text(track.title),
					subtitle: Text(artists),
					trailing: Text(count),
					contentPadding: EdgeInsets.symmetric(vertical: 8),
				);
			},
			itemCount: trackPlays.length,
			addAutomaticKeepAlives: false,
			addRepaintBoundaries: false
		);
	}

	pageControls(){
		return ButtonBar(
			alignment: MainAxisAlignment.center,
			buttonPadding: const EdgeInsets.symmetric(horizontal: 16.0),
			children: [
				IconButton(
					icon: Icon(Icons.skip_previous),
					iconSize: 48,
					onPressed: (){
						setState((){
							currentPage  = 1;
							trackPlays = refresh();
						});
					}
				),
				IconButton(
					icon: Icon(Icons.chevron_left),
					iconSize: 48,
					onPressed: (){
						setState((){
							currentPage = (currentPage-1).clamp(1, totalPages);
							trackPlays = refresh();
						});
					}
				),
				SizedBox(width: 100, child: Text(currentPage.toString(), textAlign: TextAlign.center, style: TextStyle(fontSize: 48))),
				IconButton(
					icon: Icon(Icons.chevron_right),
					iconSize: 48,
					onPressed: (){
						setState((){
							currentPage = (currentPage+1).clamp(1, totalPages);
							trackPlays = refresh();
						});
					}
				),
				IconButton(
					icon: Icon(Icons.skip_next),
					iconSize: 48,
					onPressed: (){
						setState((){
							currentPage = totalPages;
							trackPlays = refresh();
						});
					}
				),
			],
		);
	}

	titleBar(){
		return AppBar(
			title: Text("History")
		);
	}

	content(){
		final loadingWidget = Center( child: Padding( padding: const EdgeInsets.all(50.0), child: Text('LOADING...')));

		return FutureBuilder(
			future: trackPlays,
			builder: (context, snapshot){
				if(snapshot.hasData){
					final data = snapshot.data;
					if(data.isEmpty) return BlankView();

					return getTrackList(data);
				} else { return loadingWidget; }
			}
		);
	}

	build(context) {
		return Column(
			children: [
				titleBar(),
				Expanded(
					child: SizedBox(
						width: 1000,
						child: content(),
					),
				),
				Padding(
					padding: const EdgeInsets.symmetric(horizontal: 16),
					child: pageControls(),
				)
			]
		);
	}

	dispose() {
		scrollController.dispose();
		super.dispose();
	}

}