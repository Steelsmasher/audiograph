import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart' as url;

import 'server.dart' as server;
import 'expandablePageView.dart';

class SpotifyPluginCard extends StatelessWidget {

	final isSpotifyConnected = server.isSpotifyConnected();

	banner() => Padding(
		padding: const EdgeInsets.all(16.0),
		child: Stack(
			alignment: AlignmentDirectional.center,
			children: [
				Image.asset("assets/Spotify_Logo.png", fit: BoxFit.fitWidth),
				Align(
					alignment: Alignment.bottomRight,
					child: FutureBuilder(
						future: isSpotifyConnected,
						builder: (context, snapshot){
							if(!snapshot.hasData) return Text('Checking...');
							final bool spotifyConnected = snapshot.data;
							if(spotifyConnected) return Text(
								'Connected',
								style: TextStyle(color: Colors.green[800], fontSize: 16, fontWeight: FontWeight.bold)
							);
							return SizedBox();
						}
					),
				)
			]
		)
	);

	panel(connectAction, disconnectAction) => Container(
		color: Colors.green,
		child: Column(
			children: [
				Padding(
					padding: const EdgeInsets.all(8.0),
					child: Align(
						alignment: Alignment.centerLeft,
						child: Text(
							"Spotify",
							style: const TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.bold)
						),
					),
				),
				Padding(
					padding: const EdgeInsets.fromLTRB(8, 0, 8, 4),
					child: Align(
						alignment: Alignment.centerLeft,
						child: Text(
							"Connect to Spotify",
							style: const TextStyle(color: Colors.white, fontSize: 16)
						),
					),
				),
				Padding(
					padding: const EdgeInsets.all(16.0),
					child: SizedBox(
						width: double.infinity,
						child: FutureBuilder(
							future: isSpotifyConnected,
							builder: (context, snapshot){
								if(!snapshot.hasData) return Text('Checking...');
								final bool spotifyConnected = snapshot.data;
								if(spotifyConnected) return ElevatedButton(
									onPressed: () async => await disconnectAction(),
									child: Text("Disconnect"),
									style: ElevatedButton.styleFrom(
										primary: Colors.green[700], // background
										onPrimary: Colors.white, // foreground
									)
								);
								return ElevatedButton(
									onPressed: () async => await connectAction(),
									child: Text("Connect"),
									style: ElevatedButton.styleFrom(
										primary: Colors.green[700], // background
										onPrimary: Colors.white, // foreground
									)
								);
							}
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
				builder: (context) => Dialog(child: SpotifyPluginWizard())				
			);
		};

		final disconnectAction = () async {
			await showDialog(
				context: context,
				builder: (context) => Dialog(
					child: SizedBox(
						width: 450,
						height: 200,
						child: Column(
							children: [
								Expanded(
									child: Text('Are you sure? Disconnecting will stop your plays on Spotify from being recorded.', textAlign: TextAlign.center)
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
													color: Colors.red,
													textColor: Colors.white,
													child: Text('Disconnect'),
													onPressed: () => server.disconnectSpotify()
												),
											],
										),
									),
								)
							]
						),
					)
				)
			);
		};

		return Card(
			child: SizedBox(
				height: 300, width: 300,
				child: Column(
					children: [
						Expanded(child: banner()),
						Expanded(child: panel(connectAction, disconnectAction))
					]
				)
			)
		);
	}
}

class SpotifyPluginWizard extends StatefulWidget {
	createState() => _SpotifyPluginWizardState();
}

class _SpotifyPluginWizardState extends State<SpotifyPluginWizard> {

	final controller = PageController(initialPage: 0);

	Function getSpotifyRedirectURI = () async => '';
	Function getSpotifyAuthorisationURL = () async => '';
	Function isSpotifyConnected = () async => false;
	String clientID = '';
	String clientSecret = '';

	firstPage(){
		return Column(
			children: [
				Expanded(
					flex: 2,
					child: Text("To record your plays from Spotify you will need a Spotify developer account. It's quick to setup.", textAlign: TextAlign.center)
				),
				Expanded(
					child: Center(
						child: RaisedButton(
							color: Colors.orange,
							textColor: Colors.white,
							child: Text('Next'),
							onPressed: () => controller.nextPage(duration: Duration(milliseconds: 250), curve: Curves.easeIn)
						),
					),
				)
			]
		);
	}

