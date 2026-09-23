import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yerlestir/app/app.dart';
import 'package:yerlestir/features/progress/progress.dart';
import 'package:yerlestir/features/gameplay/application/game_session.dart';
import 'package:yerlestir/features/gameplay/domain/puzzle.dart';
import 'package:yerlestir/features/gameplay/presentation/result_screen.dart';

void main() {
  for (final size in [
    const Size(320, 568),
    const Size(390, 844),
    const Size(568, 320),
  ]) {
    testWidgets('complete menus fit $size with safe area', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      tester.view.padding = const FakeViewPadding(top: 24, bottom: 24);
      addTearDown(tester.view.reset);
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final container = ProviderContainer(
        overrides: [preferencesProvider.overrideWithValue(prefs)],
      );
      addTearDown(container.dispose);
      const capture = bool.fromEnvironment('CAPTURE');
      if (capture) {
        final loader = FontLoader('Arial')
          ..addFont(
            File('C:/Windows/Fonts/arial.ttf')
                .readAsBytes()
                .then((b) => ByteData.sublistView(b)),
          );
        await tester.runAsync(() => loader.load());
      }
      final key = GlobalKey();
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: RepaintBoundary(key: key, child: const YerlestirApp()),
        ),
      );
      await tester.pumpAndSettle();
      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle();
      for (final route in ['/', '/journey', '/shop', '/result']) {
        container
            .read(routerProvider)
            .go(
              route,
              extra: route == '/result'
                  ? GameResult(
                      GameSession(mode: GameMode.journey)..score = 400,
                      70,
                    )
                  : null,
            );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: '$size $route');
        for (final element in find.byType(Scrollable).evaluate()) {
          final state = (element as StatefulElement).state as ScrollableState;
          expect(
            state.position.maxScrollExtent,
            closeTo(0, 0.001),
            reason: '$size $route must not scroll',
          );
        }
        if (route == '/result') {
          expect(find.textContaining('En iyi kombo'), findsNothing);
          expect(find.text('Ana Sayfa').hitTestable(), findsOneWidget);
          expect(find.text('Sonraki').hitTestable(), findsOneWidget);
        }
        if (capture && size.width == 320) {
          await tester.runAsync(() async {
            final boundary =
                key.currentContext!.findRenderObject()!
                    as RenderRepaintBoundary;
            final image = await boundary.toImage(pixelRatio: 2);
            final bytes = await image.toByteData(
              format: ui.ImageByteFormat.png,
            );
            await Directory('output/screens').create(recursive: true);
            await File(
              'output/screens/${route == '/' ? 'home' : route.substring(1)}.png',
            ).writeAsBytes(bytes!.buffer.asUint8List());
            image.dispose();
          });
        }
      }
      await tester.pumpWidget(const SizedBox());
    });
  }
}
