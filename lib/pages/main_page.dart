import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

import '../config.dart';
import '../widgets/import_menu.dart';
import '../widgets/player.dart';
import 'loading_page.dart';
import 'music_page.dart';
import 'search_page.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage>
    with SingleTickerProviderStateMixin {
  late final animationController = AnimationController(
    duration: const Duration(seconds: 1),
    vsync: this,
  );
  late final fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
    CurvedAnimation(parent: animationController, curve: Curves.easeInOut),
  );
  var pageIndex = 1;
  var isLoaded = false;

  @override
  void dispose() {
    animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Flux Music Player',
    color: Colors.red,
    theme: ThemeData(
      colorScheme: .fromSeed(seedColor: Colors.red.shade700, brightness: .dark),
    ),
    home: isLoaded
        ? Scaffold(
            body: FadeTransition(
              opacity: fadeAnimation,
              child: Row(
                mainAxisSize: .max,
                children: [
                  Padding(
                    padding: const .symmetric(vertical: 12),
                    child: buildNavigationRail(),
                  ),

                  const VerticalDivider(width: 1),

                  Expanded(
                    child: Padding(
                      padding: const .all(8.0),
                      child: Column(
                        children: [
                          buildCaption('Flux Music Player'),

                          Expanded(
                            child: Padding(
                              padding: const .all(4),
                              child: buildPage(),
                            ),
                          ),

                          Player(),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          )
        : LoadingPage(
            future: loadConfiguration(),
            onLoad: () => setState(() {
              isLoaded = true;
              animationController.forward();
            }),
          ),
  );

  Widget buildCaption(String title) => SizedBox(
    height: 28,
    child: Padding(
      padding: const .symmetric(horizontal: 10, vertical: 2),
      child: Row(
        children: [
          Expanded(
            child: DragToMoveArea(child: Text(title, textAlign: .center)),
          ),
          IconButton(
            padding: .all(0),
            style: ButtonStyle(
              shape: .all(RoundedRectangleBorder(borderRadius: .circular(6))),
            ),
            onPressed: windowManager.minimize,
            icon: const Icon(Icons.minimize_rounded),
          ),
          IconButton(
            hoverColor: Colors.red.shade600.withAlpha(200),
            padding: .all(0),
            style: ButtonStyle(
              shape: .all(RoundedRectangleBorder(borderRadius: .circular(6))),
            ),
            onPressed: windowManager.close,
            icon: const Icon(Icons.close_rounded),
          ),
        ],
      ),
    ),
  );

  Widget buildPage() => switch (pageIndex) {
    0 => SearchPage(),
    1 => MusicPage(),
    _ => MusicPage(),
  };

  NavigationRail buildNavigationRail() => NavigationRail(
    labelType: .selected,
    destinations: [
      NavigationRailDestination(
        icon: const Icon(Icons.search_rounded),
        label: const Text('Search'),
      ),
      NavigationRailDestination(
        icon: const Icon(Icons.music_note_rounded),
        label: const Text('Main'),
      ),
    ],
    trailing: IconButton(
      onPressed: () =>
          showDialog(context: context, builder: (_) => ImportMenu()),
      icon: const Icon(Icons.add_to_photos_rounded),
    ),
    leading: Padding(
      padding: const .only(bottom: 12),
      child: Image.asset('assets/logo.png', width: 32),
    ),
    trailingAtBottom: true,
    selectedIndex: pageIndex,
    onDestinationSelected: (value) => setState(() => pageIndex = value),
  );
}
