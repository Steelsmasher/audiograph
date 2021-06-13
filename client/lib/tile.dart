import 'package:flutter/material.dart';
import 'historyPage.dart';

class Tile extends StatelessWidget {

	final Widget child;

	Tile(this.child);

	build(context){
		return InkWell(
			onTap: (){ /*Navigator.push(context, MaterialPageRoute(
				builder: (context) => HistoryPage(),
			));*/Navigator.pushNamed(context, '/history', arguments: "History"); },
			child: Container(
				child: child
			),
		);
	}
}