	secondPage(){
		return Column(
			children: [
				Expanded(
					child: Text('Follow the link below and create a new app. You can give it any name, such as "Audiograph" for example.', textAlign: TextAlign.center)
				),
				Expanded(
					child: TextButton(
						onPressed: () => url.launch('https://developer.spotify.com/dashboard/'),
						child: Text(
							'https://developer.spotify.com/dashboard/',
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
									onPressed: () => controller.previousPage(duration: Duration(milliseconds: 250), curve: Curves.easeIn)
								),
								RaisedButton(
									color: Colors.orange,
									textColor: Colors.white,
									child: Text('Next'),
									onPressed: () {
										getSpotifyRedirectURI = () => server.getSpotifyRedirectURI();
										controller.nextPage(duration: Duration(milliseconds: 250), curve: Curves.easeIn);
										setState(() {});
									}
								),
							],
						),
					),
				)
			]
		);
	}

	thirdPage(BuildContext context){
		return Column(
			children: [
				Expanded(
					child: Text("Go to the settings menu of your Spotify app then copy the text below to the Redirect URIs list", textAlign: TextAlign.center)
				),
				Expanded(
					child: FutureBuilder(
						future: getSpotifyRedirectURI(),
						builder: (context, snapshot){
							if(!snapshot.hasData) return Center( child: Padding( padding: const EdgeInsets.all(50.0), child: Text('LOADING...')));
							final String redirectURI = snapshot.data;
							return Row(
								mainAxisAlignment: MainAxisAlignment.center,
								children: [
									IconButton(icon: Icon(Icons.copy), onPressed: () async {
										await Clipboard.setData(ClipboardData(text: redirectURI));
										ScaffoldMessenger.of(context).showSnackBar(SnackBar(
											content: Text("URL Copied"),
										));
									}),
									SelectableText(
										redirectURI,
										textAlign: TextAlign.center,
									),
								],
							);
						}
					)
				),
				Expanded(
					child: Center(
						child: Row(
							mainAxisAlignment: MainAxisAlignment.spaceEvenly,
							children: [
								RaisedButton(
									child: Text('Previous'),
									onPressed: () => controller.previousPage(duration: Duration(milliseconds: 250), curve: Curves.easeIn)
								),
								RaisedButton(
									color: Colors.orange,
									textColor: Colors.white,
									child: Text('Next'),
									onPressed: () => controller.nextPage(duration: Duration(milliseconds: 250), curve: Curves.easeIn)
								),
							],
						),
					),
				)
			]
		);
	}

	fourthPage(BuildContext context){
		final clientIDController = TextEditingController();
		final clientSecretController = TextEditingController();

		return Column(
			children: [
				Expanded(
					child: Text("Copy the Client ID and Client Secret from your app into the boxes below", textAlign: TextAlign.center)
				),
				Row(
					mainAxisAlignment: MainAxisAlignment.center,
					children: [
						IconButton(icon: Icon(Icons.paste), onPressed: () async {
							final clipboardData = await Clipboard.getData('text/plain');
							clientIDController.text = clipboardData.text;
							clientID = clipboardData.text;
						}),
						Expanded(
							child: TextField(
								controller: clientIDController,
								onChanged: (text) => clientID = text,
								decoration: InputDecoration(
									border: OutlineInputBorder(),
									hintText: 'Client ID'
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
							clientSecretController.text = clipboardData.text;
							clientSecret = clipboardData.text;
						}),
						Expanded(
							child: TextField(
								controller: clientSecretController,
								onChanged: (text) => clientSecret = text,
								decoration: InputDecoration(
									border: OutlineInputBorder(),
									hintText: 'Client Secret'
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
									onPressed: () => controller.previousPage(duration: Duration(milliseconds: 250), curve: Curves.easeIn)
								),
								RaisedButton(
									color: Colors.orange,
									textColor: Colors.white,
									child: Text('Next'),
									onPressed: () async {
										await server.initialiseSpotifyAuthorisation(clientID, clientSecret);
										getSpotifyAuthorisationURL = () => server.getSpotifyAuthorisationURL();
										controller.nextPage(duration: Duration(milliseconds: 250), curve: Curves.easeIn);
										setState(() {});
									}
								),
							],
						),
					),
				)
			]
		);
	}

	fifthPage(){
		return Column(
			children: [
				Expanded(child: Text("Clicking the link below will open your browser. Follow the steps to gain authentication from Spotify", textAlign: TextAlign.center)),
				Expanded(
					child: FutureBuilder(
						future: getSpotifyAuthorisationURL(),
						builder: (context, snapshot){
							if(!snapshot.hasData) return Center( child: Padding( padding: const EdgeInsets.all(50.0), child: Text('LOADING...')));
							final String authorisationURL = snapshot.data;
							return TextButton(
								onPressed: () => url.launch(authorisationURL),
								child: Text(
									authorisationURL,
									textAlign: TextAlign.center,
									style: TextStyle(color: Colors.blue),
									overflow: TextOverflow.ellipsis,
								)
							);
						}
					)
				),
				Expanded(
					child: Center(
						child: Row(
							mainAxisAlignment: MainAxisAlignment.spaceEvenly,
							children: [
								RaisedButton(
									child: Text('Previous'),
									onPressed: () => controller.previousPage(duration: Duration(milliseconds: 250), curve: Curves.easeIn)
								),
								RaisedButton(
									color: Colors.orange,
									textColor: Colors.white,
									child: Text('Next'),
									onPressed: () {
										isSpotifyConnected = () => server.isSpotifyConnected();
										controller.nextPage(duration: Duration(milliseconds: 250), curve: Curves.easeIn);
										setState(() {});
									}
								),
							],
						),
					),
				)
			]
		);
	}

	sixthPage(){
		return FutureBuilder(
			future: isSpotifyConnected(),
			builder: (context, snapshot){
				if(snapshot.hasData && snapshot.data) return Column(
					children: [
						Expanded(child: Text("Authentication complete! Your tracks from Spotify will now be recorded.", textAlign: TextAlign.center)),
						RaisedButton(child: Text('Done'), onPressed: () => Navigator.pop(context))
					]
				); else return Column(
					children: [
						Expanded(child: Text("Spotify has not yet given authentication. Please go back to the previous page and follow the link provided.", textAlign: TextAlign.center)),
						RaisedButton(child: Text('Previous'), onPressed: () => controller.previousPage(duration: Duration(milliseconds: 250), curve: Curves.easeIn))
					]
				);
			}
		);
	}

	build(context){
		return SizedBox(
			width: 450,
			child: ExpandablePageView(
				controller: controller,
				children: [
					Container(padding: const EdgeInsets.all(16.0), height: 200, child: firstPage()),
					Container(padding: const EdgeInsets.all(16.0), height: 250, child: secondPage()),
					Container(padding: const EdgeInsets.all(16.0), height: 250, child: thirdPage(context)),
					Container(padding: const EdgeInsets.all(16.0), height: 350, child: fourthPage(context)),
					Container(padding: const EdgeInsets.all(16.0), height: 250, child: fifthPage()),
					Container(padding: const EdgeInsets.all(16.0), height: 250, child: sixthPage()),
				]
			),
		);
	}
}