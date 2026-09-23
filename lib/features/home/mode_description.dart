import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/widgets/game_ui.dart';

class ModeDescription extends ConsumerWidget {
  const ModeDescription({super.key, required this.index});
  final int index;
  @override
  Widget build(BuildContext context, WidgetRef ref) => AnimatedSwitcher(
    duration: const Duration(milliseconds: 180),
    child: CreamPanel(
      key: ValueKey(index),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            [
              Icons.all_inclusive_rounded,
              Icons.flag_rounded,
              Icons.today_rounded,
            ][index],
            color: ink,
            size: 22,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              [
                tr(
                  ref,
                  'Süre ve hamle sınırı yok. Yer kaldıkça oyna, en yüksek skorunu geliştir.',
                  'No timer or move limit. Keep playing while pieces fit and beat your best score.',
                ),
                tr(
                  ref,
                  '120 bölüm. Verilen hamle sayısında hedef puana ulaş, yıldız kazan ve yeni bölümleri aç.',
                  '120 levels. Reach the target within the move limit, earn stars and unlock the next level.',
                ),
                tr(
                  ref,
                  'Her gün yeni bir sabit parça dizisi. 30 hamlede 800 puana ulaş. Aynı gün tekrar oynarsan aynı diziyi alırsın.',
                  'A new fixed piece sequence every day. Reach 800 points in 30 moves. Replays that day use the same sequence.',
                ),
              ][index],
              style: const TextStyle(fontSize: 12, height: 1.45),
            ),
          ),
        ],
      ),
    ),
  );
}
