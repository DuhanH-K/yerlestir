from pathlib import Path
import urllib.request
from PIL import Image
for id,name in [(320659,'great'),(320660,'excellent'),(320661,'awesome')]:
    urllib.request.urlretrieve(f'https://cdn.freesound.org/previews/320/{id}_5260872-hq.mp3',f'assets/sounds/voice_{name}.mp3')
source=Path(r'C:\Users\pc\.codex\generated_images\01a097e6-e0f9-7652-b199-44b4d276706f\exec-15ffde82-81e1-4335-b6e4-d302dfe53140.png')
im=Image.open(source).convert('RGB')
im.save('assets/backgrounds/app_icon.png')
for density,size in [('mdpi',48),('hdpi',72),('xhdpi',96),('xxhdpi',144),('xxxhdpi',192)]:
    im.resize((size,size),Image.Resampling.LANCZOS).save(f'android/app/src/main/res/mipmap-{density}/ic_launcher.png')
for size in [192,512]:
    for prefix in ['Icon','Icon-maskable']:
        im.resize((size,size),Image.Resampling.LANCZOS).save(f'web/icons/{prefix}-{size}.png')
im.resize((64,64),Image.Resampling.LANCZOS).save('web/favicon.png')
p=Path('android/app/src/main/AndroidManifest.xml');s=p.read_text(encoding='utf-8').replace('@drawable/ic_launcher','@mipmap/ic_launcher').replace('        <intent><action android:name="android.intent.action.TTS_SERVICE" /></intent>\n','');p.write_text(s,encoding='utf-8')
p=Path('web/index.html');s=p.read_text(encoding='utf-8').replace('type="image/svg+xml" href="favicon.svg"','type="image/png" href="favicon.png"');p.write_text(s,encoding='utf-8')
p=Path('lib/core/services/feedback_service.dart');s=p.read_text(encoding='utf-8');start=s.index("  static const _voice");end=s.index('  final _music',start);s=s[:start]+'''  final _voice = AudioPlayer();
  final _effect = AudioPlayer();
  DateTime? _lastVoice;
  Future<void> celebrate(PlayerProgress settings, int combo) async {
    if (!settings.soundEnabled) return;
    final now = DateTime.now();
    if (_lastVoice != null && now.difference(_lastVoice!).inMilliseconds < 1100) return;
    _lastVoice = now;
    final clip = combo >= 3 ? 'awesome' : combo == 2 ? 'excellent' : 'great';
    try {
      await _voice.play(AssetSource('sounds/voice_$clip.mp3'), volume: .75);
    } catch (_) {}
  }

'''+s[end:];s=s.replace('    _effect.dispose();','    _voice.dispose();\n    _effect.dispose();');p.write_text(s,encoding='utf-8')
Path('android/app/src/main/kotlin/com/yerlestir/game/yerlestir/MainActivity.kt').write_text('package com.yerlestir.game.yerlestir\n\nimport io.flutter.embedding.android.FlutterActivity\n\nclass MainActivity : FlutterActivity()\n',encoding='utf-8')
Path('assets/sounds/VOICE_LICENSE.md').write_text('''# Voice pack attribution
Female Voice: Great, Excellent, Awesome — rhodesmas (2015), Freesound.
Licensed under Creative Commons Attribution 4.0: https://creativecommons.org/licenses/by/4.0/
https://freesound.org/people/rhodesmas/sounds/320659/
https://freesound.org/people/rhodesmas/sounds/320660/
https://freesound.org/people/rhodesmas/sounds/320661/
Public HQ MP3 previews included unchanged, renamed voice_great.mp3, voice_excellent.mp3, voice_awesome.mp3.
The creator describes the source as speech synthesis processed with Lexicon LXP.
No Block Blast game recordings are included. Attribution is also displayed in Settings.
''',encoding='utf-8')
