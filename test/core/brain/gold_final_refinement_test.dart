import 'package:flutter_test/flutter_test.dart';
import 'package:slowave/core/brain/conversation_expression_mode.dart';
import 'package:slowave/core/brain/conversation_grounding_buffer.dart';
import 'package:slowave/core/brain/conversation_phase.dart';
import 'package:slowave/core/brain/conversation_utterance.dart';
import 'package:slowave/core/brain/identity.dart';
import 'package:slowave/core/brain/living_mind_model.dart';
import 'package:slowave/core/brain/mode_safe_terminal_fallback.dart';
import 'package:slowave/core/brain/narrow_fallback_builder.dart';
import 'package:slowave/core/brain/night_session.dart';
import 'package:slowave/core/brain/permission_release_admission.dart';
import 'package:slowave/core/brain/prior_admitted_expression.dart';
import 'package:slowave/core/brain/release_decision.dart';
import 'package:slowave/core/brain/session_turn.dart';
import 'package:slowave/core/brain/thinking_function_continuity.dart';
import 'package:slowave/core/brain/thinking_function_detector.dart';
import 'package:slowave/core/brain/thinking_function_hypothesis.dart';
import 'package:slowave/core/brain/thinking_function_kind.dart';
import 'package:slowave/core/brain/user_object_mirror.dart';
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
  const detector = ThinkingFunctionDetector();
  const guard = UtteranceGuard();

  group('Final refinement — TR semantic family', () {
    test('utancı prova / kötü sonuç / ihtimal bağlama fire worstCase', () {
      for (final msg in const [
        'Aklım utancı prova ediyor gibi.',
        'Aklım sürekli başka kötü sonuç buluyor.',
        'Sonra her ihtimali kötüye bağlıyorum.',
        'Birini düşünüyorum sonra yenisi geliyor — hepsi kötü.',
        'Kötü ihtimalleri tekrar tekrar canlandırıyorum.',
      ]) {
        final h = detector.detect(
          currentMessage: msg,
          conversationGrounding:
              const ConversationGroundingBuffer.empty().appendUserUtterance(msg),
        );
        expect(
          h?.kind,
          ThinkingFunctionKind.worstCaseRehearsal,
          reason: msg,
        );
        expect(
          h!.confidence,
          greaterThanOrEqualTo(ThinkingFunctionDetector.supportedFloor),
          reason: msg,
        );
      }
    });

    test('plain sadness / excitement do not force worstCase', () {
      expect(
        detector
            .detect(
              currentMessage: 'Biraz üzgünüm bu gece.',
              conversationGrounding: const ConversationGroundingBuffer.empty()
                  .appendUserUtterance('Biraz üzgünüm bu gece.'),
            )
            ?.kind,
        isNot(ThinkingFunctionKind.worstCaseRehearsal),
      );
      expect(
        detector
            .detect(
              currentMessage: 'Yarınki gezi için heyecanlıyım ve uyuyamıyorum.',
              conversationGrounding: const ConversationGroundingBuffer.empty()
                  .appendUserUtterance(
                    'Yarınki gezi için heyecanlıyım ve uyuyamıyorum.',
                  ),
            )
            ?.kind,
        isNot(ThinkingFunctionKind.worstCaseRehearsal),
      );
    });
    test('TR correction clears worstCase despite kotu sonuc in denial', () {
      const continuity = ThinkingFunctionContinuity();
      final prior = ThinkingFunctionHypothesis(
        kind: ThinkingFunctionKind.worstCaseRehearsal,
        confidence: 0.82,
        evidenceIds: const ['current:worst_case'],
        supportTurnCount: 1,
      );
      const msg = 'Hayır, kötü sonuç düşünmüyorum. Sadece heyecanlıyım.';
      final fresh = detector.detect(
        currentMessage: msg,
        conversationGrounding:
            const ConversationGroundingBuffer.empty().appendUserUtterance(msg),
      );
      expect(fresh?.kind, isNot(ThinkingFunctionKind.worstCaseRehearsal));
      final resolved = continuity.resolve(
        fresh: fresh,
        prior: prior,
        currentMessage: msg,
        session: _session(),
      );
      expect(resolved, isNull);
    });
  });

  group('Final refinement — TF-present Narrow', () {
    test('mechanism Narrow fallback surfaces cognitive job, not still-here', () {
      final hyp = ThinkingFunctionHypothesis(
        kind: ThinkingFunctionKind.worstCaseRehearsal,
        confidence: 0.82,
        evidenceIds: const ['current:worst_case'],
        supportTurnCount: 1,
      );
      const user =
          "It's like my mind is rehearsing embarrassment on loop.";
      final fork = NarrowFallbackBuilder.forValidation(
        userUtterance: user,
        thinkingFunctionHypothesis: hyp,
      );
      expect(fork, isNotNull);
      expect(fork!.text.contains('?'), isTrue);
      expect(fork.text.toLowerCase(), isNot(contains('still here')));
      expect(
        fork.text.toLowerCase(),
        anyOf(contains('rehears'), contains('embarrass'), contains('certainty')),
      );

      final terminal = ModeSafeTerminalFallback.forExpression(
        what: ConversationPhase.validation,
        expressionMode: ConversationExpressionMode.narrow,
        userUtterance: user,
        thinkingFunctionHypothesis: hyp,
      );
      expect(terminal, isNotNull);
      expect(terminal!.text.contains('?'), isTrue);
      expect(terminal.text.toLowerCase(), isNot(contains('still here tonight')));

      final admitted = guard.allow(
        utterance: terminal,
        what: ConversationPhase.validation,
        userUtterance: user,
        expressionMode: ConversationExpressionMode.narrow,
      );
      expect(admitted, isNotNull);
    });
  });

  group('Final refinement — mirror naturalness', () {
    test('long EN clause does not paste truncated is-still-with-you', () {
      const long =
          "Okay so tonight my brain is doing that thing again where it won't "
          'shut up about next week even though nothing is actually happening '
          'yet and I keep building these tiny disaster movies in my head.';
      final mirror = UserObjectMirror.forValidation(
        userUtterance: long,
        expressionMode: ConversationExpressionMode.observePurity,
        session: _session(),
      );
      expect(mirror, isNotNull);
      expect(mirror!.text.toLowerCase(), isNot(contains('won\'t shut u')));
      expect(mirror.text.toLowerCase(), isNot(contains('shut u is still')));
      expect(
        mirror.text.toLowerCase(),
        anyOf(
          contains('those scenes'),
          contains('still here tonight'),
          contains('still with you'),
        ),
      );
    });
  });

  group('Final refinement — sleepward path check', () {
    test('Permission opens after earned reframe + integrate', () {
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
        SessionTurn(
          releaseDecision:
              ReleaseDecision(readiness: ReleaseReadiness.hold, confidence: 0.8),
          phase: ConversationPhase.validation,
          expressionMode: ConversationExpressionMode.integrate,
          admittedExpression: PriorAdmittedExpression(
            phase: ConversationPhase.validation,
            text: 'Then your mind is still looping those futures tonight.',
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
      expect(
        PermissionReleaseAdmission.allowsObligationEase(
          what: ConversationPhase.permission,
          expressionMode: ConversationExpressionMode.standard,
          userUtterance: 'Yeah that fits.',
          session: session,
        ),
        isTrue,
      );
    });
  });
}
