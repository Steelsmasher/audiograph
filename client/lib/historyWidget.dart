import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'global.dart';
import 'server.dart' as server;
import 'utilities.dart';
import 'blankView.dart';

class HistoryWidget extends StatefulWidget {
	final int id;

	const HistoryWidget (this.id);
	createState() => _HistoryWidgetState();
}

class _HistoryWidgetState extends State<HistoryWidget> {

	DateRange _dateRange = DateRange.ThisMonth;
	Future<List<Play>> playHistory;

	initState() {
		super.initState();
		widgetStates[widget.id] = false;
		refresh();
	}

	refresh(){
		final dates = getDateRange(_dateRange);
		playHistory = server.getPlays(startDate: dates["startDate"], endDate: dates["endDate"]);
		widgetStates[widget.id] = true;
	}

	Widget getPlayList(List<Play> plays){
		const tileHeight = 65.0;
		return LayoutBuilder(
			builder: (context, constraints) {
				return ListView.builder(
					physics: const NeverScrollableScrollPhysics(),
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
		  	future: playHistory,
		  	builder: (context, snapshot){
		  		if(snapshot.hasData){
		  			final filteredPlays = snapshot.data;
		  			if(filteredPlays.isEmpty) return BlankView();

		  			return getPlayList(filteredPlays);
		  		} else { return loadingWidget; }
		  	}
		  ),
		);
	}

	build(context) {

		refresh();
		return IgnorePointer(  // Allows the widget card to be clickable by passing through the click
			child: Column(
				crossAxisAlignment: CrossAxisAlignment.start, // Aligns the title to the left
				children: [
					Text("Recently Played", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
					content(),
				]
			),
		);
	}
}