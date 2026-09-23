import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

// Only main enables native ads; widget tests and web never call platform SDKs.
final adsRuntimeProvider = Provider<bool>((ref) => false);
final adProvider = Provider<GameAds>((ref) {
  final ads = GameAds(enabled: ref.watch(adsRuntimeProvider));
  ref.onDispose(ads.dispose);
  unawaited(ads.initialize());
  return ads;
});

class AdCadence {
  AdCadence(this.startedAt);
  final DateTime startedAt;
  static const minRoundsBeforeInterstitial = 2;
  static const interstitialCooldown = Duration(seconds: 90);
  int rounds = 0;
  DateTime? lastShown;
  void completeRound(int moves) {
    if (moves >= 3) rounds++;
  }

  bool eligible(DateTime now) =>
      rounds >= minRoundsBeforeInterstitial &&
      (lastShown == null || now.difference(lastShown!) >= interstitialCooldown);
  void shown(DateTime now) {
    rounds = 0;
    lastShown = now;
  }
}

class GameAds extends ChangeNotifier {
  GameAds({required this.enabled});
  final bool enabled;
  static const testMode = bool.fromEnvironment(
    'ADS_TEST_MODE',
    defaultValue: !kReleaseMode,
  );
  static bool get isIOS => defaultTargetPlatform == TargetPlatform.iOS;

  static String get bannerId => testMode
      ? (isIOS
          ? 'ca-app-pub-3940256099942544/2934735716'
          : 'ca-app-pub-3940256099942544/9214589741')
      : String.fromEnvironment(
          isIOS ? 'ADMOB_IOS_BANNER_ID' : 'ADMOB_BANNER_ID',
          defaultValue: isIOS
              ? 'ca-app-pub-4879558726064660/7172448351'
              : 'ca-app-pub-4879558726064660/3849898981',
        );
  static String get interstitialId => testMode
      ? (isIOS
          ? 'ca-app-pub-3940256099942544/4411468910'
          : 'ca-app-pub-3940256099942544/1033173712')
      : String.fromEnvironment(
          isIOS ? 'ADMOB_IOS_INTERSTITIAL_ID' : 'ADMOB_INTERSTITIAL_ID',
          defaultValue: isIOS
              ? 'ca-app-pub-4879558726064660/5643744260'
              : 'ca-app-pub-4879558726064660/5504752270',
        );
  final cadence = AdCadence(DateTime.now());
  bool ready = false,
      privacyRequired = false,
      _disposed = false,
      _loading = false;
  bool showing = false;
  InterstitialAd? _interstitial;
  RewardedAd? _rewarded;
  Future<void>? _rewardLoad;
  static String get rewardedId => testMode
      ? (isIOS
          ? 'ca-app-pub-3940256099942544/1712485313'
          : 'ca-app-pub-3940256099942544/5224354917')
      : String.fromEnvironment(
          isIOS ? 'ADMOB_IOS_REWARDED_ID' : 'ADMOB_REWARDED_ID',
          defaultValue: isIOS
              ? 'ca-app-pub-4879558726064660/2850059969'
              : 'ca-app-pub-4879558726064660/5103270903',
        );

  Future<void> preloadRewarded() {
    if (!ready || _disposed || _rewarded != null || rewardedId.isEmpty) {
      return Future.value();
    }
    return _rewardLoad ??= _loadRewarded().whenComplete(
      () => _rewardLoad = null,
    );
  }

  Future<void> _loadRewarded() async {
    final done = Completer<void>();
    try {
      await RewardedAd.load(
        adUnitId: rewardedId,
        request: const AdRequest(),
        rewardedAdLoadCallback: RewardedAdLoadCallback(
          onAdLoaded: (ad) {
            if (_disposed) {
              ad.dispose();
            } else {
              _rewarded = ad;
              debugPrint('Rewarded loaded');
            }
            if (!done.isCompleted) done.complete();
          },
          onAdFailedToLoad: (_) {
            if (!done.isCompleted) done.complete();
          },
        ),
      );
      await done.future.timeout(const Duration(seconds: 10));
    } catch (_) {}
  }

