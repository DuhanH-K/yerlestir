import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/widgets/game_ui.dart';
import '../../core/services/feedback_service.dart';
import '../progress/progress.dart';
import '../gameplay/domain/puzzle.dart';
import 'reward_celebration.dart';

class RewardScreen extends ConsumerWidget {
  const RewardScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = ref.watch(progressProvider);
    final claimable = p.canClaim(DateTime.now());
    final activeDay = claimable ? p.rewardDay : (p.rewardDay + 6) % 7;
    return GameShell(
      child: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          GameTitle(tr(ref, 'Günlük Ödül', 'Daily Reward'), size: 36),
          const SizedBox(height: 12),
          CreamPanel(
            padding: const EdgeInsets.all(8),
            child: LayoutBuilder(
              builder: (context, b) => Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: List.generate(
                  7,
                  (i) => Container(
                    width: i == 6
                        ? b.maxWidth
                        : ((b.maxWidth - 16) / 3).floorToDouble(),
                    height: i == 6 ? 52 : 82,
                    decoration: BoxDecoration(
                      color: i == activeDay
                          ? const Color(0xffd5f2bb)
                          : const Color(0xfffff4e3),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: i == activeDay ? green : Colors.white,
                        width: 2,
                      ),
                    ),
                    child: Center(
                      child: i == 6
                          ? Text(
                              '🎁  7. ${tr(ref, 'Gün', 'Day')}  •  150',
                              style: const TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 18,
                              ),
                            )
                          : Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  '${i + 1}. ${tr(ref, 'Gün', 'Day')}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 12,
                                  ),
                                ),
                                Text(
                                  '${dailyRewards[i]}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w900,
                                    fontSize: 21,
                                  ),
                                ),
                                if (i == activeDay)
                                  Text(
                                    claimable
                                        ? tr(ref, 'Bugün', 'Today')
                                        : tr(ref, 'Alındı ✓', 'Claimed ✓'),
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: green,
                                    ),
                                  ),
                              ],
                            ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          GlossButton(
            label: claimable
                ? tr(ref, 'Ödülü Al', 'Claim Reward')
                : tr(ref, 'Ödül Alındı', 'Reward Claimed'),
            icon: Icons.card_giftcard_rounded,
            color: green,
            height: 56,
            onTap: claimable
                ? () async {
                    final amount = dailyRewards[p.rewardDay];
                    final success = await ref
                        .read(progressProvider.notifier)
                        .claim(DateTime.now());
                    if (success) {
                      ref.read(feedbackProvider).tap(p, clear: true);
                    }
                    if (context.mounted) {
                      if (success) {
                        await showRewardCelebration(
                          context,
                          amount,
                          p.localeCode == 'en',
                        );
                      } else {
                        toast(
                          context,
                          success
                              ? '+$amount 🪙'
                              : tr(
                                  ref,
                                  'Yarın tekrar gel!',
                                  'Come back tomorrow!',
                                ),
                        );
                      }
                    }
                  }
                : null,
          ),
          const SizedBox(height: 12),
          CreamPanel(
            padding: const EdgeInsets.all(8),
            child: Text(
              tr(
                ref,
                'Her gün bir ödül. Kaçırdığın günlerde sıran kaybolmaz.',
                'A reward each day. Missing a day keeps your place.',
              ),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, height: 1.3),
            ),
          ),
        ],
      ),
    );
  }
}
