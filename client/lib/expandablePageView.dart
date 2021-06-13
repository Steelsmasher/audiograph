import 'package:flutter/material.dart';

class ExpandablePageView extends StatefulWidget {
	final List<Widget> children;
	final PageController controller;

	const ExpandablePageView({
		Key key,
		@required this.children,
		@required this.controller
	}) : super(key: key);

	@override
	_ExpandablePageViewState createState() => _ExpandablePageViewState();
}

class _ExpandablePageViewState extends State<ExpandablePageView> with TickerProviderStateMixin {
	List<double> _heights;
	int _currentPage = 0;

	double get _currentHeight => _heights[_currentPage];

	@override
	void initState() {
		_heights = widget.children.map((e) => 0.0).toList();
		super.initState();
		widget.controller.addListener(() {
			final _newPage = widget.controller.page.round();
			if (_currentPage != _newPage) setState(() => _currentPage = _newPage);
		});
	}

	@override
	Widget build(BuildContext context) {
		return TweenAnimationBuilder<double>(
			curve: Curves.easeInOutCubic,
			duration: const Duration(milliseconds: 100),
			tween: Tween<double>(begin: _heights[0], end: _currentHeight),
			builder: (context, value, child) => SizedBox(height: value, child: child),
			child: PageView.builder(
				physics: NeverScrollableScrollPhysics(),
				controller: widget.controller,
				itemBuilder: (context, index){
					return OverflowBox(
						//needed, so that parent won't impose its constraints on the children, thus skewing the measurement results.
						minHeight: 0,
						maxHeight: double.infinity,
						alignment: Alignment.topCenter,
						child: _SizeReportingWidget(
							onSizeChange: (size) => setState(() => _heights[index] = size?.height ?? 0),
							child: Align(child: widget.children[index])
						),
					);
				},
				//itemBuilder: (context, index) => _sizeReportingChildren[index]
			)/*PageView(
				physics: NeverScrollableScrollPhysics(),
				controller: widget.controller,
				children: _sizeReportingChildren
					.asMap() //
					.map((index, child) => MapEntry(index, child))
					.values
					.toList(),
			)*/,
		);
	}

	/*List<Widget> get _sizeReportingChildren => widget.children
		.asMap() //
		.map(
			(index, child) => MapEntry(
			index,
			OverflowBox(
				//needed, so that parent won't impose its constraints on the children, thus skewing the measurement results.
				minHeight: 0,
				maxHeight: double.infinity,
				alignment: Alignment.topCenter,
				child: _SizeReportingWidget(
				onSizeChange: (size) => setState(() => _heights[index] = size?.height ?? 0),
				child: Align(child: child),
				),
			),
			),
		)
		.values
		.toList();*/
}

class _SizeReportingWidget extends StatefulWidget {
	final Widget child;
	final ValueChanged<Size> onSizeChange;

	const _SizeReportingWidget({
		Key key,
		@required this.child,
		@required this.onSizeChange,
	}) : super(key: key);

	@override
	_SizeReportingWidgetState createState() => _SizeReportingWidgetState();
}

class _SizeReportingWidgetState extends State<_SizeReportingWidget> {
	Size _oldSize;

	@override
	Widget build(BuildContext context) {
		WidgetsBinding.instance.addPostFrameCallback((_) => _notifySize());
		return widget.child;
	}

	void _notifySize() {
		final size = context?.size;
		if (_oldSize != size) {
			_oldSize = size;
			widget.onSizeChange(size);
		}
	}
}