from pathlib import Path
p=Path('lib/features/gameplay/domain/puzzle.dart');s=p.read_text(encoding='utf-8').replace('220 + min(level, count) * 35,','220 + min(level, count) * 12,').replace('20 + min(level ~/ 5, 12),','24 + min(level ~/ 10, 12),');s=s.replace('  static int dailySeed(DateTime date) =>','''  static LevelConfig daily(int seed) => LevelConfig(1, 700 + (seed % 3) * 150, 28 + (seed % 3) * 2, 'Daily');

  static List<int> startingBoard(GameMode mode, int level, int seed) {
    final board = List<int>.filled(boardSize * boardSize, 0);
    if (mode == GameMode.classic) return board;
    final random = Random(mode == GameMode.journey ? level * 7919 : seed);
    final rows = mode == GameMode.daily ? 3 : 1 + min((level - 1) ~/ 40, 2);
    for (var r = 0; r < rows; r++) {
      final gap = random.nextInt(5);
      for (var c = 0; c < boardSize; c++) {
        if (c < gap || c >= gap + 3) {
          board[(7-r*2) * boardSize + c] = 1 + random.nextInt(5);
        }
      }
    }
    return board;
  }

  static int dailySeed(DateTime date) =>''');p.write_text(s,encoding='utf-8')
p=Path('lib/features/gameplay/application/game_session.dart');s=p.read_text(encoding='utf-8').replace('seed = seed ?? DateTime.now().microsecondsSinceEpoch {','seed = seed ?? (mode == GameMode.journey ? level * 7919 : mode == GameMode.daily ? LevelFactory.dailySeed(DateTime.now()) : DateTime.now().microsecondsSinceEpoch) {').replace('    _random = Random(this.seed);','    _random = Random(this.seed);\n    board = LevelFactory.startingBoard(mode, level, this.seed);').replace('mode == GameMode.daily ? 800 : LevelFactory.create(level).target','mode == GameMode.daily ? LevelFactory.daily(seed).target : LevelFactory.create(level).target').replace('mode == GameMode.daily ? 30 : LevelFactory.create(level).moves','mode == GameMode.daily ? LevelFactory.daily(seed).moves : LevelFactory.create(level).moves');p.write_text(s,encoding='utf-8')
p=Path('lib/features/home/home_screen.dart');s=p.read_text(encoding='utf-8').replace("import '../progress/progress.dart';", "import '../progress/progress.dart';\nimport '../gameplay/domain/puzzle.dart';").replace('    final p = ref.watch(progressProvider);', '''    final p = ref.watch(progressProvider);
    final dailySeed = LevelFactory.dailySeed(DateTime.now());
    final daily = LevelFactory.daily(dailySeed);
    final dailyDone = p.rewardedRuns.contains('daily_$dailySeed');''').replace("tr(ref, '30 hamle', '30 moves')", "tr(ref, '${daily.moves} hamle', '${daily.moves} moves')").replace("'Hedef puana ulaş, yıldız kazan ve yeni bölümleri aç.'", "'Bölüm ${p.lastPlayedLevel}: hazır çizgileri tamamla, yıldız kazan ve ilerle.'").replace("'Reach the target, earn stars and unlock levels.'", "'Level ${p.lastPlayedLevel}: finish the starting rows, earn stars and progress.'").replace("'Her gün yeni bulmaca: 30 hamlede 800 puan.'", "dailyDone ? 'Bugünün ödülünü aldın! Yarın yeni bulmaca. İstersen tekrar oyna.' : 'Bugünün hedefi: ${daily.moves} hamlede ${daily.target} puan. Her gün yeni tahta!'").replace("'A new daily puzzle: 800 points in 30 moves.'", "dailyDone ? 'Daily reward earned! A new puzzle tomorrow. Replay for practice.' : 'Today: ${daily.target} points in ${daily.moves} moves. A new board every day!'");p.write_text(s,encoding='utf-8')
p=Path('lib/features/settings/settings_screen.dart');s=p.read_text(encoding='utf-8');s=s.replace('Uygulama içinden veri gönderilmez.', 'Uygulama içinden veri gönderilmez.\\n\\nSesler: Great, Excellent, Awesome — rhodesmas / Freesound, CC BY 4.0.\\nhttps://freesound.org/people/rhodesmas/packs/17959/\\nhttps://creativecommons.org/licenses/by/4.0/').replace('No data is sent from the app.', 'No data is sent from the app.\\n\\nVoices: Great, Excellent, Awesome — rhodesmas / Freesound, CC BY 4.0.\\nhttps://freesound.org/people/rhodesmas/packs/17959/\\nhttps://creativecommons.org/licenses/by/4.0/');p.write_text(s,encoding='utf-8')
