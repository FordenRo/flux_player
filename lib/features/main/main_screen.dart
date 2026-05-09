import 'package:flutter/material.dart';

import '../../core/config.dart';
import '../../core/constants.dart';
import '../../widgets/import_menu.dart';
import '../../widgets/player_controls/player_controls.dart';
import '../all_tracks_page.dart';
import '../loading_page.dart';
import '../playlists_page.dart';
import '../settings_page.dart';
import 'caption_widget.dart';
import 'main_page_controller.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen>
    with SingleTickerProviderStateMixin {
  late final animation = AnimationController(
    duration: const Duration(seconds: 1),
    vsync: this,
  );
  var isLoaded = false;
  late final Future<void> future = loadConfiguration();

  MainPageController get controller => mainPageController;

  @override
  void initState() {
    super.initState();
    mainPageController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    animation.dispose();
    super.dispose();
  }

  void onLoad() => setState(() {
    animation.animateTo(1.0, curve: Curves.easeInOut);
    isLoaded = true;
  });

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
              opacity: animation,
              child: Column(
                children: [
                  Expanded(
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
                            padding: const .only(right: 8, left: 8, top: 8),
                            child: Column(
                              children: [
                                CaptionWidget(title: 'Flux Music Player'),

                                Expanded(
                                  child: Padding(
                                    padding: const .all(4),
                                    child: buildPage(),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const .only(right: 4, left: 4, bottom: 4),
                    child: PlayerControls(),
                  ),
                ],
              ),
            ),
          )
        : LoadingPage(future: future, onLoad: onLoad),
  );

  Widget buildPage() => switch (controller.pageIndex) {
    0 => AllTracksPage(),
    1 => PlaylistsPage(),
    2 => SettingsPage(),
    _ => AllTracksPage(),
  };

  NavigationRail buildNavigationRail() => NavigationRail(
    labelType: .selected,
    destinations: [
      NavigationRailDestination(
        icon: const Icon(Icons.music_note_rounded),
        label: const Text('Все треки'),
      ),
      NavigationRailDestination(
        icon: const Icon(Icons.library_music_rounded),
        label: const Text('Плейлисты'),
      ),
    ],
    trailing: Expanded(
      child: NavigationRail(
        groupAlignment: 1,
        labelType: .selected,
        selectedIndex: controller.pageIndex >= 2
            ? controller.pageIndex - 2
            : null,
        destinations: [
          NavigationRailDestination(
            icon: const Icon(Icons.settings_rounded),
            label: const Text('Настройки'),
          ),
        ],
        leadingAtTop: false,
        leading: IconButton(
          hoverColor: colorScheme.primary.withAlpha(10),
          splashColor: colorScheme.primary.withAlpha(100),
          visualDensity: .compact,
          padding: .symmetric(horizontal: 16),
          onPressed: () =>
              showDialog(context: context, builder: (_) => ImportMenu()),
          icon: const Icon(Icons.add_to_photos_rounded),
        ),
        onDestinationSelected: (value) =>
            setState(() => controller.pageIndex = value + 2),
      ),
    ),
    leading: Padding(
      padding: const .only(bottom: 12),
      child: Image.asset('assets/logo.png', width: 32),
    ),
    trailingAtBottom: true,
    selectedIndex: controller.pageIndex < 2 ? controller.pageIndex : null,
    onDestinationSelected: (value) =>
        setState(() => controller.pageIndex = value),
  );
}
