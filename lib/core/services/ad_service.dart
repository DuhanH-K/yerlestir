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

enum AdPlatform { android, ios }

/// Keeps platform and build-mode ad IDs explicit and testable.
class AdUnitIds {
  static const _unset = '__UNSET__';
  static const _googleTestPublisher = 'ca-app-pub-3940256099942544/';

  static const iosBanner = 'ca-app-pub-4879558726064660/7172448351';
  static const iosInterstitial = 'ca-app-pub-4879558726064660/5643744260';
  static const iosRewarded = 'ca-app-pub-4879558726064660/2850059969';
  static const androidBanner = 'ca-app-pub-4879558726064660/3849898981';
  static const androidInterstitial = 'ca-app-pub-4879558726064660/5504752270';
  static const androidRewarded = 'ca-app-pub-4879558726064660/5103270903';

  static const iosTestBanner = 'ca-app-pub-3940256099942544/2435281174';
  static const iosTestInterstitial = 'ca-app-pub-3940256099942544/4411468910';
  static const iosTestRewarded = 'ca-app-pub-3940256099942544/1712485313';
  static const androidTestBanner = 'ca-app-pub-3940256099942544/9214589741';
  static const androidTestInterstitial =
      'ca-app-pub-3940256099942544/1033173712';
  static const androidTestRewarded = 'ca-app-pub-3940256099942544/5224354917';

  static String banner(AdPlatform platform, {required bool test}) => test
      ? (platform == AdPlatform.ios ? iosTestBanner : androidTestBanner)
      : _production(
          platform == AdPlatform.ios
              ? const String.fromEnvironment(
                  'ADMOB_IOS_BANNER_ID',
                  defaultValue: _unset,
                )
              : const String.fromEnvironment(
                  'ADMOB_BANNER_ID',
                  defaultValue: _unset,
                ),
          platform == AdPlatform.ios ? iosBanner : androidBanner,
          'banner',
        );

  static String interstitial(AdPlatform platform, {required bool test}) => test
      ? (platform == AdPlatform.ios
            ? iosTestInterstitial
            : androidTestInterstitial)
      : _production(
          platform == AdPlatform.ios
              ? const String.fromEnvironment(
                  'ADMOB_IOS_INTERSTITIAL_ID',
                  defaultValue: _unset,
                )
              : const String.fromEnvironment(
                  'ADMOB_INTERSTITIAL_ID',
                  defaultValue: _unset,
                ),
          platform == AdPlatform.ios ? iosInterstitial : androidInterstitial,
          'interstitial',
        );

  static String rewarded(AdPlatform platform, {required bool test}) => test
      ? (platform == AdPlatform.ios ? iosTestRewarded : androidTestRewarded)
      : _production(
          platform == AdPlatform.ios
              ? const String.fromEnvironment(
                  'ADMOB_IOS_REWARDED_ID',
                  defaultValue: _unset,
                )
              : const String.fromEnvironment(
                  'ADMOB_REWARDED_ID',
                  defaultValue: _unset,
                ),
          platform == AdPlatform.ios ? iosRewarded : androidRewarded,
          'rewarded',
        );

  static String _production(String override, String fallback, String format) {
    final value = override == _unset ? fallback : override.trim();
    if (value.isEmpty ||
        value.startsWith(_googleTestPublisher) ||
        value != fallback) {
      throw StateError(
        'Invalid production AdMob $format unit ID for this platform.',
      );
    }
    return value;
  }
}

class AdLoadState {
  bool isLoading = false;
  bool isReady = false;
  bool isShowing = false;

  bool beginLoad() {
    if (isLoading || isReady || isShowing) return false;
    isLoading = true;
    return true;
  }

  void loaded() {
    isLoading = false;
    isReady = true;
  }

  void failed() => isLoading = false;

  void reset() {
    isLoading = false;
    isReady = false;
    isShowing = false;
  }

