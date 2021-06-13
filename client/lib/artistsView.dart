import 'package:flutter/material.dart';
import 'dart:collection';
import 'global.dart';
import 'blankView.dart';

class ArtistsView extends StatelessWidget {

	ListView getArtistList(LinkedHashMap<Artist, int> artistPlays){
		final artistPlaysList = artistPlays.keys.toList(growable: false);
		return ListView.builder(
			itemBuilder: (context, index) {
				final artist = artistPlaysList[index];
				final artistPlayCount = artistPlays[artist];
				final title = artist.name;
				final subtitle = '$artistPlayCount plays';

				return Card(
					child: ListTile(
						title: Text(title),
						subtitle: Text(subtitle),
					)
				);
			},
			itemCount: artistPlays.length,
			addAutomaticKeepAlives: false,
			addRepaintBoundaries: false
		);
	}

	build(context) {
		final loadingWidget = Center( child: Padding( padding: const EdgeInsets.all(50.0), child: Text('LOADING...')));

		return FutureBuilder(
			future: artistPlays,
			builder: (context, snapshot){
				if(snapshot.hasData){
					final _artistPlays = snapshot.data;
					if(_artistPlays.isEmpty) return BlankView();

					return getArtistList(_artistPlays);
				} else { return loadingWidget; }
			}
		);
	}
}