import 'package:flutter/material.dart';

import 'global.dart';
import 'server.dart' as server;

class TaskWidget extends StatelessWidget {

	final Task task;

	TaskWidget(this.task);

	build(context){
		return SizedBox(
			width: 450,
			height: 200,
			child: Padding(
				padding: const EdgeInsets.all(16.0),
				child: Column(
					mainAxisAlignment: MainAxisAlignment.center,
					children: [
						Text(task.description, style: TextStyle(fontSize: 24)),
						SizedBox(height: 24),
						LinearProgressIndicator(value: task.total == 0 ? null : task.progress/task.total, minHeight: 5),
						Align(
							alignment: Alignment.centerLeft,
							child: Text(task.status, overflow: TextOverflow.ellipsis)
						),
						SizedBox(height: 16),
						Row(
							children: [
								Expanded(
									child: Padding(
										padding: const EdgeInsets.all(8.0),
										child: ElevatedButton(
												style: ElevatedButton.styleFrom(
													onPrimary: Colors.white,
													primary: Colors.red,
													minimumSize: Size(88, 36),
													padding: EdgeInsets.symmetric(horizontal: 16),
													shape: const RoundedRectangleBorder(
														borderRadius: BorderRadius.all(Radius.circular(2)),
													),
												),
												onPressed: () {
													server.cancelTask(task.name);
													Navigator.pop(context);
												},
												child: Text("Stop Task"),
											)

									),
								),
								Expanded(
									child: Padding(
										padding: const EdgeInsets.all(8.0),
										child: ElevatedButton(
												style: ElevatedButton.styleFrom(
													onPrimary: Colors.white,
													primary: Colors.orange,
													minimumSize: Size(88, 36),
													padding: EdgeInsets.symmetric(horizontal: 16),
													shape: const RoundedRectangleBorder(
														borderRadius: BorderRadius.all(Radius.circular(2)),
													),
												),
												onPressed: () => Navigator.pop(context),
												child: Text("Run In Background"),
											)
									),
								)
							]
						)
					]
				),
			),
		);
	}
}