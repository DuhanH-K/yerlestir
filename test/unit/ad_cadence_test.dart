import 'package:flutter_test/flutter_test.dart';
import 'package:yerlestir/core/services/ad_service.dart';

void main() {
  test('ads require real gameplay depth and a longer cooldown', () {
    final start = DateTime(2026);
    final cadence = AdCadence(start);

    cadence.completeRound(2);
    expect(cadence.eligible(start.add(const Duration(seconds: 1))), isFalse);

    cadence.completeRound(12);
    cadence.completeRound(12);
    expect(cadence.eligible(start.add(const Duration(seconds: 1))), isTrue);
    expect(cadence.eligible(start.add(const Duration(seconds: 89))), isTrue);

    cadence.shown(start.add(const Duration(seconds: 89)));
    expect(cadence.eligible(start.add(const Duration(seconds: 89))), isFalse);

    cadence.completeRound(12);
    cadence.completeRound(12);
    expect(cadence.eligible(start.add(const Duration(seconds: 179))), isTrue);
  });
}
