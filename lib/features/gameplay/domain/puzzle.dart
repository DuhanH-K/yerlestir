import 'dart:math';

const boardSize = 8;
const dailyRewards = [20, 30, 40, 50, 70, 100, 150];

enum GameMode { classic, journey, daily }

class GridOffset {
  const GridOffset(this.row, this.col);
  final int row, col;
}

class BlockShape {
  const BlockShape(this.id, this.cells, this.color);
  final String id;
  final List<GridOffset> cells;
  final int color;
  int get width => cells.map((c) => c.col).reduce(max) + 1;
  int get height => cells.map((c) => c.row).reduce(max) + 1;
}

const shapes = [
  // Keep existing IDs stable so saved games remain compatible.
  BlockShape('single', [GridOffset(0, 0)], 1),
  BlockShape('pair', [GridOffset(0, 0), GridOffset(0, 1)], 2),
  BlockShape('triple', [
    GridOffset(0, 0),
    GridOffset(0, 1),
    GridOffset(0, 2),
  ], 3),
  BlockShape('tower', [
    GridOffset(0, 0),
    GridOffset(1, 0),
    GridOffset(2, 0),
    GridOffset(3, 0),
  ], 1),
  BlockShape('square', [
    GridOffset(0, 0),
    GridOffset(0, 1),
    GridOffset(1, 0),
    GridOffset(1, 1),
  ], 2),
  BlockShape('corner', [
    GridOffset(0, 0),
    GridOffset(1, 0),
    GridOffset(1, 1),
  ], 4),
  BlockShape('ell', [
    GridOffset(0, 0),
    GridOffset(1, 0),
    GridOffset(2, 0),
    GridOffset(2, 1),
  ], 5),
  BlockShape('tee', [
    GridOffset(0, 0),
    GridOffset(0, 1),
    GridOffset(0, 2),
    GridOffset(1, 1),
  ], 3),
  BlockShape('zig', [
    GridOffset(0, 0),
    GridOffset(0, 1),
    GridOffset(1, 1),
    GridOffset(1, 2),
  ], 4),
  BlockShape('long', [
    GridOffset(0, 0),
    GridOffset(0, 1),
    GridOffset(0, 2),
    GridOffset(0, 3),
    GridOffset(0, 4),
  ], 5),
  BlockShape('pair_vertical', [GridOffset(0, 0), GridOffset(1, 0)], 2),
  BlockShape('triple_vertical', [
    GridOffset(0, 0),
    GridOffset(1, 0),
    GridOffset(2, 0),
  ], 3),
  BlockShape('corner_up', [
    GridOffset(0, 0),
    GridOffset(0, 1),
    GridOffset(1, 0),
  ], 4),
  BlockShape('corner_right', [
    GridOffset(0, 0),
    GridOffset(0, 1),
    GridOffset(1, 1),
  ], 4),
  BlockShape('ell_left', [
    GridOffset(0, 1),
    GridOffset(1, 1),
    GridOffset(2, 0),
    GridOffset(2, 1),
  ], 5),
  BlockShape('tee_left', [
    GridOffset(0, 1),
    GridOffset(1, 0),
    GridOffset(1, 1),
    GridOffset(2, 1),
  ], 3),
  BlockShape('tee_up', [
    GridOffset(0, 1),
    GridOffset(1, 0),
    GridOffset(1, 1),
    GridOffset(1, 2),
  ], 3),
  BlockShape('zig_vertical', [
    GridOffset(0, 1),
    GridOffset(1, 0),
    GridOffset(1, 1),
    GridOffset(2, 0),
  ], 4),
  BlockShape('line_four', [
    GridOffset(0, 0),
    GridOffset(0, 1),
    GridOffset(0, 2),
    GridOffset(0, 3),
  ], 1),
  BlockShape('tee_right', [
    GridOffset(0, 0),
    GridOffset(1, 0),
    GridOffset(1, 1),
    GridOffset(2, 0),
  ], 3),
  BlockShape('zig_reverse', [
    GridOffset(0, 1),
    GridOffset(0, 2),
    GridOffset(1, 0),
    GridOffset(1, 1),
  ], 4),
  BlockShape('ell_wide', [
    GridOffset(0, 0),
    GridOffset(1, 0),
    GridOffset(1, 1),
    GridOffset(1, 2),
  ], 5),
  BlockShape('ell_wide_up', [
    GridOffset(0, 0),
    GridOffset(0, 1),
    GridOffset(0, 2),
    GridOffset(1, 2),
  ], 5),
  BlockShape('corner_lower', [
    GridOffset(0, 1),
    GridOffset(1, 0),
    GridOffset(1, 1),
  ], 4),
  BlockShape('plus', [
    GridOffset(0, 1),
    GridOffset(1, 0),
    GridOffset(1, 1),
    GridOffset(1, 2),
    GridOffset(2, 1),
  ], 2),
  BlockShape('wide_u', [
    GridOffset(0, 0),
    GridOffset(0, 2),
    GridOffset(1, 0),
    GridOffset(1, 1),
    GridOffset(1, 2),
  ], 3),
];

