import 'package:flutter_test/flutter_test.dart';
import 'package:slowave/core/brain/conversation_phase.dart';
import 'package:slowave/core/brain/conversation_utterance.dart';
import 'package:slowave/core/brain/utterance_guard.dart';

void main() {
  const guard = UtteranceGuard();

  test('rejects English Receipt on a Turkish turn', () {
    expect(
      guard.allow(
        utterance: const ConversationUtterance(
          text: 'Tomorrow feels uncertain, and that can be heavy.',
        ),
        what: ConversationPhase.validation,
        userUtterance: 'bilmiyorum.',
      ),
      isNull,
    );
  });

  test('rejects English Release on a Turkish turn', () {
    expect(
      guard.allow(
        utterance: const ConversationUtterance(
          text: 'Set this down for tonight. The night can hold what you’re carrying.',
        ),
        what: ConversationPhase.release,
        userUtterance: 'uyuyamiyorum.',
      ),
      isNull,
    );
  });

  test('still admits same-language English Receipt', () {
    expect(
      guard.allow(
        utterance: const ConversationUtterance(text: 'I hear that.'),
        what: ConversationPhase.validation,
        userUtterance: "I can't stop thinking about tomorrow.",
      ),
      isNotNull,
    );
  });

  test('drops invented tomorrow on filler idk', () {
    expect(
      guard.allow(
        utterance: const ConversationUtterance(
          text: 'Tomorrow feels uncertain, and that can be heavy.',
        ),
        what: ConversationPhase.validation,
        userUtterance: 'idk',
      ),
      isNull,
    );
  });
}
