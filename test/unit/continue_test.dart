import 'package:flutter_test/flutter_test.dart';
import 'package:yerlestir/features/gameplay/application/game_session.dart';
import 'package:yerlestir/features/gameplay/domain/puzzle.dart';

void main() {
  test(
    'reward rescues a blocked board once and preserves score after restore',
    () {
      final g = GameSession(mode: GameMode.classic, seed: 7);
      g.board = List.filled(64, 1);
      g.score = 1000;
      expect(g.canContinue, isTrue);
      expect(g.continueAfterReward(), isTrue);
      expect(g.finished, isFalse);
      expect(g.score, 1000);
      expect(g.board.sublist(40), everyElement(0));
      final restored = GameSession.restore(g.toJson())!;
      restored.board = List.filled(64, 1);
      expect(restored.canContinue, isFalse);
      expect(restored.continueAfterReward(), isFalse);
    },
  );
  test('move-limit rescue gives five moves and never revives a victory', () {
    final g = GameSession(mode: GameMode.journey, seed: 3);
    g.moves = g.moveLimit;
    expect(g.continueAfterReward(), isTrue);
    expect(g.moveLimit - g.moves, 5);
    expect(g.finished, isFalse);
    final won = GameSession(mode: GameMode.journey)..score = 99999;
    expect(won.continueAfterReward(), isFalse);
  });
}
