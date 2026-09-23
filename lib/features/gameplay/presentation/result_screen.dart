import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/widgets/game_ui.dart';
import '../../../core/widgets/celebration.dart';
import '../../progress/progress.dart';
import '../application/game_session.dart';
import '../domain/puzzle.dart';

class GameResult {
  GameResult(this.game, this.reward);
  final GameSession game;
  final int reward;
}

class ResultScreen extends ConsumerWidget {
  const ResultScreen({super.key, required this.result});
  final GameResult? result;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final r = result;
    if (r == null) {
      return GameShell(
        child: Center(
          child: GlossButton(label: 'Ana Sayfa', onTap: () => context.go('/')),
        ),
      );
    }
    final game = r.game;
    return GameShell(
      back: false,
      child: Celebration(
        enabled: game.won,
        child: FitPage(
          padding: const EdgeInsets.all(10),
          children: [
            const SizedBox(height: 4),
            GameTitle(
              game.won
                  ? tr(ref, 'Bölüm Tamamlandı!', 'Level Complete!')
                  : tr(ref, 'Güzel Oynadın!', 'Well Played!'),
              size: 32,
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                3,
                (i) => Icon(
                  i < game.stars
                      ? Icons.star_rounded
                      : Icons.star_outline_rounded,
                  color: const Color(0xffffd135),
                  size: i == 1 ? 56 : 48,
                  shadows: const [
                    Shadow(
                      color: Color(0xffc4731c),
                      offset: Offset(0, 4),
                      blurRadius: 3,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            CreamPanel(
              child: Column(
                children: [
                  Text(
                    '${tr(ref, 'Skor', 'Score')}  ${number(game.score)}',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: const Color(0xffffe9a2),
                      borderRadius: BorderRadius.circular(17),
                    ),
                    child: Text(
                      '🪙  ${tr(ref, 'Ödül', 'Reward')} +${r.reward}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  if (r.reward == 0)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Text(
                        tr(
                          ref,
                          'Bölüm ödülleri ilk tamamlamada verilir. Klasikte en az 500 puan kazan.',
                          'Level rewards are granted on first completion. Score at least 500 in Classic.',
                        ),
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                  if (game.won &&
                      game.mode == GameMode.journey &&
                      game.level % 5 == 0)
                    Padding(
                      padding: const EdgeInsets.only(top: 14),
                      child: Text(
                        tr(
                          ref,
                          '🧩 Koleksiyonunda yeni bir hatıra!',
                          '🧩 A new keepsake in your collection!',
                        ),
                        style: const TextStyle(
                          color: Color(0xff138847),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            if (game.won &&
                game.mode == GameMode.journey &&
                game.level < 120) ...[
              GlossButton(
                label: tr(ref, 'Sonraki', 'Next'),
                subtitle: tr(
                  ref,
                  'Bölüm ${game.level + 1} ile devam et',
                  'Continue to level ${game.level + 1}',
                ),
                icon: Icons.play_arrow_rounded,
                color: green,
                height: 56,
                onTap: () =>
                    context.pushReplacement('/game/journey/${game.level + 1}'),
              ),
              const SizedBox(height: 8),
            ],
            Row(
              children: [
                Expanded(
                  child: GlossButton(
                    label: tr(ref, 'Tekrar', 'Replay'),
                    height: 52,
                    icon: Icons.replay_rounded,
                    onTap: () => context.pushReplacement(
                      '/game/${game.mode.name}/${game.level}?fresh=1',
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GlossButton(
                    label: tr(ref, 'Ana Sayfa', 'Home'),
                    height: 52,
                    icon: Icons.home_rounded,
                    color: purple,
                    onTap: () => context.go('/'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              '${tr(ref, 'Toplam yıldız', 'Total stars')}: ${ref.watch(progressProvider).totalStars}',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
