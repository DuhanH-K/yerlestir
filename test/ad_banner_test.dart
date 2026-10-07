import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
// ignore: implementation_imports
import 'package:google_mobile_ads/src/ad_instance_manager.dart';
import 'package:yerlestir/core/services/ad_service.dart';
import 'package:yerlestir/core/widgets/ad_banner.dart';

void main() {
  for (final platform in [TargetPlatform.android, TargetPlatform.iOS]) {
    testWidgets(
      '$platform banner rebuild and stale size completion keep one current load',
      (tester) async {
        debugDefaultTargetPlatformOverride = platform;
        final calls = <MethodCall>[];
        final sizes = <int, Completer<int>>{};
        final messenger =
            TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
        messenger.setMockMethodCallHandler(instanceManager.channel, (
          call,
        ) async {
          calls.add(call);
          if (call.method == 'AdSize#getAnchoredAdaptiveBannerAdSize') {
            final width = (call.arguments as Map)['width'] as int;
            return (sizes[width] = Completer<int>()).future;
          }
          return null;
        });
        final ads = GameAds(enabled: false)..ready = true;
        Widget page(double width) => ProviderScope(
          overrides: [adProvider.overrideWithValue(ads)],
          child: MaterialApp(
            home: MediaQuery(
              data: MediaQueryData(size: Size(width, 700)),
              child: const Scaffold(bottomNavigationBar: GameBanner()),
            ),
          ),
        );
        await tester.pumpWidget(page(320));
        await tester.pump();
        await tester.pumpWidget(page(320));
        expect(sizes.keys, [320]);
        await tester.pumpWidget(page(390));
        await tester.pump();
        sizes[320]!.complete(50);
        await tester.pump();
        expect(calls.where((c) => c.method == 'loadBannerAd'), isEmpty);
        sizes[390]!.complete(60);
        await tester.pump();
        final load = calls.singleWhere((c) => c.method == 'loadBannerAd');
        final ad =
            instanceManager.adFor((load.arguments as Map)['adId'])! as BannerAd;
        expect(ad.size.width, 390);
        await tester.pumpWidget(page(390));
        expect(calls.where((c) => c.method == 'loadBannerAd'), hasLength(1));
        await tester.pumpWidget(page(400));
        await tester.pump();
        // Late load from the old width is disposed and cannot clear current loading.
        ad.listener.onAdLoaded!(ad);
        await tester.pump();
        sizes[400]!.complete(60);
        await tester.pump();
        expect(calls.where((c) => c.method == 'loadBannerAd'), hasLength(2));
        expect(
          calls.where(
            (c) =>
                c.method == 'disposeAd' &&
                (c.arguments as Map)['adId'] == (load.arguments as Map)['adId'],
          ),
          hasLength(1),
        );
        await tester.pumpWidget(const SizedBox());
        await tester.pump();
        ads.dispose();
        debugDefaultTargetPlatformOverride = null;
        messenger.setMockMethodCallHandler(instanceManager.channel, null);
      },
    );
  }
}
