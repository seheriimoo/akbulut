import 'package:flutter_test/flutter_test.dart';
import 'package:slowave/core/brain/conversation_compiler.dart';
import 'package:slowave/core/brain/conversation_expression_mode.dart';
import 'package:slowave/core/brain/conversation_grounding_buffer.dart';
import 'package:slowave/core/brain/conversation_phase.dart';
import 'package:slowave/core/brain/conversation_policy.dart';
import 'package:slowave/core/brain/identity.dart';
import 'package:slowave/core/brain/living_mind_model.dart';
import 'package:slowave/core/brain/llm_invocation_package.dart';
import 'package:slowave/core/brain/mode_safe_terminal_fallback.dart';
import 'package:slowave/core/brain/night_session.dart';
import 'package:slowave/core/brain/prior_admitted_expression.dart';
import 'package:slowave/core/brain/release_decision.dart';
import 'package:slowave/core/brain/session_turn.dart';
import 'package:slowave/core/brain/thinking_function_hypothesis.dart';
import 'package:slowave/core/brain/thinking_function_kind.dart';
import 'package:slowave/core/brain/validated_understanding.dart';
import 'package:slowave/core/brain/working_mind_view.dart';

LivingMindModel _emptyModel() {
  final now = DateTime.now().toUtc();
  return LivingMindModel(
    identity: Identity(
      userId: 'test',
      preferredLanguage: 'en',
      timezone: 'UTC',
      createdAt: now,
      lastInteractionAt: now,
      totalSessions: 0,
    ),
    mentalPatterns: const [],
    emotionalPatterns: const [],
    triggers: const [],
    beliefs: const [],
    needs: const [],
    preferences: const [],
  );
}

NightSession _sessionWithTurns(List<SessionTurn> turns) {
  return NightSession(
    workingMind: WorkingMindView(model: _emptyModel()),
    turns: turns,
  );
}

