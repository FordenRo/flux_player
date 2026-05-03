import 'package:flutter/material.dart';

class LoadingPage extends StatefulWidget {
  final Future future;
  final void Function() onLoad;

  const LoadingPage({super.key, required this.future, required this.onLoad});

  @override
  State<LoadingPage> createState() => _LoadingPageState();
}

class _LoadingPageState extends State<LoadingPage>
    with SingleTickerProviderStateMixin {
  late final controller = AnimationController(
    duration: const Duration(milliseconds: 500),
    vsync: this,
  );
  late final fadeAnimation = Tween<double>(
    begin: 0,
    end: 1,
  ).animate(CurvedAnimation(parent: controller, curve: Curves.easeInOut));
  late final scaleAnimation = Tween<double>(begin: 0.8, end: 1).animate(
    CurvedAnimation(parent: controller, curve: Curves.fastEaseInToSlowEaseOut),
  );

  @override
  void initState() {
    super.initState();

    start();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  void start() async {
    await controller.forward();
    await widget.future;
    await controller.animateBack(0);
    widget.onLoad();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Center(
      child: ScaleTransition(
        scale: scaleAnimation,
        child: FadeTransition(
          opacity: fadeAnimation,
          child: Image.asset('assets/logo.png', width: 180),
        ),
      ),
    ),
  );
}
