import 'package:flutter/material.dart';

import 'global.dart';
import 'artistPlaysListWidget.dart';
import 'artistPlaysChartWidget.dart';


class ArtistPage extends StatefulWidget {
	final Artist artist;

	ArtistPage(this.artist);
	createState() => _ArtistPageState();
}

const _appBarHeight = 256.0;


class _ArtistPageState extends State<ArtistPage> {
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
		final artist = widget.artist;

		return Column(
			children: [
				AppBar(
					title: Text('${artist.name}'),
				),
				Expanded(
					child: Padding(
						padding: const EdgeInsets.all(50),
						child: SizedBox(
							child: Row(
								mainAxisAlignment: MainAxisAlignment.spaceEvenly,
								children: [
									getTile(ArtistPlaysListWidget(artist), '/artistPlaysList', parameters: artist, flex: 1),
									SizedBox(width: 50),
									getTile(ArtistPlaysChartWidget(artist), '/artistPlaysChart', parameters: artist, flex: 1)
								],
							)
						),
					)
				)
			],
		);
	}
}