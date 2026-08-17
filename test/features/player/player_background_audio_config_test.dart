import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Task 19 — host-side iOS/Player background-audio configuration verification.
void main() {
  test('iOS UIBackgroundModes includes audio', () {
    final plist = File('ios/Runner/Info.plist').readAsStringSync();
    expect(plist.contains('UIBackgroundModes'), isTrue);
    expect(plist.contains('<string>audio</string>'), isTrue);
  });

  test('SleepAudioSession configures playback for background bed', () {
    final session = File('lib/features/player/sleep_audio_session.dart')
        .readAsStringSync();
    expect(session.contains('AudioSessionConfiguration.music()'), isTrue);
    expect(session.contains('AVAudioSessionCategory.playback'), isTrue);
    expect(session.contains('configureForBackgroundPlayback'), isTrue);
    expect(session.contains('setActive(true)'), isTrue);
  });

  test('Player does not pause bed on background lifecycle', () {
    final player =
        File('lib/features/player/player_screen.dart').readAsStringSync();
    expect(player.contains('AppLifecycleState.paused'), isFalse);
    expect(
      player.contains('state == AppLifecycleState.resumed && _playing'),
      isTrue,
    );
    // Single bed player instance (declaration + construction only).
    expect(player.contains('final AudioPlayer _bgPlayer = AudioPlayer()'), isTrue);
    expect(RegExp(r'AudioPlayer\(').allMatches(player).length, 1);
  });

  test('Live chat ends Player into Night Complete path', () {
    final chat = File('lib/screens/ai_chat_screen.dart').readAsStringSync();
    final premiumIdx = chat.indexOf('PaywallScreen');
    final playerIdx = chat.indexOf('PlayerScreen(');
    final finishIdx = chat.indexOf('_finishNightAndShowClosing');
    final completeIdx = chat.indexOf('completeNightSession');
    expect(premiumIdx, -1);
    expect(playerIdx, greaterThan(0));
    expect(finishIdx, greaterThan(0));
    expect(completeIdx, greaterThan(0));

    final transitionBlock = chat.substring(
      chat.indexOf('case ExitDecision.transitionToAudio:'),
      chat.indexOf('case ExitDecision.silence:'),
    );
    expect(transitionBlock.contains('_startAudioFlow'), isTrue);
    // Night close runs after audio returns, not before Player starts.
    expect(transitionBlock.contains('_closeNightSession'), isFalse);
    expect(transitionBlock.contains('PaywallScreen'), isFalse);
  });
}
