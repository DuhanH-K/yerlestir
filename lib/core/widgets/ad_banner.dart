import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../services/ad_service.dart';

class GameBanner extends ConsumerWidget {
  const GameBanner({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ads = ref.watch(adProvider);
    return ListenableBuilder(
      listenable: ads,
      builder: (_, child) =>
          ads.ready ? const _NativeBanner() : const SizedBox.shrink(),
    );
  }
}

class _NativeBanner extends StatefulWidget {
  const _NativeBanner();
  @override
  State<_NativeBanner> createState() => _NativeBannerState();
}

class _NativeBannerState extends State<_NativeBanner> {
  BannerAd? _ad;
  bool loaded = false, _loading = false;
  int _width = 0, _generation = 0, _failures = 0;
  Timer? _retry;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final width = MediaQuery.sizeOf(context).width.floor();
    if (width != _width) {
      _width = width;
      loaded = false;
      _retry?.cancel();
      final old = _ad;
      _ad = null;
      WidgetsBinding.instance.addPostFrameCallback((_) => old?.dispose());
      unawaited(_load(++_generation));
    }
  }

  Future<void> _load(int generation) async {
    if (_loading || _ad != null) return;
    _loading = true;
    try {
      // Compact anchored banners preserve room for the board and tray.
      final size =
          // ignore: deprecated_member_use
          await AdSize.getCurrentOrientationAnchoredAdaptiveBannerAdSize(
            _width,
          );
      if (!mounted ||
          generation != _generation ||
          size == null ||
          GameAds.bannerId.isEmpty) {
        _loading = false;
        return;
      }
      GameAds.log('Banner', 'load requested');
      final ad = BannerAd(
        adUnitId: GameAds.bannerId,
        size: size,
        request: const AdRequest(),
        listener: BannerAdListener(
          onAdLoaded: (ad) {
            _loading = false;
            if (!mounted || generation != _generation) {
              ad.dispose();
              return;
            }
            _failures = 0;
            setState(() => loaded = true);
            GameAds.log('Banner', 'loaded');
          },
          onAdImpression: (_) => GameAds.log('Banner', 'impression'),
          onAdFailedToLoad: (ad, error) {
            _loading = false;
            ad.dispose();
            if (!mounted || generation != _generation) return;
            _ad = null;
            setState(() => loaded = false);
            GameAds.logLoadError('Banner', error);
            // iOS no-fill should not become four requests for one screen.
            if (!GameAds.isIOS && ++_failures <= 3) {
              _retry = Timer(
                Duration(seconds: 30 * _failures),
                () => unawaited(_load(generation)),
              );
            }
          },
        ),
      );
      _ad = ad;
      await ad.load();
    } catch (error) {
      _loading = false;
      GameAds.log('Banner', 'load exception: $error');
      /* No network/platform: keep the game usable without a blank bar. */
    }
  }

  @override
  void dispose() {
    _generation++;
    _retry?.cancel();
    _ad?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ad = _ad;
    if (!loaded || ad == null) return const SizedBox.shrink();
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: Color(0xff10203a),
        border: Border(top: BorderSide(color: Color(0xff436087))),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.only(top: 12, bottom: 4),
          child: Center(
            heightFactor: 1,
            child: SizedBox(
              width: ad.size.width.toDouble(),
              height: ad.size.height.toDouble(),
              child: AdWidget(ad: ad),
            ),
          ),
        ),
      ),
    );
  }
}
