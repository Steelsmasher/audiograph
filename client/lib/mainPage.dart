import 'package:flutter/material.dart';

import 'global.dart';
import 'drawer.dart';
import 'historyView.dart';
import 'tracksView.dart';
import 'artistsView.dart';
import 'historyChart.dart';
import 'dashboard.dart';

class MainPage extends StatefulWidget {
	createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> with SingleTickerProviderStateMixin {

	TabController _tabController;
	DateRange _dateRange = DateRange.Today;
	ViewMode _viewMode = ViewMode.Tile;

	initState() {
		super.initState();
		_tabController = TabController(length: 4, vsync: this)
		..addListener(() { if(!_tabController.indexIsChanging) setState(() {}); });  // Only rebuilds after changing
		setDateRange(DateRange.AllTime);
	}

	_tabBar() => TabBar(controller: _tabController, tabs: [
		Tab(text: 'Dashboard'),
		Tab(text: 'History'),
		Tab(text: 'Tracks'),
		Tab(text: 'Artists')
	]);
	
	_tabPages() => TabBarView(controller: _tabController, children: <Widget>[
		Dashboard(),
		(_viewMode == ViewMode.Tile) ? HistoryView() : ChartView(PlayType.Play),
		(_viewMode == ViewMode.Tile) ? TracksView() : ChartView(PlayType.Track),
		(_viewMode == ViewMode.Tile) ? ArtistsView() : ChartView(PlayType.Artist)
	]);

	_refreshButton() => Align(
		alignment: Alignment.topRight,
		child: Padding(
			padding: const EdgeInsets.all(10.0),
			child: FloatingActionButton(
				child: const Icon(Icons.refresh, color: Colors.white),
				onPressed: () => setState(() => refreshWidgets())
			)
		)
	);

	_dropDown(){
		return SizedBox(
			height: 30,
			width: 200,
			child: Container(
				decoration: BoxDecoration(
					color: Colors.white,
					borderRadius: BorderRadius.circular(10)
				),

				child: DropdownButtonHideUnderline(
					child: DropdownButton<DateRange>(
						value: _dateRange,
						isExpanded: true,
						icon: const Icon(Icons.arrow_drop_down),
						onChanged: (newValue) => setState((){
							_dateRange = newValue;
							setDateRange(_dateRange);
						}),
						items: [
							const DropdownMenuItem(value: DateRange.Today, child: Center(child: Text("Today"))),
							const DropdownMenuItem(value: DateRange.ThisMonth, child: Center(child: Text("This Month"))),
							const DropdownMenuItem(value: DateRange.AllTime, child: Center(child: Text("All Time"))),
							const DropdownMenuItem(value: DateRange.Custom, child: Center(child: Text("Custom")))
						],
					)
				)
			)
		);
	}

	build(BuildContext context) {
		return Dashboard();
		/*return Scaffold(
			appBar: AppBar(
				title: Row(
					mainAxisAlignment: MainAxisAlignment.spaceBetween,
					children:[
						Padding(
							child: const Text("Audiograph"),
							padding: const EdgeInsets.only(bottom: 5),
						),
						Row(
							children:[
								const Text("Time Range"),
								SizedBox(width: 10),
								_dropDown()
							]
						),
						ToggleButtons(
							children: <Widget>[
								SizedBox(width: 100, child: Text("Tiles", textAlign: TextAlign.center)),
								SizedBox(width: 100, child: Text("Charts", textAlign: TextAlign.center))
							],
							onPressed: (index) => setState(() => _viewMode = (index == 0) ? ViewMode.Tile : ViewMode.Charts),
							isSelected: [_viewMode == ViewMode.Tile, _viewMode == ViewMode.Charts],
						)
					]
				),
				bottom: _tabBar()
			),
			body: Stack(
				children: [
					_tabPages(),
					_refreshButton()
				],
			),
			drawer: MainDrawer(),
		);*/
	}

	dispose() {
		_tabController.dispose();
		super.dispose();
	}
}