import 'package:flutter_test/flutter_test.dart';
import 'package:slowave/core/brain/conversation_phase.dart';
import 'package:slowave/core/brain/conversation_utterance.dart';
import 'package:slowave/core/brain/naming_intelligence.dart';
import 'package:slowave/core/brain/receipt_intelligence.dart';
import 'package:slowave/core/brain/utterance_guard.dart';
import 'package:slowave/core/brain/conversation_blueprint_binding.dart';

void main() {
  const guard = UtteranceGuard();
  const naming = NamingIntelligence();
  const receipt = ReceiptIntelligence();

  final namingStage = ConversationBlueprintCanon.instance
      .bindingFor(ConversationPhase.naming)!;
  final receiptStage = ConversationBlueprintCanon.instance
      .bindingFor(ConversationPhase.validation)!;

  group('Soft perspective + breath V1', () {
    test('Naming Intelligence invites soft perspective, not positivity reframe',
        () {
      final slice = naming.compile(stage: namingStage);
      final all =
          '${slice.aim}\n${slice.systemAppendix}\n${slice.forbiddenMoves.join('\n')}';
      expect(all.toLowerCase(), contains('soft perspective'));
      expect(all.toLowerCase(), contains('golden reframe'));
      expect(all, contains('positivity'));
      expect(slice.responseLength, contains('45 words'));
    });

    test('Receipt Intelligence raises breath budget and soft perspective TYPE',
        () {
      final slice = receipt.compile(stage: receiptStage);
      expect(slice.responseLength, contains('45 words'));
      expect(slice.systemAppendix.toLowerCase(), contains('soft perspective'));
      expect(
        slice.forbiddenMoves.join(' ').toLowerCase(),
        contains('positivity'),
      );
    });

    test('Guard admits soft-perspective Naming with mind-hold cue', () {
      const text =
          'The hard part may be the cost of stopping, not the thinking itself.';
      expect(
        guard.allow(
          utterance: const ConversationUtterance(text: text),
          what: ConversationPhase.naming,
        ),
        isNotNull,
      );
    });

    test('Guard allows Golden V2 short-line Receipt under word cap', () {
      const text =
          'Tomorrow has already taken up space in tonight. '
          'It may be carrying tomorrow before it exists.';
      expect(
        guard.allow(
          utterance: const ConversationUtterance(text: text),
          what: ConversationPhase.validation,
        ),
        isNotNull,
      );
    });

    test('Language Style binds Golden Conversations V2 cadence', () {
      final slice = receipt.compile(stage: receiptStage);
      // Style is on compiler binding; Intelligence carries V2 TYPE.
      expect(slice.systemAppendix, contains('Golden Conversations V2'));
      expect(slice.responseLength, contains('45 words'));
    });
  });
}
