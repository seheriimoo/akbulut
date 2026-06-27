import 'dart:async';

import '../../core/audio_engine/audio_engine.dart';
import '../../core/session_engine/sleep_session.dart';
import 'player_state.dart';

class SessionController {
  final SomniaAudioEngine _audioEngine;
  final SleepSession session;

  PlayerStatus _status = PlayerStatus.idle;
  String? _errorMessage;
  Timer? _sessionTimer;

  SessionController({
    required SomniaAudioEngine audioEngine,
    required this.session,
  }) : _audioEngine = audioEngine;

  PlayerStatus get status => _status;
  String? get errorMessage => _errorMessage;

  bool get isPlaying => _status == PlayerStatus.playing;
  bool get isPreparing => _status == PlayerStatus.preparing;
  bool get isPaused => _status == PlayerStatus.paused;
  bool get isCompleted => _status == PlayerStatus.completed;
  bool get hasError => _status == PlayerStatus.error;

  Future<void> prepareAndPlay() async {
    try {
      _setStatus(PlayerStatus.preparing);
      _errorMessage = null;

      await _audioEngine.init();
      await _audioEngine.loadSession(
        backgroundAsset: session.backgroundAsset,
        voiceAsset: session.voiceAsset,
        backgroundVolume: session.backgroundVolume,
        voiceVolume: session.voiceVolume,
      );

      await _audioEngine.play();
      _setStatus(PlayerStatus.playing);
      _startSessionTimer();
    } catch (e) {
      _setError(e.toString());
    }
  }

  Future<void> togglePlayPause() async {
    try {
      if (_status == PlayerStatus.playing) {
        await _audioEngine.pause();
        _cancelTimer();
        _setStatus(PlayerStatus.paused);
        return;
      }

      if (_status == PlayerStatus.paused) {
        await _audioEngine.play();
        _setStatus(PlayerStatus.playing);
        _startSessionTimer();
      }
    } catch (e) {
      _setError(e.toString());
    }
  }

  Future<void> stopWithFade() async {
    try {
      _cancelTimer();
      _setStatus(PlayerStatus.fadingOut);
      await _audioEngine.fadeOut(duration: session.fadeOutDuration);
      _setStatus(PlayerStatus.completed);
    } catch (e) {
      _setError(e.toString());
    }
  }

  Future<void> setBackgroundVolume(double value) async {
    try {
      await _audioEngine.setBackgroundVolume(value);
    } catch (e) {
      _setError(e.toString());
    }
  }

  Future<void> setVoiceVolume(double value) async {
    try {
      await _audioEngine.setVoiceVolume(value);
    } catch (e) {
      _setError(e.toString());
    }
  }

  Stream<Duration?> get positionStream => _audioEngine.backgroundPositionStream;
  Stream<Duration?> get durationStream => _audioEngine.backgroundDurationStream;

  void dispose() {
    _cancelTimer();
    _audioEngine.dispose();
  }

  void _startSessionTimer() {
    _cancelTimer();

    _sessionTimer = Timer(session.duration, () async {
      await stopWithFade();
    });
  }

  void _cancelTimer() {
    _sessionTimer?.cancel();
    _sessionTimer = null;
  }

  void _setStatus(PlayerStatus value) {
    _status = value;
  }

  void _setError(String message) {
    _errorMessage = message;
    _status = PlayerStatus.error;
  }
}
