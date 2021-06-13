import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'dart:io';

import 'server.dart' as server;

class SplashPage extends StatefulWidget {
	createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
//class SplashPage extends StatelessWidget {

	Future<bool> serverIsRunning;
	int numOfPlays = 0;

	initState(){
		super.initState();
		serverIsRunning = initialiseServer();
	}

	Future initialiseServer() {
		return Future<bool>(() async {
			bool _serverIsRunning = await server.ping();
			if(!_serverIsRunning){ // If the server isn't running, start the server
				print("No response from server. Starting new server process");
				await Process.start('server', [], runInShell: true, mode: ProcessStartMode.inheritStdio);
				await Future.delayed(const Duration(seconds: 5));
				_serverIsRunning = await server.ping();
			}
			if(_serverIsRunning) numOfPlays = await server.getTotalPlays();
			return _serverIsRunning;
		});
	}

	loadingWidget() => Column(
		mainAxisAlignment: MainAxisAlignment.center,
		children: [
			Text("Waiting for server response"),
			CircularProgressIndicator()
		],
	);

	retryWidget() => Column(
		mainAxisAlignment: MainAxisAlignment.center,
		children: [
			Text("Failed to connect to server"),
			ElevatedButton(
				onPressed: () => setState(() { serverIsRunning = initialiseServer(); }),
				child: Text("Retry"),
				style: ElevatedButton.styleFrom(
					primary: Colors.orange[800], // background
					onPrimary: Colors.white, // foreground
				)
			)
		],
	);

	build(context) {
		return FutureBuilder(
			future: serverIsRunning,
			builder: (context, snapshot) {
				if(snapshot.connectionState != ConnectionState.done) return loadingWidget();
				if(!snapshot.data) return retryWidget();
				if(numOfPlays > 0) SchedulerBinding.instance.addPostFrameCallback((_) => Navigator.pushReplacementNamed(context, '/dashboard'));
				else SchedulerBinding.instance.addPostFrameCallback((_) => Navigator.pushReplacementNamed(context, '/connect'));
				return Text("Connecting to server...");
			}
		);


		/*return Column(
			mainAxisAlignment: MainAxisAlignment.center,
			children: [
				FutureBuilder(
					future: initialiseServer(),
					builder: (context, snapshot) {
						if(!snapshot.hasData) return Text("Waiting for server response");
						if(!snapshot.data) return Text("Failed to connect to server");
						if(_numOfPlays > 0) SchedulerBinding.instance.addPostFrameCallback((_) => Navigator.pushReplacementNamed(context, '/dashboard'));
						else SchedulerBinding.instance.addPostFrameCallback((_) => Navigator.pushReplacementNamed(context, '/connect'));
						return Text("Connecting to server...");
					}
				),
				CircularProgressIndicator()
			]
		);*/
	}
}