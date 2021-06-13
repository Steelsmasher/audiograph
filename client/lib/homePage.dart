import 'global.dart';
import 'historyView.dart';
import 'package:flutter/material.dart';
import 'server.dart' as server;
import 'drawer.dart';
import 'historyChart.dart';

class HomePage extends StatefulWidget {
	createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with SingleTickerProviderStateMixin {
	TabController tabController;
	ScrollController scrollController;

	_searchBar (){
		return SizedBox(
			height: 40,
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
		);
	}

	_dropDown(){
		String dropdownValue;
		return SizedBox(
			height: 40,
			child: Container(
				decoration: BoxDecoration(
					color: Colors.white,
					borderRadius: BorderRadius.circular(100)
				),

				child: DropdownButtonHideUnderline(
					child: DropdownButton<String>(
						value: dropdownValue,
						icon: Icon(Icons.arrow_drop_down),
						onChanged: (String newValue) {
							setState(() {});
						},
						items: <String>[
							'One',
							'Two',
							'Three',
							'Four'
						].map<DropdownMenuItem<String>>((String value) {
							return DropdownMenuItem<String>(
							value: value,
							child: Text(value),
							);
						}).toList()
					)
				)
			)
		);
	}



	initState() {
		super.initState();
		scrollController = ScrollController();
		tabController = TabController(length: 4, vsync: this)
		..addListener(() { if(!tabController.indexIsChanging) setState(() {}); });  // Only rebuilds after changing
	}

	build(BuildContext context) {
		return Scaffold(
			body: NestedScrollView(
				controller: scrollController,
				headerSliverBuilder: (context, innerBoxIsScrolled) {
					return [
						SliverAppBar(
							title: Row(
								mainAxisAlignment: MainAxisAlignment.start,
								children:[
									Padding(
										child: Text("History"),
										padding: EdgeInsets.only(bottom: 5),
									),
									Expanded(
										child: _searchBar(),
										flex: 3,
									),
									Expanded(
										child: _dropDown(),
										flex: 1,
									)
								]
							),
							floating: true,
							pinned: true,
							centerTitle: true,
							forceElevated: innerBoxIsScrolled,
							bottom: TabBar(
								controller: tabController,
								tabs: [
									Tab(text: 'History'),
									Tab(text: 'Tracks'),
									Tab(text: 'Artists'),
									Tab(text: 'Charts')
								],
							)
						),
					];
				},
				body: Stack(
					children: [
						TabBarView(
							controller: tabController,
							children: [
								HistoryView(),
								HistoryView(),
								ChartView(PlayType.Track),
								ChartView(PlayType.Track)
							]
						),
						Align(
							alignment: Alignment.topRight,
							child: Padding(
								padding: EdgeInsets.all(10.0),
								child: FloatingActionButton(
									child: const Icon(Icons.refresh, color: Colors.white),
									onPressed: () {
										//subHistory = server.getPlays();
										setState(() { subHistory = server.getPlays(startDate: startDate, endDate: endDate); });
									}
								),
							)
						),
						Align(
							alignment: Alignment.bottomRight,
							child: Padding(
								padding: EdgeInsets.all(10.0),
								child: FloatingActionButton(
									child: const Icon(Icons.update, color: Colors.white),
									onPressed: () {
										setState(() { server.getPlayPeriodCounts(startDate: startDate, endDate: endDate); });
									}
								),
							)
						)
					],
				)
			),
			drawer: MainDrawer()
		);
	}

	dispose() {
		tabController.dispose();
		scrollController.dispose();
		super.dispose();
	}
}