  bool beginShow() {
    if (!isReady || isShowing) return false;
    isReady = false;
    isShowing = true;
    return true;
  }

  void finished() => isShowing = false;
}

class GameAds extends ChangeNotifier {
  GameAds({required this.enabled});
  final bool enabled;
  // A release build can never be switched to Google's demo units by CI flags.
  static const testMode =
      !kReleaseMode &&
      bool.fromEnvironment('ADS_TEST_MODE', defaultValue: true);
  static bool get isIOS => defaultTargetPlatform == TargetPlatform.iOS;
  static AdPlatform get platform => isIOS ? AdPlatform.ios : AdPlatform.android;
  static String get bannerId => AdUnitIds.banner(platform, test: testMode);
  static String get interstitialId =>
      AdUnitIds.interstitial(platform, test: testMode);
  final cadence = AdCadence(DateTime.now());
  bool ready = false,
      privacyRequired = false,
      _disposed = false,
      _loading = false;
  bool showing = false;
  InterstitialAd? _interstitial;
  RewardedAd? _rewarded;
  Future<void>? _rewardLoad;
  Future<void>? _initialization;
  DateTime? _nextIOSInterstitialLoad;
  final interstitialState = AdLoadState();
  static String get rewardedId => AdUnitIds.rewarded(platform, test: testMode);

  static void log(String format, String event) {
    if (kDebugMode) {
      debugPrint('[ADS][${isIOS ? 'iOS' : 'Android'}][$format] $event');
    }
  }

