import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yerlestir/app/app.dart';
import 'package:yerlestir/features/progress/progress.dart';
import 'package:yerlestir/features/gameplay/presentation/board_view.dart';
import 'package:yerlestir/features/gameplay/application/game_session.dart';
import 'package:yerlestir/features/gameplay/domain/puzzle.dart';
import 'package:yerlestir/features/gameplay/presentation/line_burst.dart';
import 'package:yerlestir/features/gameplay/presentation/game_ending.dart';
import 'package:yerlestir/core/widgets/shake_feedback.dart';

void main() {
  Future<ProviderContainer> launch(
    WidgetTester tester, {
    Size size = const Size(390, 844),
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final container = ProviderContainer(
      overrides: [preferencesProvider.overrideWithValue(prefs)],
    );
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const YerlestirApp(),
      ),
    );
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();
    return container;
  }

  testWidgets('home and each destination render on a small phone', (
    tester,
  ) async {
    final c = await launch(tester, size: const Size(360, 740));
    expect(find.text('Oyna'), findsOneWidget);
    expect(tester.takeException(), isNull);
    for (final path in [
      '/journey',
      '/collection',
      '/shop',
      '/settings',
      '/reward',
      '/game/classic/1',
    ]) {
      c.read(routerProvider).go(path);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: path);
    }
    expect(find.byType(BoardView), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });
  testWidgets(
    'game board, pieces and lamp fit without scrolling on short screens',
    (tester) async {
      final c = await launch(tester, size: const Size(320, 568));
      for (final mode in ['classic', 'daily', 'journey']) {
        c.read(routerProvider).go('/game/$mode/1');
        await tester.pumpAndSettle();
        expect(find.byType(SingleChildScrollView), findsNothing);
        final board = tester.getRect(find.byType(BoardView));
        final tray = tester.getRect(find.byType(PieceTray));
        final lamp = tester.getRect(find.byKey(const ValueKey('hint-lamp')));
        expect(board.width, greaterThan(200));
        expect(board.bottom, lessThanOrEqualTo(tray.top));
        expect(tray.bottom, lessThanOrEqualTo(lamp.top));
        expect(lamp.bottom, lessThanOrEqualTo(568));
        expect(tester.takeException(), isNull);
      }
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets('all main menus fit on a 320 by 568 phone', (tester) async {
    final c = await launch(tester, size: const Size(320, 568));
    for (final path in ['/', '/settings', '/reward', '/shop']) {
      c.read(routerProvider).go(path);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: path);
      final scrollables = tester.stateList<ScrollableState>(
        find.byType(Scrollable),
      );
      for (final scroll in scrollables) {
        expect(
          scroll.position.maxScrollExtent,
          lessThanOrEqualTo(1),
          reason: path,
        );
      }
    }
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('daily reward button grants once and disables', (tester) async {
    final c = await launch(tester);
    c.read(routerProvider).go('/reward');
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Ödülü Al'),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Ödülü Al'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ödülü Al'));
    await tester.pumpAndSettle();
    expect(c.read(progressProvider).coins, 20);
    expect(find.text('Ödül Alındı'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });
  testWidgets('tap selected piece then board places and saves it', (
    tester,
  ) async {
    final c = await launch(tester);
    c.read(routerProvider).go('/game/classic/1');
    await tester.pumpAndSettle();
    final piece = find.byType(Draggable<int>).first;
    await tester.ensureVisible(piece);
    await tester.tap(piece);
    await tester.pumpAndSettle();
    final cell = find.bySemanticsLabel('Row 1, column 1, empty');
    await tester.ensureVisible(cell);
    await tester.tap(cell);
    await tester.pumpAndSettle();
    expect(c.read(progressProvider).sessions['classic']['moves'], 1);
    expect(
      c.read(progressProvider).sessions['classic']['score'],
      greaterThan(0),
    );
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });
  testWidgets('dragging a piece previews and commits its placement', (
    tester,
  ) async {
    final c = await launch(tester);
    c.read(routerProvider).go('/game/classic/1');
    await tester.pumpAndSettle();
    final piece = find.byType(Draggable<int>).first;
    final target = find.bySemanticsLabel('Row 1, column 1, empty');
    final from = tester.getCenter(piece);
    final tray = tester.widget<PieceTray>(find.byType(PieceTray));
    final shape = tray.game.pieces.first!;
    final to =
        tester.getTopLeft(target) +
        Offset(
          shape.width * tray.boardCell / 2,
          shape.height * tray.boardCell + dragLift,
        );
    await tester.dragFrom(from, to - from);
    await tester.pumpAndSettle();
    expect(c.read(progressProvider).sessions['classic']['moves'], 1);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });
  testWidgets(
    'five-wide piece drops on bottom row even with finger below board',
    (tester) async {
      final c = await launch(tester);
      final g = GameSession(mode: GameMode.classic, seed: 5);
      final wide = shapes.firstWhere((s) => s.width == 5 && s.height == 1);
      g.pieces = [wide, shapes[0], shapes[0]];
      await c.read(progressProvider.notifier).saveSession(g);
      c.read(routerProvider).go('/game/classic/1');
      await tester.pumpAndSettle();
      final tray = tester.widget<PieceTray>(find.byType(PieceTray));
      final cell = find.bySemanticsLabel('Row 8, column 1, empty');
      final from = tester.getCenter(find.byType(Draggable<int>).first);
      final to =
          tester.getTopLeft(cell) +
          Offset(wide.width * tray.boardCell / 2, tray.boardCell + dragLift);
      expect(
        to.dy,
        greaterThan(tester.getBottomRight(find.byType(BoardView)).dy),
      );
      await tester.dragFrom(from, to - from);
      await tester.pumpAndSettle();
      final saved = c.read(progressProvider).sessions['classic'];
      expect(saved['moves'], 1);
      expect(
        (saved['board'] as List).sublist(56, 61),
        everyElement(wide.color),
      );
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets('pause exits home and resumes the exact saved score', (
    tester,
  ) async {
    final c = await launch(tester);
    c.read(routerProvider).go('/game/classic/1');
    await tester.pumpAndSettle();
    await tester.tap(find.byType(Draggable<int>).first);
    await tester.pump();
    await tester.tap(find.bySemanticsLabel('Row 1, column 1, empty'));
    await tester.pumpAndSettle();
    final score = c.read(progressProvider).sessions['classic']['score'];
    await tester.tap(find.byTooltip('Duraklat'));
    await tester.pumpAndSettle();
    expect(find.text('Oyun Duraklatıldı'), findsOneWidget);
    await tester.tap(find.text('Kaydet ve Ana Sayfa'));
    await tester.pumpAndSettle();
    c.read(routerProvider).go('/game/classic/1');
    await tester.pumpAndSettle();
    expect(tester.widget<BoardView>(find.byType(BoardView)).game.score, score);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });
  testWidgets('completing a journey level awards stars and opens the next', (
    tester,
  ) async {
    final c = await launch(tester);
    final game = GameSession(mode: GameMode.journey, level: 1, seed: 3);
    game.score = game.target - 10;
    game.pieces = [shapes[0], shapes[0], shapes[0]];
    await c.read(progressProvider.notifier).saveSession(game);
    c.read(routerProvider).go('/game/journey/1');
    await tester.pumpAndSettle();
    await tester.tap(find.byType(Draggable<int>).first);
    await tester.pump();
    await tester.tap(find.bySemanticsLabel('Row 1, column 1, empty'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byType(GameEnding), findsOneWidget);
    expect(find.byType(BoardView), findsOneWidget);
    expect(find.text('Sonraki'), findsNothing);
    await tester.pumpAndSettle();
    expect(c.read(progressProvider).levelStars['1'], 3);
    expect(c.read(progressProvider).coins, 70);
    expect(c.read(progressProvider).sessions.containsKey('journey'), isFalse);
    expect(find.text('Sonraki').hitTestable(), findsOneWidget);
    expect(find.byType(Scrollable), findsNothing);
    await tester.tap(find.text('Sonraki'));
    await tester.pumpAndSettle();
    expect(tester.widget<BoardView>(find.byType(BoardView)).game.level, 2);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });
  testWidgets('invalid placement shakes with no snackbar and no extra move', (
    tester,
  ) async {
    final c = await launch(tester);
    final g = GameSession(mode: GameMode.classic, seed: 5);
    g.board[0] = 1;
    g.pieces = [shapes[0], shapes[0], shapes[0]];
    await c.read(progressProvider.notifier).saveSession(g);
    c.read(routerProvider).go('/game/classic/1');
    await tester.pumpAndSettle();
    await tester.tap(find.byType(Draggable<int>).first);
    await tester.pump();
    await tester.tap(find.bySemanticsLabel('Row 1, column 1, filled'));
    await tester.pump(const Duration(milliseconds: 50));
    expect(tester.widget<ShakeFeedback>(find.byType(ShakeFeedback)).trigger, 1);
    expect(find.byType(SnackBar), findsNothing);
    expect(tester.widget<BoardView>(find.byType(BoardView)).game.moves, 0);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });
  testWidgets(
    'line clearing displays a finite burst and locks placement during it',
    (tester) async {
      final c = await launch(tester);
      final g = GameSession(mode: GameMode.classic, seed: 5);
      for (var i = 0; i < 7; i++) {
        g.board[i] = 1;
      }
      g.pieces = [shapes[0], shapes[0], shapes[0]];
      await c.read(progressProvider.notifier).saveSession(g);
      c.read(routerProvider).go('/game/classic/1');
      await tester.pumpAndSettle();
      await tester.tap(find.byType(Draggable<int>).first);
      await tester.pump();
      await tester.tap(find.bySemanticsLabel('Row 1, column 8, empty'));
      await tester.pump(const Duration(milliseconds: 150));
      expect(find.byType(LineBurst), findsOneWidget);
      expect(
        tester.widget<LineBurst>(find.byType(LineBurst)).cells.keys.first,
        7,
      );
      expect(tester.widget<BoardView>(find.byType(BoardView)).game.moves, 1);
      await tester.pumpAndSettle();
      expect(find.byType(LineBurst), findsNothing);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );
}
