import 'package:flutter_test/flutter_test.dart';
import 'package:slowave/core/brain/conversation_phase.dart';
import 'package:slowave/core/brain/conversation_utterance.dart';
import 'package:slowave/core/brain/permission_realization_contract.dart';
import 'package:slowave/core/brain/utterance_guard.dart';

void main() {
  const guard = UtteranceGuard();

  group('Guard Permission Contract V1.0 (shared Realization Contract)', () {
    test('exposes Permission contract version aligned with realization contract',
        () {
      expect(UtteranceGuard.permissionContractVersion, '1.0');
      expect(PermissionRealizationContract.version, '1.0');
    });

    test('A. admits observed Turn 3 don\'t-need-to candidate', () {
      const text = "You don't need to keep worrying about this tonight.";
      final admitted = guard.allow(
        utterance: const ConversationUtterance(text: text),
        what: ConversationPhase.permission,
      );
      expect(admitted, isNotNull);
      expect(admitted!.text, text);
    });

    test('B. admits do-not-need-to / do-not-have-to rehearsal ease', () {
      for (final text in const [
        'You do not need to keep rehearsing tonight.',
        'You do not have to keep rehearsing tonight.',
      ]) {
        expect(
          guard.allow(
            utterance: ConversationUtterance(text: text),
            what: ConversationPhase.permission,
          ),
          isNotNull,
          reason: text,
        );
      }
    });

    test('C. preserves classic Permission admits', () {
      for (final text in const [
        "You don't have to solve this tonight.",
        'No need to push further tonight.',
        'You do not have to solve this tonight.',
        'This is not something to solve tonight.',
      ]) {
        final admitted = guard.allow(
          utterance: ConversationUtterance(text: text),
          what: ConversationPhase.permission,
        );
        expect(admitted, isNotNull, reason: text);
      }
    });

    test('D. rejects bare it\'s okay', () {
      expect(
        guard.allow(
          utterance: const ConversationUtterance(text: "It's okay."),
          what: ConversationPhase.permission,
        ),
        isNull,
      );
    });

    test('E. rejects advice / Receipt / Naming / Release / Enough under Permission',
        () {
      for (final text in const [
        'Have you tried writing it down?',
        'That sounds really heavy tonight.',
        'Something is still holding on.',
        'Let it rest for now.',
        'You can let go of that tonight.',
        "That's enough for tonight.",
        'Nothing more is needed.',
      ]) {
        expect(
          guard.allow(
            utterance: ConversationUtterance(text: text),
            what: ConversationPhase.permission,
          ),
          isNull,
          reason: text,
        );
      }
    });

    test('F. don\'t-need-to family does not bypass DNA / unsafe', () {
      expect(
        guard.allow(
          utterance: const ConversationUtterance(
            text: "You don't need to keep worrying about this tonight?",
          ),
          what: ConversationPhase.permission,
        ),
        isNull,
        reason: 'question DNA',
      );
      expect(
        guard.allow(
          utterance: const ConversationUtterance(
            text:
                "You don't need to keep worrying about this tonight. Also try this tip.",
          ),
          what: ConversationPhase.permission,
        ),
        isNull,
        reason: 'multi-sentence / tip DNA',
      );
      expect(
        guard.allow(
          utterance: const ConversationUtterance(
            text: "You don't need to — have you tried journaling?",
          ),
          what: ConversationPhase.permission,
        ),
        isNull,
        reason: 'unsafe advice',
      );
      expect(
        guard.allow(
          utterance: const ConversationUtterance(
            text: "You don't need to work on this tonight.",
          ),
          what: ConversationPhase.permission,
        ),
        isNull,
        reason: 'unsafe work-on marker',
      );
    });

    test('G. Permission soft-modal does not change other phase admission', () {
      const needTo =
          "You don't need to keep worrying about this tonight.";
      for (final phase in const [
        ConversationPhase.validation,
        ConversationPhase.naming,
        ConversationPhase.release,
        ConversationPhase.continuity,
        ConversationPhase.neutralEntry,
      ]) {
        expect(
          guard.allow(
            utterance: const ConversationUtterance(text: needTo),
            what: phase,
          ),
          isNull,
          reason: phase.name,
        );
      }

      expect(
        guard.allow(
          utterance: const ConversationUtterance(
            text: 'Your thoughts are swirling, making it hard to find calm.',
          ),
          what: ConversationPhase.validation,
        ),
        isNotNull,
      );
      expect(
        guard.allow(
          utterance: const ConversationUtterance(
            text: 'Let it rest for now.',
          ),
          what: ConversationPhase.release,
        ),
        isNotNull,
      );
      expect(
        guard.allow(
          utterance: const ConversationUtterance(
            text: 'Something is still holding on.',
          ),
          what: ConversationPhase.naming,
        ),
        isNotNull,
      );
    });

    test('still admits leave-be family; bare need alone is not enough', () {
      expect(
        guard.allow(
          utterance: const ConversationUtterance(
            text: "It's okay to let this go for tonight.",
          ),
          what: ConversationPhase.permission,
        ),
        isNotNull,
      );
      expect(
        guard.allow(
          utterance: const ConversationUtterance(
            text: 'You need rest tonight.',
          ),
          what: ConversationPhase.permission,
        ),
        isNull,
        reason: 'bare need is not a Permission bypass',
      );
    });
  });
}
