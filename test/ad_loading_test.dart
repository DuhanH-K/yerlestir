import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
// Exercise the plugin objects and their native load callbacks without live ads.
// ignore: implementation_imports
import 'package:google_mobile_ads/src/ad_instance_manager.dart';
import 'package:yerlestir/core/services/ad_service.dart';

void main() {
  for (final platform in [TargetPlatform.android, TargetPlatform.iOS]) {
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
