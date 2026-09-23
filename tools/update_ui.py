from pathlib import Path
p=Path('lib/core/widgets/game_ui.dart'); s=p.read_text(encoding='utf-8'); s=s.replace("part 'gloss_button.dart';", "export 'fit_page.dart';\n\npart 'gloss_button.dart';"); p.write_text(s,encoding='utf-8')
p=Path('lib/features/home/home_screen.dart'); s=p.read_text(encoding='utf-8').replace('builder: (context, b) => ListView(', 'builder: (context, b) => FitPage('); p.write_text(s,encoding='utf-8')
p=Path('lib/features/gameplay/presentation/result_screen.dart'); s=p.read_text(encoding='utf-8').replace('child: ListView(', 'child: FitPage(').replace("'Bölüm\\nTamamlandı!', 'Level\\nComplete!'", "'Bölüm Tamamlandı!', 'Level Complete!'").replace("'Güzel\\nOynadın!', 'Well\\nPlayed!'", "'Güzel Oynadın!', 'Well Played!'"); start=s.index('                  _line('); end=s.index('                  if (r.reward == 0)',start); s=s[:start]+s[end:]; start=s.index('\n  Widget _line'); s=s[:start]+'\n}\n'; p.write_text(s,encoding='utf-8')
p=Path('lib/features/levels/journey_screen.dart'); s=p.read_text(encoding='utf-8'); start=s.index('            child: SingleChildScrollView('); end=s.index('\n          Padding(',start); s=s[:start]+'''            child: LayoutBuilder(
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
                  final open = level == 1 || p.levelStars.containsKey('${level - 1}');
                  return GlossButton(
                    label: open ? '$level   ${stars > 0 ? '★' * stars : ''}' : '$level',
                    subtitle: open ? '${LevelFactory.create(level).target} ${tr(ref, 'puan', 'points')}' : null,
                    icon: open ? (stars > 0 ? Icons.check_circle_rounded : Icons.play_arrow_rounded) : Icons.lock_rounded,
                    color: stars > 0 ? green : blue,
                    onTap: open ? () => context.push('/game/journey/$level') : null,
                  );
                },
              ),
            ),
          ),'''+s[end:]; start=s.index('class _PathPainter'); end=s.index('class CollectionScreen',start); s=s[:start]+s[end:]; s=s.replace("import 'dart:math';\n\n",''); p.write_text(s,encoding='utf-8')
