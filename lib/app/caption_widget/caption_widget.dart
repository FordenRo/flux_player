import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

part 'caption_controller.dart';

class CaptionWidget extends StatefulWidget {
  const CaptionWidget({required this.title, super.key});
  final String title;

  @override
  State<CaptionWidget> createState() => _CaptionWidgetState();
}

class _CaptionWidgetState extends State<CaptionWidget> {
  List<Widget Function(BuildContext)> captionWidgets = [];

  @override
  void initState() {
    super.initState();
    captionController._onWidgetAdd = (builder, controller) {
      setState(() => captionWidgets.add(builder));
      controller._onRemove = () {
        controller._onRemove = null;
        Future.microtask(() => setState(() => captionWidgets.remove(builder)));
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
                children: captionWidgets.map((e) => e(context)).toList(),
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
