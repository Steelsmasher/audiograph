import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'global.dart';
import 'utilities.dart';
import 'server.dart' as server;
import 'blankView.dart';
import 'dart:collection';

class TrackCountsListWidget extends StatefulWidget {
	createState() => _TrackCountsListWidgetState();
}

class _TrackCountsListWidgetState extends State<TrackCountsListWidget> {
	DateRange dateRange = DateRange.ThisMonth;
	Future<LinkedHashMap<Track, int>> trackPlays;

	initState() {
		super.initState();
		refresh();
	}

	refresh(){
		final dates = getDateRange(dateRange);
		trackPlays = server.getTrackPlayCounts(startDate: dates["startDate"], endDate: dates["endDate"]);
	}

	build(context) {

		Widget getTrackList(LinkedHashMap<Track, int> trackPlays){
			final trackPlaysList = trackPlays.keys.toList(growable: false);
			const tileHeight = 65.0;
			return 	LayoutBuilder(
				builder: (context, constraints) {
					return ListView.builder(
						physics: const NeverScrollableScrollPhysics(),
						itemBuilder: (context, index) {
							final track = trackPlaysList[index];
							final trackPlayCount = trackPlays[track];
							final count = '$trackPlayCount plays';

							final artists = track.artistNames.reduce((current, next) => current + ", " + next);

							return Material(
								color: Colors.transparent,
								child: InkWell(
									onTap: () => Navigator.pushNamed(context, '/track', arguments: track),
									child: ListTile(
										leading: Container(color: Theme.of(context).primaryColor, child: Icon(Icons.music_note, size: 48, color: Colors.white)),
										title: Text(track.title),
										subtitle: Text(artists),
										trailing: Text(count),
									),
								),
							);
						},
						itemCount: (constraints.maxHeight/tileHeight).floor(), // Adjusts number of tiles displayed based on height available
						itemExtent: tileHeight,
						addAutomaticKeepAlives: false,
						addRepaintBoundaries: false
					);
				}
			);
		}

		content(){
			final loadingWidget = Center( child: Padding( padding: const EdgeInsets.all(50.0), child: Text('LOADING...')));

			return Expanded(
				child: FutureBuilder(
					future: trackPlays,
					builder: (context, snapshot){
						if(snapshot.hasData){
						final _filteredTrackPlays = snapshot.data;
						if(_filteredTrackPlays.isEmpty) return BlankView();

							return getTrackList(_filteredTrackPlays);
						} else { return loadingWidget; }
					}
				),
			);
		}

		titleBar(){
			Function updateDateRange = (DateRange newDateRange) => setState(() => dateRange = newDateRange);
			return Row(
				children: [
					Expanded(
						child: IgnorePointer(child: Text("Top Tracks", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold))),
					),
					dropDown(dateRange, updateDateRange, context)
				],
			);
		}

		refresh();
		return Column(
			children: [
				titleBar(),
				content(),
			]
		);
	}

}