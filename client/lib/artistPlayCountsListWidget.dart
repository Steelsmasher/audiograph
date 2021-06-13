import 'package:flutter/material.dart';
import 'global.dart';
import 'utilities.dart';
import 'server.dart' as server;
import 'blankView.dart';
import 'dart:collection';

class ArtistPlayCountsListWidget extends StatefulWidget {
	createState() => _ArtistPlayCountsListWidgetState();
}

class _ArtistPlayCountsListWidgetState extends State<ArtistPlayCountsListWidget> {
	DateRange dateRange = DateRange.ThisMonth;
	Future<LinkedHashMap<Artist, int>> artistPlayCounts;

	initState() {
		super.initState();
		refresh();
	}

	refresh(){
		final dates = getDateRange(dateRange);
		artistPlayCounts = server.getArtistPlayCounts(startDate: dates["startDate"], endDate: dates["endDate"]);
	}

	build(context) {

		Widget getArtistPlayCountsList(LinkedHashMap<Artist, int> artistPlayCounts){
			final artistPlayCountsList = artistPlayCounts.keys.toList(growable: false);
			const tileHeight = 65.0;
			return 	LayoutBuilder(
				builder: (context, constraints) {
					return ListView.builder(
						physics: const NeverScrollableScrollPhysics(),
						itemBuilder: (context, index) {
							final artist = artistPlayCountsList[index];
							final artistPlayCount = artistPlayCounts[artist];
							final count = '$artistPlayCount plays';

							return Material(
								color: Colors.transparent,
								child: InkWell(
									onTap: () => Navigator.pushNamed(context, '/artist', arguments: artist),
									child: ListTile(
										leading: Container( color: Theme.of(context).primaryColor, child: Icon(Icons.person, size: 48, color: Colors.white)),
										title: Text(artist.name),
										trailing: Text(count),
										contentPadding: EdgeInsets.symmetric(vertical: 8),
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
					future: artistPlayCounts,
					builder: (context, snapshot){
						if(snapshot.hasData){
							if(snapshot.data.isEmpty) return BlankView();
							return getArtistPlayCountsList(snapshot.data);
						}
						return loadingWidget;
					}
				),
			);
		}

		titleBar(){
			Function updateDateRange = (DateRange newDateRange) => setState(() => dateRange = newDateRange);
			return Row(
				children: [
					Expanded(
						child: IgnorePointer(child: Text("Top Artists", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold))),
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