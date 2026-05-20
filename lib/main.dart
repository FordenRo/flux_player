import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_window_close/flutter_window_close.dart';
import 'package:media_kit/media_kit.dart' show MediaKit;
import 'package:window_manager/window_manager.dart';

import 'app/app.dart';
import 'core/audio_player/audio_player_impl.dart';
import 'core/services/config_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  MediaKit.ensureInitialized();
  await windowManager.ensureInitialized();

  const windowOptions = WindowOptions(
    size: Size(720, 480),
    title: 'Flux Music Player',
    titleBarStyle: .hidden,
  );
  await windowManager.waitUntilReadyToShow(windowOptions, windowManager.show);

  await FlutterWindowClose.setWindowShouldCloseHandler(() async {
    await saveConfiguration();
    return true;
  });

  await AudioService.init(
    builder: AudioHandlerImpl.new,
    config: const .new(
      androidNotificationChannelId: 'com.flux.notification.audio',
      androidNotificationChannelName: 'FluxPlayer',
      androidShowNotificationBadge: true,
    ),
  );

  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) =>
      const MaterialApp(title: 'Flux', home: App());
}
