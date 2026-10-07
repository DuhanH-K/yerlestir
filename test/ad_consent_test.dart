import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
// ignore: implementation_imports
import 'package:google_mobile_ads/src/ad_instance_manager.dart';
// ignore: implementation_imports
import 'package:google_mobile_ads/src/ump/user_messaging_codec.dart';
import 'package:yerlestir/core/services/ad_service.dart';

void main() {
  final ump = MethodChannel(
    'plugins.flutter.io/google_mobile_ads/ump',
    StandardMethodCodec(UserMessagingCodec()),
  );
  for (final platform in [TargetPlatform.android, TargetPlatform.iOS]) {
    testWidgets(
      '$platform one UMP flow while form stays open beyond 20 seconds',
      (tester) async {
        if (GameAds.testMode) {
          return;
        } // Run suite with --dart-define=ADS_TEST_MODE=false.
        debugDefaultTargetPlatformOverride = platform;
        final calls = <MethodCall>[];
        final form = Completer<void>();
        final messenger =
            TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
        messenger.setMockMethodCallHandler(ump, (call) async {
          calls.add(call);
          if (call.method.endsWith('loadAndShowConsentFormIfRequired')) {
            await form.future;
            return null;
          }
          if (call.method.endsWith('canRequestAds')) return true;
          if (call.method.endsWith('getPrivacyOptionsRequirementStatus')) {
            return 1;
          }
          return null;
        });
        messenger.setMockMethodCallHandler(instanceManager.channel, (
          call,
        ) async {
          calls.add(call);
          if (call.method == 'MobileAds#initialize') {
            return InitializationStatus({});
          }
          return null;
        });
        final ads = GameAds(enabled: true);
        final first = ads.initialize();
        await tester.pump();
        await tester.pump(const Duration(seconds: 30));
        final second = ads.initialize();
        ads.didChangeAppLifecycleState(AppLifecycleState.resumed);
        await tester.pump();
        expect(
          calls.where((c) => c.method.endsWith('requestConsentInfoUpdate')),
          hasLength(1),
        );
        expect(calls.where((c) => c.method.startsWith('load')), isEmpty);
        expect(calls.where((c) => c.method == 'MobileAds#initialize'), isEmpty);
        form.complete();
        await tester.pump();
        await Future.wait([first, second]);
        expect(ads.ready, isTrue);
        expect(
          calls.where((c) => c.method == 'MobileAds#initialize'),
          hasLength(1),
        );
        expect(
          calls.where((c) => c.method == 'loadInterstitialAd'),
          hasLength(1),
        );
        expect(calls.where((c) => c.method == 'loadRewardedAd'), hasLength(1));
        ads.dispose();
        debugDefaultTargetPlatformOverride = null;
        messenger.setMockMethodCallHandler(ump, null);
        messenger.setMockMethodCallHandler(instanceManager.channel, null);
      },
    );
    testWidgets('$platform denied consent blocks all native ad requests', (
      tester,
    ) async {
      if (GameAds.testMode) return;
      debugDefaultTargetPlatformOverride = platform;
      final calls = <MethodCall>[];
      final messenger =
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
      messenger.setMockMethodCallHandler(ump, (call) async {
        if (call.method.endsWith('canRequestAds')) return false;
        return null;
      });
      messenger.setMockMethodCallHandler(instanceManager.channel, (call) async {
        calls.add(call);
        return null;
      });
      final ads = GameAds(enabled: true);
      await ads.initialize();
      await ads.preload();
      await ads.preloadRewarded();
      expect(await ads.showContinueReward(), isFalse);
      await ads.showAtBreak(3);
      expect(ads.ready, isFalse);
      expect(calls, isEmpty);
      ads.dispose();
      debugDefaultTargetPlatformOverride = null;
      messenger.setMockMethodCallHandler(ump, null);
      messenger.setMockMethodCallHandler(instanceManager.channel, null);
    });
    testWidgets(
      '$platform privacy form resume and stale rewarded result do not mix epochs',
      (tester) async {
        debugDefaultTargetPlatformOverride = platform;
        final calls = <MethodCall>[];
        final privacy = Completer<void>();
        final messenger =
            TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
        messenger.setMockMethodCallHandler(ump, (call) async {
          calls.add(call);
          if (call.method.endsWith('showPrivacyOptionsForm')) {
            await privacy.future;
            return null;
          }
          if (call.method.endsWith('canRequestAds')) return true;
          return null;
        });
        messenger.setMockMethodCallHandler(instanceManager.channel, (
          call,
        ) async {
          calls.add(call);
          return null;
        });
        final ads = GameAds(enabled: true)
          ..ready = true
          ..privacyRequired = true;
        final pending = ads.preloadRewarded();
        await tester.pump();
        final load = calls.singleWhere((c) => c.method == 'loadRewardedAd');
        final stale =
            instanceManager.adFor((load.arguments as Map)['adId'])!
                as RewardedAd;
        final update = ads.privacyOptions();
        await tester.pump();
        ads.didChangeAppLifecycleState(AppLifecycleState.resumed);
        await ads.initialize();
        expect(await ads.showContinueReward(), isFalse);
        expect(
          calls.where((c) => c.method.endsWith('requestConsentInfoUpdate')),
          isEmpty,
        );
        privacy.complete();
        await tester.pump();
        await update;
        stale.rewardedAdLoadCallback.onAdLoaded(stale);
        await tester.pump();
        await pending;
        expect(
          calls.where(
            (c) =>
                c.method == 'disposeAd' &&
                (c.arguments as Map)['adId'] == (load.arguments as Map)['adId'],
          ),
          hasLength(1),
        );
        expect(calls.where((c) => c.method == 'loadRewardedAd'), hasLength(2));
        expect(calls.where((c) => c.method == 'showAdWithoutView'), isEmpty);
        ads.dispose();
        debugDefaultTargetPlatformOverride = null;
        messenger.setMockMethodCallHandler(ump, null);
        messenger.setMockMethodCallHandler(instanceManager.channel, null);
      },
    );
  }
}
