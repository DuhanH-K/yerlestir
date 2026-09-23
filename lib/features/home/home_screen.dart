import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/widgets/game_ui.dart';
import '../../core/services/feedback_service.dart';
import '../progress/progress.dart';
import '../gameplay/domain/puzzle.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});
  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int selected = 0;
  @override
  Widget build(BuildContext context) {
    final p = ref.watch(progressProvider);
    final dailySeed = LevelFactory.dailySeed(DateTime.now());
    final daily = LevelFactory.daily(dailySeed);
    final dailyDone = p.rewardedRuns.contains('daily_$dailySeed');
    return GameShell(
      back: false,
      child: LayoutBuilder(
        builder: (context, b) => FitPage(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          children: [
            SizedBox(
              height: b.maxHeight > 650 ? 100 : 60,
              child: const Center(
                child: FittedBox(child: GameTitle('Yerleştir!', size: 48)),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                for (var i = 0; i < 3; i++) ...[
                  if (i > 0) const SizedBox(width: 8),
                  Expanded(
                    child: _ModeCard(
                      index: i,
                      selected: selected == i,
                      onTap: () => setState(() => selected = i),
                      title: [
                        tr(ref, 'Klasik', 'Classic'),
                        tr(ref, 'Yolculuk', 'Journey'),
                        tr(ref, 'Günlük', 'Daily'),
                      ][i],
                      subtitle: [
                        tr(ref, 'Sınır yok', 'No limit'),
                        tr(ref, '120 bölüm', '120 levels'),
                        tr(ref, '${daily.moves} hamle', '${daily.moves} moves'),
                      ][i],
                    ),
                  ),
                ],
              ],
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: CreamPanel(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                child: Text(
                  [
                    tr(
                      ref,
                      'Süre sınırı yok. Yer kaldıkça oyna, rekorunu geliştir.',
                      'No timer. Keep placing pieces and beat your best.',
                    ),
                    tr(
                      ref,
                      'Bölüm ${p.lastPlayedLevel}: hazır çizgileri tamamla, yıldız kazan ve ilerle.',
                      'Level ${p.lastPlayedLevel}: finish the starting rows, earn stars and progress.',
                    ),
                    tr(
                      ref,
                      dailyDone
                          ? 'Bugünün ödülünü aldın! Yarın yeni bulmaca. İstersen tekrar oyna.'
                          : 'Bugünün hedefi: ${daily.moves} hamlede ${daily.target} puan. Her gün yeni tahta!',
                      dailyDone
                          ? 'Daily reward earned! A new puzzle tomorrow. Replay for practice.'
                          : 'Today: ${daily.target} points in ${daily.moves} moves. A new board every day!',
                    ),
                  ][selected],
                  style: const TextStyle(fontSize: 12),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            GlossButton(
              label: tr(ref, 'Oyna', 'Play'),
              icon: Icons.play_arrow_rounded,
              color: green,
              height: 58,
              onTap: () {
                ref.read(feedbackProvider).music(p.musicEnabled);
                context.push(
                  selected == 1
                      ? '/journey'
                      : '/game/${selected == 0 ? 'classic' : 'daily'}/1',
                );
              },
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: GlossButton(
                    label: tr(ref, 'Mağaza', 'Shop'),
                    icon: Icons.storefront_rounded,
                    color: purple,
                    height: 56,
                    onTap: () => context.push('/shop'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: GlossButton(
                    label: tr(ref, 'Günlük Ödül', 'Daily Reward'),
                    icon: Icons.card_giftcard_rounded,
                    height: 56,
                    onTap: () => context.push('/reward'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: CreamPanel(
                    padding: const EdgeInsets.all(8),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.emoji_events_rounded,
                          color: Colors.amber,
                          size: 24,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Column(
                            children: [
                              Text(
                                tr(ref, 'Rekor', 'Best'),
                                style: const TextStyle(fontSize: 11),
                              ),
                              Text(
                                number(p.highScore),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 20,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: GlossButton(
                    label: tr(ref, 'Koleksiyon', 'Collection'),
                    subtitle: '${p.collectionCount} / 24',
                    height: 60,
                    color: purple,
                    onTap: () => context.push('/collection'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ModeCard extends StatelessWidget {
  const _ModeCard({
    required this.index,
    required this.selected,
    required this.onTap,
    required this.title,
    required this.subtitle,
  });
  final int index;
  final bool selected;
  final VoidCallback onTap;
  final String title, subtitle;
  @override
  Widget build(BuildContext context) {
    final color = [blue, const Color(0xffffcc36), coral][index];
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        height: 86,
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color.lerp(color, Colors.white, .32)!, color],
          ),
          borderRadius: BorderRadius.circular(23),
          border: Border.all(
            color: selected ? Colors.white : Colors.white54,
            width: selected ? 4 : 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Color.lerp(color, Colors.black, .3)!,
              offset: const Offset(0, 5),
              blurRadius: 1,
            ),
          ],
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                [
                  Icons.extension_rounded,
                  Icons.map_rounded,
                  Icons.calendar_month_rounded,
                ][index],
                size: 40,
                color: Colors.white,
                shadows: const [
                  Shadow(color: Colors.black26, offset: Offset(0, 2)),
                ],
              ),
              const SizedBox(height: 6),
              FittedBox(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 22,
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    shadows: [
                      Shadow(color: Colors.black26, offset: Offset(0, 2)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 11, color: ink),
              ),
              const SizedBox(height: 4),
              Icon(
                selected ? Icons.check_circle_rounded : Icons.circle_outlined,
                size: 16,
                color: Colors.white,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
