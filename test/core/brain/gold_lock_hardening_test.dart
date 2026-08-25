import 'package:flutter_test/flutter_test.dart';
import 'package:slowave/core/brain/conversation_engine.dart';
import 'package:slowave/core/brain/conversation_expression_mode.dart';
import 'package:slowave/core/brain/conversation_grounding_buffer.dart';
import 'package:slowave/core/brain/conversation_phase.dart';
import 'package:slowave/core/brain/conversation_utterance.dart';
import 'package:slowave/core/brain/exit_decision.dart';
import 'package:slowave/core/brain/conversation_decision.dart';
import 'package:slowave/core/brain/identity.dart';
import 'package:slowave/core/brain/language_model_client.dart';
import 'package:slowave/core/brain/living_mind_model.dart';
import 'package:slowave/core/brain/llm_invocation_package.dart';
import 'package:slowave/core/brain/night_session.dart';
import 'package:slowave/core/brain/permission_release_admission.dart';
import 'package:slowave/core/brain/prior_admitted_expression.dart';
import 'package:slowave/core/brain/release_decision.dart';
import 'package:slowave/core/brain/session_turn.dart';
import 'package:slowave/core/brain/thinking_function_continuity.dart';
import 'package:slowave/core/brain/thinking_function_detector.dart';
import 'package:slowave/core/brain/thinking_function_hypothesis.dart';
import 'package:slowave/core/brain/thinking_function_kind.dart';
import 'package:slowave/core/brain/utterance_guard.dart';
import 'package:slowave/core/brain/working_mind_view.dart';

