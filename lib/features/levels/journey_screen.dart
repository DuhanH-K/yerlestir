import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/widgets/game_ui.dart';
import '../progress/progress.dart';
import '../gameplay/domain/puzzle.dart';

class JourneyScreen extends ConsumerStatefulWidget {
  const JourneyScreen({super.key});
  @override
  ConsumerState<JourneyScreen> createState() => _JourneyScreenState();
}

class _JourneyScreenState extends ConsumerState<JourneyScreen> {
  late int page;
  @override
  void initState() {
    super.initState();
    page = (ref.read(progressProvider).lastPlayedLevel - 1) ~/ 10;
  }

  @override
  Widget build(BuildContext context) {
    final p = ref.watch(progressProvider);
    return GameShell(
      child: FitViewport(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: GameTitle(
                tr(ref, 'Yolculuk', 'Journey'),
                size: 34,
                subtitle: tr(
                  ref,
                  'Yeni dünyalar seni bekliyor!',
                  'New worlds await!',
                ),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  onPressed: page > 0 ? () => setState(() => page--) : null,
                  icon: const Icon(Icons.chevron_left_rounded),
                ),
                Expanded(
                  child: CreamPanel(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 7,
                    ),
                    child: Text(
                      '${page * 10 + 1} – ${page * 10 + 10}  •  ${LevelFactory.create(page * 10 + 1).region}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
                IconButton(
                  onPressed: page < 11 ? () => setState(() => page++) : null,
                  icon: const Icon(Icons.chevron_right_rounded),
                ),
              ],
            ),
            Expanded(
              child: LayoutBuilder(
                builder: (context, bounds) => GridView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(12),
                  itemCount: 10,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisExtent: (bounds.maxHeight - 56) / 5,
                    mainAxisSpacing: 8,
                    crossAxisSpacing: 16,
                  ),
                  itemBuilder: (_, i) {
                    final level = page * 10 + i + 1;
                    final stars = p.levelStars['$level'] ?? 0;
                    final open =
                        level == 1 || p.levelStars.containsKey('${level - 1}');
                    return GlossButton(
                      label: open
                          ? '$level   ${stars > 0 ? '★' * stars : ''}'
                          : '$level',
                      subtitle: open
                          ? '${LevelFactory.create(level).target} ${tr(ref, 'puan', 'points')}'
                          : null,
                      icon: open
                          ? (stars > 0
                                ? Icons.check_circle_rounded
                                : Icons.play_arrow_rounded)
                          : Icons.lock_rounded,
                      color: stars > 0 ? green : blue,
                      onTap: open
                          ? () => context.push('/game/journey/$level')
                          : null,
                    );
                  },
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 5, 22, 18),
              child: GlossButton(
                label: tr(
                  ref,
                  'Koleksiyon • ${p.collectionCount}/24',
                  'Collection • ${p.collectionCount}/24',
                ),
                height: 52,
                icon: Icons.extension_rounded,
                color: purple,
                onTap: () => context.push('/collection'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CollectionScreen extends ConsumerWidget {
  const CollectionScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = ref.watch(progressProvider);
    const icons = [
      '🐱',
      '⛵',
      '🌺',
      '🏡',
      '🐬',
      '🏖️',
      '🦋',
      '🌳',
      '🏛️',
      '🦉',
      '🌻',
      '🏺',
      '🏰',
      '🦊',
      '🌙',
      '🦢',
      '🗻',
      '🌈',
      '🐢',
      '🪷',
      '🦚',
      '🎠',
      '🌅',
      '👑',
    ];
    return GameShell(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            GameTitle(
              tr(ref, 'Koleksiyon', 'Collection'),
              size: 32,
              subtitle: tr(
                ref,
                'Her 5 bölümde yeni bir hatıra',
                'A new keepsake every 5 levels',
              ),
            ),
            const SizedBox(height: 10),
            CreamPanel(
              child: Text(
                tr(
                  ref,
                  '${p.collectionCount}/24 hatıra • ${p.totalStars} yıldız',
                  '${p.collectionCount}/24 keepsakes • ${p.totalStars} stars',
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: GridView.builder(
                itemCount: 24,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                ),
                itemBuilder: (_, i) => CreamPanel(
                  padding: const EdgeInsets.all(7),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        i < p.collectionCount ? icons[i] : '🔒',
                        style: const TextStyle(fontSize: 29),
                      ),
                      Text(
                        '${(i + 1) * 5}. ${tr(ref, 'bölüm', 'level')}',
                        style: const TextStyle(fontSize: 10),
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
}
