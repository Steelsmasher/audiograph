import 'dart:ui';

import 'package:flutter/material.dart';

import 'global.dart';
import 'mainPanel.dart';
import 'mainPage.dart';
import 'historyPage.dart';
import 'playChartPage.dart';
import 'tracksPage.dart';
import 'artistPage.dart';
import 'trackPage.dart';
import 'artistPlaysListPage.dart';
import 'trackPlaysListPage.dart';
import 'artistPlaysChartPage.dart';
import 'trackPlaysChartPage.dart';
import 'artistCountsChartPage.dart';
import 'trackCountsChartPage.dart';
import 'connectionsPage.dart';
import 'tasksPage.dart';
import 'splashPage.dart';

String currentRouteName;

class FadeSlideRoute<T> extends MaterialPageRoute<T> {  //TODO this might not be necesssary anymore
	FadeSlideRoute({ WidgetBuilder builder, RouteSettings settings })
		: super(builder: builder, settings: settings);

	@override
	Widget buildTransitions(BuildContext context, Animation<double> animation,	Animation<double> secondaryAnimation, Widget child) {
		return SlideTransition(
			position: Tween(
				begin: const Offset(1.0, 0.0),
				end: Offset.zero,
			).animate(animation),
			child: child,
		);
	}
}


class NoAnimationMaterialPageRoute<T> extends MaterialPageRoute<T> {
	NoAnimationMaterialPageRoute({
		@required WidgetBuilder builder,
		RouteSettings settings,
		bool maintainState = true,
		bool fullscreenDialog = false,
	}) : super(
		builder: builder,
		maintainState: maintainState,
		settings: settings,
		fullscreenDialog: fullscreenDialog
	);

	@override
	Widget buildTransitions(BuildContext context, Animation<double> animation, Animation<double> secondaryAnimation, Widget child) {
		return child;
	}
}


generateRoutes(RouteSettings settings) {
	currentRouteName = settings.name;
	Widget page = MainPage();  // TODO change terminology from page to screen (page implies pagination)
	String title = "Audiograph";

	switch (settings.name) {
		case '/':
			title = "Startup";
			page = SplashPage(); // TODO change this to simply Dashboard
		break;
		case '/dashboard':
			title = "Dashboard";
			page = MainPage(); // TODO change this to simply Dashboard
		break;
		case '/history':
			title = settings.arguments;  // TODO change this to Played tracks or Recently played etc...
			page = HistoryPage();
		break;
		case '/tracks':
			title = settings.arguments;
			page = TracksPage();
		break;
		case '/playChart':
			title = settings.arguments;  // TODO change this to Played tracks or Recently played etc...
			page = PlayChartPage();
		break;
		case '/artist':
			final Artist artist = settings.arguments;
			page = ArtistPage(artist);
		break;
		case '/track':
			final Track track = settings.arguments;
			page = TrackPage(track);
		break;
		case '/artistPlaysList':
			final Artist artist = settings.arguments;
			page = ArtistPlaysListPage(artist);
		break;
		case '/artistPlaysChart':
			final Artist artist = settings.arguments;
			page = ArtistPlaysChartPage(artist);
		break;
		case '/trackPlaysList':
			final Track track = settings.arguments;
			page = TrackPlaysListPage(track);
		break;
		case '/trackPlaysChart':
			final Track track = settings.arguments;
			page = TrackPlaysChartPage(track);
		break;
		case '/artistPeriodCountsChart':
			page = ArtistCountsChartPage();
		break;
		case '/trackPeriodCountsChart':
			page = TrackCountsChartPage();
		break;
		case '/connect':
			title = "Connections";
			page = ConnectionsPage();
		break;
		case '/tasks':
			title = "Tasks";
			page = TasksPage();
		break;
		case '/help':
			title = "About";
			page = SizedBox(width: 500,
				child: Center(
					child: Text("Made by Tino Magondo\nTinotendaMB@gmail.com", style: TextStyle(fontSize: 32))
				)
			);
		break;
	}

	return NoAnimationMaterialPageRoute(
		settings: settings,
		builder: (_) => MainPanel(
			title: title,
			body: page
		)
	);/*Scaffold(
			appBar: AppBar(
				title: const Text("Audiograph"),
			),
			body: getRoute(),
			drawer: MainDrawer(),
		)
	);*/

	/*switch (settings.name) {
		case '/home':
			return MaterialPageRoute(
				builder: (_) => MainPage(),
				settings: settings,
			);
		default:
	}*/
}