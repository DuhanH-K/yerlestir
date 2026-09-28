import 'package:flutter/material.dart';

import 'skin_style.dart';

import '../../features/gameplay/domain/puzzle.dart';

const blockColors = [
  Color(0xff2b4266),
  Color(0xff079efa),
  Color(0xffffc900),
  Color(0xff34d447),
  Color(0xffff665e),
  Color(0xff9d40f2),
];

class BlockTile extends StatelessWidget {
  const BlockTile(
    this.value, {
    super.key,
    this.preview = false,
    this.invalid = false,
    this.board = false,
    this.skin = 'default',
  });
  final int value;
  final bool preview, invalid;
  final bool board;
  final String skin;
  @override
  Widget build(BuildContext context) {
    final style = SkinStyle.of(skin);
    var color = value == 0
        ? style.empty
        : style.colors[(value - 1).clamp(0, 4)];
    if (board && value != 0) color = Color.lerp(color, Colors.black, .25)!;
    final highlightAmount = board ? .22 : .45;
    final shadeAmount = board ? .2 : .13;
    if (invalid) {
      color = Colors.red;
    }
    return Container(
      margin: const EdgeInsets.all(1.5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(value == 0 ? 5 : 7),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color.lerp(
              color,
              Colors.white,
              value == 0 ? .08 : highlightAmount,
            )!,
            color,
            Color.lerp(color, Colors.black, shadeAmount)!,
          ],
        ),
        border: Border.all(
          color: preview
              ? Colors.white
              : Colors.white.withValues(
                  alpha: value == 0 ? (board ? .1 : .4) : (board ? .46 : .8),
                ),
          width: preview ? 2.5 : 1.5,
        ),
        boxShadow: value == 0
            ? []
            : [
                BoxShadow(
                  color: color.withValues(alpha: preview ? .8 : .4),
                  blurRadius: preview ? 12 : (board ? 3 : 1),
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: value == 0 ? null : CustomPaint(painter: _BlockSheen()),
    );
  }
}

class _BlockSheen extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    if (size.shortestSide < 12) {
      return;
    }
    final highlight = Path()
      ..moveTo(3, size.height * .6)
      ..lineTo(3, 7)
      ..quadraticBezierTo(3, 3, 7, 3)
      ..lineTo(size.width - 6, 3);
    canvas.drawPath(
      highlight,
      Paint()
        ..color = const Color(0xaaffffff)
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke,
    );
    final shadow = Path()
      ..moveTo(5, size.height - 3)
      ..lineTo(size.width - 7, size.height - 3)
      ..quadraticBezierTo(
        size.width - 3,
        size.height - 3,
        size.width - 3,
        size.height - 7,
      )
      ..lineTo(size.width - 3, 6);
    canvas.drawPath(
      shadow,
      Paint()
        ..color = const Color(0x33003075)
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class ShapeView extends StatelessWidget {
  const ShapeView(
    this.shape, {
    super.key,
    this.cell = 25,
    this.skin = 'default',
  });
  final BlockShape shape;
  final double cell;
  final String skin;
  @override
  Widget build(BuildContext context) => SizedBox(
    width: shape.width * cell,
    height: shape.height * cell,
    child: Stack(
      children: [
        for (final c in shape.cells)
          Positioned(
            left: c.col * cell,
            top: c.row * cell,
            width: cell,
            height: cell,
            child: BlockTile(shape.color, skin: skin),
          ),
      ],
    ),
  );
}

class DecorativeBoard extends StatelessWidget {
  const DecorativeBoard({super.key, this.skin = 'default'});
  final String skin;
  @override
  Widget build(BuildContext context) {
    const values = [
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      2,
      0,
      0,
      0,
      1,
      1,
      2,
      3,
      3,
      0,
      1,
      0,
      4,
      3,
      0,
      0,
      0,
      0,
      4,
      4,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
    ];
    return AspectRatio(
      aspectRatio: 1,
      child: Container(
        padding: const EdgeInsets.all(5),
        decoration: BoxDecoration(
          color: SkinStyle.of(skin).base,
          borderRadius: BorderRadius.circular(17),
          border: Border.all(color: Colors.white70, width: 2),
        ),
        child: GridView.builder(
          physics: const NeverScrollableScrollPhysics(),
          itemCount: 36,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 6,
          ),
          itemBuilder: (_, i) => BlockTile(values[i], skin: skin),
        ),
      ),
    );
  }
}
