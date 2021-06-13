import 'package:flutter/material.dart';

import 'global.dart';
import 'blankView.dart';
import 'server.dart' as server;

class PlaysListWidget extends StatefulWidget {
	createState() => _PlaysListWidgetState();
}

class _PlaysListWidgetState extends State<PlaysListWidget> {

	final tileHeight = 65.0;

	Future<List<Play>> playHistory;
	int itemCount = 1;

	Future<List<Play>> refresh() async {
		return await server.getPlays(limit: itemCount);
	}

	String getRelativeTimeString(DateTime timestamp){
		final timeDifference = DateTime.now().difference(timestamp);

		if(timeDifference.compareTo(oneMinute) == -1){
			final units = (timeDifference.inSeconds == 1) ? 'second' : 'seconds';
			return "${timeDifference.inSeconds} $units ago";
		} else if(timeDifference.compareTo(oneHour) == -1){
			final units = (timeDifference.inMinutes == 1) ? 'minute' : 'minutes';
			return "${timeDifference.inMinutes} $units ago";
		} else if(timeDifference.compareTo(oneDay) == -1){
			final units = (timeDifference.inHours == 1) ? 'hour' : 'hours';
			return "${timeDifference.inHours} $units ago";
		} else if(timeDifference.compareTo(oneWeek) == -1){
			final units = (timeDifference.inDays == 1) ? 'day' : 'days';
			return "${timeDifference.inDays} $units ago";
		} else if(timeDifference.compareTo(oneMonth) == -1){
			final units = ((timeDifference.inDays/7).floor() == 1) ? 'week' : 'weeks';
			return "${(timeDifference.inDays/7).floor()} $units ago";
		}else if(timeDifference.compareTo(oneYear) == -1){
			final units = ((timeDifference.inDays/30).floor() == 1) ? 'month' : 'months';
			return "${(timeDifference.inDays/30).floor()} $units ago";
		}

		final units = ((timeDifference.inDays/365).floor() == 1) ? 'year' : 'years';
		return "${(timeDifference.inDays/365).floor()} $units ago";
	}

	Widget getPlayList(List<Play> plays){
		return ListView.builder(
			physics: const NeverScrollableScrollPhysics(),
			itemBuilder: (context, index) {
				final play = plays[index];
				final timestamp = play.dateTime.toLocal();
				final artists = play.artistNames.reduce((current, next) => current + ", " + next);
				final dateTime = getRelativeTimeString(timestamp);

				return Material(
					color: Colors.transparent,
					child: InkWell(
						onTap: () => Navigator.pushNamed(context, '/track', arguments: Track(play.trackTitle, play.artistNames)),
						child: ListTile(
							leading: Container( color: Theme.of(context).primaryColor, child: Icon(Icons.music_note, size: 48, color: Colors.white)),
							title: Text(play.trackTitle),
							subtitle: Text(artists),
							trailing: Text(dateTime)
						)
					)
				);
			},
			itemCount: itemCount, // Adjusts number of tiles displayed based on height available
			itemExtent: tileHeight,
			addAutomaticKeepAlives: false,
			addRepaintBoundaries: false
		);
	}

	build(context){
		content(){
			final loadingWidget = Center( child: Padding( padding: const EdgeInsets.all(50.0), child: Text('LOADING...')));

			return Expanded(
				child: LayoutBuilder(
					builder: (context, constraints) {
						itemCount = (constraints.maxHeight/tileHeight).floor();
						playHistory = refresh();

						return FutureBuilder(
							future: playHistory,
							builder: (context, snapshot){
								if(snapshot.hasData){
									final filteredPlays = snapshot.data;
									if(filteredPlays.isEmpty) return BlankView();

									return getPlayList(filteredPlays);
								} else { return loadingWidget; }
							}
						);
					}
				)
			);
		}

		return Column(
			crossAxisAlignment: CrossAxisAlignment.start, // Aligns the title to the left
			children: [
				Text("Recently Played", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
				content(),
			]
		);
	}
}