import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:yerlestir/features/gameplay/application/game_session.dart';
import 'package:yerlestir/features/gameplay/domain/puzzle.dart';

void main() {
  test('three consecutive hints finish every generated tray, including after restore', () {
    for (var seed = 0; seed < 100; seed++) {
      var game = GameSession(mode: GameMode.classic, seed: seed);
      final rng = Random(seed);
      game.moves = 60;
      game.board = game.service
          .clearLines(List.generate(64, (_) => rng.nextDouble() < .7 ? 1 : 0))
          .board;
      game.refill();
      final draws = game.draws;
      for (var i = 0; i < 3; i++) {
        game = GameSession.restore(game.toJson())!;
        final hint = game.findHint();
        expect(hint, isNotNull, reason: 'seed $seed slot $i');
        expect(game.drop(hint!.$1, hint.$2, hint.$3), isTrue);
      }
      expect(game.draws, draws + 3);
      expect(game.finished, isFalse);
    }
  });
  test(
    'impossible remaining tray never receives a misleading partial hint',
    () {
      final game = GameSession(mode: GameMode.classic);
      game.board = List.generate(64, (i) => (i ~/ 8 + i % 8).isEven ? 0 : 1);
      game.pieces = [
        shapes.first,
        shapes.firstWhere((s) => s.id == 'square'),
        null,
      ];
      expect(game.finished, isFalse);
      expect(game.findHint(), isNull);
    },
  );
}
