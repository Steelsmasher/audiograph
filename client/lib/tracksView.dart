import 'package:flutter/material.dart';
import 'dart:collection';
import 'global.dart';
import 'blankView.dart';

class TracksView extends StatelessWidget {

	ListView getTrackList(LinkedHashMap<Track, int> trackPlays){
		final trackPlaysList = trackPlays.keys.toList(growable: false);
		return ListView.builder(
			itemBuilder: (context, index) {
				final track = trackPlaysList[index];
				final trackPlayCount = trackPlays[track];
				final title = '${track.leadArtistName} - ${track.title}';
				final subtitle = '$trackPlayCount plays';

				return Card(
					child: ListTile(
						title: Text(title),
						subtitle: Text(subtitle),
					)
				);
			},
			itemCount: trackPlays.length,
			addAutomaticKeepAlives: false,
			addRepaintBoundaries: false
		);
	}

	build(context) {
		final loadingWidget = Center( child: Padding( padding: const EdgeInsets.all(50.0), child: Text('LOADING...')));

		return FutureBuilder(
			future: trackPlays,
			builder: (context, snapshot){
				if(snapshot.hasData){
					final _trackPlays = snapshot.data;
					if(_trackPlays.isEmpty) return BlankView();

					return getTrackList(_trackPlays);
				} else { return loadingWidget; }
			}
		);
	}
}