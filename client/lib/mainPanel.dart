import 'package:flutter/material.dart';

import 'drawer.dart';

class MainPanel extends StatelessWidget{

	@required final String title; // TODO May not be needed
	@required final Widget body;

	MainPanel({this.title, this.body});

	build(context){

		return Scaffold(
			body: Row(
				children: [
					Material(
						color: Theme.of(context).primaryColorDark,
						child: Column(
							children: [
								InkWell(
									onTap: () => Navigator.pushNamedAndRemoveUntil(context, "/dashboard", ModalRoute.withName('/')),
									child: Padding(
										padding: const EdgeInsets.all(10.0),
										child: Icon(Icons.home, size: 36, color: Colors.white),
									),
								),
								InkWell(
									onTap: (){ Navigator.pushNamed(context, '/tasks'); },
									child: Padding(
										padding: const EdgeInsets.all(10.0),
										child: Icon(Icons.done, size: 36, color: Colors.white),
									)
								),
								InkWell(
									onTap: (){ Navigator.pushNamed(context, '/connect'); },
									child: Padding(
										padding: const EdgeInsets.all(10.0),
										child: Icon(Icons.connect_without_contact, size: 36, color: Colors.white),
									)
								),
								InkWell(
									onTap: () => print("Help Screen"),
									child: Padding(
										padding: const EdgeInsets.all(10.0),
										child: Icon(Icons.help, size: 36, color: Colors.white),
									),
								)
							],
						),
					),
					/*Expanded(
						child: Column(
							children: [
								AppBar( // Universal app bar
									title: Text(title),
								),
								Expanded( child: body ),
							],
						),
					)*/
					Expanded( child: body )
				],
			),
		);
	}
}