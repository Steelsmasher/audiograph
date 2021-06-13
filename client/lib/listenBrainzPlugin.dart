import 'package:flutter/material.dart';

import 'server.dart' as server;
import 'global.dart';
import 'expandablePageView.dart';

class ListenBrainzPluginCard extends StatelessWidget {

	banner() => Padding(
		padding: const EdgeInsets.all(16.0),
		child: Image.asset("assets/ListenBrainz_Logo.png", fit: BoxFit.fitWidth)
	);

	panel(connectAction) => Container(
		color: Colors.orange,
		child: Column(
			children: [
				Padding(
					padding: const EdgeInsets.all(8.0),
					child: Align(
						alignment: Alignment.centerLeft,
						child: Text(
							"ListenBrainz",
							style: const TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.bold)
						),
					),
				),
				Padding(
					padding: const EdgeInsets.fromLTRB(8, 0, 8, 4),
					child: Align(
						alignment: Alignment.centerLeft,
						child: Text(
							"Import from ListenBrainz",
							style: const TextStyle(color: Colors.white, fontSize: 16)
						),
					),
				),
				Padding(
					padding: const EdgeInsets.all(16.0),
					child: SizedBox(
						width: double.infinity,
						child: ElevatedButton(
							onPressed: () async => await connectAction(),
							child: Text("Import"),
							style: ElevatedButton.styleFrom(
								primary: Colors.orange[800], // background
								onPrimary: Colors.white, // foreground
							)
						)
					)
				)
			],
		),
	);

	build(context){
		final connectAction = () async {
			await showDialog(
				context: context,
				builder: (context) => Dialog(child: ListenBrainzPluginWizard())				
			);
		};

		return Card(
			child: SizedBox(
				height: 300, width: 300,
				child: Column(
					children: [
						Expanded(child: banner()),
						Expanded(child: panel(connectAction))
					]
				)
			)
		);
	}
}

class ListenBrainzPluginWizard extends StatefulWidget {
	createState() => _ListenBrainzPluginWizardState();
}

class _ListenBrainzPluginWizardState extends State<ListenBrainzPluginWizard> {

	final pageController = PageController(initialPage: 0);
	String username = '';

	firstPage(){
		return Column(
			children: [
				Expanded(
					child: Text("Enter your username in the box below to import your plays from Listenbrainz", textAlign: TextAlign.center)
				),
				Expanded(
					child: TextField(
						onChanged: (text) => username = text,
						decoration: InputDecoration(
							border: OutlineInputBorder(),
							hintText: 'Username'
						)
					),
				),
				Expanded(
					child: Center(
						child: Row(
							mainAxisAlignment: MainAxisAlignment.spaceEvenly,
							children: [
								RaisedButton(
									child: Text('Cancel'),
									onPressed: () => Navigator.pop(context)
								),
								RaisedButton(
									color: Colors.orange,
									textColor: Colors.white,
									child: Text('Begin Import'),
									onPressed: () {
										server.importPlaysFromListenBrainz(username);
										pageController.nextPage(duration: Duration(milliseconds: 250), curve: Curves.easeIn);
									}
								),
							],
						),
					),
				)
			]
		);
	}

	secondPage(){
		const taskName = "listenbrainz-import-plays";
		return StreamBuilder(
			stream: server.getTasks(),
			builder: (context, AsyncSnapshot<Map<String, Task>> snapshot) {
				if(!snapshot.hasData) return Text("LOADING...");
				if(!snapshot.data.containsKey(taskName)) return Text("LOADING...");
				final task = snapshot.data[taskName];
				return Padding(
					padding: const EdgeInsets.all(16.0),
					child: Column(
						mainAxisAlignment: MainAxisAlignment.center,
						children: [
							Text("Importing from ListenBrainz", style: TextStyle(fontSize: 24)),
							SizedBox(height: 24),
							LinearProgressIndicator(value: task.total == 0 ? null : task.progress/task.total, minHeight: 5),
							Align(
								alignment: Alignment.centerLeft,
								child: Text(task.status, overflow: TextOverflow.ellipsis)
							),
							SizedBox(height: 16),
							Row(
								children: [
									Expanded(
										child: Padding(
											padding: const EdgeInsets.all(8.0),
											child: RaisedButton(
												child: Text("Cancel"),
												textColor: Colors.white,
												color: Colors.red,
												onPressed: () {
													server.cancelTask(task.name);
													Navigator.pop(context);
												}
											),
										),
									),
									Expanded(
										child: Padding(
											padding: const EdgeInsets.all(8.0),
											child: RaisedButton(
												child: Text("Run In Background"),
												textColor: Colors.white,
												color: Colors.orange,
												onPressed: () => Navigator.pop(context)
											),
										),
									),
								]
							)
						]
					)
				);
			},
		);
	}

	build(context){
		return SizedBox(
			width: 450,
			child: ExpandablePageView(
				controller: pageController,
				children: [
					Container(padding: const EdgeInsets.all(16.0), height: 250, child: firstPage()),
					Container(padding: const EdgeInsets.all(16.0), height: 300, child: secondPage())
				]
			),
		);
	}
}