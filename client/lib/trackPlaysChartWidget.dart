import 'dart:math';
import 'dart:collection';
import 'package:flutter/material.dart';
import 'package:jiffy/jiffy.dart';

import 'global.dart';
import 'server.dart' as server;
import 'barGraph.dart';
import 'blankView.dart';

class TrackPlaysChartWidget extends StatefulWidget {
	final Track track;

	TrackPlaysChartWidget(this.track);
	createState() => _TrackPlaysChartWidgetState();
}

class _TrackPlaysChartWidgetState extends State<TrackPlaysChartWidget> {

	final barWidth = 100;
	Future<LinkedHashMap<String, int>> periodCounts;
	Period period = Period.DAY;
	int barCount = 1; // The number of bars that can fit within the space given to the bar chart
	int offset = 0;
	int maxOffset = 0;

	Future<LinkedHashMap<String, int>> refresh() async {
		int total = 0;
		final earliestPlay = await server.getEarliestTrackPlay(widget.track);
		final latestPlay = await server.getLatestTrackPlay(widget.track);
		DateTime startDate, endDate;
		switch (period) {
			case Period.MONTH:
				final earliestDate = Jiffy(earliestPlay.dateTime).startOf(Units.MONTH);
				final latestDate = Jiffy(latestPlay.dateTime).startOf(Units.MONTH);
				total = Jiffy(latestDate).diff(earliestDate, Units.MONTH);
				endDate = Jiffy(latestDate).subtract(months: offset);
				startDate = Jiffy(endDate).subtract(months: barCount-1);
				break;
			case Period.YEAR:
				final earliestDate = Jiffy(earliestPlay.dateTime).startOf(Units.YEAR);
				final latestDate = Jiffy(latestPlay.dateTime).startOf(Units.YEAR);
				total = Jiffy(latestDate).diff(earliestDate, Units.YEAR);
				endDate = Jiffy(latestDate).subtract(years: offset);
				startDate = Jiffy(endDate).subtract(years: barCount-1);
				break;
			default:
				final earliestDate = Jiffy(earliestPlay.dateTime).startOf(Units.DAY);
				final latestDate = Jiffy(latestPlay.dateTime).startOf(Units.DAY);
				total = Jiffy(latestDate).diff(earliestDate, Units.DAY);
				endDate = Jiffy(latestDate).subtract(days: offset);
				startDate = Jiffy(endDate).subtract(days: barCount-1);
				break;
		}

		maxOffset = max(total-barCount+1, 0); // Prevent negative values
		return await server.getPlayPeriodCounts(track: widget.track, startDate: startDate, endDate: endDate, period: period, limit: barCount);  //TODO Remove offset from this function as dates are now used instead
	}

	content(){
		final loadingWidget = Center( child: Padding( padding: const EdgeInsets.all(50.0), child: Text('LOADING...')));

		return IgnorePointer( // Allows the widget card to be clickable by passing through the click
			child: LayoutBuilder(
				builder: (context, constraints) {
					barCount = (constraints.maxWidth/barWidth).floor();
					periodCounts = refresh();

					return FutureBuilder(
						future: periodCounts,
						builder: (context, snapshot){
							if(snapshot.hasData){
								LinkedHashMap<String, int> _periodCounts = snapshot.data;
								if(_periodCounts.isEmpty) return BlankView();

								final reversedList = _periodCounts.entries.toList().reversed;
								final reversedMap = LinkedHashMap<String, int>()..addEntries(reversedList);

								return BarGraph(reversedMap, "Plays");
							} else { return loadingWidget; }
						}
					);
				}
			),
		);
	}

	build(context) {

		dropDown(){
			return Container(
				height: 30,
				width: 200,

				child: DropdownButton<Period>(
					value: period,
					underline: Container(),  // A blank container hides the underline
					isExpanded: true,
					icon: const Icon(Icons.arrow_drop_down),
					onChanged: (selection) => setState((){
						period = selection;
						offset = 0;
					}),
					items: [
						const DropdownMenuItem(value: Period.DAY, child: Center(child: Text("Day"))),
						const DropdownMenuItem(value: Period.MONTH, child: Center(child: Text("Month"))),
						const DropdownMenuItem(value: Period.YEAR, child: Center(child: Text("Year")))
					],
				)
			);
		}

		titleBar(){
			return Row(
				children: [
					Expanded(
						child: IgnorePointer(child: Text("Total Plays", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold))),
					),
					dropDown()
				],
			);
		}

		return Column(
			children: [
				titleBar(),
				Expanded(
				  child: Row(children: [
				  	IconButton(
				  		icon: Icon(Icons.chevron_left),
				  		iconSize: 48,
				  		onPressed: (){
				  			setState(() {
				  				offset  = (offset+1).clamp(0, maxOffset);
				  				periodCounts = refresh();
				  			});
				  		}
				  	),
				  	Expanded(child: content()),
				  	IconButton(
				  		icon: Icon(Icons.chevron_right),
				  		iconSize: 48,
				  		onPressed: (){
				  			setState((){
				  				offset  = (offset-1).clamp(0, maxOffset);
				  				periodCounts = refresh();
				  			});
				  		}
				  	)
				  ]),
				)
			]
		);
	}

}