NightSession _session([List<SessionTurn> turns = const []]) {
  final now = DateTime.now().toUtc();
  return NightSession(
    workingMind: WorkingMindView(
      model: LivingMindModel(
        identity: Identity(
          userId: 't',
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
      ),
    ),
    turns: turns,
  );
}

void main() {
  const guard = UtteranceGuard();
  const continuity = ThinkingFunctionContinuity();
  const detector = ThinkingFunctionDetector();

  group('GOLD hardening — zero silence', () {
    test('observe still-here terminal admits on EN substantive', () {
      const user =
          'Whenever one thought settles, another ugly one shows up.';
      final admitted = guard.allow(
        utterance: const ConversationUtterance(
          text: 'What you named is still here tonight.',
        ),
        what: ConversationPhase.validation,
        userUtterance: user,
        expressionMode: ConversationExpressionMode.observePurity,
      );
      expect(admitted, isNotNull);
    });

    test('engine does not silence when model emits Okay on substantive',
        () async {
      final engine = ConversationEngine(
        languageModelClient: const _RejectTextClient('Okay.'),
      );
      final spoken = await engine.generate(
        conversationDecision: const ConversationDecision(
          phase: ConversationPhase.validation,
          shouldSpeak: true,
          expressionMode: ConversationExpressionMode.standard,
        ),
        exitDecision: ExitDecision.continueConversation,
        livedExpression:
            'Whenever one thought settles, another ugly one shows up.',
        nightSession: _session(),
        conversationGrounding: const ConversationGroundingBuffer.empty()
            .appendUserUtterance(
              'Whenever one thought settles, another ugly one shows up.',
            ),
      );
      expect(spoken, isNotNull);
      expect(spoken!.text.trim().isNotEmpty, isTrue);
      expect(spoken.text.toLowerCase(), isNot('okay.'));
    });
  });

  group('GOLD hardening — premature Permission', () {
    test('rejects dont-need on early Receipt without recognition', () {
      final admitted = guard.allow(
        utterance: const ConversationUtterance(
          text: "You don't need to keep calculating what might go wrong tonight.",
        ),
        what: ConversationPhase.validation,
        userUtterance: 'I keep calculating what goes wrong if one payment slips.',
        expressionMode: ConversationExpressionMode.standard,
        nightSession: _session(),
      );
      expect(admitted, isNull);
      expect(
        PermissionReleaseAdmission.allowsObligationEase(
          what: ConversationPhase.validation,
          expressionMode: ConversationExpressionMode.standard,
          userUtterance: 'I keep calculating what goes wrong.',
          session: _session(),
        ),
        isFalse,
      );
    });

    test('admits Permission after earned reframe arc', () {
      final session = _session(const [
        SessionTurn(
          releaseDecision:
              ReleaseDecision(readiness: ReleaseReadiness.hold, confidence: 0.8),
          phase: ConversationPhase.validation,
          expressionMode: ConversationExpressionMode.reframe,
          admittedExpression: PriorAdmittedExpression(
            phase: ConversationPhase.validation,
            text:
                'Perhaps your mind keeps rehearsing what could go wrong tomorrow.',
          ),
        ),
      ]);
      expect(
        PermissionReleaseAdmission.allowsObligationEase(
          what: ConversationPhase.validation,
          expressionMode: ConversationExpressionMode.standard,
          userUtterance: 'Yeah that fits.',
          session: session,
        ),
        isTrue,
      );
      final admitted = guard.allow(
        utterance: const ConversationUtterance(
          text: "You don't have to solve this tonight.",
        ),
        what: ConversationPhase.permission,
        userUtterance: 'Yeah that fits.',
        expressionMode: ConversationExpressionMode.standard,
        nightSession: session,
      );
      expect(admitted, isNotNull);
    });
  });

  group('GOLD hardening — semantic generalization', () {
    test('fall apart / disaster movies / embarrassment rehearsal fire', () {
      for (final msg in const [
        'It keeps inventing new ways it could fall apart.',
        'I keep building these tiny disaster movies in my head.',
        "It's like my mind is rehearsing embarrassment on loop.",
      ]) {
        final g = const ConversationGroundingBuffer.empty()
            .appendUserUtterance(msg);
        final h = detector.detect(
          currentMessage: msg,
          conversationGrounding: g,
        );
        expect(
          h?.kind,
          ThinkingFunctionKind.worstCaseRehearsal,
          reason: msg,
        );
      }
    });

    test('excited tomorrow alone does not force worstCase', () {
      final h = detector.detect(
        currentMessage: "I'm just excited about tomorrow's trip.",
        conversationGrounding: const ConversationGroundingBuffer.empty()
            .appendUserUtterance("I'm just excited about tomorrow's trip."),
      );
      expect(h?.kind, isNot(ThinkingFunctionKind.worstCaseRehearsal));
    });
  });

  group('GOLD hardening — TF long chain', () {
    test('same-job elaborations refresh across 5 turns', () {
      var prior = ThinkingFunctionHypothesis(
        kind: ThinkingFunctionKind.worstCaseRehearsal,
        confidence: 0.82,
        evidenceIds: const ['current:worst_case'],
        supportTurnCount: 1,
      );
      const chain = [
        'Aklım sürekli kötü senaryolar üretiyor.',
        'Sonra her ihtimali kötüye bağlıyorum.',
        'Birini düşünüyorum sonra yenisi geliyor.',
        'Aklım sürekli başka kötü sonuç buluyor.',
        'Her yol yine kötü bitiyor.',
      ];
      for (final msg in chain) {
        final resolved = continuity.resolve(
          fresh: detector.detect(
            currentMessage: msg,
            conversationGrounding:
                const ConversationGroundingBuffer.empty().appendUserUtterance(msg),
          ),
          prior: prior,
          currentMessage: msg,
          session: _session(),
        );
        expect(resolved, isNotNull, reason: msg);
        expect(resolved!.kind, ThinkingFunctionKind.worstCaseRehearsal);
        expect(
          resolved.confidence,
          greaterThanOrEqualTo(ThinkingFunctionDetector.supportedFloor),
          reason: msg,
        );
        prior = resolved;
      }
    });
  });

  group('GOLD hardening — no I hear you sink', () {
    test('EN event mirror does not append I hear you', () {
      // UserObjectMirror path exercised via Guard-safe admission of new form.
      final admitted = guard.allow(
        utterance: const ConversationUtterance(
          text: 'Work thoughts are still with you tonight.',
        ),
        what: ConversationPhase.validation,
        userUtterance: "I can't stop thinking about work tonight.",
        expressionMode: ConversationExpressionMode.observePurity,
      );
      expect(admitted, isNotNull);
      expect(admitted!.text.toLowerCase(), isNot(contains('i hear you')));
    });
  });
}

class _RejectTextClient extends LanguageModelClient {
  const _RejectTextClient(this.text);

  final String text;

  @override
  Future<ConversationUtterance> realize(LlmInvocationPackage package) async {
    return ConversationUtterance(text: text);
  }
}
