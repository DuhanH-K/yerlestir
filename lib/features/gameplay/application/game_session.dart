import 'dart:math';

import '../domain/puzzle.dart';
import '../domain/piece_dealer.dart';

class GameSession {
  GameSession({required this.mode, this.level = 1, int? seed})
    : seed =
          seed ??
          (mode == GameMode.journey
              ? level * 7919
              : mode == GameMode.daily
              ? LevelFactory.dailySeed(DateTime.now())
              : DateTime.now().microsecondsSinceEpoch) {
    board = LevelFactory.startingBoard(mode, level, this.seed);
    refill();
  }
  final GameMode mode;
  final int level, seed;
  final service = PuzzleService();
  List<int> board = List.filled(boardSize * boardSize, 0);
  List<BlockShape?> pieces = [];
  List<PlannedMove> _plan = [];
  int continuesUsed = 0;
  int score = 0, moves = 0, combo = 0, cleared = 0, bestCombo = 0, draws = 0;
  (int, int, int)? paidHint;
  Map<int, int> lastClearedCells = {};
  int lastScoreGain = 0, lastPlacementPoints = 0, lastLinePoints = 0;
  int get target => mode == GameMode.daily
      ? LevelFactory.daily(seed).target
      : LevelFactory.create(level).target;
  int get moveLimit =>
      (mode == GameMode.daily
          ? LevelFactory.daily(seed).moves
          : LevelFactory.create(level).moves) +
      continuesUsed * 5;
  bool get canContinue => finished && !won && continuesUsed == 0;
  bool continueAfterReward() {
    if (!canContinue) return false;
    continuesUsed++;
    // A visible rescue area, without granting score for cleared cells.
    for (var i = 40; i < 64; i++) {
      board[i] = 0;
    }
    combo = 0;
    paidHint = null;
    lastClearedCells = {};
    refill();
    return true;
  }

  bool get won => mode != GameMode.classic && score >= target;
  bool get stalled =>
      !service.hasAnyMove(board, pieces.whereType<BlockShape>());
  bool get finished =>
      won || (mode != GameMode.classic && moves >= moveLimit) || stalled;
  int get stars => !won
      ? 0
      : moves <= (moveLimit * .7).floor()
      ? 3
      : moves <= (moveLimit * .9).floor()
      ? 2
      : 1;
  int get difficulty =>
      (mode == GameMode.journey
              ? (level - 1) ~/ 8 + moves ~/ 12
              : mode == GameMode.daily
              ? 2 + moves ~/ 9
              : moves ~/ 12)
          .clamp(0, 5);

  void refill() {
    draws += 3;
    final deal = PieceDealer().deal(
      board,
      difficulty,
      Random(seed ^ (draws * 7919)),
    );
    pieces = List<BlockShape?>.of(deal.pieces);
    _plan = deal.solution;
  }

  bool drop(int slot, int row, int col) {
    if (finished || slot < 0 || slot >= pieces.length) {
      return false;
    }
    final shape = pieces[slot];
    if (shape == null || !service.canPlace(board, shape, row, col)) {
      return false;
    }
    if (_plan.isNotEmpty &&
        _plan.first.slot == slot &&
        _plan.first.row == row &&
        _plan.first.col == col) {
      _plan = _plan.sublist(1);
    } else {
      _plan = [];
    }
    final placed = service.place(board, shape, row, col);
    final rows = service.clearFullRows(placed),
        columns = service.clearFullColumns(placed);
    lastClearedCells = {
      for (var i = 0; i < placed.length; i++)
        if (rows.contains(i ~/ boardSize) || columns.contains(i % boardSize))
          i: placed[i],
    };
    final ordered = lastClearedCells.keys.toList()
      ..sort((a, b) {
        final da = (a ~/ boardSize - row).abs() + (a % boardSize - col).abs();
        final db = (b ~/ boardSize - row).abs() + (b % boardSize - col).abs();
        return da == db ? a.compareTo(b) : da.compareTo(db);
      });
    lastClearedCells = {for (final index in ordered) index: placed[index]};
    final result = service.clearLines(placed);
    board = result.board;
    combo = result.lines > 0 ? combo + 1 : 0;
    bestCombo = max(bestCombo, combo);
    lastPlacementPoints = shape.cells.length * 10;
    lastLinePoints = result.lines * 80 * max(combo, 1);
    lastScoreGain = lastPlacementPoints + lastLinePoints;
    score += lastScoreGain;
    paidHint = null;
    cleared += result.lines;
    moves++;
    pieces[slot] = null;
    if (pieces.every((p) => p == null)) {
      refill();
    }
    return true;
  }

