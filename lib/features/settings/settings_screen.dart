import '../../core/services/ad_service.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/widgets/game_ui.dart';
import '../../core/services/feedback_service.dart';
import '../progress/progress.dart';
import 'parental_gate.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = ref.watch(progressProvider),
        controller = ref.read(progressProvider.notifier);
    return GameShell(
      child: ListView(
        padding: const EdgeInsets.all(8),
        children: [
          GameTitle(tr(ref, 'Ayarlar', 'Settings'), size: 32),
          const SizedBox(height: 6),
          CreamPanel(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                _toggle(
                  tr(ref, 'Ses', 'Sound'),
                  tr(ref, 'Oyun ses efektleri', 'Game sound effects'),
                  Icons.volume_up_rounded,
                  blue,
                  p.soundEnabled,
                  (v) => controller.change({'soundEnabled': v}),
                ),
                _toggle(
                  tr(ref, 'Müzik', 'Music'),
                  tr(ref, 'Arka plan müziği', 'Background music'),
                  Icons.music_note_rounded,
                  coral,
                  p.musicEnabled,
                  (v) {
                    controller.change({'musicEnabled': v});
                    ref.read(feedbackProvider).music(v);
                  },
                ),
                _toggle(
                  tr(ref, 'Titreşim', 'Haptics'),
                  tr(ref, 'Oyun içi titreşim', 'Gentle game feedback'),
                  Icons.vibration_rounded,
                  const Color(0xffffb722),
                  p.hapticsEnabled,
                  (v) => controller.change({'hapticsEnabled': v}),
                ),
                _toggle(
                  tr(ref, 'Ebeveyn Kilidi', 'Parental Gate'),
                  tr(
                    ref,
                    'Mağaza ve sıfırlama koruması',
                    'Protect shop and reset',
                  ),
                  Icons.lock_rounded,
                  purple,
                  p.parentalGateEnabled,
                  (v) async {
                    if (v ||
                        await parentalGate(
                          context,
                          english: p.localeCode == 'en',
                        )) {
                      controller.change({'parentalGateEnabled': v});
                    }
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          CreamPanel(
            padding: EdgeInsets.zero,
            child: Row(
              children: [
                const Icon(Icons.language_rounded, color: blue, size: 32),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    tr(ref, 'Dil', 'Language'),
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 21,
                    ),
                  ),
                ),
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(value: 'tr', label: Text('TR')),
                    ButtonSegment(value: 'en', label: Text('EN')),
                  ],
                  selected: {p.localeCode},
                  onSelectionChanged: (value) =>
                      controller.change({'localeCode': value.first}),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          CreamPanel(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                ListTile(
                  dense: true,
                  visualDensity: const VisualDensity(vertical: -4),
                  minVerticalPadding: 8,
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(
                    Icons.restart_alt_rounded,
                    color: coral,
                    size: 32,
                  ),
                  title: Text(tr(ref, 'İlerlemeyi Sıfırla', 'Reset Progress')),

                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () async {
                    if (!await parentalGate(
                          context,
                          english: p.localeCode == 'en',
                        ) ||
                        !context.mounted) {
                      return;
                    }
                    final reset = await showDialog<bool>(
                      context: context,
                      builder: (d) => AlertDialog(
                        title: Text(
                          tr(ref, 'Baştan başlansın mı?', 'Start over?'),
                        ),
                        content: Text(
                          tr(
                            ref,
                            'Puanlar, altınlar, satın alınan temalar ve kayıtlı oyunlar silinecek.',
                            'Scores, coins, purchased themes and saved games will be deleted.',
                          ),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(d, false),
                            child: Text(tr(ref, 'Vazgeç', 'Cancel')),
                          ),
                          FilledButton(
                            onPressed: () => Navigator.pop(d, true),
                            child: Text(tr(ref, 'Sıfırla', 'Reset')),
                          ),
                        ],
                      ),
                    );
                    if (reset == true) {
                      await controller.reset();
                      if (context.mounted) {
                        toast(context, 'İlerleme sıfırlandı / Progress reset');
                      }
                    }
                  },
                ),

                ListTile(
                  dense: true,
                  visualDensity: const VisualDensity(vertical: -4),
                  minVerticalPadding: 8,
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(
                    Icons.shield_rounded,
                    color: green,
                    size: 32,
                  ),
                  title: Text(tr(ref, 'Gizlilik', 'Privacy')),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => _info(
                    context,
                    tr(ref, 'Gizlilik', 'Privacy'),
                    tr(
                      ref,
                      'Oyun ilerlemen bu cihazda saklanır ve internet olmadan oynayabilirsin. İnternet varken Google AdMob reklamları yüklenir. Reklam sağlayıcısı cihaz, IP adresi ve reklam etkileşimi bilgilerini işleyebilir. Gerekli bölgelerde reklam tercihlerin sorulur. Uygulama verileri silinirse ilerleme kaybolur.',
                      'Progress stays on this device and gameplay works offline. Google AdMob loads ads when online and may process device, IP address and ad interaction information. Advertising choices are requested where required. Clearing app data removes progress.',
                    ),
                  ),
                ),

                ListenableBuilder(
                  listenable: ref.watch(adProvider),
                  builder: (_, child) => ref.read(adProvider).privacyRequired
                      ? ListTile(
                          title: Text(
                            tr(
                              ref,
                              'Reklam gizlilik tercihleri',
                              'Ad privacy choices',
                            ),
                          ),
                          leading: const Icon(Icons.privacy_tip_outlined),
                          onTap: () => ref.read(adProvider).privacyOptions(),
                        )
                      : const SizedBox.shrink(),
                ),
                ListTile(
                  dense: true,
                  visualDensity: const VisualDensity(vertical: -4),
                  minVerticalPadding: 8,
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(
                    Icons.help_rounded,
                    color: blue,
                    size: 32,
                  ),
                  title: Text(tr(ref, 'Nasıl Oynanır?', 'How to Play')),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => _info(
                    context,
                    tr(
                      ref,
                      'Düşün • Yerleştir • Temizle',
                      'Think • Place • Clear',
                    ),
                    tr(
                      ref,
                      'Alttaki üç parçayı 8×8 tahtaya yerleştir. Parçayı sürükle veya seçip sol üst hücresine dokun. Dolu satır ve sütunlar birlikte temizlenir. Üç parça bitince yenileri gelir.\n\nİpucu 30 oyun altınıdır. Satır/sütun temizleyen hamlelere öncelik verir. Hamle yapana kadar açık kalır; tekrar ücret alınmaz. Parçaların hiçbiri sığmıyorsa tur biter.\n\nYolculukta hamle sınırı içinde hedef puanı tamamla. Erken bitirerek daha çok yıldız kazan. Günlük bulmaca her gün değişir.',
                      'Place three pieces on the 8×8 board. Drag, or select a piece and tap its top-left cell. Full rows and columns clear together. Use all three pieces to receive more.\n\nA hint costs 30 game coins and prioritizes line clears. It stays visible until your next move without charging again. The run ends when no piece fits.\n\nReach the Journey target within the move limit. Finish early for more stars. The daily puzzle changes every day.',
                    ),
                  ),
                ),
                ListTile(
                  dense: true,
                  visualDensity: const VisualDensity(vertical: -4),
                  minVerticalPadding: 8,
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(
                    Icons.support_agent_rounded,
                    color: purple,
                    size: 32,
                  ),
                  title: Text(tr(ref, 'Destek', 'Support')),
                  onTap: () => _info(
                    context,
                    tr(ref, 'Destek', 'Support'),
                    tr(
                      ref,
                      'Sürüm 1.0.0 • Yerleştir!\n\nBir sorunla karşılaşırsan oyun modu, bölüm numarası ve yaptığın son hamleyi not ederek uygulamayı aldığın geliştiriciye ilet. Destek mesajları uygulamadan gönderilmez.\n\nSesler: Great, Excellent, Awesome — rhodesmas / Freesound, CC BY 4.0.\nhttps://freesound.org/people/rhodesmas/packs/17959/\nhttps://creativecommons.org/licenses/by/4.0/',
                      'Version 1.0.0 • Yerleştir!\n\nIf something goes wrong, note the game mode, level and last move, and contact the developer who supplied the app. Support messages are not sent from the app.\n\nVoices: Great, Excellent, Awesome — rhodesmas / Freesound, CC BY 4.0.\nhttps://freesound.org/people/rhodesmas/packs/17959/\nhttps://creativecommons.org/licenses/by/4.0/',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _toggle(
    String title,
    String subtitle,
    IconData icon,
    Color color,
    bool value,
    ValueChanged<bool> changed,
  ) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 0),
    child: Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: Colors.white, size: 28),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
        Switch(
          value: value,
          onChanged: changed,
          activeThumbColor: Colors.white,
          activeTrackColor: green,
        ),
      ],
    ),
  );
  void _info(BuildContext context, String title, String body) =>
      showDialog<void>(
        context: context,
        builder: (d) => AlertDialog(
          title: Text(title),
          content: SingleChildScrollView(child: Text(body)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(d),
              child: const Text('OK'),
            ),
          ],
        ),
      );
}
