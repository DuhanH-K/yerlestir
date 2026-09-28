import 'package:flutter/material.dart';

import '../../../core/widgets/blocks.dart';
import '../../../core/widgets/skin_style.dart';
import '../application/game_session.dart';
import '../domain/puzzle.dart';

const boardInset = 6.0;
const dragLift = 48.0;

class BoardView extends StatefulWidget {
  const BoardView({
    super.key,
    required this.game,
    required this.selected,
    required this.onDrop,
    required this.skin,
    this.settleToken = 0,
    this.placedCells = const {},
    this.hint,
  });
  final GameSession game;
  final int? selected;
  final void Function(int slot, int row, int col) onDrop;
  final String skin;
  final int settleToken;
  final Set<int> placedCells;
  final (int, int, int)? hint;
  @override
  State<BoardView> createState() => _BoardViewState();
}

class _BoardViewState extends State<BoardView> {
  final boardKey = GlobalKey();
  (int, int, int)? hover;
  (int, int) position(Offset global, double cell) {
    final box = boardKey.currentContext!.findRenderObject()! as RenderBox;
    final local = box.globalToLocal(global);
    return ((local.dy / cell).round(), (local.dx / cell).round());
  }

  @override
  Widget build(BuildContext context) => AspectRatio(
    aspectRatio: 1,
    child: Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: SkinStyle.of(widget.skin).base,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: SkinStyle.of(widget.skin).colors.first.withValues(alpha: .6),
          width: 2,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x6655381f),
            offset: Offset(0, 5),
            blurRadius: 8,
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, b) {
          final cell = b.maxWidth / boardSize;
          final active = hover ?? widget.hint;
          final shape = active == null ? null : widget.game.pieces[active.$1];
          final valid =
              shape != null &&
              widget.game.service.canPlace(
                widget.game.board,
                shape,
                active!.$2,
                active.$3,
              );
          final preview = <int>{};
          if (shape != null) {
            for (final c in shape.cells) {
              final r = active!.$2 + c.row, col = active.$3 + c.col;
              if (r >= 0 && r < boardSize && col >= 0 && col < boardSize) {
                preview.add(r * boardSize + col);
              }
            }
          }
          final completed = <int>{};
          if (valid) {
            final placed = widget.game.service.place(
              widget.game.board,
              shape,
              active.$2,
              active.$3,
            );
            final rows = widget.game.service.clearFullRows(placed);
            final columns = widget.game.service.clearFullColumns(placed);
            for (var i = 0; i < 64; i++) {
              if (rows.contains(i ~/ boardSize) ||
                  columns.contains(i % boardSize)) {
                completed.add(i);
              }
            }
          }
          return DragTarget<int>(
            onWillAcceptWithDetails: (d) {
              final p = position(d.offset, cell);
              setState(() => hover = (d.data, p.$1, p.$2));
              return true;
            },
            onMove: (d) {
              final p = position(d.offset, cell);
              final next = (d.data, p.$1, p.$2);
              if (next != hover) {
                setState(() => hover = next);
              }
            },
            onLeave: (_) => setState(() => hover = null),
            onAcceptWithDetails: (d) {
              final p = position(d.offset, cell);
              widget.onDrop(d.data, p.$1, p.$2);
              setState(() => hover = null);
            },
            builder: (_, candidates, rejected) => ClipRRect(
              borderRadius: BorderRadius.circular(9),
              child: Container(
                key: boardKey,
                color: const Color(0xff203758),
                child: GridView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  padding: EdgeInsets.zero,
                  itemCount: 64,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: boardSize,
                  ),
                  itemBuilder: (context, i) => Semantics(
                    label:
                        'Row ${i ~/ boardSize + 1}, column ${i % boardSize + 1}, ${widget.game.board[i] == 0 ? 'empty' : 'filled'}',
                    button: true,
                    child: GestureDetector(
                      onTap: () {
                        if (widget.selected != null) {
                          widget.onDrop(
                            widget.selected!,
                            i ~/ boardSize,
                            i % boardSize,
                          );
                        }
                      },
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          if (widget.placedCells.contains(i) &&
                              widget.game.board[i] != 0)
                            _SettlingBlock(
                              key: ValueKey('place-${widget.settleToken}-$i'),
                              value: widget.game.board[i],
                              skin: widget.skin,
                              rank: widget.placedCells.toList().indexOf(i),
                            )
                          else
                            BlockTile(
                              widget.game.board[i],
                              board: true,
                              skin: widget.skin,
                            ),
                          if (completed.contains(i) && !preview.contains(i))
                            Padding(
                              padding: const EdgeInsets.all(2),
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: const Color(0xffffdf88),
                                    width: 2,
                                  ),
                                  color: const Color(0x22ffdf88),
                                ),
                              ),
                            ),
                          if (preview.contains(i))
                            _LandingOutline(
                              valid: valid,
                              occupied: widget.game.board[i] != 0,
                              color: SkinStyle.of(widget.skin)
                                  .colors[(shape!.color - 1).clamp(0, 4)],
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    ),
  );
}

