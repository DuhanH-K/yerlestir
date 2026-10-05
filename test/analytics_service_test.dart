// ignore_for_file: depend_on_referenced_packages
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_core_platform_interface/firebase_core_platform_interface.dart';
import 'package:firebase_core_platform_interface/src/pigeon/messages.pigeon.dart'
    as core;
import 'package:firebase_analytics_platform_interface/src/pigeon/messages.pigeon.dart'
    as analytics;
import 'package:yerlestir/core/services/analytics_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const coreChannel = BasicMessageChannel<Object?>(
    'dev.flutter.pigeon.firebase_core_platform_interface.FirebaseCoreHostApi.initializeCore',
    core.FirebaseCoreHostApi.pigeonChannelCodec,
  );
  const analyticsChannel = BasicMessageChannel<Object?>(
    'dev.flutter.pigeon.firebase_analytics_platform_interface.FirebaseAnalyticsHostApi.setAnalyticsCollectionEnabled',
    analytics.FirebaseAnalyticsHostApi.pigeonChannelCodec,
  );
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  setUp(() {
    MethodChannelFirebase.isCoreInitialized = false;
    MethodChannelFirebase.appInstances.clear();
  });
  tearDown(() {
    debugDefaultTargetPlatformOverride = null;
    messenger.setMockDecodedMessageHandler(coreChannel, null);
    messenger.setMockDecodedMessageHandler(analyticsChannel, null);
    MethodChannelFirebase.isCoreInitialized = false;
    MethodChannelFirebase.appInstances.clear();
  });
  test('Android never initializes Firebase or enables Analytics', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    messenger.setMockDecodedMessageHandler(coreChannel, (_) async {
      fail('Android must not initialize Firebase');
    });
    expect(await IosAnalytics().initialize(), isFalse);
  });
  test(
    'missing iOS config fails safely without Analytics collection',
    () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      messenger.setMockDecodedMessageHandler(
        coreChannel,
        (_) async => [<Object?>[]],
      );
      messenger.setMockDecodedMessageHandler(analyticsChannel, (_) async {
        fail('Missing Firebase config must not enable Analytics');
      });
      expect(await IosAnalytics().initialize(), isFalse);
    },
  );
  test(
    'valid native iOS config initializes once and enables collection',
    () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      var initializations = 0, collectionCalls = 0;
      messenger.setMockDecodedMessageHandler(coreChannel, (_) async {
        initializations++;
        return [
          [
            core.CoreInitializeResponse(
              name: '[DEFAULT]',
              // Synthetic test response only; never a production config file.
              options: core.CoreFirebaseOptions(
                apiKey: 'test-only',
                appId: 'test-only',
                messagingSenderId: 'test-only',
                projectId: 'test-only',
                iosBundleId: 'com.yerlestir.game.yerlestir',
              ),
              pluginConstants: {},
            ),
          ],
        ];
      });
      messenger.setMockDecodedMessageHandler(analyticsChannel, (message) async {
        expect(message, [true]);
        collectionCalls++;
        return [null];
      });
      final service = IosAnalytics();
      expect(await service.initialize(), isTrue);
      expect(await service.initialize(), isTrue);
      expect(initializations, 1);
      expect(collectionCalls, 1);
    },
  );
}
