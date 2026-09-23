from pathlib import Path
p=Path('lib/features/daily_reward/reward_screen.dart');s=p.read_text(encoding='utf-8-sig').replace(r'\$\{dailyRewards[i]\}', '${dailyRewards[i]}');p.write_text(s,encoding='utf-8')