  Future<bool> showContinueReward() async {
    if (!ready || showing || _disposed) return false;
    await preloadRewarded();
    if (_disposed || showing) return false;
    final ad = _rewarded;
    if (ad == null) return false;
    _rewarded = null;
    showing = true;
    var earned = false;
    final done = Completer<bool>();
    void finish() {
      if (done.isCompleted) return;
      ad.dispose();
      showing = false;
      done.complete(earned);
      if (!_disposed) unawaited(preloadRewarded());
    }

    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (_) => cadence.shown(DateTime.now()),
      onAdDismissedFullScreenContent: (_) => finish(),
      onAdFailedToShowFullScreenContent: (_, error) => finish(),
    );
    try {
      await ad.show(onUserEarnedReward: (_, reward) => earned = true);
    } catch (_) {
      finish();
    }
    return done.future;
  }

  Timer? _retry;
  int _failures = 0;

  Future<void> initialize() async {
    if (!enabled ||
        kIsWeb ||
        (defaultTargetPlatform != TargetPlatform.android &&
            defaultTargetPlatform != TargetPlatform.iOS)) {
      return;
    }
    try {
      if (!testMode) {
        final done = Completer<void>();
        ConsentInformation.instance.requestConsentInfoUpdate(
          ConsentRequestParameters(),
          () async {
            try {
              await ConsentForm.loadAndShowConsentFormIfRequired((error) {});
            } finally {
              if (!done.isCompleted) done.complete();
            }
          },
          (error) {
            if (!done.isCompleted) done.complete();
          },
        );
        await done.future.timeout(const Duration(seconds: 20));
        if (!await ConsentInformation.instance.canRequestAds()) return;
        privacyRequired =
            await ConsentInformation.instance
                .getPrivacyOptionsRequirementStatus() ==
            PrivacyOptionsRequirementStatus.required;
      }
      await MobileAds.instance.initialize();
      if (_disposed) return;
      ready = true;
      notifyListeners();
      unawaited(preload());
      unawaited(preloadRewarded());
    } catch (error) {
      debugPrint('Ads initialization unavailable: $error');
    }
  }

  Future<void> preload() async {
    if (!ready ||
        _disposed ||
        _loading ||
        _interstitial != null ||
        interstitialId.isEmpty) {
      return;
    }
    _loading = true;
    try {
      await InterstitialAd.load(
        adUnitId: interstitialId,
        request: const AdRequest(),
        adLoadCallback: InterstitialAdLoadCallback(
          onAdLoaded: (ad) {
            _loading = false;
            if (_disposed) {
              ad.dispose();
              return;
            }
            _failures = 0;
            _interstitial = ad;
            debugPrint('Interstitial loaded');
          },
          onAdFailedToLoad: (error) {
            _loading = false;
            debugPrint('Interstitial unavailable: ${error.code}');
            if (!_disposed && ++_failures <= 3) {
              _retry?.cancel();
              _retry = Timer(
                Duration(seconds: 30 * _failures),
                () => unawaited(preload()),
              );
            }
          },
        ),
      );
    } catch (_) {
      _loading = false;
    }
  }

  Future<void> showAtBreak(int moves) async {
    cadence.completeRound(moves);
    if (moves < 3 ||
        !ready ||
        showing ||
        _disposed ||
        !cadence.eligible(DateTime.now())) {
      return;
    }
    final ad = _interstitial;
    if (ad == null) {
      unawaited(preload());
      return;
    }
    _interstitial = null;
    showing = true;
    final done = Completer<void>();
    void finish() {
      ad.dispose();
      showing = false;
      if (!done.isCompleted) done.complete();
      if (!_disposed) unawaited(preload());
    }

    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (_) => cadence.shown(DateTime.now()),
      onAdDismissedFullScreenContent: (_) => finish(),
      onAdFailedToShowFullScreenContent: (_, error) => finish(),
    );
    try {
      await ad.show();
      await done.future;
    } catch (_) {
      finish();
    }
  }

  Future<void> privacyOptions() async {
    if (!privacyRequired) return;
    await ConsentForm.showPrivacyOptionsForm((error) {});
    ready = await ConsentInformation.instance.canRequestAds();
    if (!_disposed) notifyListeners();
    _interstitial?.dispose();
    _interstitial = null;
    if (ready) unawaited(preload());
  }

  @override
  void dispose() {
    _disposed = true;
    _retry?.cancel();
    _interstitial?.dispose();
    _rewarded?.dispose();
    super.dispose();
  }
}
