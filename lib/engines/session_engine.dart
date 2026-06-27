import '../models/session_model.dart';
import 'audio_engine.dart';

class SomniaSessionEngine {
  final SomniaAudioEngine _audioEngine;

  SomniaSession? _currentSession;

  SomniaSessionEngine({
    required SomniaAudioEngine audioEngine,
  }) : _audioEngine = audioEngine;

  SomniaSession? get currentSession => _currentSession;
  bool get hasActiveSession => _currentSession != null;

  Future<void> prepareSession(SomniaSession session) async {
    _currentSession = session;

    await _audioEngine.loadSession(
      backgroundAssetPath: session.backgroundAssetPath,
    );
  }

  Future<void> startSession() async {
    if (_currentSession == null) {
      throw Exception('No session prepared.');
    }

    await _audioEngine.play();
  }

  Future<void> pauseSession() async {
    await _audioEngine.pause();
  }

  Future<void> stopSession() async {
    await _audioEngine.stop();
  }

  Future<void> resetSession() async {
    await _audioEngine.reset();
  }

  Future<void> fadeOutAndStopSession() async {
    await _audioEngine.fadeOutAll();
  }

  void clearSession() {
    _currentSession = null;
  }
}