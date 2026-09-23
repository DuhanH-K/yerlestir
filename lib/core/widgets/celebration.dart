import 'dart:math';

import 'package:flutter/material.dart';

/// A finite animation. Particle positions are derived from their index, so no
/// random generator is created during a frame or widget build.
class Celebration extends StatefulWidget {
  const Celebration({super.key, required this.child, required this.enabled});
  final Widget child;
  final bool enabled;
  @override
  State<Celebration> createState() => _CelebrationState();
}

class _CelebrationState extends State<Celebration>
    with SingleTickerProviderStateMixin {
  late final AnimationController controller;
  @override
  void initState() {
    super.initState();
    controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    );
    if (widget.enabled) {
      controller.forward();
    }
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Stack(
    children: [
      widget.child,
      if (widget.enabled)
        Positioned.fill(
          child: IgnorePointer(
            child: AnimatedBuilder(
              animation: controller,
              builder: (_, child) =>
                  CustomPaint(painter: _ConfettiPainter(controller.value)),
            ),
          ),
        ),
    ],
  );
}

class _ConfettiPainter extends CustomPainter {
  _ConfettiPainter(this.progress);
  final double progress;
  static const colors = [
    Color(0xffffce32),
    Color(0xff0da8f5),
    Color(0xffff645d),
    Color(0xff1bd177),
    Color(0xffa467ed),
  ];
  @override
  void paint(Canvas canvas, Size size) {
    if (progress >= 1) {
      return;
    }
    for (var i = 0; i < 48; i++) {
      final x =
          ((i * 73) % 101) / 101 * size.width + sin(progress * 8 + i) * 20;
      final y = (progress * 1.4 - ((i * 17) % 31) / 65) * size.height;
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(progress * 8 + i.toDouble());
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(-4, -7, 8, 14),
          const Radius.circular(2),
        ),
        Paint()
          ..color = colors[i % 5].withValues(alpha: (1 - progress).clamp(0, 1)),
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
