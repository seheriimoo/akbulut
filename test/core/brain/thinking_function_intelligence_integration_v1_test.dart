import 'package:flutter_test/flutter_test.dart';
import 'package:slowave/core/brain/conversation_blueprint_binding.dart';
import 'package:slowave/core/brain/conversation_compiler.dart';
import 'package:slowave/core/brain/conversation_grounding_buffer.dart';
import 'package:slowave/core/brain/conversation_phase.dart';
import 'package:slowave/core/brain/conversation_policy.dart';
import 'package:slowave/core/brain/conversation_utterance.dart';
import 'package:slowave/core/brain/exit_intelligence.dart';
import 'package:slowave/core/brain/hcos_live_entry.dart';
import 'package:slowave/core/brain/llm_invocation_package.dart';
import 'package:slowave/core/brain/night_session.dart';
import 'package:slowave/core/brain/permission_intelligence.dart';
import 'package:slowave/core/brain/receipt_intelligence.dart';
import 'package:slowave/core/brain/release_decision.dart';
import 'package:slowave/core/brain/release_engine.dart';
import 'package:slowave/core/brain/release_intelligence.dart';
import 'package:slowave/core/brain/thinking_function_hypothesis.dart';
import 'package:slowave/core/brain/thinking_function_intelligence_shaping.dart';
import 'package:slowave/core/brain/thinking_function_kind.dart';
import 'package:slowave/core/brain/utterance_guard.dart';
import 'package:slowave/core/brain/validated_understanding.dart';
import 'package:slowave/core/brain/working_mind_view.dart';

