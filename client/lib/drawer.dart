import 'package:flutter/material.dart';

import 'global.dart';
import 'server.dart' as server;

class MainDrawer extends StatefulWidget{
	createState() => DrawerState();
}

SimpleDialog authenticationDialog(context){
	return SimpleDialog(
		title: Text(
			"Access was denied!",
			textAlign: TextAlign.center
		),
		children: [
			Padding(
				padding: const EdgeInsets.fromLTRB(16.0, 0.0, 16.0, 32.0),
				child: Text(
					"Audiograph needs permission to retrieve your Spotify history again.",
					textAlign: TextAlign.center
				)
			),
			FractionallySizedBox(
				widthFactor: 0.7,
				child: RaisedButton(
					child: Text("Proceed"),
					textColor: Colors.white,
					color: Colors.orange,
					onPressed: () { Navigator.of(context).pushNamed('/authentication'); }
				),
			),
		]
	);
}

SimpleDialog importDialog(context, Stream stream){
	return SimpleDialog(
		title: Text(
			'Notice',
			textAlign: TextAlign.center
		),
		children: [
			Padding(
				padding: const EdgeInsets.fromLTRB(16.0, 0.0, 16.0, 32.0),
				child: Text(
					"Import Started",
					textAlign: TextAlign.center
				)
			),
			StreamBuilder(
				stream: stream,
				builder: (context, snapshot) {
					return Text(
						snapshot.hasData ? '${snapshot.data}' : '',
						textAlign: TextAlign.left,
						overflow: TextOverflow.ellipsis,
					);
				},
			),
			FractionallySizedBox(
				widthFactor: 0.7,
				child: RaisedButton(
					child: Text("Cancel"),
					textColor: Colors.white,
					color: Colors.red,
					onPressed: () { Navigator.pop(context); }
				),
			),
		]
	);
}

SimpleDialog statusDialog(context){
	return SimpleDialog(
		title: Text(
			'Notice',
			textAlign: TextAlign.center
		),
		children: [
			Padding(
				padding: const EdgeInsets.fromLTRB(16.0, 0.0, 16.0, 32.0),
				child: Text(
					"Import Started",
					textAlign: TextAlign.center
				)
			),
			StreamBuilder(
				stream: server.getStatus(),
				builder: (context, snapshot) {
					return Text(
						snapshot.hasData ? '${snapshot.data}' : '',
						textAlign: TextAlign.left,
						overflow: TextOverflow.ellipsis,
					);
				},
			),
			FractionallySizedBox(
				widthFactor: 0.7,
				child: RaisedButton(
					child: Text("Cancel"),
					textColor: Colors.white,
					color: Colors.red,
					onPressed: () { Navigator.pop(context); }
				),
			),
		]
	);
}

SimpleDialog connectDialog(context){
	String username = "";
	return SimpleDialog(
		title: Text(
			'Notice',
			textAlign: TextAlign.center
		),
		children: [
			Padding(
				padding: const EdgeInsets.fromLTRB(16.0, 0.0, 16.0, 32.0),
				child: Text(
					"Import Started",
					textAlign: TextAlign.center
				)
			),
			TextField(
				onChanged: (inputText) => username = inputText,
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
			),
			FractionallySizedBox(
				widthFactor: 0.7,
				child: RaisedButton(
					child: Text("Import"),
					textColor: Colors.white,
					color: Colors.blue,
					onPressed: () {
						server.storePlaysFromListenBrainz(username);
						Navigator.pop(context);
					}
				),
			),
		]
	);
}

class DrawerState extends State<MainDrawer>{

	content(){
		return StreamBuilder(
			stream: server.getTasks(),
			builder: (context, AsyncSnapshot<Map<String, Task>> snapshot) {
				if(!snapshot.hasData) return Text("No active tasks");
				final tasks = snapshot.data;
				final taskList = <Task>[];
				tasks.forEach((key, value) => taskList.add(value));
				return ListView.builder(
					itemBuilder: (context, index) {
						final task = taskList[index];
						return ListTile(
							leading: CircularProgressIndicator(),
							title: Text(task.name),
							subtitle: Text(task.status),
						);
					},
					itemCount: taskList.length,
				);
			},
		);
	}

	build(context) {
		return Drawer(
			child: ListTileTheme(
				selectedColor: Colors.white,
				style: ListTileStyle.drawer,
				child: content()
			)
		);
	}
}