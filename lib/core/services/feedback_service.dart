import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/progress/progress.dart';

final feedbackProvider = Provider<FeedbackService>((ref) {
  final service = FeedbackService();
  ref.onDispose(service.dispose);
  return service;
});

class FeedbackService {
  final _voice = AudioPlayer();
  final _effect = AudioPlayer();
  final _burst = AudioPlayer();
  DateTime? _lastVoice;
  Future<void> celebrate(PlayerProgress settings, int combo) async {
    if (!settings.soundEnabled || combo < 2) return;
    final now = DateTime.now();
    if (_lastVoice != null &&
        now.difference(_lastVoice!).inMilliseconds < 1100) {
      return;
    }
    _lastVoice = now;
    try {
      await _voice.play(AssetSource('sounds/reference_combo.wav'), volume: .55);
    } catch (_) {}
  }

  final _music = AudioPlayer();
  bool _playing = false;
  Future<void> tap(PlayerProgress settings, {bool clear = false}) async {
    if (settings.hapticsEnabled) {
      HapticFeedback.lightImpact();
    }
    if (!settings.soundEnabled) {
      return;
    }
    try {
      await _effect.play(
        AssetSource(
          clear ? 'sounds/reference_clear.wav' : 'sounds/reference_place.wav',
        ),
        volume: .55,
      );
    } catch (_) {}
  }

  Future<void> popLine(PlayerProgress settings, int count) async {
    if (settings.hapticsEnabled) {
      HapticFeedback.mediumImpact();
    }
    if (!settings.soundEnabled || count < 8 || count > 64) {
      return;
    }
    try {
      await _burst.play(AssetSource('sounds/reference_clear.wav'), volume: .65);
    } catch (_) {}
  }

  Future<void> music(bool enabled) async {
    if (_playing == enabled) {
      return;
    }
    _playing = enabled;
    try {
      if (enabled) {
        await _music.setReleaseMode(ReleaseMode.loop);
        await _music.play(AssetSource('sounds/music.wav'), volume: .12);
      } else {
        await _music.pause();
      }
    } catch (_) {
      _playing = false;
    }
  }

  void dispose() {
    _voice.dispose();
    _effect.dispose();
    _burst.dispose();
    _music.dispose();
  }
}
