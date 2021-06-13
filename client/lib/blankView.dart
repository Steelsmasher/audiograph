import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'global.dart';

class BlankView extends StatelessWidget {
	build(context) {
		return Center(
			child: Column(
				mainAxisAlignment: MainAxisAlignment.center,
				children: [
					Expanded(
						child: FittedBox(
							fit: BoxFit.contain,
							child: Icon(
								Icons.help_outline,
								color: Colors.grey,
							),
						),
					),
					Padding(
						padding: const EdgeInsets.all(16.0),
						child: Text(
						"You have not listened to any tracks between ${DateFormat('d MMMM').format(startDate)} and ${DateFormat('d MMMM').format(endDate)}"
						"\n\nTry clicking the refresh icon to get an updated list of tracks",
						style: TextStyle(
							color: Colors.black
						),
						textAlign: TextAlign.center,
						),
					)
				],
			),
		);
	}
}