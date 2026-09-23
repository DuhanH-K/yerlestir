import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/widgets/game_ui.dart';
import '../../core/widgets/blocks.dart';
import '../../core/widgets/skin_style.dart';
import '../progress/progress.dart';
import '../settings/parental_gate.dart';

class ShopScreen extends ConsumerStatefulWidget {
  const ShopScreen({super.key});
  @override
  ConsumerState<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends ConsumerState<ShopScreen> {
  bool blocks = false;
  @override
  Widget build(BuildContext context) {
    final p = ref.watch(progressProvider);
    final items = blocks
        ? [('candy', 'Şeker', 'Candy', 250), ('ocean', 'Okyanus', 'Ocean', 300)]
        : [
            ('default', 'Klasik', 'Classic', 0),
            ('sunset', 'Gün Batımı', 'Sunset', 400),
            ('forest', 'Orman', 'Forest', 500),
            ('night', 'Gece', 'Night', 700),
          ];
    return GameShell(
      child: LayoutBuilder(
        builder: (context, bounds) => FitPage(
          padding: const EdgeInsets.all(8),
          children: [
            GameTitle(tr(ref, 'Mağaza', 'Shop'), size: 34),
            const SizedBox(height: 8),
            SegmentedButton<bool>(
              segments: [
                ButtonSegment(
                  value: false,
                  label: Text(tr(ref, 'Temalar', 'Themes')),
                  icon: const Icon(Icons.palette_rounded),
                ),
                ButtonSegment(
                  value: true,
                  label: Text(tr(ref, 'Renk Paketleri', 'Color Packs')),
                  icon: const Icon(Icons.view_in_ar_rounded),
                ),
              ],
              selected: {blocks},
              onSelectionChanged: (v) => setState(() => blocks = v.first),
            ),
            const SizedBox(height: 8),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: items.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 8,
                mainAxisExtent: ((bounds.maxHeight - 210) / 2).clamp(
                  130.0,
                  300.0,
                ),
              ),
              itemBuilder: (context, i) {
                final item = items[i],
                    owned = p.unlockedItems.contains(item.$1),
                    selected = p.selectedSkin == item.$1;
                return CreamPanel(
                  padding: const EdgeInsets.all(9),
                  child: Column(
                    children: [
                      FittedBox(
                        child: Text(
                          tr(ref, item.$2, item.$3),
                          style: const TextStyle(
                            fontSize: 21,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: SkinBackdrop(
                            skin: item.$1,
                            child: Center(
                              child: Padding(
                                padding: const EdgeInsets.all(8),
                                child: DecorativeBoard(skin: item.$1),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      GlossButton(
                        label: selected
                            ? tr(ref, 'Seçili ✓', 'Selected ✓')
                            : owned
                            ? tr(ref, 'Seç', 'Select')
                            : '🪙 ${number(item.$4)}',
                        subtitle: owned ? null : tr(ref, 'Satın Al', 'Buy'),
                        color: selected ? green : blue,
                        height: 48,
                        onTap: selected
                            ? null
                            : () async {
                                if (!owned &&
                                    p.parentalGateEnabled &&
                                    !await parentalGate(
                                      context,
                                      english: p.localeCode == 'en',
                                    )) {
                                  return;
                                }
                                if (!context.mounted) {
                                  return;
                                }
                                if (!owned && p.coins < item.$4) {
                                  toast(
                                    context,
                                    tr(
                                      ref,
                                      'Yeterli altın yok. Bölüm ve günlük ödüllerle kazanabilirsin.',
                                      'Not enough coins. Earn them from levels and daily rewards.',
                                    ),
                                  );
                                  return;
                                }
                                if (!owned) {
                                  final ok = await showDialog<bool>(
                                    context: context,
                                    builder: (d) => AlertDialog(
                                      title: Text(tr(ref, 'Satın Al', 'Buy')),
                                      content: Text(
                                        '${tr(ref, item.$2, item.$3)} • ${number(item.$4)} 🪙',
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.pop(d, false),
                                          child: Text(
                                            tr(ref, 'Vazgeç', 'Cancel'),
                                          ),
                                        ),
                                        FilledButton(
                                          onPressed: () =>
                                              Navigator.pop(d, true),
                                          child: Text(
                                            tr(ref, 'Satın Al', 'Buy'),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                  if (ok != true) {
                                    return;
                                  }
                                }
                                await ref
                                    .read(progressProvider.notifier)
                                    .buy(item.$1, item.$4);
                              },
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 8),
            CreamPanel(
              padding: const EdgeInsets.all(5),
              child: Text(
                tr(
                  ref,
                  'Her paket: özel arka plan, tahta ve blok renkleri. Kalıcı açılır; yalnızca oyun altını.',
                  'Every pack includes a background, board and block palette. Unlock forever with game coins.',
                ),
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 11),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
