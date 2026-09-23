import 'dart:math';

import 'package:flutter/material.dart';

import '../../../core/widgets/blocks.dart';

const lineBurstDuration = Duration(milliseconds: 600);

class LineBurst extends StatelessWidget {
  const LineBurst({
    super.key,
    required this.cells,
    required this.points,
    this.message = '',
    this.detail = '',
  });
  final Map<int, int> cells;
  final int points;
  final String message, detail;
  @override
  Widget build(BuildContext context) => IgnorePointer(
    child: TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: lineBurstDuration,
      builder: (_, progress, child) => Stack(
        fit: StackFit.expand,
        children: [
          CustomPaint(painter: _BurstPainter(cells, progress)),
          Align(
            alignment: Alignment(0, -.15 - progress * .5),
            child: Opacity(
              opacity: sin(pi * progress).clamp(0, 1),
              child: Transform.scale(
                scale: 1 + sin(pi * progress) * .2,
                child: Text(
                  textAlign: TextAlign.center,
                  message.isEmpty ? '+$points' : '$message\n$detail',
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    shadows: [
                      Shadow(
                        color: Color(0xff075da0),
                        blurRadius: 8,
                        offset: Offset(0, 3),
                      ),
                      Shadow(color: Colors.amber, blurRadius: 20),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

class _BurstPainter extends CustomPainter {
  _BurstPainter(this.cells, this.progress);
  final Map<int, int> cells;
  final double progress;
  @override
  void paint(Canvas canvas, Size size) {
    final cell = size.width / 8;
    var rank = 0;
    final step = min(28.0, 300 / max(1, cells.length - 1));
    for (final entry in cells.entries) {
      final row = entry.key ~/ 8, col = entry.key % 8;
      final center = Offset((col + .5) * cell, (row + .5) * cell);
      final elapsed = progress * 600 - rank++ * step;
      final t = (elapsed / 280).clamp(0.0, 1.0);
      final color = blockColors[entry.value];
      if (t < 80 / 280) {
        final flash = sin(pi * (t / (80 / 280)));
        final rect = Rect.fromCenter(
          center: center,
          width: (cell - 3) * (1 + flash * .2),
          height: (cell - 3) * (1 + flash * .2),
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(rect, Radius.circular(7 + flash * 5)),
          Paint()..color = Color.lerp(color, Colors.white, flash * .95)!,
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(rect.inflate(2), const Radius.circular(8)),
          Paint()
            ..color = Colors.white.withValues(alpha: flash * .8)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2,
        );
      } else if (t < 1) {
        final burst = (t - 80 / 280) / (200 / 280);
        for (var i = 0; i < 8; i++) {
          final angle = i * pi / 4 + entry.key * .35;
          final distance = cell * (.15 + burst * 1.4);
          final point =
              center +
              Offset(
                cos(angle) * distance,
                sin(angle) * distance + burst * burst * cell * .6,
              );
          final radius = cell * .105 * (1 - burst);
          canvas.save();
          canvas.translate(point.dx, point.dy);
          canvas.rotate(angle + burst * 4);
          canvas.drawRRect(
            RRect.fromRectAndRadius(
              Rect.fromCenter(
                center: Offset.zero,
                width: radius * 2,
                height: radius * 2,
              ),
              const Radius.circular(2),
            ),
            Paint()
              ..color = (i.isEven ? color : Colors.white).withValues(
                alpha: 1 - burst,
              ),
          );
          canvas.restore();
        }
        canvas.drawCircle(
          center,
          cell * burst * .8,
          Paint()
            ..color = Colors.white.withValues(alpha: (1 - burst) * .65)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2 * (1 - burst),
        );
      }
    }
  }

  @override
  bool shouldRepaint(_BurstPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.cells != cells;
}
