import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:yerlestir/features/gameplay/domain/puzzle.dart';
import 'package:yerlestir/features/gameplay/domain/piece_dealer.dart';
import 'package:yerlestir/features/gameplay/application/game_session.dart';

void main() {
  final service = PuzzleService();
  test(
    'every difficulty has a legal complete plan including intermediate clears',
    () {
      var setupDeals = 0;
      for (var difficulty = 0; difficulty <= 5; difficulty++) {
        for (var seed = 0; seed < 40; seed++) {
          final random = Random(seed);
          final board = service
              .clearLines(
                List.generate(
                  64,
                  (_) => random.nextDouble() < .35 + (seed % 4) * .15 ? 1 : 0,
                ),
              )
              .board;
          final snapshot = List<int>.of(board);
          final deal = PieceDealer().deal(board, difficulty, random);
          expect(board, snapshot);
          expect(deal.solution.length, 3);
          expect(deal.solution.map((m) => m.slot).toSet().length, 3);
          var replay = List<int>.of(board);
          for (final move in deal.solution) {
            final shape = deal.pieces[move.slot];
            expect(
              service.canPlace(replay, shape, move.row, move.col),
              isTrue,
              reason: 'difficulty $difficulty seed $seed',
            );
            replay = service
                .clearLines(service.place(replay, shape, move.row, move.col))
                .board;
          }
          if (deal.pieces.any((p) => service.firstMove(board, p) == null)) {
            setupDeals++;
          }
        }
      }
      expect(
        setupDeals,
        greaterThan(0),
        reason: 'Advanced deals should include clear-before-fit reasoning',
      );
    },
  );

  test(
    'advanced deals increase pattern variety without relying on larger pieces',
    () {
      var easyPatterns = 0, hardPatterns = 0;
      for (var seed = 0; seed < 30; seed++) {
        final board = List<int>.filled(64, 0);
        final easy = PieceDealer().deal(board, 0, Random(seed));
        final hard = PieceDealer().deal(board, 5, Random(seed));
        easyPatterns += easy.pieces
            .where((s) => s.width > 1 && s.height > 1)
            .length;
        hardPatterns += hard.pieces
            .where((s) => s.width > 1 && s.height > 1)
            .length;
        expect(hard.pieces.every((s) => s.cells.length <= 5), isTrue);
      }
      expect(hardPatterns, greaterThan(easyPatterns + 20));
    },
  );

  test('difficulty grows gradually and survives a saved session', () {
    final game = GameSession(mode: GameMode.classic, seed: 32);
    expect(game.difficulty, 0);
    game.moves = 24;
    expect(game.difficulty, 2);
    game.moves = 60;
    expect(game.difficulty, 5);
    final restored = GameSession.restore(game.toJson())!;
    game.refill();
    restored.refill();
    expect(restored.difficulty, 5);
    expect(restored.pieces.map((p) => p!.id), game.pieces.map((p) => p!.id));
  });
}