class _LandingOutline extends StatelessWidget {
  const _LandingOutline({
    required this.valid,
    required this.occupied,
    required this.color,
  });
  final bool valid, occupied;
  final Color color;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(2),
    child: DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        // Preserve the occupied block underneath instead of replacing its color.
        color: valid
            ? color.withValues(alpha: .4)
            : occupied
            ? Colors.transparent
            : const Color(0x24ff566c),
        border: Border.all(
          color: valid ? const Color(0xffdcffff) : const Color(0xffff566c),
          width: 2.5,
        ),
        boxShadow: valid
            ? [BoxShadow(color: color.withValues(alpha: .38), blurRadius: 7)]
            : const [],
      ),
      child: !valid && occupied
          ? const Center(
              child: Icon(
                Icons.close_rounded,
                size: 20,
                color: Color(0xffff8998),
              ),
            )
          : null,
    ),
  );
}

class _SettlingBlock extends StatelessWidget {
  const _SettlingBlock({
    super.key,
    required this.value,
    required this.skin,
    required this.rank,
  });
  final int value, rank;
  final String skin;
  static final settle = TweenSequence<double>([
    TweenSequenceItem(
      tween: Tween(
        begin: 1.0,
        end: 1.08,
      ).chain(CurveTween(curve: Curves.easeOutCubic)),
      weight: 35,
    ),
    TweenSequenceItem(tween: Tween(begin: 1.08, end: .96), weight: 30),
    TweenSequenceItem(
      tween: Tween(
        begin: .96,
        end: 1.0,
      ).chain(CurveTween(curve: Curves.easeOutCubic)),
      weight: 35,
    ),
  ]);
  @override
  Widget build(BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context)) {
      return BlockTile(value, skin: skin, board: true);
    }
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 240 + rank * 16),
      child: BlockTile(value, skin: skin, board: true),
      builder: (_, t, child) {
        final total = 240 + rank * 16;
        final p = ((t * total - rank * 16) / 240).clamp(0.0, 1.0);
        return Transform.scale(
          scale: settle.transform(p),
          child: Stack(
            fit: StackFit.expand,
            children: [
              child!,
              if (p > 0 && p < 1)
                Padding(
                  padding: const EdgeInsets.all(2),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: (1 - p) * .75),
                        width: 1 + 2 * (1 - p),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class PieceTray extends StatelessWidget {
  const PieceTray({
    super.key,
    required this.game,
    required this.selected,
    required this.onSelected,
    required this.skin,
    this.boardCell = 34,
    this.height = 120,
  });
  final GameSession game;
  final int? selected;
  final ValueChanged<int> onSelected;
  final String skin;
  final double boardCell, height;
  @override
  Widget build(BuildContext context) => SizedBox(
    height: height,
    child: Row(
      children: [
        for (var i = 0; i < 3; i++)
          Expanded(
            child: LayoutBuilder(
              builder: (context, bounds) {
                final shape = game.pieces[i];
                if (shape == null) {
                  return const SizedBox.expand();
                }
                final size = ((bounds.maxWidth - 12) / shape.width).clamp(
                  8.0,
                  ((bounds.maxHeight - 12) / shape.height).clamp(8.0, 25.0),
                );
                final content = SizedBox.expand(
                  child: Center(
                    child: AnimatedScale(
                      scale: selected == i ? 1.07 : 1,
                      duration: const Duration(milliseconds: 100),
                      child: RepaintBoundary(
                        child: ShapeView(shape, cell: size, skin: skin),
                      ),
                    ),
                  ),
                );
                return Semantics(
                  label: 'Piece ${i + 1}: ${shape.id}',
                  button: true,
                  child: Draggable<int>(
                    data: i,
                    maxSimultaneousDrags: 1,
                    // The finger sits below the piece. Feedback and board use the same cell size.
                    dragAnchorStrategy: (_, context, position) => Offset(
                      shape.width * boardCell / 2,
                      shape.height * boardCell + dragLift,
                    ),
                    feedbackOffset: Offset(
                      0,
                      -shape.height * boardCell / 2 - dragLift,
                    ),
                    feedback: Material(
                      color: Colors.transparent,
                      child: RepaintBoundary(
                        child: ShapeView(shape, cell: boardCell, skin: skin),
                      ),
                    ),
                    childWhenDragging: const SizedBox.expand(),
                    onDragStarted: () => onSelected(i),
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => onSelected(i),
                      child: content,
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    ),
  );
}
