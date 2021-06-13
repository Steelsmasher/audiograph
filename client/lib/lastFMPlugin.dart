import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart' as url;
import 'package:flutter/services.dart';

import 'server.dart' as server;
import 'global.dart';
import 'expandablePageView.dart';

class LastFMPluginCard extends StatelessWidget {

	banner() => Padding(
		padding: const EdgeInsets.all(16.0),
		child: Image.asset("assets/LastFM_Logo.png", fit: BoxFit.fitWidth)
	);

	panel(connectAction) => Container(
		color: Colors.red,
		child: Column(
			children: [
				Padding(
					padding: const EdgeInsets.all(8.0),
					child: Align(
						alignment: Alignment.centerLeft,
						child: Text(
							"Last.fm",
							style: const TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.bold)
						),
					),
				),
				Padding(
					padding: const EdgeInsets.fromLTRB(8, 0, 8, 4),
					child: Align(
						alignment: Alignment.centerLeft,
						child: Text(
							"Import from Last.fm",
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
								primary: Colors.red[700], // background
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
				builder: (context) => Dialog(child: LastFMPluginWizard())				
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

class LastFMPluginWizard extends StatefulWidget {
	createState() => _LastFMPluginWizardState();
}

class _LastFMPluginWizardState extends State<LastFMPluginWizard> {

	final pageController = PageController(initialPage: 0);
	String username = '';
	String apiKey = '';

	firstPage(){
		return Column(
			children: [
				Expanded(
					flex: 2,
					child: Text("To import your plays from Last.fm you will need an API account. It's quick to setup.", textAlign: TextAlign.center)
				),
				Expanded(
					child: Center(
						child: RaisedButton(
							color: Colors.orange,
							textColor: Colors.white,
							child: Text('Next'),
							onPressed: () => pageController.nextPage(duration: Duration(milliseconds: 250), curve: Curves.easeIn)
						),
					),
				)
			]
		);
	}

	secondPage(){
		const accountURL = 'https://www.last.fm/api/account/create';
		return Column(
			children: [
				Expanded(
					child: Text('Follow the link below and create a new app. Give it any name, such as "Audiograph" for example.', textAlign: TextAlign.center)
				),
				Expanded(
					child: TextButton(
						onPressed: () => url.launch(accountURL),
						child: Text(
							accountURL,
							textAlign: TextAlign.center,
							style: TextStyle(color: Colors.blue),
						)
					)
				),
				Expanded(
					child: Center(
						child: Row(
							mainAxisAlignment: MainAxisAlignment.spaceEvenly,
							children: [
								RaisedButton(
									child: Text('Previous'),
									onPressed: () => pageController.previousPage(duration: Duration(milliseconds: 250), curve: Curves.easeIn)
								),
								RaisedButton(
									color: Colors.orange,
									textColor: Colors.white,
									child: Text('Next'),
									onPressed: () => pageController.nextPage(duration: Duration(milliseconds: 250), curve: Curves.easeIn)
								),
							],
						),
					),
				)
			]
		);
	}

	thirdPage(){
		final apiController = TextEditingController();
		final usernameController = TextEditingController();

		return Column(
			children: [
				Expanded(
					child: Text("Copy the API Key from your app into the box below. Then enter your Last.fm username", textAlign: TextAlign.center)
				),
				Row(
					mainAxisAlignment: MainAxisAlignment.center,
					children: [
						IconButton(icon: Icon(Icons.paste), onPressed: () async {
							final clipboardData = await Clipboard.getData('text/plain');
							apiController.text = clipboardData.text;
							apiKey = clipboardData.text;
						}),
						Expanded(
							child: TextField(
								controller: apiController,
								onChanged: (text) => apiKey = text,
								decoration: InputDecoration(
									border: OutlineInputBorder(),
									hintText: 'API Key'
								)
							),
						),
					],
				),
				SizedBox(height: 25),
				Row(
					mainAxisAlignment: MainAxisAlignment.center,
					children: [
						IconButton(icon: Icon(Icons.paste), onPressed: () async {
							final clipboardData = await Clipboard.getData('text/plain');
							usernameController.text = clipboardData.text;
							username = clipboardData.text;
						}),
						Expanded(
							child: TextField(
								controller: usernameController,
								onChanged: (text) => username = text,
								decoration: InputDecoration(
									border: OutlineInputBorder(),
									hintText: 'Username'
								)
							),
						),
					],
				),
				Expanded(
					child: Center(
						child: Row(
							mainAxisAlignment: MainAxisAlignment.spaceEvenly,
							children: [
								RaisedButton(
									child: Text('Previous'),
									onPressed: () => pageController.previousPage(duration: Duration(milliseconds: 250), curve: Curves.easeIn)
								),
								RaisedButton(
									color: Colors.orange,
									textColor: Colors.white,
									child: Text('Begin Import'),
									onPressed: () {
										server.importPlaysFromLastFM(username, apiKey);
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

	fourthPage(){
		const taskName = "lastfm-import-plays";
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
							Text("Importing from Last.fm", style: TextStyle(fontSize: 24)),
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
					Container(padding: const EdgeInsets.all(16.0), height: 200, child: firstPage()),
					Container(padding: const EdgeInsets.all(16.0), height: 250, child: secondPage()),
					Container(padding: const EdgeInsets.all(16.0), height: 350, child: thirdPage()),
					Container(padding: const EdgeInsets.all(16.0), height: 300, child: fourthPage())
				]
			),
		);
	}
}