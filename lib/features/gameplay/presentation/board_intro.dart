import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/widgets/blocks.dart';

class BoardIntro extends StatelessWidget {
  const BoardIntro({super.key, required this.onEnd});
  final VoidCallback onEnd;
  @override
  Widget build(BuildContext context) => IgnorePointer(
    child: TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: MediaQuery.disableAnimationsOf(context)
          ? Duration.zero
          : const Duration(milliseconds: 850),
      onEnd: onEnd,
      builder: (_, t, child) => Stack(
        alignment: Alignment.center,
        children: [
          Positioned.fill(child: CustomPaint(painter: _OpeningBlocks(t))),
          Opacity(
            opacity: math.sin(math.pi * t).clamp(0, 1),
            child: Transform.scale(
              scale: .75 + math.sin(math.pi * t) * .35,
              child: const Text(
                'Yerleştir!',
                style: TextStyle(
                  fontSize: 44,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  shadows: [
                    Shadow(
                      color: Color(0xff153965),
                      blurRadius: 12,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

class _OpeningBlocks extends CustomPainter {
  _OpeningBlocks(this.t);
  final double t;
  @override
  void paint(Canvas canvas, Size size) {
    final cell = size.width / 8;
    for (var row = 0; row < 8; row++) {
      for (var col = 0; col < 8; col++) {
        final delay = (row + col) * .012;
        final enter = ((t - delay) / .22).clamp(0.0, 1.0);
        final exit = ((t - .45 - delay) / .25).clamp(0.0, 1.0);
        final scale = Curves.easeOutBack.transform(enter) * (1 - exit);
        if (scale <= 0) continue;
        final center = Offset((col + .5) * cell, (row + .5) * cell);
        final rect = Rect.fromCenter(
          center: center,
          width: (cell - 3) * scale,
          height: (cell - 3) * scale,
        );
        final color = blockColors[1 + (row + col) % 5];
        canvas.drawRRect(
          RRect.fromRectAndRadius(rect, const Radius.circular(5)),
          Paint()
            ..shader = LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color.lerp(color, Colors.white, .4)!, color],
            ).createShader(rect),
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _OpeningBlocks oldDelegate) =>
      t != oldDelegate.t;
}
