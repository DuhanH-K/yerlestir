import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/widgets/game_ui.dart';
import '../../../core/widgets/skin_style.dart';
import '../../../core/services/feedback_service.dart';
import '../../../core/services/storage_status.dart';
import '../../progress/progress.dart';
import '../application/game_session.dart';
import '../domain/puzzle.dart';
import 'board_view.dart';
import 'result_screen.dart';
import 'pause_dialog.dart';
import 'line_burst.dart';
import 'live_score.dart';
import 'score_celebration.dart';
import 'board_intro.dart';
import 'game_ending.dart';
import 'continue_dialog.dart';
import '../../../core/services/ad_service.dart';
import '../../../core/widgets/ad_banner.dart';
import '../../../core/widgets/shake_feedback.dart';

import 'package:flutter/services.dart';

part 'game_layout.dart';

class GameScreen extends ConsumerStatefulWidget {
  const GameScreen({
    super.key,
    required this.mode,
    required this.level,
    this.fresh = false,
  });
  final GameMode mode;
  final int level;
  final bool fresh;
  @override
  ConsumerState<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends ConsumerState<GameScreen>
    with WidgetsBindingObserver {
  late GameSession game;
  int? selected;
  bool busy = false, paused = false, animating = false, purchasing = false;
  int rejections = 0;
  bool showGain = false, starting = false;
  Timer? scoreTimer, soundTimer, comboSoundTimer;
  int displayedScore = 0;
  Set<int> placedCells = {};
  final clearEffects = <_ClearEvent>[];
  String? hintNotice;
  (int, int, int)? hint;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    final saved = ref.read(progressProvider).sessions[widget.mode.name];
    final restored = saved is Map<String, dynamic> && !widget.fresh
        ? GameSession.restore(saved)
        : null;
    final seed = LevelFactory.dailySeed(DateTime.now());
    game =
        restored != null &&
            !restored.finished &&
            restored.level == widget.level &&
            (widget.mode != GameMode.daily || restored.seed == seed)
        ? restored
        : GameSession(
            mode: widget.mode,
            level: widget.level,
            seed: widget.mode == GameMode.daily ? seed : null,
          );
    starting = game.moves == 0 && game != restored;
    hint = game.paidHint;
    selected = hint?.$1;
    displayedScore = game.score;
  }

