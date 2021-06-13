import 'dart:collection';

import 'package:flutter/material.dart';
import 'router.dart';
import 'package:logging/logging.dart';

main() {
	Queue<LogRecord> logs = Queue();

	Logger.root.level = Level.ALL; // defaults to Level.INFO
	Logger.root.onRecord.listen((record) {
		print('${record.level.name}: ${record.time}: ${record.message}');
		logs.addLast(record);
		while(logs.length > 100) logs.removeFirst();
	});

	final log = Logger('Audiograph');
	log.info("Starting client app");


	runApp(MaterialApp(
		title: 'Audiograph',
		theme: ThemeData(
			primaryColor: Colors.blue[800],
			primaryColorDark: Colors.blue[900],
			accentColor: Colors.orange,
			visualDensity: VisualDensity.adaptivePlatformDensity,
		),
		//home: MainPage(),
		initialRoute: '/',
		onGenerateRoute: (settings) => generateRoutes(settings),
	));
}