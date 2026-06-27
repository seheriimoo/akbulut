import 'dart:async';
import 'package:audio_session/audio_session.dart';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';

class SomniaAudioEngine {
  final AudioPlayer _bgPlayer = AudioPlayer();

  double _bgVolume = 0.22;

  bool _isInitialized = false;

  AudioPlayer get bgPlayer => _bgPlayer;

  double get bgVolume => _bgVolume;

  bool get isInitialized => _isInitialized;
  bool get isPlaying => _bgPlayer.playing;

  Future<void> initialize() async {
    if (_isInitialized) return;

    final session = await AudioSession.instance;
    await session.configure(
      const AudioSessionConfiguration.music(),
    );

    _bgPlayer.setLoopMode(LoopMode.one);

    _isInitialized = true;
  }

  Future<void> loadSession({
    required String backgroundAssetPath,
  }) async {
    await initialize();

    await _bgPlayer.setAsset(backgroundAssetPath);
    await _bgPlayer.setVolume(_bgVolume);
  }

  Future<void> play() async {
    await initialize();

    if (_bgPlayer.audioSource != null) {
      await _bgPlayer.play();
    }
  }

  Future<void> pause() async {
    await _bgPlayer.pause();
  }

  Future<void> stop() async {
    await _bgPlayer.stop();
  }

  Future<void> seekToStart() async {
    await _bgPlayer.seek(Duration.zero);
  }

  Future<void> reset() async {
    await stop();
    await seekToStart();
  }

  Future<void> setBackgroundVolume(double value) async {
    _bgVolume = value.clamp(0.0, 1.0);
    await _bgPlayer.setVolume(_bgVolume);
  }

  Future<void> setVolume(double value) async {
    final safeValue = value.clamp(0.0, 1.0);

    try {
      _bgVolume = safeValue;
      await _bgPlayer.setVolume(_bgVolume);
    } catch (e) {
      debugPrint('Volume change failed: $e');
    }
  }

  Future<void> fadeInBackground({
    Duration duration = const Duration(seconds: 3),
    double targetVolume = 0.22,
    int steps = 20,
  }) async {
    final safeTarget = targetVolume.clamp(0.0, 1.0);
    await _bgPlayer.setVolume(0.0);

    if (!_bgPlayer.playing) {
      await _bgPlayer.play();
    }

    final stepDuration = Duration(
      milliseconds: (duration.inMilliseconds / steps).round(),
    );

    for (int i = 1; i <= steps; i++) {
      final volume = safeTarget * (i / steps);
      await _bgPlayer.setVolume(volume);
      await Future.delayed(stepDuration);
    }

    _bgVolume = safeTarget;
  }

  Future<void> fadeOutAll({
    Duration duration = const Duration(seconds: 5),
    int steps = 20,
  }) async {
    final initialBg = _bgVolume;

    final stepDuration = Duration(
      milliseconds: (duration.inMilliseconds / steps).round(),
    );

    for (int i = steps; i >= 0; i--) {
      final factor = i / steps;
      await _bgPlayer.setVolume(initialBg * factor);
      await Future.delayed(stepDuration);
    }

    await stop();
    await _bgPlayer.setVolume(initialBg);
  }

  Stream<Duration?> get backgroundDurationStream => _bgPlayer.durationStream;
  Stream<Duration> get backgroundPositionStream => _bgPlayer.positionStream;
  Stream<PlayerState> get backgroundPlayerStateStream =>
      _bgPlayer.playerStateStream;

  Future<void> dispose() async {
    await _bgPlayer.dispose();
  }
}