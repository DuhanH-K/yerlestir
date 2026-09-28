import 'dart:math' as math;

import 'package:flutter/material.dart';

const clearFeedbackDuration = Duration(milliseconds: 1450);
const placementFeedbackDuration = Duration(milliseconds: 700);

/// Floating lettering never places an opaque surface over playable cells.
class ScoreCelebration extends StatelessWidget {
  const ScoreCelebration({
    super.key,
    required this.clock,
    required this.points,
    required this.combo,
    required this.lines,
    required this.placementPoints,
    required this.linePoints,
    required this.english,
    this.reducedMotion = false,
  });
  final Animation<double> clock;
  final int points, combo, lines, placementPoints, linePoints;
  final bool english, reducedMotion;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, bounds) {
      final hasCombo = combo >= 2;
      return AnimatedBuilder(
        animation: clock,
        child: Semantics(
          label:
              '+$points ${english ? "points" : "puan"}'
              '${hasCombo ? ", combo $combo" : ""}',
          child: SizedBox(
            key: const ValueKey('compact-clear-label'),
            width: math.min(180, bounds.maxWidth * .52),
            height: hasCombo ? 66 : 34,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (hasCombo)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        _OutlinedText(
                          english ? 'Combo ' : 'Kombo ',
                          size: 26,
                          italic: true,
                        ),
                        _OutlinedText(
                          '×$combo',
                          size: 36,
                          color: const Color(0xffffdc54),
                          italic: true,
                        ),
                      ],
                    ),
                  _OutlinedText(
                    '+$points',
                    size: hasCombo ? 19 : 25,
                    color: hasCombo ? const Color(0xfffff2b4) : Colors.white,
                  ),
                ],
              ),
            ),
          ),
        ),
        builder: (_, child) {
          final ms = clock.value * clearFeedbackDuration.inMilliseconds;
          if (ms < 360 || ms >= 1360) return const SizedBox.shrink();
          final enter = ((ms - 360) / 170).clamp(0.0, 1.0);
          final exit = ((ms - 1020) / 340).clamp(0.0, 1.0);
          return Align(
            alignment: Alignment(0, hasCombo ? .12 : -.35),
            child: Opacity(
              opacity: enter * (1 - exit),
              child: Transform.translate(
                offset: Offset(
                  0,
                  reducedMotion ? 0 : 8 * (1 - enter) - 20 * exit,
                ),
                child: Transform.rotate(
                  angle: reducedMotion ? 0 : -.055 * math.sin(enter * math.pi),
                  child: Transform.scale(
                    scale: reducedMotion
                        ? 1
                        : .8 + .2 * Curves.easeOutBack.transform(enter),
                    child: child,
                  ),
                ),
              ),
            ),
          );
        },
      );
    },
  );
}

class _OutlinedText extends StatelessWidget {
  const _OutlinedText(
    this.text, {
    required this.size,
    this.color = Colors.white,
    this.italic = false,
  });
  final String text;
  final double size;
  final Color color;
  final bool italic;
  @override
  Widget build(BuildContext context) {
    final style = TextStyle(
      fontSize: size,
      height: 1.1,
      fontWeight: FontWeight.w900,
      fontStyle: italic ? FontStyle.italic : FontStyle.normal,
    );
    return Stack(
      children: [
        ExcludeSemantics(
          child: Text(
            text,
            style: style.copyWith(
              foreground: Paint()
                ..style = PaintingStyle.stroke
                ..strokeWidth = 3.5
                ..color = const Color(0xff16243d),
            ),
          ),
        ),
        Text(
          text,
          style: style.copyWith(
            color: color,
            shadows: const [
              Shadow(
                color: Color(0x99071121),
                offset: Offset(0, 2),
                blurRadius: 3,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class PlacementScore extends StatelessWidget {
  const PlacementScore({super.key, required this.points, required this.onEnd});
  final int points;
  final VoidCallback onEnd;
  @override
  Widget build(BuildContext context) => IgnorePointer(
    child: TweenAnimationBuilder<double>(
      duration: placementFeedbackDuration,
      tween: Tween(begin: 0, end: 1),
      onEnd: onEnd,
      child: _OutlinedText('+$points', size: 21),
      builder: (_, t, child) {
        final enter = (t / .17).clamp(0.0, 1.0);
        final exit = ((t - .6) / .4).clamp(0.0, 1.0);
        final reduced = MediaQuery.disableAnimationsOf(context);
        return Align(
          alignment: const Alignment(0, -.9),
          child: Opacity(
            opacity: enter * (1 - exit),
            child: Transform.translate(
              offset: Offset(0, reduced ? 0 : -18 * t),
              child: Transform.scale(
                scale: reduced
                    ? 1
                    : .85 + .15 * Curves.easeOutBack.transform(enter),
                child: child,
              ),
            ),
          ),
        );
      },
    ),
  );
}

/// Keeps the most recent score legible even after the animated popup leaves.
class LastMoveReceipt extends StatelessWidget {
  const LastMoveReceipt({
    super.key,
    required this.points,
    required this.combo,
    required this.cleared,
    required this.english,
  });
  final int points, combo;
  final bool cleared, english;
  @override
  Widget build(BuildContext context) => FittedBox(
    fit: BoxFit.scaleDown,
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          cleared
              ? Icons.auto_awesome_rounded
              : Icons.add_circle_outline_rounded,
          color: const Color(0xff80eaff),
          size: 14,
        ),
        const SizedBox(width: 6),
        Text(
          '${english ? "LAST MOVE" : "SON HAMLE"}  +$points',
          style: const TextStyle(
            color: Color(0xffd2e6ff),
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: .6,
          ),
        ),
        if (cleared && combo >= 2) ...[
          const SizedBox(width: 10),
          Text(
            '${english ? "COMBO" : "KOMBO"} ×$combo',
            style: const TextStyle(
              color: Color(0xffffdb78),
              fontWeight: FontWeight.w900,
              fontSize: 11,
            ),
          ),
        ],
      ],
    ),
  );
}
