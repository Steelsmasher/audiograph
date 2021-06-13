import 'package:flutter/material.dart';

import 'global.dart';
import 'taskWidget.dart';
import 'blankView.dart';
import 'server.dart' as server;

class TasksPage extends StatelessWidget {

	build(context){
		return Column(
			children: [
				AppBar(
					title: Text('Tasks'),
				),
				Expanded(
					child: StreamBuilder(
						stream: server.getTasks(),
						builder: (context, AsyncSnapshot<Map<String, Task>> snapshot) {
							if(!snapshot.hasData) return BlankView();
							final tasks = snapshot.data;
							final taskList = <Task>[];
							tasks.forEach((key, value) => taskList.add(value));
							return Padding(
								padding: const EdgeInsets.all(16.0),
								child: ListView.builder(
									itemBuilder: (context, index) {
										final task = taskList[index];
										return Card(
											child: InkWell(
												onTap: () async => await showDialog(
													context: context,
													builder: (context) => Dialog(child: TaskWidget(task))				
												),
												child: Column(
													crossAxisAlignment: CrossAxisAlignment.start,
													children: [
														Padding(
															padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 2.0),
															child: Text(task.description, style: const TextStyle(fontSize: 16.0)),
														),
														Padding(
															padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 2.0),
															child: Text(task.status, style: const TextStyle(fontSize: 14.0, color: Colors.black54)),
														),
														(task.total < 0)
															? SizedBox(height: 10)
															: SizedBox(
																height: 10,
																child: LinearProgressIndicator(value: task.total == 0 ? null : task.progress/task.total),
															)
													]
												),
											),
										);
									},
									itemCount: taskList.length,
								),
							);
						},
					),
				),
			],
		);
	}
}