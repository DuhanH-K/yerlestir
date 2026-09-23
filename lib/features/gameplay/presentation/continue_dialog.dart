import 'package:flutter/material.dart';

import '../../../core/services/ad_service.dart';
import '../../../core/widgets/game_ui.dart';

class ContinueDialog extends StatefulWidget {
  const ContinueDialog({
    super.key,
    required this.ads,
    required this.english,
    required this.classic,
  });
  final GameAds ads;
  final bool english, classic;
  @override
  State<ContinueDialog> createState() => _ContinueDialogState();
}

class _ContinueDialogState extends State<ContinueDialog> {
  bool loading = false;
  String? error;
  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !loading,
    child: Dialog(
      backgroundColor: Colors.transparent,
      child: CreamPanel(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.favorite_rounded, color: coral, size: 58),
              const SizedBox(height: 12),
              Text(
                widget.english ? 'One more chance!' : 'Bir şans daha!',
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                widget.english
                    ? 'Watch an ad to clear the bottom 3 rows and get new pieces.${widget.classic ? '' : ' Plus 5 extra moves!'}'
                    : 'Reklam izle: alt 3 satır açılsın, yeni parçalar gelsin.${widget.classic ? '' : ' Üstelik +5 hamle!'}',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              if (loading)
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: CircularProgressIndicator(),
                )
              else
                GlossButton(
                  label: widget.english
                      ? 'Watch & Continue'
                      : 'Reklam izle ve devam et',
                  icon: Icons.ondemand_video_rounded,
                  color: green,
                  height: 56,
                  onTap: () async {
                    setState(() {
                      loading = true;
                      error = null;
                    });
                    final earned = await widget.ads.showContinueReward();
                    if (!context.mounted) return;
                    if (earned) {
                      Navigator.pop(context, true);
                    } else {
                      setState(() {
                        loading = false;
                        error = widget.english
                            ? 'Reward not earned. Try again or finish the round.'
                            : 'Ödül kazanılmadı. Tekrar dene veya turu bitir.';
                      });
                    }
                  },
                ),
              if (error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(error!, textAlign: TextAlign.center),
                ),
              TextButton(
                onPressed: loading ? null : () => Navigator.pop(context, false),
                child: Text(widget.english ? 'Finish round' : 'Turu bitir'),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
