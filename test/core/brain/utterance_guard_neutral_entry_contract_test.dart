import 'package:flutter_test/flutter_test.dart';
import 'package:slowave/core/brain/conversation_phase.dart';
import 'package:slowave/core/brain/conversation_utterance.dart';
import 'package:slowave/core/brain/utterance_guard.dart';

void main() {
  const guard = UtteranceGuard();

  group('Guard Neutral Entry Contract V1', () {
    test('exposes Neutral Entry contract version', () {
      expect(UtteranceGuard.neutralEntryContractVersion, '1.0');
    });

    test('admits short legal welcome acknowledgments', () {
      for (final text in const [
        "Hi whenever you're ready.",
        "Hello whenever you're ready.",
        'Hey.',
        'Hello.',
        'Good evening.',
        'Take your time.',
        "Hi when you're ready.",
      ]) {
        final admitted = guard.allow(
          utterance: ConversationUtterance(text: text),
          what: ConversationPhase.neutralEntry,
        );
        expect(admitted, isNotNull, reason: text);
        expect(admitted!.text, text);
      }
    });

    test('rejects invented emotion, presence, stillness, sleep problem', () {
      for (final text in const [
        'Hi — that sounds heavy tonight.',
        "Hello. You're present, just being here.",
        'Hey, find some stillness.',
        "Hi. Sounds like you can't sleep.",
        'Hello, your loneliness is here.',
      ]) {
        expect(
          guard.allow(
            utterance: ConversationUtterance(text: text),
            what: ConversationPhase.neutralEntry,
          ),
          isNull,
          reason: text,
        );
      }
    });

    test('rejects questions, advice, and other-WHAT drift', () {
      for (final text in const [
        'Hi, how are you?',
        'Hello — have you tried breathing?',
        'That makes sense.',
        'I hear that.',
        'You do not have to solve this tonight.',
        'You can let this rest for now.',
        'Nothing more is needed right now.',
        'Something is still holding on.',
      ]) {
        expect(
          guard.allow(
            utterance: ConversationUtterance(text: text),
            what: ConversationPhase.neutralEntry,
          ),
          isNull,
          reason: text,
        );
      }
    });

    test('rejects DNA multi-insight / multi-sentence candidates', () {
      expect(
        guard.allow(
          utterance: const ConversationUtterance(
            text: "Hi whenever you're ready. Take your time tonight.",
          ),
          what: ConversationPhase.neutralEntry,
        ),
        isNull,
      );
    });

    test('Guard reject remains null with no filler', () {
      final rejected = guard.allow(
        utterance: const ConversationUtterance(text: 'How are you feeling?'),
        what: ConversationPhase.neutralEntry,
      );
      expect(rejected, isNull);
    });

    test('substring hi inside this does not false-admit Neutral Entry', () {
      // Cross-phase safety: Release lines with "this" must not match Neutral Entry.
      final release = guard.allow(
        utterance: const ConversationUtterance(
          text: 'You can let this rest for now.',
        ),
        what: ConversationPhase.release,
      );
      expect(release, isNotNull);
    });
  });
}
