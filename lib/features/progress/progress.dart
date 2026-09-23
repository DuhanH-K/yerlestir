import 'dart:convert';
import 'dart:math';

import '../../core/services/storage_status.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../gameplay/application/game_session.dart';
import '../gameplay/domain/puzzle.dart';

final preferencesProvider = Provider<SharedPreferences>(
  (ref) => throw StateError('Bootstrap required'),
);
final progressProvider = NotifierProvider<ProgressController, PlayerProgress>(
  ProgressController.new,
);

class PlayerProgress {
  PlayerProgress({
    this.coins = 0,
    this.highScore = 0,
    this.lastPlayedLevel = 1,
    this.selectedSkin = 'default',
    Map<String, int>? levelStars,
    Set<String>? unlockedItems,
    this.lastRewardDate = 0,
    this.rewardDay = 0,
    this.soundEnabled = true,
    this.musicEnabled = true,
    this.hapticsEnabled = true,
    this.parentalGateEnabled = false,
    this.localeCode = 'tr',
    Map<String, dynamic>? sessions,
    Set<String>? rewardedRuns,
  }) : levelStars = Map.unmodifiable(levelStars ?? {}),
       unlockedItems = Set.unmodifiable(unlockedItems ?? {'default'}),
       sessions = Map.unmodifiable(sessions ?? {}),
       rewardedRuns = Set.unmodifiable(rewardedRuns ?? {});
  final int coins, highScore, lastPlayedLevel, lastRewardDate, rewardDay;
  final String selectedSkin, localeCode;
  final Map<String, int> levelStars;
  final Set<String> unlockedItems, rewardedRuns;
  final Map<String, dynamic> sessions;
  final bool soundEnabled, musicEnabled, hapticsEnabled, parentalGateEnabled;
  int get totalStars => levelStars.values.fold(0, (a, b) => a + b);
  Set<String> get completedLevels => levelStars.keys.toSet();
  int get collectionCount => min(24, levelStars.length ~/ 5);
  bool canClaim(DateTime now) => LevelFactory.dailySeed(now) > lastRewardDate;
  Map<String, dynamic> toJson() => {
    'version': 1,
    'coins': coins,
    'highScore': highScore,
    'lastPlayedLevel': lastPlayedLevel,
    'selectedSkin': selectedSkin,
    'levelStars': levelStars,
    'unlockedItems': unlockedItems.toList(),
    'lastRewardDate': lastRewardDate,
    'rewardDay': rewardDay,
    'soundEnabled': soundEnabled,
    'musicEnabled': musicEnabled,
    'hapticsEnabled': hapticsEnabled,
    'parentalGateEnabled': parentalGateEnabled,
    'localeCode': localeCode,
    'sessions': sessions,
    'rewardedRuns': rewardedRuns.toList(),
  };
  factory PlayerProgress.fromJson(Map<String, dynamic> j) {
    if (j['version'] != 1) {
      throw const FormatException('Unsupported save');
    }
    final coins = j['coins'] as int;
    final stars = Map<String, int>.from(j['levelStars']);
    final day = j['rewardDay'] as int;
    if (coins < 0 ||
        day < 0 ||
        day > 6 ||
        stars.values.any((s) => s < 1 || s > 3)) {
      throw const FormatException('Invalid progress');
    }
    return PlayerProgress(
      coins: coins,
      highScore: j['highScore'],
      lastPlayedLevel: j['lastPlayedLevel'],
      selectedSkin: j['selectedSkin'],
      levelStars: stars,
      unlockedItems: Set<String>.from(j['unlockedItems']),
      lastRewardDate: j['lastRewardDate'],
      rewardDay: day,
      soundEnabled: j['soundEnabled'],
      musicEnabled: j['musicEnabled'],
      hapticsEnabled: j['hapticsEnabled'],
      parentalGateEnabled: j['parentalGateEnabled'],
      localeCode: j['localeCode'],
      sessions: Map<String, dynamic>.from(j['sessions'] ?? {}),
      rewardedRuns: Set<String>.from(j['rewardedRuns'] ?? []),
    );
  }
}

abstract interface class ProgressRepository {
  Future<PlayerProgress> load();
  Future<void> save(PlayerProgress progress);
  Future<void> clear();
}

class LocalProgressRepository implements ProgressRepository {
  LocalProgressRepository(this.preferences);
  final SharedPreferences preferences;
  static const key = 'yerlestir_progress_v1';
  PlayerProgress read() {
    for (final candidate in [key, '${key}_backup']) {
      try {
        return PlayerProgress.fromJson(
          jsonDecode(preferences.getString(candidate) ?? '')
              as Map<String, dynamic>,
        );
      } catch (_) {
        /* Try the last known-good snapshot. */
      }
    }
    return PlayerProgress();
  }

