import 'dart:math';

import 'package:flutter/material.dart';

class ShakeFeedback extends StatefulWidget {
  const ShakeFeedback({super.key, required this.trigger, required this.child});
  final int trigger;
  final Widget child;
  @override
  State<ShakeFeedback> createState() => _ShakeFeedbackState();
}

class _ShakeFeedbackState extends State<ShakeFeedback>
    with SingleTickerProviderStateMixin {
  late final controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 320),
  );
  @override
  void didUpdateWidget(ShakeFeedback oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.trigger != widget.trigger &&
        !MediaQuery.disableAnimationsOf(context)) {
      controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: controller,
    child: widget.child,
    builder: (_, child) => Transform.translate(
      offset: Offset(
        sin(controller.value * pi * 6) * (1 - controller.value) * 5,
        0,
      ),
      child: child,
    ),
  );
}
