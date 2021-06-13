import 'package:flutter/material.dart';
import 'package:charts_flutter/flutter.dart';
import 'dart:collection';

class _Model {
	final String category;
	final int value;

	_Model(this.category, this.value);
}

class BarGraph extends StatefulWidget {
	final LinkedHashMap<String, int> data;
	final String units;

	BarGraph(this.data, this.units);
	createState() => _BarGraphState();
}

class _BarGraphState extends State<BarGraph> {
	List<Series<_Model, String>> chartData;

	_onSelectionChanged(SelectionModel model) {
		_Model selectedData = (model.hasDatumSelection) ? model.selectedDatum.first.datum : null;  // TODO To be used later
	}

	convertData(){ // Convert data to dispayable chart data
		List<_Model> dataList = widget.data.entries.map((entry) => _Model(entry.key, entry.value)).toList();

		return [ Series<_Model, String>(
			id: 'Chart',
			colorFn: (_, __) => MaterialPalette.blue.shadeDefault,
			domainFn: (_Model model, _) => model.category,
			measureFn: (_Model model, _) => model.value,
			data: dataList,
			labelAccessorFn: (_Model model, _){
				return (model.value == 0) ? 'No ${widget.units}' : '${model.value} ${widget.units}';
			}
		)];
	}

	build(context) {

		chartData = convertData();

		return BarChart(
			chartData,
			animate: false,
			vertical: true,
			primaryMeasureAxis: NumericAxisSpec(renderSpec: NoneRenderSpec()),
			domainAxis: OrdinalAxisSpec(
				showAxisLine: false,
			),
			barRendererDecorator: BarLabelDecorator<String>(),
			selectionModels: [
				SelectionModelConfig(
					type: SelectionModelType.info,
					changedListener: _onSelectionChanged,
					updatedListener: _onSelectionChanged,
				)
			],
		);
	}
}