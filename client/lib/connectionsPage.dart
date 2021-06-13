import 'package:flutter/material.dart';

import 'spotifyPlugin.dart';
import 'lastFMPlugin.dart';
import 'listenbrainzPlugin.dart';

class ConnectionsPage extends StatelessWidget {

	build(context){
		return Center(
			child: Row(
				mainAxisAlignment: MainAxisAlignment.center,
				children: [
					SpotifyPluginCard(),
					SizedBox(width: 50),
					LastFMPluginCard(),
					SizedBox(width: 50),
					ListenBrainzPluginCard()
				],
			),
		);
	}
}