  @override
  void dispose() {
    scoreTimer?.cancel();
    soundTimer?.cancel();
    comboSoundTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) {
      ref.read(feedbackProvider).music(false);
      if (!busy && !game.finished) {
        ref.read(progressProvider.notifier).saveSession(game);
      }
    }
  }

  void updateUi(VoidCallback action) => setState(action);

  Future<void> persist() async {
    try {
      await ref.read(progressProvider.notifier).saveSession(game);
    } catch (_) {
      if (mounted) {
        toast(context, 'Kayıt yapılamadı. Cihaz depolamasını kontrol et.');
      }
    }
  }

  Future<void> finish() async {
    if (busy) {
      return;
    }
    setState(() => busy = true);
    final reducedMotion = MediaQuery.disableAnimationsOf(context);
    final reward = await ref.read(progressProvider.notifier).complete(game);
    await Future<void>.delayed(
      reducedMotion ? const Duration(milliseconds: 350) : gameEndingDuration,
    );

    if (!mounted) return;
    await ref.read(adProvider).showAtBreak(game.moves);

    if (mounted) {
      context.pushReplacement('/result', extra: GameResult(game, reward));
    }
  }

  Future<void> drop(int slot, int row, int col) async {
    if (busy || starting || animating || paused || purchasing) {
      return;
    }
    final shape = slot >= 0 && slot < game.pieces.length
        ? game.pieces[slot]
        : null;
    if (!game.drop(slot, row, col)) {
      setState(() => rejections++);
      if (ref.read(progressProvider).hapticsEnabled) {
        HapticFeedback.lightImpact();
      }
      return;
    }
    final feedback = ref.read(feedbackProvider),
        settings = ref.read(progressProvider);
    final cleared = game.lastClearedCells.isNotEmpty;
    feedback.tap(settings);
    soundTimer?.cancel();
    if (cleared) {
      final count = game.lastClearedCells.length, combo = game.combo;
      comboSoundTimer?.cancel();
      soundTimer = Timer(const Duration(milliseconds: 300), () {
        if (!mounted) return;
        feedback.popLine(settings, count);
      });
      if (combo >= 2) {
        // Keep the recording's clear -> celebration order, without overlapping
        // the loud attacks of both excerpts.
        comboSoundTimer = Timer(const Duration(milliseconds: 1080), () {
          if (mounted) feedback.celebrate(ref.read(progressProvider), combo);
        });
      }
    }
    setState(() {
      placedCells = {
        for (final c in shape!.cells) (row + c.row) * boardSize + col + c.col,
      };
      showGain = !cleared;
      if (cleared) {
        // One prominent card at a time. A new clear replaces the previous
        // presentation; ordinary placements do not truncate a clear's card.
        clearEffects
          ..clear()
          ..add(_ClearEvent(game));
      }
      selected = null;
      hint = null;
      hintNotice = null;
      animating = game.lastClearedCells.isNotEmpty;
    });
    final move = game.moves;
    scoreTimer?.cancel();
    scoreTimer = Timer(Duration(milliseconds: cleared ? 120 : 60), () {
      if (mounted && game.moves == move) {
        setState(() => displayedScore = game.score);
      }
    });
    // Saves already queue immutable snapshots; disk writes never hold input.
    unawaited(persist());
    if (animating) await Future<void>.delayed(lineBurstDuration);
    if (!mounted || game.moves != move) {
      return;
    }
    setState(() => animating = false);
    if (game.finished) {
      // Finish only after the short score lettering has left the board.
      await Future<void>.delayed(
        cleared
            ? clearFeedbackDuration - lineBurstDuration
            : placementFeedbackDuration,
      );
      if (!mounted) return;
      final ads = ref.read(adProvider);
      if (game.canContinue && ads.enabled) {
        setState(() => purchasing = true);
        final revive = await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (_) => ContinueDialog(
            ads: ads,
            english: ref.read(progressProvider).localeCode == 'en',
            classic: game.mode == GameMode.classic,
          ),
        );
        if (!mounted) return;
        setState(() => purchasing = false);
        if (revive == true && game.continueAfterReward()) {
          setState(() {
            hint = null;
            selected = null;
            starting = true;
          });
          await persist();
          return;
        }
      }
      await finish();
    }
  }

  Future<void> purchaseHint() async {
    if (busy || starting || animating || purchasing || hint != null) {
      return;
    }
    setState(() {
      purchasing = true;
      hintNotice = null;
    });
    final h = await ref.read(progressProvider.notifier).buyHint(game);
    if (!mounted) {
      return;
    }
    if (h == null &&
        !game.finished &&
        ref.read(progressProvider).coins < ProgressController.hintPrice) {
      setState(() => purchasing = false);
      final watch = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(tr(ref, 'İpucu için altın yetmiyor', 'Not enough coins')),
          content: Text(
            tr(
              ref,
              'Reklam izleyerek 30 altın kazan ve ipucunu hemen kullan.',
              'Watch a rewarded ad to earn 30 coins and use the hint now.',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(tr(ref, 'Vazgeç', 'Cancel')),
            ),
            FilledButton.icon(
              onPressed: () => Navigator.pop(context, true),
              icon: const Icon(Icons.ondemand_video_rounded),
              label: Text(tr(ref, 'Reklam izle', 'Watch ad')),
            ),
          ],
        ),
      );
      if (watch == true && mounted) {
        setState(() => purchasing = true);
        try {
          final earned = await ref.read(adProvider).showContinueReward();
          if (earned && mounted) {
            final rewardedHint = await ref
                .read(progressProvider.notifier)
                .claimHintFromReward(game);
            if (!mounted) return;
            if (rewardedHint != null) {
              setState(() {
                hint = rewardedHint;
                selected = rewardedHint.$1;
                hintNotice = tr(
                  ref,
                  'Reklam ödülüyle ipucu açıldı!',
                  'Hint unlocked from ad reward!',
                );
              });
              return;
            }
          }
          if (mounted) {
            setState(
              () => hintNotice = tr(
                ref,
                'Reklam ödülü alınamadı.',
                'Ad reward was not earned.',
              ),
            );
          }
        } finally {
          if (mounted) setState(() => purchasing = false);
        }
      }
      return;
    }
    setState(() {
      purchasing = false;
      hint = h;
      selected = h?.$1;
      if (h == null) {
        hintNotice = game.finished
            ? tr(
                ref,
                'Bu turda uygun hamle kalmadı.',
                'There are no valid moves left.',
              )
            : tr(
                ref,
                'İpucu için 30 altın gerekiyor.',
                'A hint costs 30 coins.',
              );
      }
    });
  }

  Future<void> pause() async {
    if (paused || busy || animating || purchasing) {
      return;
    }
    paused = true;
    await persist();
    if (!mounted) {
      return;
    }
    final action = await showPauseDialog(
      context,
      english: ref.read(progressProvider).localeCode == 'en',
      saved: ref.read(storageStatusProvider),
      score: game.score,
      mode: switch (game.mode) {
        GameMode.classic => tr(ref, 'Klasik', 'Classic'),
        GameMode.journey => tr(
          ref,
          'Yolculuk • Bölüm ${game.level}',
          'Journey • Level ${game.level}',
        ),
        GameMode.daily => tr(ref, 'Günlük Bulmaca', 'Daily Puzzle'),
      },
    );
    paused = false;
    if (!mounted) {
      return;
    }
    if (action == PauseAction.home) {
      context.go('/');
    }
    if (action == PauseAction.finish) {
      await finish();
    }
  }

  @override
  Widget build(BuildContext context) => Stack(
    children: [
      buildGame(context),
      if (busy)
        GameEnding(
          won: game.won,
          title: game.won
              ? tr(ref, 'Bölüm tamamlandı!', 'Level complete!')
              : tr(ref, 'Tur tamamlandı', 'Round complete'),
          subtitle: game.won
              ? tr(ref, 'Harika iş çıkardın!', 'Well played!')
              : game.stalled
              ? tr(ref, 'Yerleştirilecek alan kalmadı', 'No placements left')
              : game.moves >= game.moveLimit && game.mode != GameMode.classic
              ? tr(ref, 'Hamlelerin tamamlandı', 'All moves used')
              : tr(ref, 'Skorun hazır', 'Your score is ready'),
        ),
    ],
  );
}

class _ClearEvent {
  _ClearEvent(GameSession game)
    : id = game.moves,
      cells = Map.unmodifiable(game.lastClearedCells),
      points = game.lastScoreGain,
      combo = game.combo,
      placementPoints = game.lastPlacementPoints,
      linePoints = game.lastLinePoints;
  final int id, points, combo, placementPoints, linePoints;
  final Map<int, int> cells;
}
