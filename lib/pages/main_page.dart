import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

import '../config.dart';
import '../widgets/import_menu.dart';
import '../widgets/player.dart';
import 'loading_page.dart';
import 'playlists_page.dart';
import 'search_page.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage>
    with SingleTickerProviderStateMixin {
  late final animation = AnimationController(
    duration: const Duration(seconds: 1),
    vsync: this,
  );
  var pageIndex = 1;
  var isLoaded = false;

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
                          CaptionWidget(title: 'Flux Music Player'),

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
        : LoadingPage(future: loadConfiguration(), onLoad: onLoad),
  );

  Widget buildPage() => switch (pageIndex) {
    0 => AllTracksPage(),
    1 => PlaylistsPage(),
    _ => PlaylistsPage(),
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

class CaptionWidget extends StatefulWidget {
  final String title;

  const CaptionWidget({super.key, required this.title});

  @override
  State<CaptionWidget> createState() => _CaptionWidgetState();
}

class _CaptionWidgetState extends State<CaptionWidget> {
  List<Widget Function(BuildContext)> captionButtons = [];

  @override
  void initState() {
    super.initState();
    captionController._onButtonAdd = (builder, controller) {
      setState(() => captionButtons.add(builder));
      controller._onRemove = () {
        controller._onRemove = null;
        Future.microtask(() => setState(() => captionButtons.remove(builder)));
      };
    };
  }

  @override
  Widget build(BuildContext context) => IconButtonTheme(
    data: .new(
      style: .new(
        padding: .all(.zero),
        shape: .all(RoundedRectangleBorder(borderRadius: .circular(6))),
      ),
    ),
    child: SizedBox(
      height: 28,
      child: Padding(
        padding: const .symmetric(horizontal: 10, vertical: 2),
        child: Row(
          children: [
            AnimatedSize(
              duration: Durations.medium1,
              curve: Curves.easeOutCubic,
              child: Row(
                children: captionButtons.map((e) => e(context)).toList(),
              ),
            ),
            Expanded(
              child: DragToMoveArea(
                child: Text(widget.title, textAlign: .center),
              ),
            ),
            IconButton(
              onPressed: windowManager.minimize,
              icon: const Icon(Icons.minimize_rounded),
            ),
            IconButton(
              hoverColor: Colors.red.shade600.withAlpha(200),
              onPressed: windowManager.close,
              icon: const Icon(Icons.close_rounded),
            ),
          ],
        ),
      ),
    ),
  );
}

final captionController = CaptionController._internal();

class CaptionButtonController {
  void Function()? _onRemove;

  CaptionButtonController();

  void remove() => _onRemove!();

  void dispose() => _onRemove?.call();
}

class CaptionController {
  void Function(
    Widget Function(BuildContext context) builder,
    CaptionButtonController controller,
  )?
  _onButtonAdd;

  CaptionController._internal();

  void addIconButton({
    required IconButton Function(BuildContext context) builder,
    required CaptionButtonController controller,
  }) => _onButtonAdd!(builder, controller);
}
