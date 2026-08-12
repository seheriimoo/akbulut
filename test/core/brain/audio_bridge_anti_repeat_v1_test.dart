import 'package:flutter_test/flutter_test.dart';
import 'package:slowave/core/brain/conversation_compiler.dart';
import 'package:slowave/core/brain/conversation_decision.dart';
import 'package:slowave/core/brain/conversation_phase.dart';
import 'package:slowave/core/brain/conversation_policy.dart';
import 'package:slowave/core/brain/conversation_utterance.dart';
import 'package:slowave/core/brain/exit_decision.dart';
import 'package:slowave/core/brain/exit_intelligence.dart';
import 'package:slowave/core/brain/hcos_live_entry.dart';
import 'package:slowave/core/brain/llm_invocation_package.dart';
import 'package:slowave/core/brain/night_session.dart';
import 'package:slowave/core/brain/prior_admitted_expression.dart';
import 'package:slowave/core/brain/release_decision.dart';
import 'package:slowave/core/brain/session_turn.dart';
import 'package:slowave/core/brain/turn_response_stance.dart';
import 'package:slowave/core/brain/utterance_guard.dart';
import 'package:slowave/core/brain/validated_understanding.dart';
import 'package:slowave/core/brain/working_mind_view.dart';

void main() {
  const policy = ConversationPolicy();
  const exit = ExitIntelligence();
  const compiler = ConversationCompiler();
  const guard = UtteranceGuard();

  NightSession sessionEndingIn({
    required ConversationPhase phase,
    ReleaseReadiness readiness = ReleaseReadiness.settling,
    PriorAdmittedExpression? admitted,
  }) {
    final mind = HcosLiveEntry.emptyMindModel();
    return NightSession(
      workingMind: WorkingMindView(model: mind),
      turns: [
        SessionTurn(
          releaseDecision: ReleaseDecision(
            readiness: readiness,
            confidence: 1,
          ),
          phase: phase,
          admittedExpression: admitted,
        ),
      ],
    );
  }

  group('Audio bridge + prior-admitted anti-repeat V1', () {
    test('softening after Release speaks Enough before audio', () {
      final session = sessionEndingIn(phase: ConversationPhase.release);
      final decision = policy.decide(
        releaseDecision: const ReleaseDecision(
          readiness: ReleaseReadiness.transitionReady,
          confidence: 1,
        ),
        message: 'ok',
        session: session,
        understanding: const ValidatedUnderstanding(
          turnResponseStance: TurnResponseStance.softeningAcceptance,
        ),
      );
      expect(decision.phase, ConversationPhase.continuity);
      expect(decision.shouldSpeak, isTrue);
    });

    test('second Quiet Enough bridges Exit to audio (not silence)', () {
      final session = sessionEndingIn(phase: ConversationPhase.continuity);
      final decision = policy.decide(
        releaseDecision: const ReleaseDecision(
          readiness: ReleaseReadiness.receptive,
          confidence: 1,
        ),
        message: 'tmm',
        session: session,
      );
      expect(decision.phase, ConversationPhase.continuity);
      expect(decision.shouldSpeak, isFalse);

      final exitDecision = exit.decide(
        releaseDecision: const ReleaseDecision(
          readiness: ReleaseReadiness.receptive,
          confidence: 1,
        ),
        conversationDecision: decision,
        session: session,
      );
      expect(exitDecision, ExitDecision.transitionToAudio);
    });

    test('transitionReady after Enough continuity goes to audio', () {
      final session = sessionEndingIn(phase: ConversationPhase.continuity);
      final decision = policy.decide(
        releaseDecision: const ReleaseDecision(
          readiness: ReleaseReadiness.transitionReady,
          confidence: 1,
        ),
        message: 'ok',
        session: session,
      );
      expect(decision.phase, ConversationPhase.audio);
      expect(decision.shouldSpeak, isFalse);

      final exitDecision = exit.decide(
        releaseDecision: const ReleaseDecision(
          readiness: ReleaseReadiness.transitionReady,
          confidence: 1,
        ),
        conversationDecision: decision,
        session: session,
      );
      expect(exitDecision, ExitDecision.transitionToAudio);
    });

    test('Permission compile includes prior admitted anti-repeat', () {
      final compiled = compiler.compile(
        LlmInvocationPackage(
          what: ConversationPhase.permission,
          priorAdmittedExpression: const PriorAdmittedExpression(
            phase: ConversationPhase.permission,
            text: "You don't have to solve this tonight.",
          ),
        ),
      )!;
      expect(compiled.systemContent, contains('Anti-repeat'));
      expect(
        compiled.systemContent,
        contains("You don't have to solve this tonight."),
      );
      expect(compiled.stage.responseLength, contains('24 words'));
    });

    test('Release compile includes prior admitted anti-repeat', () {
      final compiled = compiler.compile(
        LlmInvocationPackage(
          what: ConversationPhase.release,
          priorAdmittedExpression: const PriorAdmittedExpression(
            phase: ConversationPhase.release,
            text: 'Let it rest for now.',
          ),
        ),
      )!;
      expect(compiled.userContent, contains('Anti-repeat'));
      expect(compiled.userContent, contains('Let it rest for now.'));
      expect(compiled.stage.responseLength, contains('28 words'));
    });

    test('spoken Enough handoff under transitionReady exits to audio', () {
      final session = sessionEndingIn(phase: ConversationPhase.release);
      const decision = ConversationDecision(
        phase: ConversationPhase.continuity,
        shouldSpeak: true,
      );
      expect(
        exit.decide(
          releaseDecision: const ReleaseDecision(
            readiness: ReleaseReadiness.transitionReady,
            confidence: 1,
          ),
          conversationDecision: decision,
          session: session,
        ),
        ExitDecision.transitionToAudio,
      );
    });

    test('Enough compile prefers soft rest-audio handoff TYPE', () {
      final compiled = compiler.compile(
        LlmInvocationPackage(
          what: ConversationPhase.continuity,
          exitDecision: ExitDecision.transitionToAudio,
        ),
      )!;
      expect(compiled.systemContent, contains('Enough Intelligence v1.3'));
      expect(compiled.systemContent.toLowerCase(), contains('handoff'));
      expect(compiled.systemContent, contains('preparing'));
    });

    test('Guard admits soft audio-handoff Enough lines', () {
      for (final text in const [
        "I'm preparing a little quiet for you now.",
        "I'm preparing a session for you now.",
        "I'll leave you with a little rest now.",
      ]) {
        expect(
          guard.allow(
            utterance: ConversationUtterance(text: text),
            what: ConversationPhase.continuity,
          ),
          isNotNull,
          reason: text,
        );
      }
    });

    test('Exit continues speaking path unchanged', () {
      final session = sessionEndingIn(phase: ConversationPhase.validation);
      const decision = ConversationDecision(
        phase: ConversationPhase.permission,
        shouldSpeak: true,
      );
      expect(
        exit.decide(
          releaseDecision: const ReleaseDecision(
            readiness: ReleaseReadiness.regulated,
            confidence: 1,
          ),
          conversationDecision: decision,
          session: session,
        ),
        ExitDecision.continueConversation,
      );
    });
  });
}
