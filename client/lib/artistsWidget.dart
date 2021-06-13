import 'package:flutter/material.dart';
import 'global.dart';
import 'utilities.dart';
import 'server.dart' as server;
import 'blankView.dart';
import 'dart:collection';

class ArtistsWidget extends StatefulWidget {
	final int id;

	const ArtistsWidget (this.id);
	createState() => _ArtistsWidgetState();
}

class _ArtistsWidgetState extends State<ArtistsWidget> {
	DateRange dateRange = DateRange.ThisMonth;
	Future<LinkedHashMap<Artist, int>> artistPlays;

	initState() {
		super.initState();
		widgetStates[widget.id] = false;
		_refresh();
	}

	_refresh(){
		final dates = getDateRange(dateRange);
		artistPlays = server.getArtistPlayCounts(startDate: dates["startDate"], endDate: dates["endDate"]);
		widgetStates[widget.id] = true;
	}

	Widget getArtistList(LinkedHashMap<Artist, int> artistPlays){
		final artistPlaysList = artistPlays.keys.toList(growable: false);
		const tileHeight = 65.0;
		return 	LayoutBuilder(
			builder: (context, constraints) {
				return ListView.builder(
					physics: const NeverScrollableScrollPhysics(),
					itemBuilder: (context, index) {
						final artist = artistPlaysList[index];
						final artistPlayCount = artistPlays[artist];
						final count = '$artistPlayCount plays';

						return ListTile(
							leading: Container( color: Theme.of(context).primaryColor, child: Icon(Icons.person, size: 48, color: Colors.white)),
							title: Text(artist.name),
							trailing: Text(count),
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
		  	future: artistPlays,
		  	builder: (context, snapshot){
		  		if(snapshot.hasData){
					final filteredArtistPlays = snapshot.data;
					if(filteredArtistPlays.isEmpty) return BlankView();

		  			return getArtistList(filteredArtistPlays);
		  		} else { return loadingWidget; }
		  	}
		  ),
		);
	}

	build(context) {

		titleBar(){
			Function updateDateRange = (DateRange newDateRange) => setState(() => dateRange = newDateRange);
			return Row(
				children: [
					Expanded(
						child: InkWell(
							onTap: () => Navigator.pushNamed(context, '/history', arguments: "History"),
							child: Text("Top Artists", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
						),
					),
					dropDown(dateRange, updateDateRange, context)
				],
			);
		}

		_refresh();
		return Column(
			children: [
				titleBar(),
				content(),
			]
		);
	}

}