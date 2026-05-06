import 'package:flutter/material.dart';
import 'package:flutter_window_close/flutter_window_close.dart';
import 'package:media_kit/media_kit.dart' show MediaKit;
import 'package:window_manager/window_manager.dart';

import 'config.dart';
import 'pages/main_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  MediaKit.ensureInitialized();
  await windowManager.ensureInitialized();

  final windowOptions = WindowOptions(
    size: Size(720, 480),
    title: 'Flux Music Player',
    titleBarStyle: .hidden,
  );
  await windowManager.waitUntilReadyToShow(windowOptions, windowManager.show);

  await FlutterWindowClose.setWindowShouldCloseHandler(() async {
    await saveConfiguration();
    return true;
  });

  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Flux',
    onGenerateTitle: (context) => 'Flux',
    color: Colors.red,
    theme: ThemeData(
      colorScheme: .fromSeed(seedColor: Colors.red.shade700, brightness: .dark),
    ),
    home: MainPage(),
  );
}
