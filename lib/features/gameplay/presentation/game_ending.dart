import 'dart:math' as math;

import 'package:flutter/material.dart';

const gameEndingDuration = Duration(milliseconds: 1600);

class GameEnding extends StatelessWidget {
  const GameEnding({
    super.key,
    required this.won,
    required this.title,
    required this.subtitle,
  });

  final bool won;
  final String title, subtitle;

  @override
  Widget build(BuildContext context) => Positioned.fill(
    child: AbsorbPointer(
      child: Material(
        type: MaterialType.transparency,
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: 1),
          duration: MediaQuery.disableAnimationsOf(context)
              ? Duration.zero
              : gameEndingDuration,
          builder: (context, t, _) {
            final entrance = Curves.easeOutCubic.transform((t * 3).clamp(0, 1));
            final accent = won
                ? const Color(0xffffd45a)
                : const Color(0xffa8daff);
            return ColoredBox(
              color: Color.fromRGBO(10, 24, 52, .85 * entrance),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  for (var i = 0; i < 12; i++)
                    Transform.translate(
                      offset: Offset(
                        math.cos(i * math.pi / 6) * (55 + t * 100),
                        math.sin(i * math.pi / 6) * (55 + t * 100),
                      ),
                      child: Opacity(
                        opacity: (math.sin(math.pi * t) * .8).clamp(0, 1),
                        child: Transform.rotate(
                          angle: t * 2 + i.toDouble(),
                          child: Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: accent,
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                        ),
                      ),
                    ),
                  Opacity(
                    opacity: entrance,
                    child: Transform.scale(
                      scale: .7 + .3 * entrance,
                      child: Padding(
                        padding: const EdgeInsets.all(28),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              won
                                  ? Icons.emoji_events_rounded
                                  : Icons.extension_rounded,
                              size: 76,
                              color: accent,
                            ),
                            const SizedBox(height: 20),
                            Text(
                              title,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 30,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              subtitle,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Color(0xffd2e6ff),
                                fontSize: 17,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    ),
  );
}
