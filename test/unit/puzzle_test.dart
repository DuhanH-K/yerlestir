import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:yerlestir/features/gameplay/domain/puzzle.dart';
import 'package:yerlestir/features/gameplay/application/game_session.dart';

void main() {
  final service = PuzzleService();
  bool canPlayTray(List<int> board, List<BlockShape> tray) {
    if (tray.isEmpty) return true;
    for (var slot = 0; slot < tray.length; slot++) {
      for (var row = 0; row < boardSize; row++) {
        for (var col = 0; col < boardSize; col++) {
          if (!service.canPlace(board, tray[slot], row, col)) continue;
          final next = service.clearLines(
            service.place(board, tray[slot], row, col),
          );
          final rest = List<BlockShape>.of(tray)..removeAt(slot);
          if (canPlayTray(next.board, rest)) return true;
        }
      }
    }
    return false;
  }

  test('all modes deal three jointly playable pieces on crowded boards', () {
    for (final mode in GameMode.values) {
      for (var seed = 0; seed < 20; seed++) {
        final g = GameSession(mode: mode, seed: seed);
        final random = Random(seed);
        g.board = service
            .clearLines(
              List.generate(64, (_) => random.nextDouble() < .8 ? 1 : 0),
            )
            .board;
        final before = List<int>.of(g.board);
        g.refill();
        final tray = g.pieces.cast<BlockShape>();
        expect(g.board, before);
        expect(tray.any((s) => service.firstMove(g.board, s) != null), isTrue);
        expect(canPlayTray(g.board, tray), isTrue, reason: '$mode seed $seed');
      }
    }
  });

  test(
    'isolated holes receive small pieces instead of an impossible large tray',
    () {
      final g = GameSession(mode: GameMode.classic, seed: 4);
      g.board = List.generate(64, (i) => (i ~/ 8 + i % 8).isEven ? 0 : 1);
      g.refill();
      expect(g.pieces.map((s) => s!.id), everyElement('single'));
      expect(g.stalled, isFalse);
    },
  );

  test(
    'row-gap deal remains solvable without forcing the obvious first piece',
    () {
      final g = GameSession(mode: GameMode.classic, seed: 5);
      g.board = List.filled(64, 0);
      for (var col = 0; col < 5; col++) {
        g.board[56 + col] = 1;
      }
      g.refill();
      expect(canPlayTray(g.board, g.pieces.cast<BlockShape>()), isTrue);
    },
  );
  test('placement rejects edges and occupied cells without mutating input', () {
    final board = List.filled(64, 0);
    expect(service.canPlace(board, shapes[4], 7, 7), isFalse);
    expect(service.canPlace(board, shapes[0], -1, 0), isFalse);
    final placed = service.place(board, shapes[4], 6, 6);
    expect(board.every((v) => v == 0), isTrue);
    expect(placed.where((v) => v > 0).length, 4);
    expect(service.canPlace(placed, shapes[0], 6, 6), isFalse);
    expect(() => service.place(placed, shapes[0], 6, 6), throwsStateError);
  });
  test('intersecting row and column clear simultaneously', () {
    final board = List.filled(64, 0);
    for (var i = 0; i < 8; i++) {
      board[i] = 1;
      board[i * 8] = 2;
    }
    board[63] = 4;
    final result = service.clearLines(board);
    expect(result.lines, 2);
    expect(result.board.where((v) => v > 0).length, 1);
    expect(result.board[63], 4);
  });
  test('all legal origins considered when looking for a move', () {
    final board = List.filled(64, 1)..[63] = 0;
    expect(service.firstMove(board, shapes[0]), (7, 7));
    expect(service.hasAnyMove(board, [shapes[4]]), isFalse);
    expect(service.hasAnyMove(board, [shapes[4], shapes[0]]), isTrue);
  });
  test('daily seed and piece sequence reproduce across sessions', () {
    final seed = LevelFactory.dailySeed(DateTime(2026, 9, 12));
    final a = GameSession(mode: GameMode.daily, seed: seed);
    final b = GameSession(mode: GameMode.daily, seed: seed);
    for (var i = 0; i < 5; i++) {
      expect(a.pieces.map((s) => s?.id), b.pieces.map((s) => s?.id));
      a.refill();
      b.refill();
    }
    expect(seed, 20260912);
  });
  test('saved run resumes RNG, score and helpers', () {
    final a = GameSession(mode: GameMode.classic, seed: 20);
    a.refill();
    a.paidHint = a.findHint();
    a.drop(0, 0, 0);
    final b = GameSession.restore(a.toJson())!;
    expect(b.toJson(), a.toJson());
    a.refill();
    b.refill();
    expect(b.pieces.map((s) => s?.id), a.pieces.map((s) => s?.id));
  });
  test('invalid saved board fails safely', () {
    expect(
      GameSession.restore({
        'board': [1],
      }),
      isNull,
    );
  });
  test('used pieces refill after third placement', () {
    final g = GameSession(mode: GameMode.classic, seed: 2);
    g.pieces = [shapes[0], shapes[0], shapes[0]];
    expect(g.drop(0, 0, 0), isTrue);
    expect(g.drop(0, 1, 0), isFalse);
    g.drop(1, 0, 1);
    g.drop(2, 0, 2);
    expect(g.pieces.every((p) => p != null), isTrue);
    expect(g.score, 30);
    expect(g.moves, 3);
  });
  test('no move ends the run without removed powerups', () {
    final g = GameSession(mode: GameMode.classic);
    g.board = List.filled(64, 1);
    expect(g.finished, isTrue);
    expect(g.findHint(), isNull);
    expect(g.toJson().containsKey('bombs'), isFalse);
  });
  test('line burst records each crossed cell once before clearing', () {
    final g = GameSession(mode: GameMode.classic);
    for (var i = 1; i < 8; i++) {
      g.board[i] = 1;
      g.board[i * 8] = 2;
    }
    g.pieces = [shapes[0], shapes[0], shapes[0]];
    expect(g.drop(0, 0, 0), isTrue);
    expect(g.lastClearedCells.length, 15);
    expect(g.cleared, 2);
    expect(g.board.every((v) => v == 0), isTrue);
    expect(g.lastScoreGain, 170);
  });
  test('hint prioritizes a line clear over the first free cell', () {
    final g = GameSession(mode: GameMode.classic);
    for (var i = 0; i < 7; i++) {
      g.board[56 + i] = 1;
    }
    g.pieces = [shapes[0], null, null];
    expect(g.findHint(), (0, 7, 7));
  });
  test('journey targets increase and all levels are configured', () {
    for (var i = 1; i <= 120; i++) {
      final c = LevelFactory.create(i);
      expect(c.moves, greaterThan(0));
      if (i > 1) {
        expect(c.target, greaterThan(LevelFactory.create(i - 1).target));
      }
    }
  });
  test('win and move-limit endings are recognized', () {
    final g = GameSession(mode: GameMode.journey);
    g.score = g.target;
    g.moves = 5;
    expect(g.won, isTrue);
    expect(g.stars, 3);
    expect(g.drop(0, 0, 0), isFalse);
    final h = GameSession(mode: GameMode.daily);
    h.moves = h.moveLimit;
    expect(h.finished, isTrue);
    expect(h.won, isFalse);
  });
  test('pops propagate from right placement back across the row', () {
    final g = GameSession(mode: GameMode.classic);
    for (var i = 0; i < 7; i++) {
      g.board[i] = 1;
    }
    g.pieces = [shapes[0], shapes[0], shapes[0]];
    g.drop(0, 0, 7);
    expect(g.lastClearedCells.keys.toList(), [7, 6, 5, 4, 3, 2, 1, 0]);
  });
  test('pops propagate from bottom placement up the column', () {
    final g = GameSession(mode: GameMode.classic);
    for (var i = 0; i < 7; i++) {
      g.board[i * 8] = 1;
    }
    g.pieces = [shapes[0], shapes[0], shapes[0]];
    g.drop(0, 7, 0);
    expect(g.lastClearedCells.keys.toList(), [56, 48, 40, 32, 24, 16, 8, 0]);
  });
}
