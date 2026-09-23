import 'package:flutter/material.dart';

import '../../../core/widgets/game_ui.dart';

Future<void> showGameHelp(
  BuildContext context,
  bool english,
) => showModalBottomSheet<void>(
  context: context,
  backgroundColor: const Color(0xfffff3df),
  showDragHandle: true,
  builder: (context) => SafeArea(
    child: Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            english ? 'A little space for your mind' : 'Zihnine küçük bir mola',
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: ink,
            ),
          ),
          const SizedBox(height: 18),
          _step(
            Icons.touch_app_rounded,
            english ? 'Pick up a piece' : 'Bir parça seç',
            english
                ? 'Drag it onto the board, or tap the piece and then its top-left cell.'
                : 'Tahtaya sürükle veya parçaya, ardından yerleşeceği sol üst hücreye dokun.',
          ),
          _step(
            Icons.auto_awesome_rounded,
            english ? 'Make room' : 'Yeni yer aç',
            english
                ? 'Fill a whole row or column to clear it. Consecutive clears increase your combo.'
                : 'Dolu satır ve sütunları temizle. Art arda temizlemelerle kombonu artır.',
          ),
          _step(
            Icons.favorite_rounded,
            english ? 'Take your time' : 'Acele etme',
            english
                ? 'There is no timer. Your game saves after every move.'
                : 'Süre sınırı yok. Oyunun her hamleden sonra kaydedilir.',
          ),
          _step(
            Icons.lightbulb_rounded,
            english ? 'Hint • 30 coins' : 'İpucu • 30 altın',
            english
                ? 'Highlights a suggested move. No coins are charged when no move exists.'
                : 'Önerilen hamleyi gösterir. Uygun hamle yoksa altın alınmaz.',
          ),
          const SizedBox(height: 16),
          GlossButton(
            label: english ? 'Let’s play' : 'Haydi Oynayalım',
            color: green,
            onTap: () => Navigator.pop(context),
          ),
        ],
      ),
    ),
  ),
);
Widget _step(IconData icon, String title, String description) => Padding(
  padding: const EdgeInsets.symmetric(vertical: 9),
  child: Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Icon(icon, color: blue, size: 30),
      const SizedBox(width: 14),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17),
            ),
            Text(
              description,
              style: const TextStyle(fontSize: 13, height: 1.5),
            ),
          ],
        ),
      ),
    ],
  ),
);
