import 'package:flutter/material.dart';

import 'server.dart' as server;
import 'playChartWidget.dart';
import 'trackCountsListWidget.dart';
import 'artistPlayCountsListWidget.dart';
import 'trackCountsChartWidget.dart';
import 'artistCountsChartWidget.dart';
import 'playsListWidget.dart';

class Dashboard extends StatelessWidget {
	build(context) {
		return FutureBuilder(
			future: server.getTotalPlays(),
			builder: (context, snapshot) {
				if(!snapshot.hasData) return Text("Loading...");
				if(snapshot.data > 0) return DashboardPage();
				return Center(
					child: Text("You have no have no plays. Start by clicking the connect button on the sidebar to connect to a service.")
				);
			}
		);
	}
}

class DashboardPage extends StatelessWidget {

	getContainer(String text) => Container(
		constraints: BoxConstraints.expand(),
		child: Text(text),
		color: Colors.teal[100],
	);

	build(context) {
		getTile(Widget content, String route, {int flex}){
			getContent() => Stack(
				children: [
					Card(
						child: InkWell(
							onTap: () => Navigator.pushNamed(context, route)
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

		return Column(
			children: [
				AppBar(
					leading: IconButton(
						icon: Icon(Icons.arrow_back),
						iconSize: 24,
						onPressed: () => Navigator.canPop(context) ? Navigator.pop(context) : {}
					),
					title: Text("Dashboard"),
				),
				Expanded(
					child: ListView(
						padding: const EdgeInsets.all(50),
						children: [
							SizedBox(
								height: 400,
								child: getTile(PlayChartWidget(), '/playChart')
							),
							SizedBox(height: 50),
							SizedBox(
								height: 700,
								child: Row(
									mainAxisAlignment: MainAxisAlignment.spaceEvenly,
									children: [
										getTile(PlaysListWidget(), '/history', flex: 1),
										SizedBox(width: 50),
										getTile(TrackCountsListWidget(), '/tracks', flex: 1),
									],
								),
							),
							SizedBox(height: 50),
							SizedBox(
								height: 700,
								child: Row(
									mainAxisAlignment: MainAxisAlignment.spaceEvenly,
									children: [
										getTile(ArtistPlayCountsListWidget(), '/artists', flex: 1),
										SizedBox(width: 50),
										Expanded(
											flex: 1,
											child: Column(
												children: [
													getTile(TrackCountsChartWidget(), '/trackPeriodCountsChart', flex: 1),
													SizedBox(height: 50),
													getTile(ArtistCountsChartWidget(), '/artistPeriodCountsChart', flex: 1),
												]
											)
										)
									]
								),
							)
						],
					),
				),
			],
		);
	}
}