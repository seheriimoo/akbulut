import 'package:flutter_test/flutter_test.dart';
import 'package:slowave/core/brain/conversation_phase.dart';
import 'package:slowave/core/brain/conversation_utterance.dart';
import 'package:slowave/core/brain/language_style.dart';
import 'package:slowave/core/brain/permission_realization_contract.dart';
import 'package:slowave/core/brain/utterance_guard.dart';

void main() {
  const guard = UtteranceGuard();

  group('Quality climb V1 — Guard admit paths', () {
    test('LanguageStyle is v1.2 with language mirror', () {
      expect(LanguageStyle.version, '1.2');
      expect(
        LanguageStyle.instance.compileBinding(),
        contains('same language'),
      );
    });

    test('Permission rejects Release let-go; admits obligation-ease', () {
      expect(
        guard.allow(
          utterance: const ConversationUtterance(
            text: 'You can let go of that tonight.',
          ),
          what: ConversationPhase.permission,
        ),
        isNull,
      );
      expect(
        guard.allow(
          utterance: const ConversationUtterance(
            text: "You don't need to keep preparing for the worst tonight.",
          ),
          what: ConversationPhase.permission,
        ),
        isNotNull,
      );
      expect(
        PermissionRealizationContract.matchesObligationEase(
          "you don't need to keep preparing for the worst tonight.",
        ),
        isTrue,
      );
    });

    test('Release admits leave-some / night-hold / bounded let-go', () {
      for (final text in const [
        'Perhaps you can leave some of that here tonight. The night can hold what you don’t need to carry right now.',
        'Leave some of that here tonight.',
        'Let go of that tonight.',
        'The night can hold what you no longer need to carry.',
      ]) {
        expect(
          guard.allow(
            utterance: ConversationUtterance(text: text),
            what: ConversationPhase.release,
          ),
          isNotNull,
          reason: text,
        );
      }
    });

    test('Release rejects bare let-go narration without stem', () {
      expect(
        guard.allow(
          utterance: const ConversationUtterance(
            text:
                "It seems like things are softening. Perhaps it's a good moment to let go.",
          ),
          what: ConversationPhase.release,
        ),
        isNull,
      );
    });

    test('Turkish Permission / Release / Enough stems admit', () {
      expect(
        guard.allow(
          utterance: const ConversationUtterance(
            text: 'Bu gece bunu çözmek zorunda değilsin.',
          ),
          what: ConversationPhase.permission,
        ),
        isNotNull,
      );
      expect(
        guard.allow(
          utterance: const ConversationUtterance(
            text: 'Bunu burada bırak. Gece tutabilir.',
          ),
          what: ConversationPhase.release,
        ),
        isNotNull,
      );
      expect(
        guard.allow(
          utterance: const ConversationUtterance(
            text: 'Seni şimdi biraz dinlenmeyle bırakıyorum.',
          ),
          what: ConversationPhase.continuity,
        ),
        isNotNull,
      );
    });

    test('Enough handoff still admits with incidental it\'s + quiet', () {
      expect(
        guard.allow(
          utterance: const ConversationUtterance(
            text:
                "I'll leave you with a little rest now. It's time to let the night be quiet.",
          ),
          what: ConversationPhase.continuity,
        ),
        isNotNull,
      );
      expect(
        guard.allow(
          utterance: const ConversationUtterance(
            text:
                "I'm preparing a little quiet for you now. Let the night hold you softly.",
          ),
          what: ConversationPhase.continuity,
        ),
        isNotNull,
      );
    });

    test('Naming admits holding-on even with soft Receipt opener', () {
      expect(
        guard.allow(
          utterance: const ConversationUtterance(
            text: "It sounds like you're holding on to a lot of worries.",
          ),
          what: ConversationPhase.naming,
        ),
        isNotNull,
      );
    });

    test('mixed-language Release is rejected (one language only)', () {
      expect(
        guard.allow(
          utterance: const ConversationUtterance(
            text:
                'Sanki biraz hafifliyor. You can set this down now. The night can hold what you no longer need to carry.',
          ),
          what: ConversationPhase.release,
        ),
        isNull,
      );
      expect(
        guard.allow(
          utterance: const ConversationUtterance(
            text:
                'You can leave some of that here. The night can hold what you no longer need to carry.',
          ),
          what: ConversationPhase.release,
        ),
        isNotNull,
      );
    });
  });
}
