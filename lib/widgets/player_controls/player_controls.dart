import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_show_menu/flutter_show_menu.dart';

import '../../core/audio_player/audio_player.dart';
import '../../core/models/track.dart';
import '../../core/services/config_service.dart';
import '../../core/theme/theme.dart';
import '../../pages/playlists_page/widgets/add_to_playlist_button.dart';
import 'widgets/position_slider.dart';
import 'widgets/queue_overlay.dart';
import 'widgets/volume_button/volume_button.dart';

class PlayerControls extends StatefulWidget {
  const PlayerControls({super.key});

  @override
  State<PlayerControls> createState() => _PlayerControlsState();
}

class _PlayerControlsState extends State<PlayerControls>
    with SingleTickerProviderStateMixin {
  late final StreamSubscription subscription;
  late final AnimationController playAnim = .new(
    vsync: this,
    duration: Durations.short2,
  );
  double nextBtnOffset = 0;
  double prevBtnOffset = 0;

  Track get track => audioPlayer.currentTrack!;

  @override
  void initState() {
    super.initState();
    subscription = audioPlayer.stream.isPlaying.listen(
      (_) => playAnim.animateTo(audioPlayer.isPlaying ? 1 : 0),
    );
  }

  @override
  void dispose() {
    playAnim.dispose();
    subscription.cancel();
    audioPlayer.dispose();
    super.dispose();
  }

  Widget _trackInfo(BuildContext context) => StreamBuilder(
    stream: audioPlayer.stream.currentTrack,
    builder: (context, asyncSnapshot) => Row(
      mainAxisSize: .min,
      spacing: 8,
      children: [
        Container(
          decoration: BoxDecoration(
            borderRadius: Radiuses.r6,
            border: .all(color: Colors.grey.shade600, width: 1, strokeAlign: 1),
          ),
          height: 40,
          width: 40,
          clipBehavior: .hardEdge,
          child: track.picture != null
              ? Image.memory(track.picture!.bytes)
              : Icon(Icons.music_note_rounded, color: Colors.grey.shade400),
        ),
        Flexible(
          child: Column(
            crossAxisAlignment: .start,
            children: [
              Text(
                track.title,
                overflow: .ellipsis,
                style: TextStyles.trackTitle,
              ),
              Text(
                track.author,
                overflow: .ellipsis,
                style: TextStyles.trackArtist,
              ),
            ],
          ),
        ),
        if (playlists.isNotEmpty)
          AddToPlaylistButton(
            track: track,
            iconBuilder: (context) => Icon(
              mainPlaylist?.contains(track) ??
                      playlists.where((e) => e.contains(track)).isNotEmpty
                  ? Icons.playlist_add_check_rounded
                  : Icons.playlist_add_rounded,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            countBuilder: (context, child) =>
                Transform.translate(offset: const .new(-14, 10), child: child),
          ),
      ],
    ),
  );

  Widget _controlButtons() => Row(
    mainAxisAlignment: .center,
    children: [
      /// Shuffle
      StreamBuilder(
        stream: audioPlayer.stream.isShuffled,
        builder: (context, asyncSnapshot) => IconButton(
          color: audioPlayer.isShuffled
              ? Theme.of(context).colorScheme.primary
              : null,
          onPressed: () => audioPlayer.setShuffled(!audioPlayer.isShuffled),
          icon: const Icon(Icons.shuffle_rounded),
        ),
      ),

      /// Previous
      StatefulBuilder(
        builder: (context, setState) => AnimatedSlide(
          offset: Offset(-prevBtnOffset / 10, 0),
          duration: Durations.short2,
          onEnd: () {
            if (prevBtnOffset != 0) setState(() => prevBtnOffset = 0);
          },
          child: IconButton(
            color: prevBtnOffset != 0
                ? Theme.of(context).colorScheme.primary
                : null,
            onPressed: () => setState(() {
              prevBtnOffset = 1;
              audioPlayer.previous();
            }),
            icon: const Icon(Icons.skip_previous_rounded),
          ),
        ),
      ),

      /// Play/Pause
      IconButton(
        onPressed: () =>
            audioPlayer.isPlaying ? audioPlayer.pause() : audioPlayer.play(),
        icon: AnimatedIcon(
          icon: AnimatedIcons.play_pause,
          progress: playAnim,
          // audioPlayer.isPlaying
          //     ? Icons.pause_circle_outline_rounded
          //     : Icons.play_circle_fill_rounded,
        ),
      ),

      /// Next
      StatefulBuilder(
        builder: (context, setState) => AnimatedSlide(
          offset: Offset(nextBtnOffset / 10, 0),
          duration: Durations.short2,
          onEnd: () {
            if (nextBtnOffset != 0) setState(() => nextBtnOffset = 0);
          },
          child: IconButton(
            color: nextBtnOffset != 0
                ? Theme.of(context).colorScheme.primary
                : null,
            onPressed: () => setState(() {
              nextBtnOffset = 1;
              audioPlayer.next();
            }),
            icon: const Icon(Icons.skip_next_rounded),
          ),
        ),
      ),

      /// Loop
      StreamBuilder(
        stream: audioPlayer.stream.isLooped,
        builder: (context, asyncSnapshot) => AnimatedRotation(
          duration: Durations.short3,
          turns: audioPlayer.isLooped ? -0.5 : 0,
          child: IconButton(
            color: audioPlayer.isLooped
                ? Theme.of(context).colorScheme.primary
                : null,
            onPressed: () => audioPlayer.setLooped(!audioPlayer.isLooped),
            icon: const Icon(Icons.loop_rounded),
          ),
        ),
      ),
    ],
  );

  Widget _inputDeviceButton() => Builder(
    builder: (context) => IconButton(
      onPressed: () async {
        final device = await showOverlayMenu(
          context: context,
          initialValue: audioPlayer.audioDevice,
          style: const .new(padding: .zero, itemStyle: .new(height: 30)),
          items: audioPlayer.audioDevices
              .map(
                (e) => OverlayMenuItem(
                  child: Padding(
                    padding: const .symmetric(horizontal: 8),
                    child: Text(e.description, style: const .new(fontSize: 12)),
                  ),
                  value: e,
                  enabled: e != audioPlayer.audioDevice,
                ),
              )
              .toList(),
        );
        if (device != null) await audioPlayer.setAudioDevice(device);
      },
      icon: const Icon(Icons.input_rounded),
    ),
  );

  @override
  Widget build(BuildContext context) => StreamBuilder(
    stream: audioPlayer.stream.currentIndex.map((e) => e != null).distinct(),
    initialData: audioPlayer.currentIndex != null,
    builder: (context, hasPlayback) {
      if (!hasPlayback.requireData) {
        return const SizedBox();
      }
      return StreamBuilder(
        stream: audioPlayer.stream.isPlaying,
        initialData: audioPlayer.isPlaying,
        builder: (context, isPlaying) => Card(
          clipBehavior: .hardEdge,
          shape: RoundedRectangleBorder(
            borderRadius: Radiuses.r12,
            side: BorderSide(
              color: isPlaying.requireData
                  ? Theme.of(context).colorScheme.primary.withAlpha(200)
                  : Theme.of(context).colorScheme.secondary.withAlpha(100),
            ),
          ),
          elevation: 2,
          child: Column(
            children: [
              Padding(
                padding: const .only(top: 8, right: 8, left: 8, bottom: 4),
                child: Row(
                  mainAxisAlignment: .center,
                  children: [
                    Expanded(child: _trackInfo(context)),
                    _controlButtons(),
                    Expanded(
                      child: Row(
                        mainAxisAlignment: .end,
                        children: [
                          IconButton(
                            onPressed: () => showDialog(
                              context: context,
                              builder: (context) => const QueueOverlay(),
                            ),
                            icon: const Icon(Icons.queue_music_rounded),
                          ),
                          _inputDeviceButton(),
                          const VolumeButton(),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const PositionSlider(),
            ],
          ),
        ),
      );
    },
  );
}
