import 'package:flutter/material.dart';

import 'global.dart';
import 'trackPlaysListWidget.dart';
import 'trackPlaysChartWidget.dart';


class TrackPage extends StatefulWidget {
	final Track track;

	TrackPage(this.track);
	createState() => _TrackPageState();
}

const _appBarHeight = 256.0;


class _TrackPageState extends State<TrackPage> {
	ScrollController scrollController;
	bool showTitle = false;

	initState(){
		super.initState();
		/*scrollController = ScrollController()
		..addListener(() {
			bool appBarAtMinimumHeight = scrollController.hasClients && scrollController.offset > _appBarHeight - kToolbarHeight;
			if(appBarAtMinimumHeight != showTitle){
				showTitle = appBarAtMinimumHeight;
				setState((){});
			}
		});*/
	}

	getTile(Widget content, String route, {int flex, parameters}){
		getContent() => Stack(
			children: [
				Card(
					child: InkWell(
						onTap: () => Navigator.pushNamed(context, route, arguments: parameters)
					)
				),
				Padding(
					padding: const EdgeInsets.all(20),
					child: content
				),
			],
		);
		if(flex == null) return getContent(); // No flex given implies the given content is not part of a column or row
			else return Expanded(flex: flex, child: getContent());
	}

	build(context) {
		final track = widget.track;

		return Column(
			children: [
				AppBar(
					title: Text('${track.title} - ${track.artistsString}'),
				),
				Expanded(
					child: Padding(
						padding: const EdgeInsets.all(50),
						child: SizedBox(
							child: Row(
								mainAxisAlignment: MainAxisAlignment.spaceEvenly,
								children: [
									getTile(TrackPlaysListWidget(track), '/trackPlaysList', parameters: track, flex: 1),
									SizedBox(width: 50),
									getTile(TrackPlaysChartWidget(track), '/trackPlaysChart', parameters: track, flex: 1)  // TODO Navigate to trackPlaysChartPage
								],
							)
						),
					)
				)
			],
		);
	}
}