  @override
  Future<PlayerProgress> load() async => read();
  @override
  Future<void> save(PlayerProgress progress) async {
    final previous = preferences.getString(key);
    if (previous != null) {
      try {
        PlayerProgress.fromJson(jsonDecode(previous) as Map<String, dynamic>);
        await preferences.setString('${key}_backup', previous);
      } catch (_) {
        /* Keep the existing valid backup. */
      }
    }
    if (!await preferences.setString(key, jsonEncode(progress.toJson()))) {
      throw StateError('Save failed');
    }
  }

  @override
  Future<void> clear() async {
    await preferences.remove(key);
    await preferences.remove('${key}_backup');
  }
}

class ProgressController extends Notifier<PlayerProgress> {
  late LocalProgressRepository repository;
  Future<void> _pending = Future.value();
  @override
  PlayerProgress build() {
    repository = LocalProgressRepository(ref.read(preferencesProvider));
    final initial = repository.read();
    _pending = repository.save(initial).catchError((Object _) {});
    return initial;
  }

  Future<void> change(Map<String, dynamic> changes) {
    state = PlayerProgress.fromJson({...state.toJson(), ...changes});
    final snapshot = state;
    _pending = _pending.catchError((Object _) {}).then((_) async {
      try {
        await repository.save(snapshot);
        if (ref.mounted) {
          ref.read(storageStatusProvider.notifier).report(true);
        }
      } catch (_) {
        if (ref.mounted) {
          ref.read(storageStatusProvider.notifier).report(false);
        }
      }
    });
    return _pending;
  }

  Future<bool> claim(DateTime now) async {
    if (!state.canClaim(now)) {
      return false;
    }
    await change({
      'coins': state.coins + dailyRewards[state.rewardDay],
      'lastRewardDate': LevelFactory.dailySeed(now),
      'rewardDay': (state.rewardDay + 1) % 7,
    });
    return true;
  }

  Future<bool> buy(String id, int cost) async {
    if (state.unlockedItems.contains(id)) {
      await change({'selectedSkin': id});
      return true;
    }
    if (cost < 0 || state.coins < cost) {
      return false;
    }
    await change({
      'coins': state.coins - cost,
      'unlockedItems': [...state.unlockedItems, id],
      'selectedSkin': id,
    });
    return true;
  }

  static const hintPrice = 30;
  Future<(int, int, int)?> buyHint(GameSession game) async {
    if (game.paidHint != null) {
      return game.paidHint;
    }
    final location = game.findHint();
    if (location == null || state.coins < hintPrice) {
      return null;
    }
    game.paidHint = location;
    await change({
      'coins': state.coins - hintPrice,
      'sessions': {...state.sessions, game.mode.name: game.toJson()},
    });
    return location;
  }

  /// Applies a hint earned from a rewarded ad without charging coins.
  Future<(int, int, int)?> claimHintFromReward(GameSession game) async {
    if (game.paidHint != null) return game.paidHint;
    final location = game.findHint();
    if (location == null) return null;
    game.paidHint = location;
    await change({
      'sessions': {...state.sessions, game.mode.name: game.toJson()},
    });
    return location;
  }

  Future<void> saveSession(GameSession game) => change({
    'sessions': {...state.sessions, game.mode.name: game.toJson()},
    if (game.mode == GameMode.journey) 'lastPlayedLevel': game.level,
    'highScore': game.mode == GameMode.classic
        ? max(state.highScore, game.score)
        : state.highScore,
  });
  Future<int> complete(GameSession game) async {
    final id = game.mode == GameMode.journey
        ? 'level_${game.level}'
        : game.mode == GameMode.daily
        ? 'daily_${game.seed}'
        : 'classic_${game.seed}';
    final eligible =
        game.won || (game.mode == GameMode.classic && game.score >= 500);
    final reward = eligible && !state.rewardedRuns.contains(id)
        ? (game.mode == GameMode.classic ? 20 : 50 + (game.stars == 3 ? 20 : 0))
        : 0;
    final stars = {...state.levelStars};
    if (game.won && game.mode == GameMode.journey) {
      stars['${game.level}'] = max(stars['${game.level}'] ?? 0, game.stars);
    }
    final sessions = {...state.sessions}..remove(game.mode.name);
    await change({
      'coins': state.coins + reward,
      'levelStars': stars,
      'highScore': game.mode == GameMode.classic
          ? max(state.highScore, game.score)
          : state.highScore,
      'rewardedRuns': {...state.rewardedRuns, if (eligible) id}.toList(),
      'sessions': sessions,
      if (game.won && game.mode == GameMode.journey)
        'lastPlayedLevel': min(120, game.level + 1),
    });
    return reward;
  }

  Future<void> reset() async {
    await _pending;
    await repository.clear();
    state = PlayerProgress();
    await change(state.toJson());
  }
}
