import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../core/widgets/game_ui.dart';

enum PauseAction { resume, home, finish }

Future<PauseAction?> showPauseDialog(
  BuildContext context, {
  required bool english,
  required bool saved,
  required String mode,
  required int score,
}) => showGeneralDialog<PauseAction>(
  context: context,
  barrierDismissible: true,
  barrierLabel: english ? 'Resume' : 'Devam et',
  barrierColor: const Color(0x8805233b),
  transitionDuration: MediaQuery.disableAnimationsOf(context)
      ? Duration.zero
      : const Duration(milliseconds: 480),
  transitionBuilder: (_, animation, secondary, child) => FadeTransition(
    opacity: animation,
    child: ScaleTransition(
      scale: Tween(
        begin: .82,
        end: 1.0,
      ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutBack)),
      child: child,
    ),
  ),
  pageBuilder: (dialog, animation, secondary) => BackdropFilter(
    filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
    child: Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 25, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 360),
        child: SingleChildScrollView(
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xff263e70), Color(0xff101e3b)],
              ),
              borderRadius: BorderRadius.circular(32),
              border: Border.all(color: const Color(0xff6a88b6)),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x7707132d),
                  blurRadius: 40,
                  offset: Offset(0, 18),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: 1),
                  duration: MediaQuery.disableAnimationsOf(dialog)
                      ? Duration.zero
                      : const Duration(milliseconds: 1600),
                  builder: (_, t, child) => SizedBox(
                    height: 106,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        for (var i = 0; i < 4; i++)
                          Transform.translate(
                            offset: Offset(
                              (i.isEven ? -1 : 1) * (66 + 8 * t),
                              (i < 2 ? -1 : 1) * (22 + 8 * t),
                            ),
                            child: Transform.rotate(
                              angle: (i.isEven ? -1 : 1) * (.15 + .3 * t),
                              child: Container(
                                width: 19,
                                height: 19,
                                decoration: BoxDecoration(
                                  color: [
                                    blue,
                                    purple,
                                    green,
                                    coral,
                                  ][i].withValues(alpha: .7),
                                  borderRadius: BorderRadius.circular(5),
                                  border: Border.all(color: Colors.white30),
                                ),
                              ),
                            ),
                          ),
                        Transform.scale(
                          scale: .8 + .2 * Curves.easeOutBack.transform(t),
                          child: Container(
                            width: 86,
                            height: 86,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xffffeaa1), Color(0xffeda928)],
                              ),
                              borderRadius: BorderRadius.circular(28),
                              boxShadow: const [
                                BoxShadow(
                                  color: Color(0x44ffce54),
                                  blurRadius: 24,
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.pause_rounded,
                              size: 52,
                              color: Color(0xff62451b),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  english ? 'Paused' : 'Oyun Duraklatıldı',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '$mode  •  ${english ? 'Score' : 'Skor'} ${number(score)}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: Color(0xffffd979),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  saved
                      ? (english
                            ? 'Your progress is safe. Continue whenever you’re ready.'
                            : 'İlerlemen kaydedildi. Hazır olduğunda kaldığın yerden devam et.')
                      : (english
                            ? 'Could not save to this device. Please check storage.'
                            : 'Cihaza kayıt yapılamadı. Depolama alanını kontrol et.'),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 13,
                    height: 1.5,
                    color: Color(0xffb6c9e5),
                  ),
                ),
                const SizedBox(height: 22),
                GlossButton(
                  label: english ? 'Continue' : 'Devam Et',
                  icon: Icons.play_arrow_rounded,
                  color: green,
                  onTap: () => Navigator.pop(dialog, PauseAction.resume),
                ),
                const SizedBox(height: 14),
                GlossButton(
                  label: english ? 'Save & Home' : 'Kaydet ve Ana Sayfa',
                  icon: Icons.home_rounded,
                  color: blue,
                  onTap: () => Navigator.pop(dialog, PauseAction.home),
                ),
                const SizedBox(height: 10),
                TextButton(
                  onPressed: () async {
                    final confirmed = await showDialog<bool>(
                      context: dialog,
                      builder: (d) => AlertDialog(
                        title: Text(
                          english ? 'End this run?' : 'Bu tur bitsin mi?',
                        ),
                        content: Text(
                          english
                              ? 'This run will end. You can start a new one afterwards.'
                              : 'Bu tur sona erecek. Ardından yeni bir oyun başlatabilirsin.',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(d, false),
                            child: Text(english ? 'Cancel' : 'Vazgeç'),
                          ),
                          FilledButton(
                            onPressed: () => Navigator.pop(d, true),
                            child: Text(english ? 'End Run' : 'Turu Bitir'),
                          ),
                        ],
                      ),
                    );
                    if (confirmed == true && dialog.mounted) {
                      Navigator.pop(dialog, PauseAction.finish);
                    }
                  },
                  child: Text(
                    english ? 'End Run' : 'Turu Bitir',
                    style: const TextStyle(color: Color(0xffb6c9e5)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  ),
);
