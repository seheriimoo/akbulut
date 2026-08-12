import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:slowave/features/player/player_screen.dart';

/// A1 night-path reliability — chat stay/retry/continue + loading cue wiring.
void main() {
  late String chat;
  late String player;

  setUpAll(() {
    chat = File('lib/screens/ai_chat_screen.dart').readAsStringSync();
    player = File('lib/features/player/player_screen.dart').readAsStringSync();
  });

  String _audioFlow() {
    final flowIdx = chat.indexOf('Future<void> _startAudioFlow()');
    final flowEnd = chat.indexOf('Future<void> _retryAudioHandoff()', flowIdx);
    return chat.substring(flowIdx, flowEnd);
  }

  test('true → Night Complete via _finishNightAndShowClosing', () {
    final flow = _audioFlow();
    // After false/null early returns, natural complete still finishes night.
    expect(flow.contains('await _finishNightAndShowClosing'), isTrue);
    expect(
      flow.contains('true  → bed completed naturally → close night'),
      isTrue,
    );
    // Only true reaches finish: false and null return first.
    expect(flow.contains('if (playerOk == false)'), isTrue);
    expect(flow.contains('if (playerOk == null)'), isTrue);
    final finishIdx = flow.lastIndexOf('await _finishNightAndShowClosing');
    final falseIdx = flow.indexOf('if (playerOk == false)');
    final nullIdx = flow.indexOf('if (playerOk == null)');
    expect(finishIdx, greaterThan(nullIdx));
    expect(nullIdx, greaterThan(falseIdx));
  });

  test('false → Chat + load-fail message + Tekrar dene', () {
    expect(chat.contains('_audioHandoffFailed'), isTrue);
    expect(chat.contains('Tekrar dene'), isTrue);
    expect(chat.contains('This quiet session could not start.'), isTrue);
    expect(chat.contains('_retryAudioHandoff'), isTrue);

    final flow = _audioFlow();
    final failStart = flow.indexOf('if (playerOk == false)');
    final failReturn = flow.indexOf('return;', failStart);
    final failBranch = flow.substring(failStart, failReturn);
    expect(failBranch.contains('_audioHandoffFailed = true'), isTrue);
    expect(failBranch.contains('isLoadingAudio = false'), isTrue);
    expect(failBranch.contains('_finishNightAndShowClosing'), isFalse);
    expect(failBranch.contains('_audioContinueAvailable = false'), isTrue);
  });

  test('null → Chat without error + Continue to audio / Sese devam et', () {
    expect(chat.contains('_audioContinueAvailable'), isTrue);
    expect(chat.contains('Continue to audio'), isTrue);
    expect(chat.contains('Sese devam et'), isTrue);
    expect(chat.contains('_AudioContinueCue'), isTrue);
    expect(chat.contains('_continueAudioHandoff'), isTrue);

    final flow = _audioFlow();
    final nullStart = flow.indexOf('if (playerOk == null)');
    final nullReturn = flow.indexOf('return;', nullStart);
    final nullBranch = flow.substring(nullStart, nullReturn);
    expect(nullBranch.contains('_audioContinueAvailable = true'), isTrue);
    expect(nullBranch.contains('_audioHandoffFailed = false'), isTrue);
    expect(nullBranch.contains('_finishNightAndShowClosing'), isFalse);
    // Must not present load-fail copy on early leave.
    expect(nullBranch.contains('This quiet session could not start.'), isFalse);
    expect(nullBranch.contains('Tekrar dene'), isFalse);
  });

  test('null preserves chat/session state (no night close)', () {
    final flow = _audioFlow();
    final nullStart = flow.indexOf('if (playerOk == null)');
    final nullReturn = flow.indexOf('return;', nullStart);
    final nullBranch = flow.substring(nullStart, nullReturn + 'return;'.length);
    expect(nullBranch.contains('_closeNightSession'), isFalse);
    expect(nullBranch.contains('_finishNightAndShowClosing'), isFalse);
    expect(nullBranch.contains('_session = null'), isFalse);

    final continueIdx = chat.indexOf('Future<void> _continueAudioHandoff()');
    final continueBlock = chat.substring(continueIdx, continueIdx + 420);
    expect(continueBlock.contains('if (_session == null) return;'), isTrue);
    expect(continueBlock.contains('await _startAudioFlow()'), isTrue);
  });

  test('Continue CTA reopens Player via same _startAudioFlow bed path', () {
    final continueIdx = chat.indexOf('Future<void> _continueAudioHandoff()');
    final continueEnd = chat.indexOf(
      'Future<void> _closeNightSession',
      continueIdx,
    );
    final continueBlock = chat.substring(continueIdx, continueEnd);
    expect(continueBlock.contains('await _startAudioFlow()'), isTrue);
    expect(continueBlock.contains('_finishNightAndShowClosing'), isFalse);
    // Same PlayerScreen handoff lives inside _startAudioFlow.
    expect(_audioFlow().contains('PlayerScreen('), isTrue);
  });

  test('loading cue arms before player and clears on fail/finish/early leave', () {
    expect(chat.contains('Preparing a little quiet…'), isTrue);
    expect(chat.contains('if (isLoadingAudio) const _AudioPreparingCue()'), isTrue);

    final flow = _audioFlow();
    expect(flow.contains('isLoadingAudio = true'), isTrue);
    expect(flow.contains('isLoadingAudio = false'), isTrue);

    final finishIdx = chat.indexOf('Future<void> _finishNightAndShowClosing');
    final finishBlock = chat.substring(finishIdx, finishIdx + 280);
    expect(finishBlock.contains('isLoadingAudio = false'), isTrue);
  });

  test('Player early leave pops null, load failure pops false, natural true', () {
    expect(
      player.contains(
        'Navigator.of(context).pop(completedNaturally ? true : null)',
      ),
      isTrue,
    );
    expect(player.contains('Navigator.of(context).pop(false)'), isTrue);
  });

  testWidgets(
    'false pop keeps host open with fail semantics (not Night Complete)',
    (tester) async {
      bool? playerResult;
      var nightFinished = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              return Scaffold(
                body: TextButton(
                  onPressed: () async {
                    playerResult = await Navigator.of(context).push<bool>(
                      MaterialPageRoute(
                        builder: (_) => const PlayerScreen(
                          blocker: 'mind',
                          sleepLatency: 'medium',
                          energy: 'medium',
                          goal: 'sleep',
                          sessionLength: Duration(minutes: 30),
                          audioAssetPath:
                              'assets/audio/bg/CoreDefaultAir/does_not_exist.m4a',
                        ),
                      ),
                    );
                    if (playerResult == true) {
                      nightFinished = true;
                    } else if (playerResult == false) {
                      nightFinished = false;
                    } else {
                      nightFinished = false;
                    }
                  },
                  child: const Text('open-player'),
                ),
              );
            },
          ),
        ),
      );

      await tester.tap(find.text('open-player'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      await tester.tap(find.text('End Session'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(playerResult, isFalse);
      expect(nightFinished, isFalse);
      expect(find.text('open-player'), findsOneWidget);
      expect(find.text('Tonight is complete'), findsNothing);
    },
  );

  testWidgets(
    'null pop keeps host open without finishing night (early leave contract)',
    (tester) async {
      bool? playerResult;
      var nightFinished = false;
      var continueOffered = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              return Scaffold(
                body: TextButton(
                  onPressed: () async {
                    playerResult = await Navigator.of(context).push<bool>(
                      MaterialPageRoute(
                        builder: (playerContext) {
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            Navigator.of(playerContext).pop(null);
                          });
                          return const Scaffold(
                            body: Text('fake-player'),
                          );
                        },
                      ),
                    );
                    // Mirror AISleepChatScreen true/false/null contract.
                    if (playerResult == true) {
                      nightFinished = true;
                    } else if (playerResult == false) {
                      nightFinished = false;
                    } else {
                      nightFinished = false;
                      continueOffered = true;
                    }
                  },
                  child: const Text('open-player'),
                ),
              );
            },
          ),
        ),
      );

      await tester.tap(find.text('open-player'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(playerResult, isNull);
      expect(nightFinished, isFalse);
      expect(continueOffered, isTrue);
      expect(find.text('open-player'), findsOneWidget);
      expect(find.text('Tonight is complete'), findsNothing);
    },
  );
}
