import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';

import '../../core/widgets/game_ui.dart';

Future<void> showRewardCelebration(
  BuildContext context,
  int amount,
  bool english,
) => showGeneralDialog<void>(
  context: context,
  barrierDismissible: false,
  barrierColor: const Color(0xaa091a35),
  transitionDuration: const Duration(milliseconds: 350),
  transitionBuilder: (_, animation, secondary, child) =>
      FadeTransition(opacity: animation, child: child),
  pageBuilder: (dialog, _, secondary) => RewardCelebration(
    amount: amount,
    english: english,
    onClose: () => Navigator.pop(dialog),
  ),
);

class RewardCelebration extends StatelessWidget {
  const RewardCelebration({
    super.key,
    required this.amount,
    required this.english,
    required this.onClose,
  });
  final int amount;
  final bool english;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) => BackdropFilter(
    filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
    child: Material(
      type: MaterialType.transparency,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: MediaQuery.disableAnimationsOf(context)
            ? Duration.zero
            : const Duration(milliseconds: 2200),
        builder: (_, t, child) {
          final entrance = Curves.easeOutBack.transform((t * 3).clamp(0, 1));
          return Stack(
            alignment: Alignment.center,
            children: [
              Positioned.fill(
                child: IgnorePointer(
                  child: CustomPaint(painter: _CoinShower(t)),
                ),
              ),
              SafeArea(
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Transform.scale(
                      scale: .75 + entrance * .25,
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 340),
                        child: Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [Color(0xff2b4274), Color(0xff111d3c)],
                            ),
                            borderRadius: BorderRadius.circular(32),
                            border: Border.all(
                              color: const Color(0xffffd36b),
                              width: 2,
                            ),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x44ffc83e),
                                blurRadius: 44,
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                english ? 'DAILY GIFT' : 'GÜNÜN HEDİYESİ',
                                style: const TextStyle(
                                  color: Color(0xffffd777),
                                  fontSize: 12,
                                  letterSpacing: 3,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 22),
                              Container(
                                width: 96,
                                height: 96,
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: LinearGradient(
                                    colors: [
                                      Color(0xffffeea5),
                                      Color(0xffeaa329),
                                    ],
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Color(0x66ffc23b),
                                      blurRadius: 24,
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.card_giftcard_rounded,
                                  size: 58,
                                  color: Color(0xff815414),
                                ),
                              ),
                              const SizedBox(height: 18),
                              Text(
                                '+${(amount * Curves.easeOut.transform((t * 2).clamp(0, 1))).round()}',
                                style: const TextStyle(
                                  color: Color(0xffffdf80),
                                  fontSize: 60,
                                  fontWeight: FontWeight.w900,
                                  height: 1.1,
                                ),
                              ),
                              Text(
                                english ? 'coins are yours!' : 'altın senin!',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 23,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                english
                                    ? 'A little gift, a new adventure.\nSee you tomorrow!'
                                    : 'Küçük bir hediye, yeni bir macera.\nYarın yine bekleriz!',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: Color(0xffb9cbe5),
                                  fontSize: 14,
                                  height: 1.5,
                                ),
                              ),
                              const SizedBox(height: 24),
                              GlossButton(
                                label: english ? 'Wonderful!' : 'Harika!',
                                icon: Icons.check_rounded,
                                color: green,
                                height: 52,
                                onTap: onClose,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    ),
  );
}

class _CoinShower extends CustomPainter {
  _CoinShower(this.t);
  final double t;
  @override
  void paint(Canvas canvas, Size size) {
    for (var i = 0; i < 32; i++) {
      final progress = ((t - (i % 5) * .035) / .8).clamp(0.0, 1.0);
      final angle = i * 2.39996;
      final distance = progress * (120 + i % 7 * 28);
      final center = Offset(
        size.width / 2 + math.cos(angle) * distance,
        size.height / 2 -
            50 +
            math.sin(angle) * distance +
            progress * progress * 170,
      );
      final opacity = (math.sin(progress * math.pi) * .9).clamp(0.0, 1.0);
      final paint = Paint()
        ..color = const Color(0xffffd66b).withValues(alpha: opacity);
      canvas.drawCircle(center, 5 + i % 4.toDouble(), paint);
      canvas.drawCircle(
        center,
        3 + i % 4.toDouble(),
        Paint()
          ..color = Colors.white.withValues(alpha: opacity * .6)
          ..style = PaintingStyle.stroke,
      );
    }
  }

  @override
  bool shouldRepaint(_CoinShower oldDelegate) => oldDelegate.t != t;
}
