import 'dart:async';
import 'package:just_audio/just_audio.dart';

class SomniaAudioEngine {
  final AudioPlayer backgroundPlayer = AudioPlayer();
  final AudioPlayer voicePlayer = AudioPlayer();

  bool _isInitialized = false;

  Future<void> init() async {
    if (_isInitialized) return;
    _isInitialized = true;
  }

  Future<void> loadSession({
    required String backgroundAsset,
    String? voiceAsset,
    double backgroundVolume = 0.22,
    double voiceVolume = 1.0,
    bool loopBackground = true,
  }) async {
    await backgroundPlayer.setVolume(backgroundVolume);
    await voicePlayer.setVolume(voiceVolume);

    await backgroundPlayer.setAsset(backgroundAsset);

    if (loopBackground) {
      await backgroundPlayer.setLoopMode(LoopMode.one);
    } else {
      await backgroundPlayer.setLoopMode(LoopMode.off);
    }

    if (voiceAsset != null && voiceAsset.isNotEmpty) {
      await voicePlayer.setAsset(voiceAsset);
    }
  }

  Future<void> play() async {
    await backgroundPlayer.play();
    if (voicePlayer.audioSource != null) {
      await voicePlayer.play();
    }
  }

  Future<void> pause() async {
    await backgroundPlayer.pause();
    await voicePlayer.pause();
  }

  Future<void> stop() async {
    await backgroundPlayer.stop();
    await voicePlayer.stop();
  }

  Future<void> setBackgroundVolume(double value) async {
    await backgroundPlayer.setVolume(value.clamp(0.0, 1.0));
  }

  Future<void> setVoiceVolume(double value) async {
    await voicePlayer.setVolume(value.clamp(0.0, 1.0));
  }

  Future<void> fadeOut({
    Duration duration = const Duration(seconds: 20),
    int steps = 20,
  }) async {
    final startBg = backgroundPlayer.volume;
    final startVoice = voicePlayer.volume;

    if (steps <= 0) {
      await stop();
      return;
    }

    final stepDelay = Duration(
      milliseconds: (duration.inMilliseconds / steps).round(),
    );

    for (int i = steps; i >= 1; i--) {
      final factor = i / steps;
      await backgroundPlayer.setVolume(startBg * factor);
      await voicePlayer.setVolume(startVoice * factor);
      await Future.delayed(stepDelay);
    }

    await stop();
  }

  Stream<Duration?> get backgroundPositionStream =>
      backgroundPlayer.positionStream;

  Stream<Duration?> get backgroundDurationStream =>
      backgroundPlayer.durationStream;

  bool get isPlaying => backgroundPlayer.playing || voicePlayer.playing;

  Future<void> dispose() async {
    await backgroundPlayer.dispose();
    await voicePlayer.dispose();
  }
}