class ClearResult {
  const ClearResult(this.board, this.lines);
  final List<int> board;
  final int lines;
}

class PuzzleService {
  bool canPlace(List<int> board, BlockShape shape, int row, int col) =>
      shape.cells.every(
        (c) =>
            row + c.row >= 0 &&
            row + c.row < boardSize &&
            col + c.col >= 0 &&
            col + c.col < boardSize &&
            board[(row + c.row) * boardSize + col + c.col] == 0,
      );
  List<int> place(List<int> board, BlockShape shape, int row, int col) {
    if (!canPlace(board, shape, row, col)) {
      throw StateError('Invalid placement');
    }
    final next = List<int>.of(board);
    for (final c in shape.cells) {
      next[(row + c.row) * boardSize + col + c.col] = shape.color;
    }
    return next;
  }

  Set<int> clearFullRows(List<int> board) => {
    for (var r = 0; r < boardSize; r++)
      if (List.generate(
        boardSize,
        (c) => board[r * boardSize + c],
      ).every((v) => v > 0))
        r,
  };
  Set<int> clearFullColumns(List<int> board) => {
    for (var c = 0; c < boardSize; c++)
      if (List.generate(
        boardSize,
        (r) => board[r * boardSize + c],
      ).every((v) => v > 0))
        c,
  };
  ClearResult clearLines(List<int> board) {
    final rows = clearFullRows(board), cols = clearFullColumns(board);
    return ClearResult(
      List.generate(
        board.length,
        (i) => rows.contains(i ~/ boardSize) || cols.contains(i % boardSize)
            ? 0
            : board[i],
      ),
      rows.length + cols.length,
    );
  }

  (int, int)? firstMove(List<int> board, BlockShape shape) {
    for (var r = 0; r < boardSize; r++) {
      for (var c = 0; c < boardSize; c++) {
        if (canPlace(board, shape, r, c)) {
          return (r, c);
        }
      }
    }
    return null;
  }

  bool hasAnyMove(List<int> board, Iterable<BlockShape> pieces) =>
      pieces.any((s) => firstMove(board, s) != null);
}

class LevelConfig {
  const LevelConfig(this.number, this.target, this.moves, this.region);
  final int number, target, moves;
  final String region;
}

class LevelFactory {
  static const count = 120;
  static const regions = ['Ege Kıyıları', 'Tarihin İzinde', 'Güzel Yarınlar'];
  static LevelConfig create(int level) => LevelConfig(
    level,
    220 + min(level, count) * 12,
    24 + min(level ~/ 10, 12),
    regions[((level - 1) ~/ 40).clamp(0, 2)],
  );
  static LevelConfig daily(int seed) =>
      LevelConfig(1, 700 + (seed % 3) * 150, 28 + (seed % 3) * 2, 'Daily');

  static List<int> startingBoard(GameMode mode, int level, int seed) {
    final board = List<int>.filled(boardSize * boardSize, 0);
    if (mode == GameMode.classic) return board;
    final random = Random(mode == GameMode.journey ? level * 7919 : seed);
    final rows = mode == GameMode.daily ? 3 : 1 + min((level - 1) ~/ 40, 2);
    for (var r = 0; r < rows; r++) {
      final gap = random.nextInt(5);
      for (var c = 0; c < boardSize; c++) {
        if (c < gap || c >= gap + 3) {
          board[(7 - r * 2) * boardSize + c] = 1 + random.nextInt(5);
        }
      }
    }
    return board;
  }

  static int dailySeed(DateTime date) =>
      date.year * 10000 + date.month * 100 + date.day;
}