  (int, int, int)? findHint() {
    if (finished) {
      return null;
    }
    if (!_validPlan()) {
      _plan = PieceDealer().solve(board, pieces, budget: 30000) ?? [];
    }
    if (_plan.isEmpty) return null;
    final first = _plan.first;
    return (first.slot, first.row, first.col);
  }

  bool _validPlan() {
    if (_plan.length != pieces.whereType<BlockShape>().length) return false;
    var grid = List<int>.of(board);
    final used = <int>{};
    for (final move in _plan) {
      if (move.slot < 0 || move.slot >= pieces.length || !used.add(move.slot)) {
        return false;
      }
      final shape = pieces[move.slot];
      if (shape == null || !service.canPlace(grid, shape, move.row, move.col)) {
        return false;
      }
      grid = service
          .clearLines(service.place(grid, shape, move.row, move.col))
          .board;
    }
    return true;
  }

  Map<String, dynamic> toJson() => {
    'mode': mode.name,
    'level': level,
    'seed': seed,
    'board': List<int>.of(board),
    'pieces': pieces.map((p) => p?.id).toList(),
    'score': score,
    'moves': moves,
    'combo': combo,
    'cleared': cleared,
    'bestCombo': bestCombo,
    'draws': draws,
    'continuesUsed': continuesUsed,
    'plan': [
      for (final m in _plan) [m.slot, m.row, m.col],
    ],
    'paidHint': paidHint == null
        ? null
        : [paidHint!.$1, paidHint!.$2, paidHint!.$3],
  };
  static GameSession? restore(Map<String, dynamic> json) {
    try {
      final g = GameSession(
        mode: GameMode.values.byName(json['mode']),
        level: json['level'],
        seed: json['seed'],
      );
      g.board = List<int>.from(json['board']);
      if (g.board.length != 64 || g.board.any((v) => v < 0 || v > 5)) {
        return null;
      }
      g.pieces = (json['pieces'] as List)
          .map((id) => id == null ? null : shapes.firstWhere((s) => s.id == id))
          .toList();
      if (g.pieces.length != 3) {
        return null;
      }
      g.score = json['score'];
      g.moves = json['moves'];
      g.continuesUsed = json['continuesUsed'] as int? ?? 0;
      if (g.continuesUsed < 0 || g.continuesUsed > 1) return null;
      g.combo = json['combo'];
      g.cleared = json['cleared'];
      g.bestCombo = json['bestCombo'];
      g._plan = [
        for (final m in (json['plan'] as List? ?? []))
          PlannedMove(m[0] as int, m[1] as int, m[2] as int),
      ];
      if (!g._validPlan()) g._plan = [];
      final h = json['paidHint'];
      if (h is List && h.length == 3) {
        final slot = h[0] as int, row = h[1] as int, col = h[2] as int;
        if (slot >= 0 &&
            slot < 3 &&
            g.pieces[slot] != null &&
            g.service.canPlace(g.board, g.pieces[slot]!, row, col)) {
          g.paidHint = (slot, row, col);
        }
      }
      final draws = json['draws'] as int;
      if (draws < 3 ||
          draws > 1000000 ||
          g.level < 1 ||
          g.level > 120 ||
          g.score < 0 ||
          g.moves < 0 ||
          g.pieces.every((p) => p == null)) {
        return null;
      }
      g.draws = draws;
      return g;
    } catch (_) {
      return null;
    }
  }
}
