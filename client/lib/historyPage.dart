import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'global.dart';
import 'server.dart' as server;
import 'utilities.dart';
import 'blankView.dart';
import 'barGraph.dart';
import 'dart:collection';

class HistoryPage extends StatefulWidget {
	createState() => _HistoryPageState();
}

const _playsPerPage = 50;

class _HistoryPageState extends State<HistoryPage> {

	DateRange dateRange = DateRange.ThisMonth;
	Future<List<Play>> playHistory;
	Future<LinkedHashMap<String, int>> playCounts;
	int totalPages = 1, currentPage = 1;
	bool isChartExpanded = true;
	ScrollController scrollController;


	initState() {
		super.initState();
		scrollController = ScrollController();
		final dates = getDateRange(dateRange);
		startDate = dates["startDate"];
		endDate = dates["endDate"];
		playCounts = server.getPlayPeriodCounts(startDate: dates["startDate"], endDate: dates["endDate"]);
		playHistory = refresh();
	}

	Future<List<Play>> refresh() async {
		if (scrollController.hasClients) scrollController.jumpTo(0); // Ensures scrollController has a listView attached before controlling
		final totalPlays = await server.getTotalPlays();
		totalPages = (totalPlays/_playsPerPage).ceil();
		final offset = (currentPage-1)*_playsPerPage;
		return await server.getPlays(limit: _playsPerPage, offset: offset);
	}

	ListView getPlayList(List<Play> plays){
		return ListView.separated(
			controller: scrollController,
			separatorBuilder: (BuildContext context, int index) => Divider(),
			//physics: const NeverScrollableScrollPhysics(),
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

					return getPlayList(data);
				} else { return loadingWidget; }
			}
		);
	}

	searchBar(){
		return Align(
			child: SizedBox(
				height: 40,
				width: 400,
				child: Padding(
					padding: EdgeInsets.symmetric(horizontal: 40),
					child: TextField(
						onChanged: (inputText) {},
						decoration: InputDecoration(
							hintText: 'Search...',
							contentPadding: EdgeInsets.all(10.0),
							alignLabelWithHint: true,
							border: OutlineInputBorder(
								borderRadius: BorderRadius.circular(100)
							),
							filled: true,
							fillColor: Colors.white
						),
					)
				)
			),
		);
	}

	titleBar(){
		getRangeOption(String text, DateRange _dateRange){
			return Padding(
				padding: const EdgeInsets.all(8.0),
				child: ChoiceChip(
					label: Text(text),
					shape: StadiumBorder(side: BorderSide()),
					backgroundColor: Colors.transparent,
					selected: dateRange == _dateRange,
					onSelected: (bool selected) {
						setState(() => dateRange = selected ? _dateRange : null);
					}
				),
			);
		}

		return AppBar(
			title: Text("History"),
			/*actions: [
				getRangeOption('Today', DateRange.Today),
				getRangeOption('This Month', DateRange.ThisMonth),
				getRangeOption('All Time', DateRange.AllTime),
				getRangeOption('Custom', DateRange.Custom),
				searchBar()
			],*/
		);
	}

	chart(){
		final loadingWidget = Center( child: Padding( padding: const EdgeInsets.all(50.0), child: Text('LOADING...')));

		return Card(
			child: ExpansionTile(
				title: Text("Plays", style: TextStyle(color: Colors.black, fontSize: 24, fontWeight: FontWeight.bold)), // Specifying colour prevents it from changing when expanded
				initiallyExpanded: isChartExpanded,
				onExpansionChanged: (newValue) => setState(() => isChartExpanded = newValue),
				children: [
					SizedBox(
						height: 500,
						child: FutureBuilder(
							future: playCounts,
							builder: (context, snapshot){
								if(snapshot.hasData){
									LinkedHashMap<String, int> _playCounts = snapshot.data;
									if(_playCounts.isEmpty) return BlankView();

									return BarGraph(snapshot.data, "Plays");
								} else { return loadingWidget; }
							}
						),
					)
				],
			),
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
				SizedBox(width: 100, child: Text(currentPage.toString(), textAlign: TextAlign.center, style: TextStyle(fontSize: 48))),
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

	build(context) {
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