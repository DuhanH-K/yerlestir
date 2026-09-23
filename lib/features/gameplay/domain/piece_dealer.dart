import 'dart:math';

import 'puzzle.dart';

class PlannedMove {
  const PlannedMove(this.slot, this.row, this.col);
  final int slot, row, col;
}

class PieceDeal {
  const PieceDeal(this.pieces, this.solution);
  final List<BlockShape> pieces;
  final List<PlannedMove> solution;
}

/// Difficulty changes pattern variety and delayed clears, never solvability.
class PieceDealer {
  final service = PuzzleService();

  PieceDeal deal(List<int> board, int difficulty, Random random) {
    PieceDeal? best;
    var bestValue = double.negativeInfinity;
    for (var attempt = 0; attempt < 12; attempt++) {
      var simulated = List<int>.of(board);
      final pieces = <BlockShape>[];
      final plan = <PlannedMove>[];
      var lines = 0, delayedLines = 0, complex = 0;
      for (var slot = 0; slot < 3; slot++) {
        final available = shapes
            .where((s) => service.firstMove(simulated, s) != null)
            .toList();
        if (available.isEmpty) break;
        // Tiny pieces remain a rescue when needed, rather than the normal deal.
        final patterned = available
            .where((s) => s.width > 1 && s.height > 1)
            .toList();
        final regular = available.where((s) => s.cells.length >= 2).toList();
        final pool =
            patterned.isNotEmpty && random.nextDouble() < .15 + difficulty * .14
            ? patterned
            : regular.isNotEmpty
            ? regular
            : available;
        final shape = pool[random.nextInt(pool.length)];
        final placements =
            <({int row, int col, List<int> board, int lines, int value})>[];
        for (var r = 0; r < 8; r++) {
          for (var c = 0; c < 8; c++) {
            if (!service.canPlace(simulated, shape, r, c)) continue;
            final placed = service.place(simulated, shape, r, c);
            final cleared = service.clearLines(placed);
            var contact = 0;
            for (final cell in shape.cells) {
              final row = r + cell.row, col = c + cell.col;
              for (final (dr, dc) in const [(-1, 0), (1, 0), (0, -1), (0, 1)]) {
                final nr = row + dr, nc = col + dc;
                if (nr < 0 ||
                    nr >= 8 ||
                    nc < 0 ||
                    nc >= 8 ||
                    simulated[nr * 8 + nc] != 0) {
                  contact++;
                }
              }
            }
            placements.add((
              row: r,
              col: c,
              board: cleared.board,
              lines: cleared.lines,
              value: cleared.lines * 24 + contact,
            ));
          }
        }
        placements.sort((a, b) => b.value.compareTo(a.value));
        final pick =
            placements[random.nextInt(min(placements.length, 2 + difficulty))];
        pieces.add(shape);
        plan.add(PlannedMove(slot, pick.row, pick.col));
        lines += pick.lines;
        if (slot > 0) delayedLines += pick.lines;
        if (shape.width > 1 && shape.height > 1) complex++;
        simulated = pick.board;
      }
      if (pieces.length != 3) continue;
      final initiallyBlocked = pieces
          .where((s) => service.firstMove(board, s) == null)
          .length;
      // Early play is readable. Later play rewards recognizing setup -> clear -> fit.
      if (difficulty == 0 && initiallyBlocked > 0) continue;
      final variety = pieces.map((s) => s.id).toSet().length;
      final value = difficulty == 0
          ? lines * 25 - complex * 3 + variety + random.nextDouble() * 6
          : delayedLines * (8 + difficulty * 4) +
                lines * 4 +
                complex * difficulty * 4 +
                variety * 3 +
                initiallyBlocked * difficulty * 5 +
                random.nextDouble() * 10;
      if (value > bestValue) {
        bestValue = value;
        // Display order must not reveal the order of the constructed solution.
        final order = [0, 1, 2]..shuffle(random);
        best = PieceDeal(
          [for (final i in order) pieces[i]],
          [
            for (final move in plan)
              PlannedMove(order.indexOf(move.slot), move.row, move.col),
          ],
        );
      }
    }
    if (best != null) return best;
    // Crowded-board fallback still accounts for clears between all three moves.
    var simulated = List<int>.of(board);
    final plan = <PlannedMove>[];
    for (var i = 0; i < 3; i++) {
      final origin = service.firstMove(simulated, shapes.first);
      if (origin == null) break;
      plan.add(PlannedMove(i, origin.$1, origin.$2));
      simulated = service
          .clearLines(
            service.place(simulated, shapes.first, origin.$1, origin.$2),
          )
          .board;
    }
    return PieceDeal(List.filled(3, shapes.first), plan);
  }

  /// Search across slot order as well as position; capped so hints cannot stall UI.
  List<PlannedMove>? solve(
    List<int> board,
    List<BlockShape?> pieces, {
    int budget = 12000,
  }) {
    var visited = 0;
    final dead = <String>{};
    List<PlannedMove>? search(List<int> grid, int remaining) {
      if (remaining == 0) return [];
      if (++visited > budget) return null;
      final key = '${grid.map((v) => v == 0 ? 0 : 1).join()}:$remaining';
      if (dead.contains(key)) return null;
      final options = <({PlannedMove move, List<int> board, int lines})>[];
      for (var slot = 0; slot < pieces.length; slot++) {
        if (remaining & (1 << slot) == 0) continue;
        final shape = pieces[slot]!;
        for (var r = 0; r < 8; r++) {
          for (var c = 0; c < 8; c++) {
            if (!service.canPlace(grid, shape, r, c)) continue;
            final next = service.clearLines(service.place(grid, shape, r, c));
            options.add((
              move: PlannedMove(slot, r, c),
              board: next.board,
              lines: next.lines,
            ));
          }
        }
      }
      options.sort((a, b) => b.lines.compareTo(a.lines));
      for (final option in options) {
        final rest = search(option.board, remaining & ~(1 << option.move.slot));
        if (rest != null) return [option.move, ...rest];
        if (visited > budget) return null;
      }
      dead.add(key);
      return null;
    }

    return search(
      board,
      [
        for (var i = 0; i < pieces.length; i++)
          if (pieces[i] != null) 1 << i,
      ].fold(0, (a, b) => a | b),
    );
  }
}
