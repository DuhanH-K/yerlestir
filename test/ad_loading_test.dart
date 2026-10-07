import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
// Exercise the plugin objects and their native load callbacks without live ads.
// ignore: implementation_imports
import 'package:google_mobile_ads/src/ad_instance_manager.dart';
import 'package:yerlestir/core/services/ad_service.dart';

void main() {
  for (final platform in [TargetPlatform.android, TargetPlatform.iOS]) {
    for (final blocked in ['consent_changed', 'background']) {
      testWidgets(
        '$platform does not show rewarded after $blocked during load',
        (tester) async {
          debugDefaultTargetPlatformOverride = platform;
          final calls = <MethodCall>[];
          final messenger =
              TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
          messenger.setMockMethodCallHandler(instanceManager.channel, (
            call,
          ) async {
            calls.add(call);
            return null;
          });
          final ads = GameAds(enabled: true)..ready = true;
          final result = ads.showContinueReward();
          await tester.pump();
          final load = calls.singleWhere((c) => c.method == 'loadRewardedAd');
          final ad =
              instanceManager.adFor((load.arguments as Map)['adId'])!
                  as RewardedAd;
          if (blocked == 'consent_changed') {
            ads.ready = false;
          } else {
            tester.binding.handleAppLifecycleStateChanged(
              AppLifecycleState.paused,
            );
          }
          ad.rewardedAdLoadCallback.onAdLoaded(ad);
          await tester.pump();
          expect(await result, isFalse);
          expect(calls.where((c) => c.method == 'showAdWithoutView'), isEmpty);
          ads.dispose();
          tester.binding.handleAppLifecycleStateChanged(
            AppLifecycleState.resumed,
          );
          debugDefaultTargetPlatformOverride = null;
          messenger.setMockMethodCallHandler(instanceManager.channel, null);
        },
      );
    }
    testWidgets(
      '$platform failed show preserves cadence and preloads one replacement',
      (tester) async {
        debugDefaultTargetPlatformOverride = platform;
        final calls = <MethodCall>[];
        final messenger =
            TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
        messenger.setMockMethodCallHandler(instanceManager.channel, (
          call,
        ) async {
          calls.add(call);
          return null;
        });
        final ads = GameAds(enabled: true)..ready = true;
        await ads.preload();
        final load = calls.singleWhere((c) => c.method == 'loadInterstitialAd');
        final ad =
            instanceManager.adFor((load.arguments as Map)['adId'])!
                as InterstitialAd;
        ad.adLoadCallback.onAdLoaded(ad);
        await ads.showAtBreak(3); // First round: keep the loaded ad.
        expect(calls.where((c) => c.method == 'disposeAd'), isEmpty);
        final show = ads.showAtBreak(3);
        await tester.pump();
        expect(
          calls.where((c) => c.method == 'showAdWithoutView'),
          hasLength(1),
        );
        await ads.showAtBreak(3); // Cannot show the same ad twice.
        expect(
          calls.where((c) => c.method == 'showAdWithoutView'),
          hasLength(1),
        );
        ad.fullScreenContentCallback!.onAdFailedToShowFullScreenContent!(
          ad,
          AdError(1, 'test', 'Failed'),
        );
        await tester.pump();
        await show;
        expect(ads.cadence.lastShown, isNull);
        expect(
          calls.where((c) => c.method == 'loadInterstitialAd'),
          hasLength(2),
        );
        ad.fullScreenContentCallback!.onAdDismissedFullScreenContent!(ad);
        await tester.pump();
        expect(
          calls.where((c) => c.method == 'loadInterstitialAd'),
          hasLength(2),
        );
        ads.dispose();
        debugDefaultTargetPlatformOverride = null;
        messenger.setMockMethodCallHandler(instanceManager.channel, null);
      },
    );
    testWidgets('$platform reward requires earned callback and dismissal', (
      tester,
    ) async {
      debugDefaultTargetPlatformOverride = platform;
      final calls = <MethodCall>[];
      final messenger =
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
      messenger.setMockMethodCallHandler(instanceManager.channel, (call) async {
        calls.add(call);
        return null;
      });
      final ads = GameAds(enabled: true)..ready = true;
      final pending = ads.preloadRewarded();
      await tester.pump();
      final load = calls.singleWhere((c) => c.method == 'loadRewardedAd');
      final ad =
          instanceManager.adFor((load.arguments as Map)['adId'])! as RewardedAd;
      ad.rewardedAdLoadCallback.onAdLoaded(ad);
      await pending;
      bool? earned;
      final show = ads.showContinueReward().then((value) => earned = value);
      await tester.pump();
      expect(earned, isNull);
      ad.onUserEarnedRewardCallback!(ad, RewardItem(1, 'hint'));
      ad.onUserEarnedRewardCallback!(ad, RewardItem(1, 'hint'));
      expect(earned, isNull);
      ad.fullScreenContentCallback!.onAdDismissedFullScreenContent!(ad);
      ad.fullScreenContentCallback!.onAdDismissedFullScreenContent!(ad);
      await tester.pump();
      await show;
      expect(earned, isTrue);
      expect(calls.where((c) => c.method == 'disposeAd'), hasLength(1));
      expect(calls.where((c) => c.method == 'loadRewardedAd'), hasLength(2));
      ads.dispose();
      debugDefaultTargetPlatformOverride = null;
      messenger.setMockMethodCallHandler(instanceManager.channel, null);
    });
    testWidgets(
      '$platform keeps one pending rewarded request after UI timeout',
      (tester) async {
        debugDefaultTargetPlatformOverride = platform;
        final calls = <MethodCall>[];
        final messenger =
            TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
        messenger.setMockMethodCallHandler(instanceManager.channel, (
          call,
        ) async {
          calls.add(call);
          return null;
        });
        final ads = GameAds(enabled: true)..ready = true;
        addTearDown(() {
          debugDefaultTargetPlatformOverride = null;
          messenger.setMockMethodCallHandler(instanceManager.channel, null);
        });
        var result = true;
        final show = ads.showContinueReward().then((value) => result = value);
        await tester.pump();
        await tester.pump(const Duration(seconds: 11));
        await show;
        expect(result, isFalse);
        final pending = ads.preloadRewarded();
        await tester.pump();
        final loads = calls.where((c) => c.method == 'loadRewardedAd').toList();
        expect(loads, hasLength(1));
        final ad =
            instanceManager.adFor((loads.single.arguments as Map)['adId'])!
                as RewardedAd;
        ad.rewardedAdLoadCallback.onAdLoaded(ad);
        await tester.pump();
        await pending;
        await ads.preloadRewarded();
        expect(calls.where((c) => c.method == 'loadRewardedAd'), hasLength(1));
        expect(calls.where((c) => c.method == 'showAdWithoutView'), isEmpty);
        ads.dispose();
        debugDefaultTargetPlatformOverride = null;
      },
    );
    testWidgets(
      '$platform deduplicates interstitial loads and backs off failures',
      (tester) async {
        debugDefaultTargetPlatformOverride = platform;
        final calls = <MethodCall>[];
        final messenger =
            TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
        messenger.setMockMethodCallHandler(instanceManager.channel, (
          call,
        ) async {
          calls.add(call);
          return null;
        });
        final ads = GameAds(enabled: true)..ready = true;
        addTearDown(() {
          debugDefaultTargetPlatformOverride = null;
          messenger.setMockMethodCallHandler(instanceManager.channel, null);
        });
        await ads.preload();
        await ads.preload();
        final loads = calls
            .where((c) => c.method == 'loadInterstitialAd')
            .toList();
        expect(loads, hasLength(1));
        final ad =
            instanceManager.adFor((loads.single.arguments as Map)['adId'])!
                as InterstitialAd;
        ad.adLoadCallback.onAdFailedToLoad(
          LoadAdError(3, 'test', 'No fill', null),
        );
        await ad.dispose();
        await ads.preload();
        expect(
          calls.where((c) => c.method == 'loadInterstitialAd'),
          hasLength(1),
        );
        expect(ads.interstitialState.isLoading, isFalse);
        ads.dispose();
        debugDefaultTargetPlatformOverride = null;
      },
    );
  }
}
