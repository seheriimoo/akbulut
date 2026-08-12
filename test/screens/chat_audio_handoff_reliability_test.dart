import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// A1 night-path reliability — chat stay/retry + loading cue wiring.
void main() {
  late String chat;

  setUpAll(() {
    chat = File('lib/screens/ai_chat_screen.dart').readAsStringSync();
  });

  test('broken/missing audio keeps chat open and offers Tekrar dene', () {
    expect(chat.contains('_audioHandoffFailed'), isTrue);
    expect(chat.contains('Tekrar dene'), isTrue);
    expect(chat.contains('_retryAudioHandoff'), isTrue);

    final flowIdx = chat.indexOf('Future<void> _startAudioFlow()');
    expect(flowIdx, greaterThan(0));
    final flowEnd = chat.indexOf('Future<void> _retryAudioHandoff()', flowIdx);
    final flow = chat.substring(flowIdx, flowEnd);

    // Load failure must clear loading and set fail flag without finishing night.
    expect(flow.contains('if (playerOk == false)'), isTrue);
    final failStart = flow.indexOf('if (playerOk == false)');
    final failReturn = flow.indexOf('return;', failStart);
    expect(failReturn, greaterThan(failStart));
    final failBranch = flow.substring(failStart, failReturn);
    expect(failBranch.contains('_audioHandoffFailed = true'), isTrue);
    expect(failBranch.contains('isLoadingAudio = false'), isTrue);
    expect(failBranch.contains('_finishNightAndShowClosing'), isFalse);
  });

  test('loading cue arms before player and clears on fail/finish', () {
    expect(chat.contains('Preparing a little quiet…'), isTrue);
    expect(chat.contains('_AudioPreparingCue'), isTrue);
    expect(chat.contains('if (isLoadingAudio) const _AudioPreparingCue()'), isTrue);

    final flowIdx = chat.indexOf('Future<void> _startAudioFlow()');
    final flowEnd = chat.indexOf('Future<void> _retryAudioHandoff()', flowIdx);
    final flow = chat.substring(flowIdx, flowEnd);
    expect(flow.contains('isLoadingAudio = true'), isTrue);

    final finishIdx = chat.indexOf('Future<void> _finishNightAndShowClosing');
    final finishBlock = chat.substring(finishIdx, finishIdx + 280);
    expect(finishBlock.contains('isLoadingAudio = false'), isTrue);

    final transitionBlock = chat.substring(
      chat.indexOf('ExitDecision.transitionToAudio'),
      chat.indexOf('ExitDecision.silence'),
    );
    expect(transitionBlock.contains('isLoadingAudio = true'), isTrue);
  });

  test('user-left player (null) still finishes night; false does not', () {
    final flowIdx = chat.indexOf('Future<void> _startAudioFlow()');
    final flowEnd = chat.indexOf('Future<void> _retryAudioHandoff()', flowIdx);
    final flow = chat.substring(flowIdx, flowEnd);

    expect(
      flow.contains('false → bed load/play failed → stay on chat + retry'),
      isTrue,
    );
    expect(
      flow.contains('null  → user left player early → close night'),
      isTrue,
    );

    // After the false early-return, natural/null paths still finish night.
    final afterFail = flow.substring(flow.indexOf('if (playerOk == false)'));
    final returnIdx = afterFail.indexOf('return;');
    final afterReturn = afterFail.substring(returnIdx);
    expect(afterReturn.contains('_finishNightAndShowClosing'), isTrue);
  });

  test('Player early leave pops null, load failure pops false', () {
    final player =
        File('lib/features/player/player_screen.dart').readAsStringSync();
    expect(
      player.contains('Navigator.of(context).pop(completedNaturally ? true : null)'),
      isTrue,
    );
    expect(player.contains('Navigator.of(context).pop(false)'), isTrue);
  });
}
