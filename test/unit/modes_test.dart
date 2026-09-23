import 'package:flutter_test/flutter_test.dart';
import 'package:yerlestir/features/gameplay/domain/puzzle.dart';
import 'package:yerlestir/features/gameplay/application/game_session.dart';

void main() {
  test('all journey openings are repeatable, legal and never pre-cleared', () {
    final service = PuzzleService();
    for (var level = 1; level <= 120; level++) {
      final a = GameSession(mode: GameMode.journey, level: level);
      final b = GameSession(mode: GameMode.journey, level: level);
      expect(a.board, b.board);
      expect(a.pieces.map((p) => p!.id), b.pieces.map((p) => p!.id));
      expect(a.stalled, isFalse);
      expect(service.clearLines(a.board).lines, 0);
      expect(a.board.where((v) => v != 0), isNotEmpty);
    }
  });
  test(
    'daily changes by date, and save preserves the future piece sequence',
    () {
      final a = GameSession(mode: GameMode.daily, seed: 20260913);
      final next = GameSession(mode: GameMode.daily, seed: 20260914);
      expect(a.board, isNot(next.board));
      expect(a.target, isNot(next.target));
      for (var i = 0; i < 9 && !a.finished; i++) {
        final move = a.findHint()!;
        a.drop(move.$1, move.$2, move.$3);
      }
      final b = GameSession.restore(a.toJson())!;
      expect(a.toJson(), b.toJson());
      a.refill();
      b.refill();
      expect(a.pieces.map((p) => p!.id), b.pieces.map((p) => p!.id));
    },
  );
}
