import 'package:flutter/material.dart';

import '../core/config.dart';
import '../core/constants.dart';
import '../features/all_tracks_page.dart';
import '../features/import_menu.dart';
import '../features/loading_page.dart';
import '../features/player_controls/player_controls.dart';
import '../features/playlists_page.dart';
import '../features/settings_page.dart';
import 'app_controller.dart';
import 'caption_widget.dart';

class App extends StatefulWidget {
  const App({super.key});

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> with SingleTickerProviderStateMixin {
  late final animation = AnimationController(
    duration: const Duration(seconds: 1),
    vsync: this,
  );
  var isLoaded = false;
  late final Future<void> future = loadConfiguration();

  AppController get controller => mainPageController;

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
    animation.animateTo(1, curve: Curves.easeInOut);
    isLoaded = true;
  });

  @override
  Widget build(BuildContext context) => isLoaded
      ? Scaffold(
          body: FadeTransition(
            opacity: animation,
            child: Column(
              children: [
                Expanded(
                  child: Row(
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
                              const CaptionWidget(title: 'Flux Music Player'),

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
                const Padding(
                  padding: .only(right: 4, left: 4, bottom: 4),
                  child: PlayerControls(),
                ),
              ],
            ),
          ),
        )
      : LoadingPage(future: future, onLoad: onLoad);

  Widget buildPage() => switch (controller.pageIndex) {
    0 => const AllTracksPage(),
    1 => const PlaylistsPage(),
    2 => const SettingsPage(),
    _ => const AllTracksPage(),
  };

  NavigationRail buildNavigationRail() => NavigationRail(
    labelType: .selected,
    destinations: const [
      NavigationRailDestination(
        icon: Icon(Icons.music_note_rounded),
        label: Text('Все треки'),
      ),
      NavigationRailDestination(
        icon: Icon(Icons.library_music_rounded),
        label: Text('Плейлисты'),
      ),
    ],
    trailing: Expanded(
      child: NavigationRail(
        groupAlignment: 1,
        labelType: .selected,
        selectedIndex: controller.pageIndex >= 2
            ? controller.pageIndex - 2
            : null,
        destinations: const [
          NavigationRailDestination(
            icon: Icon(Icons.settings_rounded),
            label: Text('Настройки'),
          ),
        ],
        leadingAtTop: false,
        leading: IconButton(
          hoverColor: colorScheme.primary.withAlpha(10),
          splashColor: colorScheme.primary.withAlpha(100),
          visualDensity: .compact,
          padding: const .symmetric(horizontal: 16),
          onPressed: () =>
              showDialog(context: context, builder: (_) => const ImportMenu()),
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
