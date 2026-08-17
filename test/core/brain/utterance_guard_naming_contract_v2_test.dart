import 'package:flutter_test/flutter_test.dart';
import 'package:slowave/core/brain/conversation_phase.dart';
import 'package:slowave/core/brain/conversation_utterance.dart';
import 'package:slowave/core/brain/utterance_guard.dart';

void main() {
  const guard = UtteranceGuard();

  group('Guard Naming Contract V2 — admit quiet recognition', () {
    test('exposes Naming Contract V2 version', () {
      expect(UtteranceGuard.namingContractVersion, '2.0');
    });

    test('still admits V1 canonical Naming stems', () {
      for (final text in const [
        'Something is still holding on.',
        'Something is still weighing on you.',
        'It is still there.',
        'Something is lingering.',
        'Something is on your mind.',
      ]) {
        expect(
          guard.allow(
            utterance: ConversationUtterance(text: text),
            what: ConversationPhase.naming,
          ),
          isNotNull,
          reason: text,
        );
      }
    });

    test('admits recognition-frame + evident load pattern', () {
      expect(
        guard.allow(
          utterance: const ConversationUtterance(
            text:
                'Yes… that’s exactly what’s happening: the loops keep repeating.',
          ),
          what: ConversationPhase.naming,
        ),
        isNotNull,
      );
    });

    test('admits keep-going-over rumination as Naming, not bait', () {
      expect(
        guard.allow(
          utterance: const ConversationUtterance(
            text:
                'You keep going over everything you have to do. That is still on your mind.',
          ),
          what: ConversationPhase.naming,
        ),
        isNotNull,
      );
    });

    test('still rejects keep-going conversation bait', () {
      expect(
        guard.allow(
          utterance: const ConversationUtterance(
            text: 'Those loops keep repeating. Want to keep going?',
          ),
          what: ConversationPhase.naming,
        ),
        isNull,
      );
    });

    test('admits evident load + persistence pattern', () {
      expect(
        guard.allow(
          utterance: const ConversationUtterance(
            text: 'Those loops keep repeating.',
          ),
          what: ConversationPhase.naming,
        ),
        isNotNull,
      );
      expect(
        guard.allow(
          utterance: const ConversationUtterance(
            text: 'The replaying won’t stop.',
          ),
          what: ConversationPhase.naming,
        ),
        isNotNull,
      );
    });
  });

  group('Guard Naming Contract V2 — reject non-Naming / unsafe', () {
    test('rejects Receipt-only wording under Naming WHAT', () {
      expect(
        guard.allow(
          utterance: const ConversationUtterance(text: 'That makes sense.'),
          what: ConversationPhase.naming,
        ),
        isNull,
      );
    });

    test('rejects Permission under Naming WHAT', () {
      expect(
        guard.allow(
          utterance: const ConversationUtterance(
            text: 'You do not have to solve this tonight.',
          ),
          what: ConversationPhase.naming,
        ),
        isNull,
      );
    });

    test('rejects Release under Naming WHAT', () {
      expect(
        guard.allow(
          utterance: const ConversationUtterance(
            text: 'You can let this rest for now.',
          ),
          what: ConversationPhase.naming,
        ),
        isNull,
      );
    });

    test('rejects interpretation and psychology explanation', () {
      expect(
        guard.allow(
          utterance: const ConversationUtterance(
            text: 'Those loops keep repeating because you fear failure.',
          ),
          what: ConversationPhase.naming,
        ),
        isNull,
      );
      expect(
        guard.allow(
          utterance: const ConversationUtterance(
            text: 'Deep down the looping is your trauma.',
          ),
          what: ConversationPhase.naming,
        ),
        isNull,
      );
      expect(
        guard.allow(
          utterance: const ConversationUtterance(
            text: 'This looping means your psychology is overloaded.',
          ),
          what: ConversationPhase.naming,
        ),
        isNull,
      );
    });

    test('rejects bare meta recognition without evident load', () {
      expect(
        guard.allow(
          utterance: const ConversationUtterance(
            text: 'Yes… that’s exactly what’s happening.',
          ),
          what: ConversationPhase.naming,
        ),
        isNull,
      );
    });

    test('does not let Receipt texture collide into Naming cross-phase reject', () {
      // Receipt that mentions a loop once without persistence/recognition frame
      // must still admit under validation WHAT.
      expect(
        guard.allow(
          utterance: const ConversationUtterance(
            text: 'That sounds exhausting, with your mind caught in a loop.',
          ),
          what: ConversationPhase.validation,
        ),
        isNotNull,
      );
    });
  });
}
