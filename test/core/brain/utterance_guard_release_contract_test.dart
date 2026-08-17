import 'package:flutter_test/flutter_test.dart';
import 'package:slowave/core/brain/conversation_phase.dart';
import 'package:slowave/core/brain/conversation_utterance.dart';
import 'package:slowave/core/brain/utterance_guard.dart';

void main() {
  const guard = UtteranceGuard();

  group('Guard Release Contract V1.1', () {
    test('exposes Release contract version', () {
      expect(UtteranceGuard.releaseContractVersion, '1.1');
    });

    test('still admits classic Release stems', () {
      for (final text in const [
        'You can let this rest for now.',
        'You can let it rest for now.',
        'Set this down for now.',
        'Let go for now.',
      ]) {
        final admitted = guard.allow(
          utterance: ConversationUtterance(text: text),
          what: ConversationPhase.release,
        );
        expect(admitted, isNotNull, reason: text);
      }
    });

    test('admits Step 2E bounded set-down Release candidate', () {
      final admitted = guard.allow(
        utterance: const ConversationUtterance(
          text: 'You can set those thoughts down for now.',
        ),
        what: ConversationPhase.release,
      );
      expect(admitted, isNotNull);
    });

    test('does not admit arbitrary set-down text', () {
      expect(
        guard.allow(
          utterance: const ConversationUtterance(
            text: 'Set the agenda down in writing.',
          ),
          what: ConversationPhase.release,
        ),
        isNull,
      );
    });

    test('admits natural Release variants without Let it rest catchphrase', () {
      for (final text in const [
        'Leave it here for the night.',
        'The night can hold this.',
        'Loosen your grip for now.',
        'Set this aside for now.',
        'Rest it here.',
      ]) {
        final admitted = guard.allow(
          utterance: ConversationUtterance(text: text),
          what: ConversationPhase.release,
        );
        expect(admitted, isNotNull, reason: text);
      }
    });

    test('rejects English Release on a Turkish ASCII night', () {
      expect(
        guard.allow(
          utterance: const ConversationUtterance(
            text: "Leave some of that here tonight. The night can hold this.",
          ),
          what: ConversationPhase.release,
          userUtterance: 'kafayi yicem ya bu gece.',
        ),
        isNull,
      );
    });

    test('rejects Receipt, Permission, Naming, advice, sleep, DNA under Release', () {
      expect(
        guard.allow(
          utterance: const ConversationUtterance(
            text: 'That sounds really heavy tonight.',
          ),
          what: ConversationPhase.release,
        ),
        isNull,
      );
      expect(
        guard.allow(
          utterance: const ConversationUtterance(
            text: "You don't have to solve this tonight.",
          ),
          what: ConversationPhase.release,
        ),
        isNull,
      );
      expect(
        guard.allow(
          utterance: const ConversationUtterance(
            text: "It's okay to let things be for now.",
          ),
          what: ConversationPhase.release,
        ),
        isNull,
      );
      expect(
        guard.allow(
          utterance: const ConversationUtterance(
            text: 'Something is still holding on.',
          ),
          what: ConversationPhase.release,
        ),
        isNull,
      );
      expect(
        guard.allow(
          utterance: const ConversationUtterance(
            text: 'Have you tried a breathing exercise?',
          ),
          what: ConversationPhase.release,
        ),
        isNull,
      );
      expect(
        guard.allow(
          utterance: const ConversationUtterance(
            text: 'You should sleep now.',
          ),
          what: ConversationPhase.release,
        ),
        isNull,
      );
      expect(
        guard.allow(
          utterance: const ConversationUtterance(
            text: 'Let it rest for now. Also try this tip.',
          ),
          what: ConversationPhase.release,
        ),
        isNull,
      );
      expect(
        guard.allow(
          utterance: const ConversationUtterance(
            text: 'Let it rest for now?',
          ),
          what: ConversationPhase.release,
        ),
        isNull,
      );
    });
  });
}
