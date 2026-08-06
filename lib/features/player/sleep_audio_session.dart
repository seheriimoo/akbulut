import 'package:audio_session/audio_session.dart'
    hide
        AVAudioSessionCategory,
        AVAudioSessionCategoryOptions,
        AndroidAudioFocus;
import 'package:audioplayers/audioplayers.dart';

/// Production sleep-audio session setup for background / lock-screen playback.
///
/// Not HCOS. Used only by the player after Conversation → Audio handoff.
class SleepAudioSession {
  SleepAudioSession._();

  /// Configure OS audio session + audioplayers for continuous bed playback.
  static Future<void> configureForBackgroundPlayback(AudioPlayer player) async {
    final session = await AudioSession.instance;
    await session.configure(const AudioSessionConfiguration.music());

    final context = AudioContext(
      iOS: AudioContextIOS(
        category: AVAudioSessionCategory.playback,
        options: const {},
      ),
      android: const AudioContextAndroid(
        isSpeakerphoneOn: false,
        stayAwake: true,
        contentType: AndroidContentType.music,
        usageType: AndroidUsageType.media,
        audioFocus: AndroidAudioFocus.gain,
      ),
    );

    await AudioPlayer.global.setAudioContext(context);
    await player.setAudioContext(context);
    await player.setPlayerMode(PlayerMode.mediaPlayer);
    await player.setReleaseMode(ReleaseMode.stop);

    await session.setActive(true);
  }

  /// Keep the session active while sleep audio is audible.
  static Future<void> activate() async {
    final session = await AudioSession.instance;
    await session.setActive(true);
  }

  /// Release focus when the sleep session fully stops.
  static Future<void> deactivate() async {
    final session = await AudioSession.instance;
    await session.setActive(false);
  }
}
