import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'global.dart';
import 'blankView.dart';

class HistoryView extends StatelessWidget {

	ListView getPlayList(List<Play> plays){
		return ListView.builder(
			itemBuilder: (context, index) {
				final play = plays[index];
				final timestamp = play.dateTime.toLocal();
				final title = '${play.artistNames} - ${play.trackTitle}';
				final subtitle ='${DateFormat('d MMM yyyy, kk:mm').format(timestamp)}';

				return Card(
					child: ListTile(
						title: Text(title),
						subtitle: Text(subtitle),
					)
				);
			},
			itemCount: plays.length,
			addAutomaticKeepAlives: false,
			addRepaintBoundaries: false
		);
	}

	build(context) {
		final loadingWidget = Center( child: Padding( padding: const EdgeInsets.all(50.0), child: Text('LOADING...')));

		return FutureBuilder(
			future: subHistory,
			builder: (context, snapshot){
				if(snapshot.hasData){
					final _filteredPlays = snapshot.data;
					if(_filteredPlays.isEmpty) return BlankView();

					return getPlayList(_filteredPlays);
				} else { return loadingWidget; }
			}
		);
	}
}