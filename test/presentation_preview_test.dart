import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yerlestir/app/app.dart';
import 'package:yerlestir/features/progress/progress.dart';

void main() {
  testWidgets('pause and reward presentations fit and return to the game', (
    tester,
  ) async {
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(
      const MethodChannel('xyz.luan/audioplayers.global'),
      (_) async => null,
    );
    messenger.setMockMethodCallHandler(
      const MethodChannel('xyz.luan/audioplayers.global/events'),
      (_) async => null,
    );
    messenger.setMockMethodCallHandler(
      const MethodChannel('xyz.luan/audioplayers'),
      (call) async {
        final id = (call.arguments as Map?)?['playerId'];
        if (id != null) {
          messenger.setMockMethodCallHandler(
            MethodChannel('xyz.luan/audioplayers/events/$id'),
            (_) async => null,
          );
        }
        return null;
      },
    );
    if (Platform.environment['UPDATE_PREVIEWS'] == '1') {
      await tester.runAsync(() async {
        for (final entry in {
          'Ahem': 'C:/Windows/Fonts/arial.ttf',
          'Roboto': 'C:/Windows/Fonts/arial.ttf',
          'Arial': 'C:/Windows/Fonts/arial.ttf',
          'MaterialIcons': 'C:/Users/pc/flutter/bin/cache/artifacts/material_fonts/materialicons-regular.otf',
        }.entries) {
          final loader = FontLoader(entry.key)
            ..addFont(
              File(entry.value).readAsBytes().then(ByteData.sublistView),
            );
          await loader.load();
        }
      });
    }
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final container = ProviderContainer(
      overrides: [preferencesProvider.overrideWithValue(prefs)],
    );
    addTearDown(container.dispose);
    final boundaryKey = GlobalKey();
    await tester.pumpWidget(
      RepaintBoundary(
        key: boundaryKey,
        child: UncontrolledProviderScope(
          container: container,
          child: const YerlestirApp(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();
    Future<void> capture(String name) async {
      if (Platform.environment['UPDATE_PREVIEWS'] != '1') return;
      final boundary =
          boundaryKey.currentContext!.findRenderObject()!
              as RenderRepaintBoundary;
      await tester.runAsync(() async {
        final image = await boundary.toImage();
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        await Directory('output/previews').create(recursive: true);
        await File('output/previews/$name.png')
            .writeAsBytes(bytes!.buffer.asUint8List());
        image.dispose();
      });
    }

    container.read(routerProvider).go('/game/classic/1');
    await tester.pumpAndSettle();
    await capture('game');
    await tester.tap(find.byTooltip('Duraklat'));
    await tester.pumpAndSettle();
    expect(find.text('Oyun Duraklatıldı'), findsOneWidget);
    await capture('pause');
    await tester.tap(find.text('Devam Et'));
    await tester.pumpAndSettle();
    expect(find.text('Oyun Duraklatıldı'), findsNothing);
    container.read(routerProvider).go('/reward');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ödülü Al'));
    await tester.pumpAndSettle();
    expect(find.text('+20'), findsOneWidget);
    await capture('reward');
    await tester.tap(find.text('Harika!'));
    await tester.pumpAndSettle();
    expect(container.read(progressProvider).coins, 20);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });
}
