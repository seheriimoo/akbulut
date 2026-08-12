import 'package:flutter_test/flutter_test.dart';
import 'package:slowave/core/brain/conversation_blueprint_binding.dart';
import 'package:slowave/core/brain/conversation_compiler.dart';
import 'package:slowave/core/brain/conversation_grounding_buffer.dart';
import 'package:slowave/core/brain/conversation_phase.dart';
import 'package:slowave/core/brain/conversation_utterance.dart';
import 'package:slowave/core/brain/llm_invocation_package.dart';
import 'package:slowave/core/brain/receipt_intelligence.dart';
import 'package:slowave/core/brain/receipt_realization_contract.dart';
import 'package:slowave/core/brain/thinking_function_hypothesis.dart';
import 'package:slowave/core/brain/thinking_function_intelligence_shaping.dart';
import 'package:slowave/core/brain/thinking_function_kind.dart';
import 'package:slowave/core/brain/utterance_guard.dart';
import 'package:slowave/core/brain/validated_understanding.dart';

void main() {
  const receipt = ReceiptIntelligence();
  const guard = UtteranceGuard();
  const compiler = ConversationCompiler();

  final receiptStage = ConversationBlueprintCanon.instance
      .bindingFor(ConversationPhase.validation)!;

  ConversationGroundingBuffer grounding(String text) =>
      const ConversationGroundingBuffer.empty().appendUserUtterance(text);

  ThinkingFunctionHypothesis hyp(
    ThinkingFunctionKind kind, {
    double confidence = 0.72,
  }) {
    return ThinkingFunctionHypothesis(
      kind: kind,
      confidence: confidence,
      evidenceIds: const ['test:evidence'],
      supportTurnCount: 1,
    );
  }

  String surface(ReceiptCompileSlice slice) =>
      '${slice.aim}\n${slice.userContent}\n${slice.systemAppendix}\n'
      '${slice.forbiddenMoves.join('\n')}\n${slice.responseLength}';

  group('GOLD-C Early Tomorrow Carry Tuning V1', () {
    test(
      'A. earlyTomorrowCarry compile requires temporal carry; busy+tomorrow insufficient',
      () {
        final h = hyp(ThinkingFunctionKind.earlyTomorrowCarry, confidence: 0.72);
        final slice = receipt.compile(
          stage: receiptStage,
          conversationGrounding:
              grounding("I can't stop thinking about tomorrow."),
          thinkingFunctionHypothesis: h,
        );
        final all = surface(slice);

        expect(all, contains('INSUFFICIENT TYPE'));
        expect(all, contains('REQUIRED FUNCTION TYPE'));
        expect(all.toLowerCase(), contains('carried into tonight'));
        expect(all.toLowerCase(), contains('living tomorrow'));
        expect(all, contains('Anti-equivalence'));
        expect(all, contains('busy/swirl/race/spin + tomorrow'));
        expect(all, contains('does NOT count'));
        expect(all, contains('Activation + topic alone is insufficient'));
        expect(all, contains('functional night-load texture'));
        expect(all, isNot(contains('earlyTomorrowCarry')));
        expect(ReceiptIntelligence.version, '1.6');
      },
    );

    test('B. null/tentative does not invent tomorrow-carry; short budget kept', () {
      final nullSlice = receipt.compile(stage: receiptStage);
      expect(nullSlice.responseLength, contains('45 words'));
      expect(nullSlice.responseLength, isNot(contains('60 words')));
      expect(nullSlice.userContent, isNot(contains('REQUIRED FUNCTION TYPE')));
      expect(nullSlice.userContent, isNot(contains('carried into tonight')));
      expect(
        nullSlice.systemAppendix,
        contains('do not invent a mind-job'),
      );

      final tentative = receipt.compile(
        stage: receiptStage,
        thinkingFunctionHypothesis: hyp(
          ThinkingFunctionKind.earlyTomorrowCarry,
          confidence: 0.55,
        ),
      );
      expect(tentative.responseLength, contains('45 words'));
      expect(tentative.userContent, isNot(contains('REQUIRED FUNCTION TYPE')));
      expect(
        ThinkingFunctionIntelligenceShaping.isTentativeOnly(
          hyp(ThinkingFunctionKind.earlyTomorrowCarry, confidence: 0.55),
        ),
        isTrue,
      );
    });

    test('C. other hypothesis Receipt shaping unchanged in TYPE cores', () {
      final cases = <ThinkingFunctionKind, String>{
        ThinkingFunctionKind.worstCaseRehearsal: 'rehearsing possible futures',
        ThinkingFunctionKind.preparationRehearsal: 'less prepared',
        ThinkingFunctionKind.protectiveHolding: 'stopping may feel',
        ThinkingFunctionKind.certaintyChase: 'one more thought',
      };
      for (final entry in cases.entries) {
        final slice = receipt.compile(
          stage: receiptStage,
          thinkingFunctionHypothesis: hyp(entry.key),
        );
        expect(
          slice.userContent.toLowerCase(),
          contains(entry.value),
          reason: entry.key.name,
        );
        expect(
          slice.userContent,
          isNot(contains('INSUFFICIENT TYPE')),
          reason: '${entry.key.name} must not get GOLD-C-only contrast',
        );
      }
    });

    test('D. Guard remains structural — shallow and functional both admissible',
        () {
      expect(UtteranceGuard.receiptContractVersion, '1.6');
      expect(ReceiptRealizationContract.version, '1.6');

      expect(
        guard.allow(
          utterance: const ConversationUtterance(
            text:
                'Your thoughts may be busy with tomorrow, making it hard to find rest tonight.',
          ),
          what: ConversationPhase.validation,
        ),
        isNotNull,
        reason: 'shallow structurally-valid form still admitted',
      );
      expect(
        guard.allow(
          utterance: const ConversationUtterance(
            text:
                'Part of your mind may already be carrying tomorrow into tonight.',
          ),
          what: ConversationPhase.validation,
        ),
        isNotNull,
        reason: 'functional form still admitted',
      );
    });

    test('E. no canned GOLD-C production reply lines', () {
      final slice = receipt.compile(
        stage: receiptStage,
        thinkingFunctionHypothesis:
            hyp(ThinkingFunctionKind.earlyTomorrowCarry),
      );
      final all = surface(slice);
      for (final banned in const [
        'GOLD-C',
        'Your thoughts are swirling around tomorrow.',
        'gold_reply_library',
        'best quality-reference',
      ]) {
        expect(all, isNot(contains(banned)), reason: banned);
      }
    });

    test('F. supported Receipt budget remains max ~60 words', () {
      final slice = receipt.compile(
        stage: receiptStage,
        thinkingFunctionHypothesis:
            hyp(ThinkingFunctionKind.earlyTomorrowCarry),
      );
      expect(slice.responseLength, contains('60 words'));
      expect(slice.userContent, contains('max 60 words'));
    });

    test('G. compiler wiring preserves Detector/Permission/Release ownership freeze',
        () {
      final compiled = compiler.compile(
        LlmInvocationPackage(
          what: ConversationPhase.validation,
          understanding: ValidatedUnderstanding(
            thinkingFunctionHypothesis:
                hyp(ThinkingFunctionKind.earlyTomorrowCarry),
          ),
          conversationGrounding:
              grounding("I can't stop thinking about tomorrow."),
        ),
      )!;
      expect(compiled.systemContent, contains('Receipt Intelligence v1.6'));
      expect(compiled.systemContent, contains('INSUFFICIENT TYPE'));
      expect(compiled.systemContent, contains('Anti-equivalence'));
      expect(
        compiled.systemContent,
        contains('Activation + topic alone is insufficient'),
      );
      expect(compiled.systemContent, isNot(contains('Permission Intelligence')));
      expect(compiled.systemContent, isNot(contains('Release Intelligence')));
    });
  });
}
