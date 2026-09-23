import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yerlestir/features/progress/progress.dart';
import 'package:yerlestir/features/gameplay/application/game_session.dart';
import 'package:yerlestir/features/gameplay/domain/puzzle.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late SharedPreferences prefs;
  late ProviderContainer container;
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    container = ProviderContainer(
      overrides: [preferencesProvider.overrideWithValue(prefs)],
    );
  });
  tearDown(() => container.dispose());
  test('corrupt JSON and invalid values recover to defaults', () async {
    await prefs.setString(LocalProgressRepository.key, '{broken');
    expect((await LocalProgressRepository(prefs).load()).coins, 0);
    await prefs.setString(
      LocalProgressRepository.key,
      jsonEncode({...PlayerProgress().toJson(), 'coins': -3}),
    );
    expect((await LocalProgressRepository(prefs).load()).coins, 0);
  });
  test(
    'daily double tap and clock rollback cannot grant extra coins',
    () async {
      final c = container.read(progressProvider.notifier);
      final now = DateTime(2026, 9, 12);
      final result = await Future.wait([c.claim(now), c.claim(now)]);
      expect(result.where((v) => v).length, 1);
      expect(container.read(progressProvider).coins, 20);
      expect(await c.claim(DateTime(2026, 9, 11)), isFalse);
      expect(await c.claim(DateTime(2026, 9, 13)), isTrue);
      expect(container.read(progressProvider).coins, 50);
    },
  );
  test('seven reward days total 460 and cycle to day one', () async {
    final c = container.read(progressProvider.notifier);
    for (var i = 0; i < 7; i++) {
      await c.claim(DateTime(2026, 9, 12 + i));
    }
    expect(container.read(progressProvider).coins, 460);
    expect(container.read(progressProvider).rewardDay, 0);
  });
  test('buy deducts once and rejects insufficient balance', () async {
    final c = container.read(progressProvider.notifier);
    expect(await c.buy('forest', 4990), isFalse);
    await c.change({'coins': 5000});
    expect(await c.buy('forest', 4990), isTrue);
    expect(await c.buy('forest', 4990), isTrue);
    expect(container.read(progressProvider).coins, 10);
    expect(container.read(progressProvider).selectedSkin, 'forest');
  });
  test('replays improve stars but cannot farm level rewards', () async {
    final c = container.read(progressProvider.notifier);
    final game = GameSession(mode: GameMode.journey, level: 1)
      ..score = 999
      ..moves = 19;
    expect(await c.complete(game), 50);
    game.moves = 3;
    expect(await c.complete(game), 0);
    expect(container.read(progressProvider).levelStars['1'], 3);
    expect(container.read(progressProvider).lastPlayedLevel, 2);
    expect(container.read(progressProvider).coins, 50);
  });
  test('settings and session survive repository roundtrip', () async {
    final c = container.read(progressProvider.notifier);
    await c.change({'localeCode': 'en', 'musicEnabled': false});
    final game = GameSession(mode: GameMode.classic, seed: 42)..score = 300;
    await c.saveSession(game);
    final loaded = await LocalProgressRepository(prefs).load();
    expect(loaded.localeCode, 'en');
    expect(loaded.musicEnabled, isFalse);
    expect(
      GameSession.restore(
        Map<String, dynamic>.from(loaded.sessions['classic']),
      )!.score,
      300,
    );
    expect(loaded.highScore, 300);
    await c.reset();
    expect((await LocalProgressRepository(prefs).load()).sessions, isEmpty);
  });
  test('last good snapshot recovers when primary save is corrupted', () async {
    final repo = LocalProgressRepository(prefs);
    await repo.save(PlayerProgress(coins: 50));
    await repo.save(PlayerProgress(coins: 80));
    await prefs.setString(LocalProgressRepository.key, 'broken');
    expect((await repo.load()).coins, 50);
    await repo.clear();
    expect((await repo.load()).coins, 0);
  });
  test('paid hint costs 30 once, survives resume, and does not charge when blocked', () async {
    final c = container.read(progressProvider.notifier);
    final g = GameSession(mode: GameMode.classic, seed: 8);
    expect(await c.buyHint(g), isNull);
    await c.change({'coins': 60});
    final results = await Future.wait([c.buyHint(g), c.buyHint(g)]);
    expect(results[0], isNotNull);
    expect(results[0], results[1]);
    expect(container.read(progressProvider).coins, 30);
    final resumed = GameSession.restore(
      Map<String, dynamic>.from(
        container.read(progressProvider).sessions['classic'],
      ),
    )!;
    expect(await c.buyHint(resumed), results[0]);
    expect(container.read(progressProvider).coins, 30);
    final h = results[0]!;
    expect(resumed.drop(h.$1, h.$2, h.$3), isTrue);
    expect(resumed.paidHint, isNull);
    final blocked = GameSession(mode: GameMode.classic)
      ..board = List.filled(64, 1);
    expect(await c.buyHint(blocked), isNull);
    expect(container.read(progressProvider).coins, 30);
  });
}