/// Phase 1 — Narrow → mechanism-capable Receipt progression (no GOLD scripts).
void main() {
  const policy = ConversationPolicy();
  const compiler = ConversationCompiler();

  NightSession observeThenNarrow({
    String observeText = 'That sounds hard tonight.',
    String narrowText =
        'Are you worried about specific things that might go wrong, '
        'or more about the general uncertainty of the future?',
  }) {
    return _sessionWithTurns([
      SessionTurn(
        releaseDecision:
            const ReleaseDecision(readiness: ReleaseReadiness.hold, confidence: 0.8),
        phase: ConversationPhase.validation,
        expressionMode: ConversationExpressionMode.observePurity,
        admittedExpression: PriorAdmittedExpression(
          phase: ConversationPhase.validation,
          text: observeText,
        ),
      ),
      SessionTurn(
        releaseDecision:
            const ReleaseDecision(readiness: ReleaseReadiness.hold, confidence: 0.8),
        phase: ConversationPhase.validation,
        expressionMode: ConversationExpressionMode.narrow,
        admittedExpression: PriorAdmittedExpression(
          phase: ConversationPhase.validation,
          text: narrowText,
        ),
      ),
    ]);
  }

  group('Phase 1 policy progression', () {
    test('after Narrow + substantive EN answer → standard, not observePurity',
        () {
      const t3 =
          "It's not one specific thing. My mind keeps creating different "
          'scenarios, and every one of them ends badly.';
      final grounding = const ConversationGroundingBuffer.empty()
          .appendUserUtterance("I can't stop thinking tonight.")
          .appendUserUtterance(
            'My mind keeps thinking about everything that could go wrong tomorrow.',
          )
          .appendUserUtterance(t3);

      final decision = policy.decide(
        releaseDecision:
            const ReleaseDecision(readiness: ReleaseReadiness.hold, confidence: 0.8),
        message: t3,
        session: observeThenNarrow(),
        conversationGrounding: grounding,
      );

      expect(decision.expressionMode, ConversationExpressionMode.standard);
      expect(decision.expressionMode, isNot(ConversationExpressionMode.observePurity));
    });

    test('first Receipt still observePurity', () {
      final decision = policy.decide(
        releaseDecision:
            const ReleaseDecision(readiness: ReleaseReadiness.hold, confidence: 0.8),
        message: "I can't stop thinking tonight.",
      );
      expect(decision.expressionMode, ConversationExpressionMode.observePurity);
    });

    test('T1 observe then T2 still narrow before mechanism turn', () {
      final s1 = _sessionWithTurns([
        SessionTurn(
          releaseDecision: const ReleaseDecision(
            readiness: ReleaseReadiness.hold,
            confidence: 0.8,
          ),
          phase: ConversationPhase.validation,
          expressionMode: ConversationExpressionMode.observePurity,
          admittedExpression: const PriorAdmittedExpression(
            phase: ConversationPhase.validation,
            text: 'Thinking is still loud tonight.',
          ),
        ),
      ]);
      final t2 = policy.decide(
        releaseDecision:
            const ReleaseDecision(readiness: ReleaseReadiness.hold, confidence: 0.8),
        message:
            'My mind keeps thinking about everything that could go wrong tomorrow.',
        session: s1,
      );
      expect(t2.expressionMode, ConversationExpressionMode.narrow);
    });
  });

  group('Phase 1 ThinkingFunction reaches standard Receipt', () {
    test('compiler keeps worstCase hinge on standard, strips on observe', () {
      final hyp = ThinkingFunctionHypothesis(
        kind: ThinkingFunctionKind.worstCaseRehearsal,
        confidence: 0.82,
        evidenceIds: const ['current:worst_case'],
        supportTurnCount: 2,
      );
      final understanding = ValidatedUnderstanding(
        thinkingFunctionHypothesis: hyp,
      );
      final grounding = const ConversationGroundingBuffer.empty()
          .appendUserUtterance(
            'My mind keeps thinking about everything that could go wrong tomorrow.',
          );

      final standardPkg = LlmInvocationPackage(
        what: ConversationPhase.validation,
        expressionMode: ConversationExpressionMode.standard,
        understanding: understanding,
        conversationGrounding: grounding,
      );
      final observePkg = LlmInvocationPackage(
        what: ConversationPhase.validation,
        expressionMode: ConversationExpressionMode.observePurity,
        understanding: understanding,
        conversationGrounding: grounding,
      );

      final standardPrompt = compiler.compile(standardPkg);
      final observePrompt = compiler.compile(observePkg);

      expect(standardPrompt, isNotNull);
      expect(observePrompt, isNotNull);

      final standardBlob =
          '${standardPrompt!.systemContent}\n${standardPrompt.userContent}';
      final observeBlob =
          '${observePrompt!.systemContent}\n${observePrompt.userContent}';

      expect(
        standardBlob.toLowerCase(),
        anyOf(
          contains('worst'),
          contains('rehears'),
          contains('blindsid'),
          contains('possible futures'),
          contains('functional'),
        ),
        reason: 'standard Receipt must carry soft TF hinge doctrine',
      );
      expect(
        observeBlob.toLowerCase(),
        isNot(contains('rehearsing worst-case')),
        reason: 'observePurity must still strip TF',
      );
    });
  });

  group('Phase 1 evidence-bound terminal anti-repeat', () {
    test('does not repeat That sounds hard tonight across session', () {
      final session = observeThenNarrow();
      const user =
          "It's not one specific thing. My mind keeps creating different "
          'scenarios, and every one of them ends badly.';

      final terminal = ModeSafeTerminalFallback.forExpression(
        what: ConversationPhase.validation,
        expressionMode: ConversationExpressionMode.standard,
        userUtterance: user,
        session: session,
        groundingBlob: user,
      );

      expect(terminal, isNotNull);
      expect(
        terminal!.text.trim().toLowerCase(),
        isNot('that sounds hard tonight.'),
      );
    });
  });
}
