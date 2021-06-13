import 'dart:collection';

import 'package:charts_flutter/flutter.dart';
import 'package:flutter/material.dart';
import 'global.dart';
import 'server.dart' as server;

// TODO Deprecate this code

class TimestampCounts {
	final String timestamp;
	final int count;

	TimestampCounts(this.timestamp, this.count);
}

Future<List<Series<TimestampCounts, String>>> getChartData(PlayType playType) async {

	List<TimestampCounts> data;  // Data to be plotted on graph
	LinkedHashMap playCounts;

	switch(playType){  // Update dates with data from database
		case PlayType.Play:
			playCounts = await server.getPlayPeriodCounts(startDate: startDate, endDate: endDate);
		break;
		case PlayType.Artist:
			playCounts = await server.getArtistCount(startDate, endDate);
		break;
		case PlayType.Track:
			playCounts = await server.getPeriodCounts(startDate, endDate);
		break;
	}

	data = playCounts.entries.map((timestampEntry) => TimestampCounts(timestampEntry.key, timestampEntry.value)).toList();

	return [ Series<TimestampCounts, String>(
		id: 'Plays',
		colorFn: (_, __) => MaterialPalette.blue.shadeDefault,
		domainFn: (TimestampCounts plays, _) => plays.timestamp,
		measureFn: (TimestampCounts plays, _) => plays.count,
		data: data,
		labelAccessorFn: (TimestampCounts timestampCount, _){
			switch(playType){
				case PlayType.Play:
					return (timestampCount.count == 0) ? 'No Plays' : '${timestampCount.count} Plays';
				case PlayType.Artist:
					return (timestampCount.count == 0) ? 'No Artists' : '${timestampCount.count} Artists';
				case PlayType.Track:
					return (timestampCount.count == 0) ? 'No Tracks' : '${timestampCount.count} Tracks';
				default: return ""; // TODO should fail in this event
			}
		}
	)];
}

class BarGraph_OLD extends StatefulWidget {
	final List<Series<TimestampCounts, String>> chartData;

	BarGraph_OLD(this.chartData);
	createState() => BarGraphState_OLD();
}

class BarGraphState_OLD extends State<BarGraph_OLD> {
	List<Series<TimestampCounts, String>> chartData;

	_onSelectionChanged(SelectionModel model) {
		TimestampCounts selectedData = (model.hasDatumSelection) ? model.selectedDatum.first.datum : null;  // TODO To be used later
	}

	build(context) {
		return BarChart(
			widget.chartData,
			animate: false,
			vertical: false,
			primaryMeasureAxis: NumericAxisSpec(renderSpec: NoneRenderSpec()),
			domainAxis: OrdinalAxisSpec(
				showAxisLine: false,
			),
			barRendererDecorator: BarLabelDecorator<String>(),
			selectionModels: [
				SelectionModelConfig(
					type: SelectionModelType.info,
					changedListener: _onSelectionChanged,
					updatedListener: _onSelectionChanged,
				)
			],
		);
	}
}

class ChartView extends StatelessWidget{

	final PlayType playType;

	ChartView(this.playType);

	build(context){
		final loadingWidget = Center( child: Padding( padding: const EdgeInsets.all(50.0), child: Text('LOADING...')));

		Future<List<Series<TimestampCounts, String>>> chartData;

		if(chartData == null) chartData = getChartData(playType);

		return FutureBuilder(
			future: chartData,
			builder: (context, AsyncSnapshot<List<Series<TimestampCounts, String>>> snapshot){
				if(snapshot.hasData){
					int dataLength = snapshot.data.first.data.length;

					Widget fillRemaining() => SliverFillRemaining(
						child: BarGraph_OLD(snapshot.data),
					);

					Widget fixedHeight(){
						double viewHeight = dataLength*50.0;

						return SliverToBoxAdapter(
							child: SizedBox(
								height: viewHeight,
								child: BarGraph_OLD(snapshot.data)
							),
						);
					}

					return CustomScrollView(
						slivers: [ (dataLength <= 12) ? fillRemaining() : fixedHeight() ]
					);
				}
				return loadingWidget;
			}
		);
	}
}