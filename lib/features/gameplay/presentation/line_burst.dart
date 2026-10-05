import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/widgets/skin_style.dart';
import 'score_celebration.dart';

// Input resumes when the last tile dissolves; particles and text continue.
const lineBurstDuration = Duration(milliseconds: 260);
const clearPresentationDuration = clearFeedbackDuration;

class LineBurst extends StatefulWidget {
  const LineBurst({
    super.key,
    required this.cells,
    required this.points,
    this.message = '',
    this.detail = '',
    this.skin = 'default',
    this.combo = 1,
    this.placementPoints = 0,
    this.linePoints = 0,
    this.english = false,
    this.onEnd,
  });
  final Map<int, int> cells;
  final int points, combo, placementPoints, linePoints;
  final String message, detail, skin;
  final bool english;
  final VoidCallback? onEnd;

  @override
  State<LineBurst> createState() => _LineBurstState();
}

class _LineBurstState extends State<LineBurst>
    with SingleTickerProviderStateMixin {
  late final AnimationController clock = AnimationController(
    vsync: this,
    duration: clearPresentationDuration,
  );
  late final ClearChoreography choreography = ClearChoreography(
    widget.cells,
    widget.skin,
  );
  bool reduced = false;

  @override
  void initState() {
    super.initState();
    clock.addStatusListener((status) {
      if (status == AnimationStatus.completed) widget.onEnd?.call();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    reduced = MediaQuery.disableAnimationsOf(context);
    if (!clock.isAnimating && clock.value == 0) clock.forward();
  }

  @override
  void dispose() {
    clock.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => IgnorePointer(
    child: RepaintBoundary(
      child: Stack(
        fit: StackFit.expand,
        clipBehavior: Clip.none,
        children: [
          CustomPaint(painter: _ClearPainter(clock, choreography, reduced)),
          ScoreCelebration(
            clock: clock,
            points: widget.points,
            combo: widget.combo,
            lines: choreography.lines.length,
            placementPoints: widget.placementPoints,
            linePoints: widget.linePoints,
            english: widget.english,
            reducedMotion: reduced,
          ),
        ],
      ),
    ),
  );
}

class ClearLine {
  const ClearLine(this.index, this.vertical);
  final int index;
  final bool vertical;
}

class ClearShard {
  const ClearShard(
    this.cell,
    this.angle,
    this.speed,
    this.spin,
    this.radius,
    this.lifetime,
    this.kind,
    this.color,
  );
  final int cell, kind;
  final double angle, speed, spin, radius, lifetime;
  final Color color;
}

/// Immutable, seeded once per clear, with a hard global particle budget.
class ClearChoreography {
  ClearChoreography(Map<int, int> source, String skin)
    : cells = Map.unmodifiable(source) {
    final palette = SkinStyle.of(skin).colors;
    for (var i = 0; i < 8; i++) {
      if (List.generate(8, (col) => i * 8 + col).every(cells.containsKey)) {
        lines.add(ClearLine(i, false));
      }
      if (List.generate(8, (row) => row * 8 + i).every(cells.containsKey)) {
        lines.add(ClearLine(i, true));
      }
    }
    for (final entry in cells.entries) {
      colors[entry.key] = palette[(entry.value - 1).clamp(0, 4)];
      final row = entry.key ~/ 8, col = entry.key % 8;
      final crossing = lines.where(
        (line) => line.index == (line.vertical ? col : row),
      );
      // Horizontal sweeps run left to right; vertical sweeps top to bottom.
      starts[entry.key] = crossing.isEmpty
          ? 90
          : crossing
                .map((line) => 90.0 + (line.vertical ? row : col) * 12)
                .reduce(math.min);
    }
    final random = math.Random(source.keys.fold<int>(17, (a, b) => a * 31 + b));
    final count = math.min(168, cells.length * 12);
    final keys = cells.keys.toList();
    for (var i = 0; i < count; i++) {
      final cell = keys[i % keys.length];
      shards.add(
        ClearShard(
          cell,
          random.nextDouble() * math.pi * 2,
          .7 + random.nextDouble() * 1.9,
          (random.nextDouble() - .5) * 9,
          .055 + random.nextDouble() * .105,
          480 + random.nextDouble() * 240,
          i % 3,
          i % 5 == 0 ? Colors.white : colors[cell]!,
        ),
      );
    }
  }
  final Map<int, int> cells;
  final lines = <ClearLine>[];
  final starts = <int, double>{};
  final colors = <int, Color>{};
  final shards = <ClearShard>[];
}

double phase(double time, double start, double duration) =>
    ((time - start) / duration).clamp(0.0, 1.0);

class _ClearPainter extends CustomPainter {
  _ClearPainter(this.clock, this.effect, this.reduced) : super(repaint: clock);
  final Animation<double> clock;
  final ClearChoreography effect;
  final bool reduced;
  final Paint fill = Paint();
  final Paint stroke = Paint()..style = PaintingStyle.stroke;

  @override
  void paint(Canvas canvas, Size size) {
    final ms = clock.value * clearPresentationDuration.inMilliseconds;
    if (ms > 1350) return;
    final cell = size.width / 8;
    if (reduced) {
      final alpha = 1 - phase(ms, 60, 180);
      for (final entry in effect.cells.entries) {
        fill.color = effect.colors[entry.key]!.withValues(alpha: alpha);
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(
              entry.key % 8 * cell + 2,
              entry.key ~/ 8 * cell + 2,
              cell - 4,
              cell - 4,
            ),
            const Radius.circular(6),
          ),
          fill,
        );
      }
      return;
    }

    // Reconstruct cleared cells until the sweep reaches them. The game model
    // has already removed them, so this layer owns their visible dissolution.
    for (final entry in effect.cells.entries) {
      final start = effect.starts[entry.key]!;
      final dissolve = phase(ms, start, 80);
      if (dissolve >= 1) continue;
      final center = Offset(
        (entry.key % 8 + .5) * cell,
        (entry.key ~/ 8 + .5) * cell,
      );
      final charge = phase(ms, 0, 90);
      final scale = 1 + .05 * math.sin(charge * math.pi / 2) - dissolve * .25;
      final rect = Rect.fromCenter(
        center: center,
        width: (cell - 3) * scale,
        height: (cell - 3) * scale,
      );
      final rr = RRect.fromRectAndRadius(rect, const Radius.circular(6));
      fill.color = Color.lerp(
        effect.colors[entry.key],
        Colors.white,
        charge * .65,
      )!.withValues(alpha: 1 - dissolve);
      canvas.drawRRect(rr, fill);
      stroke
        ..color = Colors.white.withValues(
          alpha: (.3 + charge * .7) * (1 - dissolve),
        )
        ..strokeWidth = 1 + charge * 1.5;
      canvas.drawRRect(rr, stroke);
    }

    // Beams are clipped to actual cleared rows/columns, never the whole board.
    for (final line in effect.lines) {
      final t = phase(ms, 270, 330);
      if (t == 0 || t == 1) continue;
      final band = line.vertical
          ? Rect.fromLTWH(line.index * cell, 0, cell, size.height)
          : Rect.fromLTWH(0, line.index * cell, size.width, cell);
      final origin = line.vertical
          ? Offset(band.center.dx, t * (size.height + cell) - cell / 2)
          : Offset(t * (size.width + cell) - cell / 2, band.center.dy);
      canvas.save();
      canvas.clipRect(band);
      final beamRect = Rect.fromCenter(
        center: origin,
        width: line.vertical ? cell : cell * 3,
        height: line.vertical ? cell * 3 : cell,
      );
      fill.shader = LinearGradient(
        begin: line.vertical ? Alignment.topCenter : Alignment.centerLeft,
        end: line.vertical ? Alignment.bottomCenter : Alignment.centerRight,
        colors: const [
          Colors.transparent,
          Color(0xaa72eeff),
          Colors.white,
          Color(0xaaffdf94),
          Colors.transparent,
        ],
      ).createShader(beamRect);
      canvas.drawRect(beamRect, fill);
      fill.shader = null;
      canvas.restore();
    }

    // Ballistic shards, short trails and four-point sparks; no per-frame RNG.
    for (final p in effect.shards) {
      final t = phase(ms, effect.starts[p.cell]!, p.lifetime);
      if (t <= 0 || t >= 1) continue;
      final center = Offset(
        (p.cell % 8 + .5) * cell,
        (p.cell ~/ 8 + .5) * cell,
      );
      final velocity =
          Offset(math.cos(p.angle), math.sin(p.angle)) * cell * p.speed;
      final position = center + velocity * t + Offset(0, cell * 1.5 * t * t);
      final opacity = 1 - phase(t, .35, .65);
      fill.color = p.color.withValues(alpha: opacity);
      canvas.save();
      canvas.translate(position.dx, position.dy);
      canvas.rotate(p.angle + p.spin * t);
      final radius = cell * p.radius * (1 - t * .65);
      if (p.kind == 0) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(
              center: Offset.zero,
              width: radius * 2,
              height: radius * 1.5,
            ),
            const Radius.circular(1.5),
          ),
          fill,
        );
      } else if (p.kind == 1) {
        final star = Path()
          ..moveTo(0, -radius * 1.6)
          ..lineTo(radius * .3, -radius * .3)
          ..lineTo(radius * 1.6, 0)
          ..lineTo(radius * .3, radius * .3)
          ..lineTo(0, radius * 1.6)
          ..lineTo(-radius * .3, radius * .3)
          ..lineTo(-radius * 1.6, 0)
          ..lineTo(-radius * .3, -radius * .3)
          ..close();
        canvas.drawPath(star, fill);
      } else {
        stroke
          ..color = p.color.withValues(alpha: opacity * .6)
          ..strokeWidth = radius * .7
          ..strokeCap = StrokeCap.round;
        canvas.drawLine(Offset(-radius * 3, 0), Offset.zero, stroke);
        canvas.drawCircle(Offset.zero, radius * .65, fill);
      }
      canvas.restore();
    }

    final edge = math.sin(phase(ms, 260, 700) * math.pi);
    if (edge > 0) {
      final frame = RRect.fromRectAndRadius(
        (Offset.zero & size).inflate(3 + phase(ms, 260, 700) * 6),
        const Radius.circular(12),
      );
      stroke
        ..color = const Color(0xff7ef5ff).withValues(alpha: edge * .18)
        ..strokeWidth = 10;
      canvas.drawRRect(frame, stroke);
      stroke
        ..color = Colors.white.withValues(alpha: edge * .8)
        ..strokeWidth = 2;
      canvas.drawRRect(frame, stroke);
    }
  }

  @override
  bool shouldRepaint(covariant _ClearPainter oldDelegate) =>
      oldDelegate.effect != effect || oldDelegate.reduced != reduced;
}
