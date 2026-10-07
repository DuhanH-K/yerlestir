import 'package:flutter_test/flutter_test.dart';
import 'package:yerlestir/core/services/ad_service.dart';

void main() {
  test('ads require real gameplay depth and a longer cooldown', () {
    final start = DateTime(2026);
    final cadence = AdCadence(start);

    cadence.completeRound(2);
    expect(cadence.eligible(start.add(const Duration(seconds: 1))), isFalse);

    cadence.completeRound(12);
    cadence.completeRound(12);
    expect(cadence.eligible(start.add(const Duration(seconds: 1))), isTrue);
    expect(cadence.eligible(start.add(const Duration(seconds: 89))), isTrue);

    cadence.shown(start.add(const Duration(seconds: 89)));
    expect(cadence.eligible(start.add(const Duration(seconds: 89))), isFalse);

    cadence.completeRound(12);
    cadence.completeRound(12);
    expect(cadence.eligible(start.add(const Duration(seconds: 178))), isFalse);
    expect(cadence.eligible(start.add(const Duration(seconds: 179))), isTrue);
  });

  test('platform IDs stay separated in debug and production', () {
    expect(AdUnitIds.banner(AdPlatform.ios, test: false), AdUnitIds.iosBanner);
    expect(
      AdUnitIds.interstitial(AdPlatform.ios, test: false),
      AdUnitIds.iosInterstitial,
    );
    expect(
      AdUnitIds.rewarded(AdPlatform.ios, test: false),
      AdUnitIds.iosRewarded,
    );
    expect(
      AdUnitIds.banner(AdPlatform.android, test: false),
      AdUnitIds.androidBanner,
    );
    expect(
      AdUnitIds.interstitial(AdPlatform.android, test: false),
      AdUnitIds.androidInterstitial,
    );
    expect(
      AdUnitIds.rewarded(AdPlatform.android, test: false),
      AdUnitIds.androidRewarded,
    );
    expect(
      AdUnitIds.banner(AdPlatform.ios, test: true),
      AdUnitIds.iosTestBanner,
    );
    expect(
      AdUnitIds.banner(AdPlatform.android, test: true),
      AdUnitIds.androidTestBanner,
    );
  });

  test('load state rejects duplicate load and ready requests', () {
    final state = AdLoadState();

    expect(state.beginLoad(), isTrue);
    expect(state.beginLoad(), isFalse);
    state.loaded();
    expect(state.beginLoad(), isFalse);
    expect(state.beginShow(), isTrue);
    expect(state.beginShow(), isFalse);
    state.finished();
    expect(state.beginLoad(), isTrue);
  });

  test('disabled ads do not initialize a platform SDK', () async {
    final ads = GameAds(enabled: false);
    await ads.initialize();
    expect(ads.ready, isFalse);
    ads.dispose();
  });
}
