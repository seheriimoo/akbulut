import 'package:flutter_test/flutter_test.dart';
import 'package:slowave/core/brain/conversation_grounding_buffer.dart';
import 'package:slowave/core/brain/session_locale.dart';
import 'package:slowave/core/brain/utterance_guard.dart';
import 'package:slowave/core/brain/conversation_expression_mode.dart';
import 'package:slowave/core/brain/conversation_phase.dart';
import 'package:slowave/core/brain/conversation_utterance.dart';

void main() {
  test('session blob detects ASCII Turkish current turn', () {
    final blob = SessionLocale.userEvidenceBlob(
      conversationGrounding: const ConversationGroundingBuffer.empty()
          .appendUserUtterance('5000 kelime yazmam lazım pazar')
          .appendUserUtterance('ekran boş bakıyorum')
          .appendUserUtterance('yine erteledim'),
    );
    expect(SessionLocale.prefersTurkish('yine erteledim', blob), isTrue);
  });

  test('guard rejects EN short ack when session is Turkish', () {
    const guard = UtteranceGuard();
    final blob = SessionLocale.userEvidenceBlob(
      conversationGrounding: const ConversationGroundingBuffer.empty()
          .appendUserUtterance('tembel değilim korkuyorum galiba')
          .appendUserUtterance('yine erteledim'),
    );
    expect(
      guard.allow(
        utterance: const ConversationUtterance(text: 'Okay.'),
        what: ConversationPhase.validation,
        userUtterance: 'yine erteledim',
        mirrorGroundingUtterance: blob,
        expressionMode: ConversationExpressionMode.groundedHold,
      ),
      isNull,
    );
  });
}
