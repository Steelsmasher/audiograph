import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'global.dart';

Map<String, DateTime> getDateRange(DateRange dateRange){
	final today = DateTime.now();
	DateTime startDate, endDate;
	switch(dateRange) {
		case DateRange.Today:
			startDate = DateTime(today.year, today.month, today.day);
			endDate = DateTime(today.year, today.month, today.day+1).subtract(microsecond);
			break;
		case DateRange.ThisMonth:
			startDate = DateTime(today.year, today.month);
			endDate = DateTime(today.year, today.month+1).subtract(microsecond);
			break;
		default:
			startDate = earliestDate;
			endDate = latestDate;
	}
	return {"startDate": startDate, "endDate": endDate};
}

dropDown(DateRange dateRange, Function onDateChange, BuildContext context){
	return Container(
		height: 30,
		width: 200,

		child: DropdownButton<DateRange>(
			value: dateRange,
			underline: Container(),  // A blank container hides the underline
			isExpanded: true,
			icon: const Icon(Icons.arrow_drop_down),
			onChanged: (selection) async {
				onDateChange(selection);
				if(selection == DateRange.Custom){
					await showDialog(
						context: context,
						builder: (context) => DateDialogBox()
					);
				} else { onDateChange(selection); }
			},
			items: [
				const DropdownMenuItem(value: DateRange.Today, child: Center(child: Text("Today"))),
				const DropdownMenuItem(value: DateRange.ThisMonth, child: Center(child: Text("This Month"))),
				const DropdownMenuItem(value: DateRange.AllTime, child: Center(child: Text("All Time"))),
				const DropdownMenuItem(value: DateRange.Custom, child: Center(child: Text("Custom")))
			],
		)
	);
}

class DateDialogBox extends StatefulWidget {
	DateDialogBoxState createState() => DateDialogBoxState();
}

class DateDialogBoxState extends State<DateDialogBox> {

	DateTime _startDate;
	DateTime _endDate;

	initState() {
		super.initState();
		_startDate = startDate;
		_endDate = endDate;
	}
	
	build(context) {
		return SimpleDialog(
			title: const Text('Select A Period'),
			contentPadding: EdgeInsets.zero,
			children: [
				SimpleDialogOption(
					child: InkWell(
						onTap: () {
							showDatePicker(
								context: context,
								firstDate: earliestDate,
								initialDate: earliestDate,
								lastDate: latestDate,
							).then((date){
								if(date != null)  // If user selects cancel the date is null
									setState((){
										_startDate = date;
										if(_endDate.compareTo(_startDate) <= 0){  // The endDate must always be after the startDate
											_endDate = _startDate.add(oneDay).subtract(microsecond);
										}
									});
							});
						},
						child: InputDecorator(
							decoration: InputDecoration(
								labelText: 'Start Date'
							),
							child: Text(DateFormat.yMMMd().format(_startDate)),
						)
					)
				),
				SimpleDialogOption(
					child: InkWell(
						onTap: () {
							showDatePicker(
								context: context,
								firstDate: earliestDate,
								initialDate: latestDate,
								lastDate: latestDate,
							).then((date){
								if(date != null)  // If user selects cancel the date is null
									setState((){
										_endDate = date;
										if(_startDate.compareTo(_endDate) >= 0){  // The startDate must always be before the endDate
											_startDate = _endDate.subtract(oneDay);
										}
									});
							});
						},
						child: InputDecorator(
							decoration: InputDecoration(
								labelText: 'End Date'
							),
							child: Text(DateFormat.yMMMd().format(_endDate)),
						)
					)
				),
				Padding(
					padding: const EdgeInsets.only(top: 20.0),
					child: Row(
						children: <Widget>[
							Expanded(
								child: SizedBox(
									height: 50.0,
									child: OutlineButton(
										shape: BeveledRectangleBorder(),
										child: Text('Confirm'),
										onPressed: (){
											setState(() {
												//setSubDateRange(DateRange.Custom, customStartDate: _startDate, customEndDate: endDate);
												Navigator.pop(context);
											});
										},
									),
								),
							),
							Expanded(
								child: SizedBox(
									height: 50.0,
									child: OutlineButton(
										shape: BeveledRectangleBorder(),
										child: Text('Cancel'),
										onPressed: (){ Navigator.pop(context); }
									),
								),
							),
						],
					)
				)
			]
		);
	}
}