void main() {
  const receipt = ReceiptIntelligence();
  const permission = PermissionIntelligence();
  const release = ReleaseIntelligence();
  const compiler = ConversationCompiler();
  const guard = UtteranceGuard();

  final receiptStage =
      ConversationBlueprintCanon.instance.bindingFor(ConversationPhase.validation)!;
  final permissionStage =
      ConversationBlueprintCanon.instance.bindingFor(ConversationPhase.permission)!;
  final releaseStage =
      ConversationBlueprintCanon.instance.bindingFor(ConversationPhase.release)!;

  ConversationGroundingBuffer grounding(String utterance) =>
      const ConversationGroundingBuffer.empty().appendUserUtterance(utterance);

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

  String visiblePrompt(ReceiptCompileSlice? r, PermissionCompileSlice? p,
      ReleaseCompileSlice? rel) {
    final parts = <String>[
      if (r != null) ...[r.userContent, r.systemAppendix, r.aim, r.responseLength],
      if (p != null) ...[p.userContent, p.systemAppendix, p.aim],
      if (rel != null) ...[rel.userContent, rel.systemAppendix, rel.aim],
    ];
    return parts.join('\n');
  }

  void expectNoEnumLeak(String text) {
    for (final id in const [
      'earlyTomorrowCarry',
      'preparationRehearsal',
      'protectiveHolding',
      'worstCaseRehearsal',
      'certaintyChase',
      'ThinkingFunctionKind',
      'GOLD-A',
      'GOLD-B',
      'GOLD-C',
      'GOLD-D',
      'GOLD-E',
    ]) {
      expect(text, isNot(contains(id)), reason: 'leaked $id');
    }
  }

  group('Slice 2 — null/tentative preserve baseline', () {
    test('null hypothesis keeps short Receipt budget', () {
      final slice = receipt.compile(stage: receiptStage);
      expect(slice.responseLength, contains('45 words'));
      expect(slice.responseLength, isNot(contains('60 words')));
      expect(slice.systemAppendix, contains('no supported soft functional'));
    });

    test('tentative hypothesis does not unlock functional Receipt', () {
      final slice = receipt.compile(
        stage: receiptStage,
        thinkingFunctionHypothesis: hyp(
          ThinkingFunctionKind.earlyTomorrowCarry,
          confidence: 0.55,
        ),
      );
      expect(slice.responseLength, contains('45 words'));
      expect(slice.userContent, isNot(contains('Required hinge TYPE')));
      expect(slice.userContent, isNot(contains('Soft hinge TYPE')));
      expect(
        ThinkingFunctionIntelligenceShaping.isTentativeOnly(
          hyp(ThinkingFunctionKind.earlyTomorrowCarry, confidence: 0.55),
        ),
        isTrue,
      );
    });
  });

  group('Slice 2 — five kinds Receipt/Permission/Release shaping', () {
    final cases = <ThinkingFunctionKind, ({
      String receiptNeedle,
      String permissionNeedle,
      String releaseNeedle,
    })>{
      ThinkingFunctionKind.earlyTomorrowCarry: (
        receiptNeedle: 'carried into tonight',
        permissionNeedle: 'not required to carry',
        releaseNeedle: 'leaving tomorrow where it is',
      ),
      ThinkingFunctionKind.preparationRehearsal: (
        receiptNeedle: 'less prepared',
        permissionNeedle: 'not required to keep preparing',
        releaseNeedle: 'pausing preparation',
      ),
      ThinkingFunctionKind.protectiveHolding: (
        receiptNeedle: 'stopping may feel',
        permissionNeedle: 'not required to keep watch',
        releaseNeedle: 'keep-watch',
      ),
      ThinkingFunctionKind.worstCaseRehearsal: (
        receiptNeedle: 'rehearsing possible futures',
        permissionNeedle: 'not required to keep rehearsing',
        releaseNeedle: 'rehearsal stop',
      ),
      ThinkingFunctionKind.certaintyChase: (
        receiptNeedle: 'one more thought',
        permissionNeedle: 'not required to reach certainty',
        releaseNeedle: 'pausing the search',
      ),
    };

    for (final entry in cases.entries) {
      final kind = entry.key;
      final needles = entry.value;

      test('$kind shapes Receipt/Permission/Release without enum leak', () {
        final h = hyp(kind, confidence: 0.72);
        final r = receipt.compile(
          stage: receiptStage,
          conversationGrounding: grounding('load present tonight'),
          thinkingFunctionHypothesis: h,
        );
        final p = permission.compile(
          stage: permissionStage,
          thinkingFunctionHypothesis: h,
        );
        final rel = release.compile(
          stage: releaseStage,
          thinkingFunctionHypothesis: h,
        );

        expect(r.responseLength, contains('60 words'));
        expect(r.userContent, contains('Required hinge TYPE'));
        expect(r.userContent, contains('MUST realize exactly ONE'));
        expect(r.userContent.toLowerCase(), contains(needles.receiptNeedle));
        expect(r.forbiddenMoves.join(' '), contains('Paraphrase-only'));
        expect(
          r.systemAppendix,
          contains('Activation description is texture, not recognition'),
        );

        expect(p.userContent.toLowerCase(), contains(needles.permissionNeedle));
        expect(p.systemAppendix.toLowerCase(), contains(needles.permissionNeedle));

        expect(rel.userContent.toLowerCase(), contains(needles.releaseNeedle));
        expect(rel.systemAppendix.toLowerCase(), contains(needles.releaseNeedle));

        final all = visiblePrompt(r, p, rel);
        expectNoEnumLeak(all);
        expect(all, isNot(contains('gold_reply_library')));
        expect(all.toLowerCase(), isNot(contains('best quality-reference')));
      });
    }

    test('strong confidence still forbids hard diagnosis language', () {
      final h = hyp(ThinkingFunctionKind.certaintyChase, confidence: 0.88);
      final r = receipt.compile(stage: receiptStage, thinkingFunctionHypothesis: h);
      expect(r.userContent, contains('never hard diagnosis'));
      expect(r.forbiddenMoves.join(' '), contains('Hard certainty'));
    });
  });

  group('Slice 2 — compiler wiring + determinism', () {
    test('compiler passes hypothesis into stage overlays deterministically', () {
      final understanding = ValidatedUnderstanding(
        thinkingFunctionHypothesis: hyp(ThinkingFunctionKind.earlyTomorrowCarry),
      );
      final package = LlmInvocationPackage(
        what: ConversationPhase.validation,
        understanding: understanding,
        conversationGrounding: grounding(
          "I can't stop thinking about tomorrow.",
        ),
      );
      final a = compiler.compile(package)!;
      final b = compiler.compile(package)!;
      expect(a.systemContent, b.systemContent);
      expect(a.userContent, b.userContent);
      expect(a.systemContent, contains('carrying tomorrow into tonight'));
      expect(a.systemContent, contains('60 words'));
      expectNoEnumLeak('${a.systemContent}\n${a.userContent}');
    });

    test('compiler Permission/Release overlays include obligation/job shaping',
        () {
      final understanding = ValidatedUnderstanding(
        thinkingFunctionHypothesis:
            hyp(ThinkingFunctionKind.preparationRehearsal, confidence: 0.88),
      );
      final permissionPkg = LlmInvocationPackage(
        what: ConversationPhase.permission,
        understanding: understanding,
      );
      final releasePkg = LlmInvocationPackage(
        what: ConversationPhase.release,
        understanding: understanding,
      );
      final p = compiler.compile(permissionPkg)!;
      final r = compiler.compile(releasePkg)!;
      expect(p.systemContent.toLowerCase(), contains('not required to keep preparing'));
      expect(r.systemContent.toLowerCase(), contains('pausing preparation'));
      expectNoEnumLeak('${p.systemContent}\n${r.systemContent}');
    });
  });

  group('Slice 2 — architecture freeze', () {
    test('hypothesis does not change Release/Policy/Exit or reopen Naming', () {
      final mind = WorkingMindView(model: HcosLiveEntry.emptyMindModel());
      final session = NightSession(workingMind: mind, turns: const []);
      final base = const ValidatedUnderstanding();
      final withHyp = ValidatedUnderstanding(
        thinkingFunctionHypothesis: hyp(ThinkingFunctionKind.worstCaseRehearsal),
      );
      final releaseEngine = const ReleaseEngine();
      final policy = const ConversationPolicy();
      final exit = const ExitIntelligence();

      final r1 = releaseEngine.evaluate(
        understanding: base,
        workingMind: mind,
        session: session,
      );
      final r2 = releaseEngine.evaluate(
        understanding: withHyp,
        workingMind: mind,
        session: session,
      );
      expect(r1.readiness, r2.readiness);

      final c1 = policy.decide(
        releaseDecision: ReleaseDecision(readiness: ReleaseReadiness.hold, confidence: 1),
        message: 'hi',
        session: session,
        understanding: withHyp,
      );
      expect(c1.phase, ConversationPhase.validation);
      // First-turn hold stays Receipt; Naming requires prior Receipt.

      final e1 = exit.decide(
        releaseDecision: r1,
        conversationDecision: c1,
        session: session,
      );
      final e2 = exit.decide(
        releaseDecision: r2,
        conversationDecision: c1,
        session: session,
      );
      expect(e1, e2);
    });

    test('Guard still rejects diagnosis and stage drift', () {
      expect(
        guard.allow(
          utterance: const ConversationUtterance(
            text: 'Your mind is racing because you have a clinical disorder.',
          ),
          what: ConversationPhase.validation,
        ),
        isNull,
      );
      expect(
        guard.allow(
          utterance: const ConversationUtterance(
            text: "You don't have to solve this tonight.",
          ),
          what: ConversationPhase.validation,
        ),
        isNull,
      );
      expect(
        guard.allow(
          utterance: const ConversationUtterance(
            text: 'Something is still holding on.',
          ),
          what: ConversationPhase.validation,
        ),
        isNull,
      );
    });
  });
}
