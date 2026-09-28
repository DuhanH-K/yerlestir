import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/widgets/game_ui.dart';

class LiveScore extends StatefulWidget {
  const LiveScore({
    super.key,
    required this.score,
    required this.best,
    required this.compact,
    required this.english,
  });
  final int score, best;
  final bool compact, english;
  @override
  State<LiveScore> createState() => _LiveScoreState();
}

class _LiveScoreState extends State<LiveScore>
    with SingleTickerProviderStateMixin {
  late final AnimationController pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 850),
  );
  int previous = 0;
  bool record = false;
  @override
  void initState() {
    super.initState();
    previous = widget.score;
  }

  @override
  void didUpdateWidget(covariant LiveScore oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.score != oldWidget.score) {
      previous = oldWidget.score;
      record =
          widget.best > 0 &&
          oldWidget.score <= widget.best &&
          widget.score > widget.best;
      if (!MediaQuery.disableAnimationsOf(context)) pulse.forward(from: 0);
    }
  }

  @override
  void dispose() {
    pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => RepaintBoundary(
    child: AnimatedBuilder(
      animation: pulse,
      builder: (_, child) {
        final t = pulse.value;
        final glow = pulse.isAnimating ? math.sin(t * math.pi) : 0.0;
        final color = record
            ? const Color(0xffffd45a)
            : const Color(0xff45ddff);
        return Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            if (glow > 0)
              Transform.rotate(
                angle: math.pi / 4,
                child: Container(
                  width: 58 + t * 24,
                  height: 58 + t * 24,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: color.withValues(alpha: glow * .14),
                    boxShadow: [
                      BoxShadow(
                        color: color.withValues(alpha: glow * .4),
                        blurRadius: 24,
                        spreadRadius: 4,
                      ),
                    ],
                  ),
                ),
              ),
            TweenAnimationBuilder<double>(
              tween: Tween(
                begin: previous.toDouble(),
                end: widget.score.toDouble(),
              ),
              duration: const Duration(milliseconds: 480),
              builder: (_, value, child) => Transform.scale(
                scale: 1 + glow * .07,
                child: FittedBox(
                  child: Text(
                    number(value.round()),
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: widget.compact ? 40 : 58,
                      fontWeight: FontWeight.w900,
                      shadows: const [
                        Shadow(
                          color: Colors.black26,
                          offset: Offset(0, 3),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            if (record && pulse.isAnimating)
              Positioned(
                top: -3,
                child: Opacity(
                  opacity: glow,
                  child: Text(
                    widget.english ? 'NEW BEST!' : 'YENİ REKOR!',
                    style: const TextStyle(
                      color: Color(0xffffdf73),
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    ),
  );
}
