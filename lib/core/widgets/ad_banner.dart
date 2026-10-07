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
      _loading = false;
      _failures = 0;
      _retry?.cancel();
      final old = _ad;
      _ad = null;
      WidgetsBinding.instance.addPostFrameCallback((_) => old?.dispose());
      unawaited(_load(++_generation));
    }
  }

  Future<void> _load(int generation) async {
    if (!mounted || generation != _generation || _loading || _ad != null) {
      return;
    }
    final lifecycle = WidgetsBinding.instance.lifecycleState;
    if ((lifecycle != null && lifecycle != AppLifecycleState.resumed) ||
        ModalRoute.of(context)?.isCurrent == false) {
      _retry = Timer(
        const Duration(seconds: 30),
        () => unawaited(_load(generation)),
      );
      return;
    }
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
        if (generation == _generation) _loading = false;
        return;
      }
      GameAds.log('Banner', 'load_start width=$_width');
      final ad = BannerAd(
        adUnitId: GameAds.bannerId,
        size: size,
        request: const AdRequest(),
        listener: BannerAdListener(
          onAdLoaded: (ad) {
            if (!mounted || generation != _generation) {
              ad.dispose();
              return;
            }
            _loading = false;
            _retry?.cancel();
            _failures = 0;
            setState(() => loaded = true);
            GameAds.log('Banner', 'load_success');
          },
          onAdImpression: (_) => GameAds.log('Banner', 'impression'),
          onAdFailedToLoad: (ad, error) {
            ad.dispose();
            if (!mounted || generation != _generation) return;
            _loading = false;
            _ad = null;
            setState(() => loaded = false);
            GameAds.logLoadError('Banner', error);
            _scheduleRetry(generation);
          },
        ),
      );
      _ad = ad;
      await ad.load();
    } catch (error) {
      if (!mounted || generation != _generation) return;
      _loading = false;
      _ad?.dispose();
      _ad = null;
      _scheduleRetry(generation);
      GameAds.log('Banner', 'load_fail exception=${error.runtimeType}');
      /* No network/platform: keep the game usable without a blank bar. */
    }
  }

  void _scheduleRetry(int generation) {
    _retry?.cancel();
    final delay = Duration(seconds: 30 * (1 << (_failures++).clamp(0, 2)));
    _retry = Timer(delay, () => unawaited(_load(generation)));
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
