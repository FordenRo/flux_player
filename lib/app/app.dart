import 'package:flutter/material.dart';

import '../core/services/config_service.dart';
import '../pages/all_tracks_page.dart';
import '../pages/import_menu.dart';
import '../pages/loading_page.dart';
import '../pages/playlists_page/playlists_page.dart';
import '../pages/settings_page.dart';
import '../widgets/fade_in_widget.dart';
import '../widgets/player_controls/player_controls.dart';
import 'app_controller.dart';
import 'caption_widget/caption_widget.dart';

class App extends StatefulWidget {
  const App({super.key});

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  var isLoaded = false;
  late final Future<void> future = loadConfiguration();

  AppController get controller => appController;

  @override
  void initState() {
    super.initState();
    controller.addListener(() => setState(() {}));
  }

  void onLoad() => setState(() => isLoaded = true);

  @override
  Widget build(BuildContext context) => isLoaded
      ? Scaffold(
          body: FadeInWidget(
            duration: Durations.extralong4,
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

  Widget buildPage() => switch (controller.currentPage) {
    .allTracks => const AllTracksPage(),
    .playlists => const PlaylistsPage(),
    .settings => const SettingsPage(),
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
        selectedIndex: controller.currentPage.index >= 2
            ? controller.currentPage.index - 2
            : null,
        destinations: const [
          NavigationRailDestination(
            icon: Icon(Icons.settings_rounded),
            label: Text('Настройки'),
          ),
        ],
        leadingAtTop: false,
        leading: IconButton(
          hoverColor: Theme.of(context).colorScheme.primary.withAlpha(10),
          splashColor: Theme.of(context).colorScheme.primary.withAlpha(100),
          visualDensity: .compact,
          padding: const .symmetric(horizontal: 16),
          onPressed: () =>
              showDialog(context: context, builder: (_) => const ImportMenu()),
          icon: const Icon(Icons.add_to_photos_rounded),
        ),
        onDestinationSelected: (value) =>
            setState(() => controller.currentPage = AppPages.values[value + 2]),
      ),
    ),
    leading: Padding(
      padding: const .only(bottom: 12),
      child: Builder(
        builder: (context) => Image.asset(
          'assets/logo.png',
          width: 32,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    ),
    trailingAtBottom: true,
    selectedIndex: controller.currentPage.index < 2
        ? controller.currentPage.index
        : null,
    onDestinationSelected: (value) =>
        setState(() => controller.currentPage = AppPages.values[value]),
  );
}
