import 'package:flutter/material.dart';

class FadeInWidget extends StatefulWidget {
  const FadeInWidget({required this.duration, required this.child, super.key});

  final Duration duration;
  final Widget child;

  @override
  State<FadeInWidget> createState() => _FadeInWidgetState();
}

class _FadeInWidgetState extends State<FadeInWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController animation = .new(
    vsync: this,
    duration: widget.duration,
  );

  @override
  void initState() {
    super.initState();
    animation.forward();
  }

  @override
  void dispose() {
    animation.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      FadeTransition(opacity: animation, child: widget.child);
}
