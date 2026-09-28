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
import 'package:yerlestir/features/gameplay/application/game_session.dart';
import 'package:yerlestir/features/gameplay/domain/puzzle.dart';
import 'package:yerlestir/features/gameplay/presentation/board_view.dart';
import 'package:yerlestir/features/gameplay/presentation/line_burst.dart';
import 'package:yerlestir/features/gameplay/presentation/score_celebration.dart';
import 'package:yerlestir/core/widgets/blocks.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() {
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    for (final channel in [
      'xyz.luan/audioplayers.global',
      'xyz.luan/audioplayers.global/events',
    ]) {
      messenger.setMockMethodCallHandler(
        MethodChannel(channel),
        (_) async => null,
      );
    }
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
  });
  test('dense clears respect global particle cap and row/column geometry', () {
    final dense = ClearChoreography({
      for (var i = 0; i < 64; i++) i: i % 5 + 1,
    }, 'night');
    expect(dense.shards.length, lessThanOrEqualTo(168));
    expect(dense.lines.where((l) => l.vertical).length, 8);
    expect(dense.lines.where((l) => !l.vertical).length, 8);
    final vertical = ClearChoreography({
      for (var i = 0; i < 8; i++) i * 8 + 3: 1,
    }, 'default');
    expect(vertical.lines.single.vertical, isTrue);
    expect(vertical.starts[59], greaterThan(vertical.starts[3]!));
  });

  testWidgets('occupied drag preview preserves the real block underneath', (
    tester,
  ) async {
    final game = GameSession(mode: GameMode.classic, seed: 7);
    game.board[0] = 2;
    game.pieces = [shapes.firstWhere((s) => s.cells.length == 1), null, null];
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 320,
            height: 320,
            child: BoardView(
              game: game,
              selected: 0,
              skin: 'default',
              hint: (0, 0, 0),
              onDrop: (_, _, _) {},
            ),
          ),
        ),
      ),
    );
    final occupied = find.bySemanticsLabel('Row 1, column 1, filled');
    final tile = tester.widget<BlockTile>(
      find.descendant(of: occupied, matching: find.byType(BlockTile)),
    );
    expect(tile.value, 2);
    expect(tile.invalid, isFalse);
    expect(
      find.descendant(of: occupied, matching: find.byIcon(Icons.close_rounded)),
      findsOneWidget,
    );
    expect(game.board[0], 2);
  });

  for (final width in [320.0, 390.0]) {
    testWidgets(
      'clear card survives input unlock and next placement at width $width',
      (tester) async {
        tester.view.physicalSize = Size(width, width == 320 ? 568 : 844);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final preview = Platform.environment['UPDATE_PREVIEWS'] == '1';
        if (preview) {
          await tester.runAsync(() async {
            for (final name in ['Ahem', 'Roboto', 'Arial']) {
              final font = FontLoader(name)
                ..addFont(
                  File('C:/Windows/Fonts/arial.ttf')
                      .readAsBytes()
                      .then(ByteData.sublistView),
                );
              await font.load();
            }
            final icons = FontLoader('MaterialIcons')
              ..addFont(
                File(
                  'C:/Users/pc/flutter/bin/cache/artifacts/material_fonts/materialicons-regular.otf',
                ).readAsBytes().then(ByteData.sublistView),
              );
            await icons.load();
          });
        }
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
        final game = GameSession(mode: GameMode.classic, seed: 5);
        game.combo = 2;
        for (var row = 0; row < 2; row++) {
          for (var col = 0; col < 7; col++) {
            game.board[row * 8 + col] = (col % 5) + 1;
          }
        }
        game.pieces = [
          shapes.firstWhere((s) => s.width == 1 && s.height == 2),
          shapes.firstWhere((s) => s.cells.length == 1),
          shapes.firstWhere((s) => s.cells.length == 1),
        ];
        await container.read(progressProvider.notifier).saveSession(game);
        container.read(routerProvider).go('/game/classic/1');
        await tester.pumpAndSettle();

        Future<void> capture(String name) async {
          if (!preview) return;
          final boundary =
              boundaryKey.currentContext!.findRenderObject()!
                  as RenderRepaintBoundary;
          await tester.runAsync(() async {
            final image = await boundary.toImage(pixelRatio: 2);
            final bytes = await image.toByteData(
              format: ui.ImageByteFormat.png,
            );
            await Directory('output/game-feel').create(recursive: true);
            await File('output/game-feel/$name-${width.toInt()}.png')
                .writeAsBytes(bytes!.buffer.asUint8List());
            image.dispose();
          });
        }

        await capture('01-board');
        await tester.tap(find.byType(Draggable<int>).first);
        await tester.pump();
        await tester.tap(find.bySemanticsLabel('Row 1, column 8, empty'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 350));
        await capture('02-sweep');
        await tester.pump(const Duration(milliseconds: 450));
        await capture('03-combo');
        expect(find.text('MÜKEMMEL!'), findsNothing);
        expect(find.text('+500'), findsNWidgets(2)); // Outline + foreground.
        final label = find.byKey(const ValueKey('compact-clear-label'));
        expect(tester.getSize(label).height, lessThanOrEqualTo(66));
        expect(tester.getSize(label).width, lessThanOrEqualTo(180));
        expect(
          find.descendant(of: label, matching: find.byType(Container)),
          findsNothing,
        );
        final before = tester
            .widget<BoardView>(find.byType(BoardView))
            .game
            .moves;
        // The short text presentation must not block the next move.
        await tester.tap(find.byType(Draggable<int>).first);
        await tester.pump();
        await tester.tap(find.bySemanticsLabel('Row 3, column 1, empty'));
        await tester.pump();
        expect(
          tester.widget<BoardView>(find.byType(BoardView)).game.moves,
          before + 1,
        );
        expect(tester.widget<LineBurst>(find.byType(LineBurst)).points, 500);
        await tester.pump(const Duration(milliseconds: 600));
        await capture('04-label-gone');
        expect(find.byKey(const ValueKey('compact-clear-label')), findsNothing);
        expect(find.byType(LastMoveReceipt), findsOneWidget);
        await tester.pumpAndSettle();
        expect(find.byType(LineBurst), findsNothing);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
      },
    );
  }

  testWidgets('reduced motion still presents score and disposes cleanly', (
    tester,
  ) async {
    var completed = false;
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: Scaffold(
            body: SizedBox(
              width: 200,
              height: 200,
              child: LineBurst(
                cells: {for (var i = 0; i < 8; i++) i: 1},
                points: 90,
                onEnd: () => completed = true,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 800));
    expect(find.text('+90'), findsNWidgets(2));
    expect(find.text('×1'), findsNothing);
    await tester.pumpAndSettle();
    expect(completed, isTrue);
    await tester.pumpWidget(const SizedBox());
    expect(tester.takeException(), isNull);
  });
}
