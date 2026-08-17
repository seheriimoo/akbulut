import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// UI lock + single-flight audio wiring for transitionToAudio.
void main() {
  late String chat;

  setUpAll(() {
    chat = File('lib/screens/ai_chat_screen.dart').readAsStringSync();
  });

  test('handoff lock arms before spoken delay and starts single audio flow', () {
    expect(chat.contains('_dismissKeyboardAndClearDraft'), isTrue);
    expect(chat.contains('_audioFlowRunning'), isTrue);
    expect(chat.contains('_sendInFlight'), isTrue);
    expect(chat.contains('focusNode: _inputFocus'), isTrue);
    expect(chat.contains('readOnly: !_acceptsUserInput'), isTrue);

    final genIdx = chat.indexOf('Future<void> _generateAIResponse');
    final genEnd = chat.indexOf('Future<void> _addAIMessage', genIdx);
    final gen = chat.substring(genIdx, genEnd);
    expect(gen.contains('isLoadingAudio = true'), isTrue);
    expect(gen.contains('_dismissKeyboardAndClearDraft()'), isTrue);
    expect(gen.contains('await _startAudioFlow()'), isTrue);

    // Loading is set before the spoken-handoff delay.
    final loadIdx = gen.indexOf('isLoadingAudio = true');
    final delayIdx = gen.indexOf('Duration(milliseconds: 1600)');
    final startIdx = gen.indexOf('await _startAudioFlow()');
    expect(loadIdx, greaterThan(0));
    expect(delayIdx, greaterThan(loadIdx));
    expect(startIdx, greaterThan(delayIdx));
  });

  test('single-flight _startAudioFlow rejects re-entrant navigation', () {
    final flowIdx = chat.indexOf('Future<void> _startAudioFlow()');
    final flowEnd = chat.indexOf('Future<void> _retryAudioHandoff()', flowIdx);
    final flow = chat.substring(flowIdx, flowEnd);
    expect(flow.contains('if (_audioFlowRunning) return;'), isTrue);
    expect(flow.contains('_audioFlowRunning = true;'), isTrue);
    expect(flow.contains('_audioFlowRunning = false;'), isTrue);
  });

  test('false reopens input; null keeps input closed with continue CTA', () {
    expect(chat.contains('if (exit == ExitDecision.transitionToAudio)'), isTrue);
    expect(chat.contains('return _audioHandoffFailed;'), isTrue);
    expect(chat.contains('if (_audioContinueAvailable) return false;'), isTrue);
    expect(chat.contains('_sessionUiLanguage'), isTrue);
    expect(chat.contains('continueAudioLabel(_sessionUiLanguage)'), isTrue);
    expect(chat.contains('_audioRetryLabel'), isTrue);
    final locale = File('lib/screens/session_ui_language.dart').readAsStringSync();
    expect(locale.contains('Sese devam et'), isTrue);
    expect(locale.contains('Continue to audio'), isTrue);
    expect(locale.contains('Tekrar dene'), isTrue);
    expect(locale.contains('Try again'), isTrue);
  });

  test('true still finishes night via _finishNightAndShowClosing', () {
    final flowIdx = chat.indexOf('Future<void> _startAudioFlow()');
    final flowEnd = chat.indexOf('Future<void> _retryAudioHandoff()', flowIdx);
    final flow = chat.substring(flowIdx, flowEnd);
    expect(flow.contains('await _finishNightAndShowClosing'), isTrue);
    expect(flow.contains('if (playerOk == false)'), isTrue);
    expect(flow.contains('if (playerOk == null)'), isTrue);
  });
}
