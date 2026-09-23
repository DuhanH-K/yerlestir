import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yerlestir/features/gameplay/presentation/game_ending.dart';

void main() {
  testWidgets('ending animates over the board and blocks touches', (
    tester,
  ) async {
    var taps = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Stack(
            children: [
              Positioned.fill(
                child: GestureDetector(
                  onTap: () => taps++,
                  child: const ColoredBox(color: Colors.blue),
                ),
              ),
              const GameEnding(
                won: true,
                title: 'Bölüm tamamlandı!',
                subtitle: 'Harika!',
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 200));
    final entering = tester.widget<Opacity>(
      find
          .ancestor(
            of: find.text('Bölüm tamamlandı!'),
            matching: find.byType(Opacity),
          )
          .first,
    );
    expect(entering.opacity, inExclusiveRange(0, 1));
    await tester.tapAt(const Offset(10, 10));
    expect(taps, 0);
    await tester.pump(gameEndingDuration);
    expect(find.text('Bölüm tamamlandı!'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