  static void logLoadError(String format, LoadAdError error) {
    if (!kDebugMode) return;
    log(format, 'failed');
    debugPrint('  code: ${error.code}');
    debugPrint('  domain: ${error.domain}');
    debugPrint('  message: ${error.message}');
    debugPrint('  responseInfo: ${error.responseInfo}');
  }

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
      log('Rewarded', 'load requested');
      await RewardedAd.load(
        adUnitId: rewardedId,
        request: const AdRequest(),
        rewardedAdLoadCallback: RewardedAdLoadCallback(
          onAdLoaded: (ad) {
            if (_disposed) {
              ad.dispose();
            } else {
              _rewarded = ad;
              log('Rewarded', 'loaded');
            }
            if (!done.isCompleted) done.complete();
          },
          onAdFailedToLoad: (error) {
            logLoadError('Rewarded', error);
            if (!done.isCompleted) done.complete();
          },
        ),
      );
      await done.future.timeout(const Duration(seconds: 10));
    } catch (error) {
      log('Rewarded', 'load exception: $error');
    }
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
      if (!_disposed && !isIOS) unawaited(preloadRewarded());
    }

    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (_) {
        log('Rewarded', 'shown');
        cadence.shown(DateTime.now());
      },
      onAdDismissedFullScreenContent: (_) {
        log('Rewarded', 'dismissed; earned=$earned');
        finish();
      },
      onAdImpression: (_) => log('Rewarded', 'impression'),
      onAdFailedToShowFullScreenContent: (_, error) {
        log('Rewarded', 'show failed: ${error.code} ${error.message}');
        finish();
      },
    );
    try {
      await ad.show(
        onUserEarnedReward: (_, reward) {
          earned = true;
          log('Rewarded', 'reward earned');
        },
      );
    } catch (_) {
      finish();
    }
    return done.future;
  }

  Timer? _retry;
  int _failures = 0;

  Future<void> initialize() => _initialization ??= _initialize();

  Future<void> _initialize() async {
    if (!enabled ||
        kIsWeb ||
        (defaultTargetPlatform != TargetPlatform.android &&
            defaultTargetPlatform != TargetPlatform.iOS)) {
      return;
    }
    try {
      if (!testMode) {
        log('UMP', 'consent info update requested');
        final done = Completer<void>();
        ConsentInformation.instance.requestConsentInfoUpdate(
          ConsentRequestParameters(),
          () async {
            try {
              await ConsentForm.loadAndShowConsentFormIfRequired((error) {
                if (error != null) log('UMP', 'form error: ${error.message}');
              });
            } finally {
              if (!done.isCompleted) done.complete();
            }
          },
          (error) {
            log('UMP', 'consent update error: ${error.message}');
            if (!done.isCompleted) done.complete();
          },
        );
        await done.future.timeout(const Duration(seconds: 20));
        if (!await ConsentInformation.instance.canRequestAds()) {
          log('UMP', 'canRequestAds=false; ad loading stopped');
          return;
        }
        privacyRequired =
            await ConsentInformation.instance
                .getPrivacyOptionsRequirementStatus() ==
            PrivacyOptionsRequirementStatus.required;
      }
      await MobileAds.instance.initialize();
      if (_disposed) return;
      ready = true;
      log('SDK', 'initialized once');
      notifyListeners();
      unawaited(preload());
      // On iOS rewarded is loaded only after an explicit user action.
      if (!isIOS) unawaited(preloadRewarded());
    } catch (error) {
      debugPrint('Ads initialization unavailable: $error');
    }
  }

  Future<void> preload() async {
    if (!ready ||
        _disposed ||
        _loading ||
        _interstitial != null ||
        interstitialId.isEmpty ||
        !interstitialState.beginLoad()) {
      return;
    }
    final now = DateTime.now();
    if (isIOS &&
        _nextIOSInterstitialLoad != null &&
        now.isBefore(_nextIOSInterstitialLoad!)) {
      interstitialState.failed();
      log('Interstitial', 'load skipped during iOS no-fill cooldown');
      return;
    }
    _loading = true;
    try {
      log('Interstitial', 'load requested');
      await InterstitialAd.load(
        adUnitId: interstitialId,
        request: const AdRequest(),
        adLoadCallback: InterstitialAdLoadCallback(
          onAdLoaded: (ad) {
            _loading = false;
            if (_disposed) {
              ad.dispose();
              interstitialState.reset();
              return;
            }
            interstitialState.loaded();
            _failures = 0;
            _nextIOSInterstitialLoad = null;
            _interstitial = ad;
            log('Interstitial', 'loaded');
          },
          onAdFailedToLoad: (error) {
            _loading = false;
            interstitialState.failed();
            logLoadError('Interstitial', error);
            if (isIOS) {
              // Avoid turning an iOS no-fill into several background requests.
              _nextIOSInterstitialLoad = DateTime.now().add(
                const Duration(minutes: 2),
              );
            } else if (!_disposed && ++_failures <= 3) {
              _retry?.cancel();
              _retry = Timer(
                Duration(seconds: 30 * _failures),
                () => unawaited(preload()),
              );
            }
          },
        ),
      );
    } catch (error) {
      _loading = false;
      interstitialState.failed();
      log('Interstitial', 'load exception: $error');
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
    if (!interstitialState.beginShow()) return;
    _interstitial = null;
    showing = true;
    final done = Completer<void>();
    void finish() {
      ad.dispose();
      showing = false;
      interstitialState.finished();
      if (!done.isCompleted) done.complete();
      if (!_disposed) unawaited(preload());
    }

    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (_) {
        log('Interstitial', 'shown');
        cadence.shown(DateTime.now());
      },
      onAdDismissedFullScreenContent: (_) {
        log('Interstitial', 'dismissed');
        finish();
      },
      onAdImpression: (_) => log('Interstitial', 'impression'),
      onAdFailedToShowFullScreenContent: (_, error) {
        log('Interstitial', 'show failed: ${error.code} ${error.message}');
        finish();
      },
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
    interstitialState.reset();
    if (ready) unawaited(preload());
  }

  @override
  void dispose() {
    _disposed = true;
    _retry?.cancel();
    _interstitial?.dispose();
    _rewarded?.dispose();
    interstitialState.reset();
    super.dispose();
  }
}
