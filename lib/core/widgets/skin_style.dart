import 'dart:math';

import 'package:flutter/material.dart';

class SkinStyle {
  const SkinStyle(this.sky, this.base, this.empty, this.colors);
  final Color sky, base, empty;
  final List<Color> colors;
  static SkinStyle of(String id) => switch (id) {
    'sunset' => const SkinStyle(
      Color(0xffa34475),
      Color(0xff39294e),
      Color(0xff603653),
      [
        Color(0xffffa45b),
        Color(0xffffd46d),
        Color(0xffff728d),
        Color(0xffd697fc),
        Color(0xffffc5a0),
      ],
    ),
    'forest' => const SkinStyle(
      Color(0xff247d71),
      Color(0xff102e37),
      Color(0xff244e4b),
      [
        Color(0xff89de83),
        Color(0xffffd878),
        Color(0xff41cbb0),
        Color(0xffc6e8a3),
        Color(0xfff29d6e),
      ],
    ),
    'night' => const SkinStyle(
      Color(0xff362a77),
      Color(0xff10172f),
      Color(0xff302d59),
      [
        Color(0xff80eaff),
        Color(0xffb395ff),
        Color(0xffff83d3),
        Color(0xff77f6c9),
        Color(0xffffde91),
      ],
    ),
    'candy' => const SkinStyle(
      Color(0xff895cba),
      Color(0xff3b2859),
      Color(0xff594674),
      [
        Color(0xffff87c4),
        Color(0xffcba0ff),
        Color(0xffffc388),
        Color(0xff8fede0),
        Color(0xffffed9b),
      ],
    ),
    'ocean' => const SkinStyle(
      Color(0xff087caa),
      Color(0xff092c4f),
      Color(0xff1c526e),
      [
        Color(0xff56ddeb),
        Color(0xff4caaff),
        Color(0xff7ef1c4),
        Color(0xffffcb82),
        Color(0xffa1c5ff),
      ],
    ),
    _ => const SkinStyle(
      Color(0xff345c94),
      Color(0xff243d6b),
      Color(0xff2b4266),
      [
        Color(0xff079efa),
        Color(0xffffc900),
        Color(0xff34d447),
        Color(0xffff665e),
        Color(0xff9d40f2),
      ],
    ),
  };
}

class SkinBackdrop extends StatelessWidget {
  const SkinBackdrop({super.key, required this.skin, this.child});
  final String skin;
  final Widget? child;
  @override
  Widget build(BuildContext context) {
    final style = SkinStyle.of(skin);
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [style.sky, style.base],
        ),
      ),
      child: CustomPaint(painter: _Landscape(skin), child: child),
    );
  }
}

class _Landscape extends CustomPainter {
  _Landscape(this.skin);
  final String skin;
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    if (skin == 'night') {
      final random = Random(7);
      for (var i = 0; i < 55; i++) {
        canvas.drawCircle(
          Offset(random.nextDouble() * w, random.nextDouble() * h),
          i % 4 == 0 ? 2 : 1,
          Paint()..color = Colors.white.withValues(alpha: .35),
        );
      }
      canvas.drawCircle(
        Offset(w * .82, h * .16),
        w * .07,
        Paint()..color = const Color(0xffffe9c4),
      );
    } else if (skin == 'sunset') {
      canvas.drawCircle(
        Offset(w * .78, h * .22),
        w * .18,
        Paint()..color = const Color(0x66ffca81),
      );
    }
    for (var layer = 0; layer < 3; layer++) {
      final path = Path()..moveTo(0, h);
      for (var i = 0; i <= 40; i++) {
        final x = w * i / 40;
        final y =
            h * (.78 + layer * .075) + sin(i * .14 + layer * 2) * h * .045;
        path.lineTo(x, y);
      }
      path
        ..lineTo(w, h)
        ..close();
      canvas.drawPath(
        path,
        Paint()..color = Colors.white.withValues(alpha: .045 + layer * .02),
      );
    }
    if (skin == 'forest') {
      for (var i = 0; i < 9; i++) {
        final x = w * i / 8;
        final y = h * (.9 + (i % 2) * .035);
        final path = Path()
          ..moveTo(x - 22, y)
          ..lineTo(x, y - h * .13)
          ..lineTo(x + 22, y)
          ..close();
        canvas.drawPath(path, Paint()..color = const Color(0x4439c6a0));
      }
    }
  }

  @override
  bool shouldRepaint(covariant _Landscape oldDelegate) =>
      oldDelegate.skin != skin;
}
