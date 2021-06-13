import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'global.dart';
import 'server.dart' as server;
import 'blankView.dart';

class ArtistPlaysListPage extends StatefulWidget {
	final Artist artist;

	ArtistPlaysListPage(this.artist);

	createState() => _ArtistPlaysListPageState();
}

const _playsPerPage = 50;

class _ArtistPlaysListPageState extends State<ArtistPlaysListPage> {

	Artist artist;
	Future<List<Play>> playHistory;
	ScrollController scrollController;
	int totalPages = 1, currentPage = 1;

	initState() {
		super.initState();
		scrollController = ScrollController();
		artist = widget.artist;
		playHistory = refresh();
	}

	Future<List<Play>> refresh() async {
		if (scrollController.hasClients) scrollController.jumpTo(0); // Ensures scrollController has a listView attached before controlling
		final artistCount = await server.getArtistPlayCount(artist);
		totalPages = (artistCount/_playsPerPage).ceil();
		final offset = (currentPage-1)*_playsPerPage;
		return await server.getArtistPlays(artist, limit: _playsPerPage, offset: offset);
	}

	ListView getArtistPlayList(List<Play> plays){
		return ListView.separated(
			controller: scrollController,
			separatorBuilder: (BuildContext context, int index) => Divider(),
			shrinkWrap: true, // Gives the listView a fixed height
			itemBuilder: (context, index) {
				final play = plays[index];
				final timestamp = play.dateTime.toLocal();
				final artists = play.artistNames.reduce((current, next) => current + ", " + next);
				final dateTime ='${DateFormat('d MMM yyyy, kk:mm').format(timestamp)}';

				return ListTile(
					leading: Container( color: Theme.of(context).primaryColor, child: Icon(Icons.music_note, size: 48, color: Colors.white)),
					title: Text(play.trackTitle),
					subtitle: Text(artists),
					trailing: Text(dateTime),
					contentPadding: EdgeInsets.symmetric(vertical: 8),
				);
			},
			itemCount: plays.length,
			addAutomaticKeepAlives: false,
			addRepaintBoundaries: false
		);
	}

	content(){
		final loadingWidget = Center( child: Padding( padding: const EdgeInsets.all(50.0), child: Text('LOADING...')));

		return FutureBuilder(
			future: playHistory,
			builder: (context, snapshot){
				if(snapshot.hasData){
					final data = snapshot.data;
					if(data.isEmpty) return BlankView();

					return getArtistPlayList(data);
				} else { return loadingWidget; }
			}
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
							playHistory = refresh();
						});
					}
				),
				IconButton(
					icon: Icon(Icons.chevron_left),
					iconSize: 48,
					onPressed: (){
						setState((){
							currentPage = (currentPage-1).clamp(1, totalPages);
							playHistory = refresh();
						});
					}
				),
				SizedBox(width: 150, child: Text(currentPage.toString(), textAlign: TextAlign.center, style: TextStyle(fontSize: 48))),
				IconButton(
					icon: Icon(Icons.chevron_right),
					iconSize: 48,
					onPressed: (){
						setState((){
							currentPage = (currentPage+1).clamp(1, totalPages);
							playHistory = refresh();
						});
					}
				),
				IconButton(
					icon: Icon(Icons.skip_next),
					iconSize: 48,
					onPressed: (){
						setState((){
							currentPage = totalPages;
							playHistory = refresh();
						});
					}
				),
			],
		);
	}

	titleBar(){
		return AppBar(
			title: Text('${artist.name}'),
		);
	}

	build(context){
		return Column(
			children: [
				titleBar(),
				Expanded(
					child: SizedBox(
						width: 1000,
						//padding: const EdgeInsets.symmetric(horizontal: 50),
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