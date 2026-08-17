import 'package:flutter_test/flutter_test.dart';
import 'package:slowave/core/brain/conversation_blueprint_binding.dart';
import 'package:slowave/core/brain/conversation_compiler.dart';
import 'package:slowave/core/brain/conversation_phase.dart';
import 'package:slowave/core/brain/conversation_policy.dart';
import 'package:slowave/core/brain/conversation_utterance.dart';
import 'package:slowave/core/brain/enough_intelligence.dart';
import 'package:slowave/core/brain/exit_decision.dart';
import 'package:slowave/core/brain/hcos_live_entry.dart';
import 'package:slowave/core/brain/llm_invocation_package.dart';
import 'package:slowave/core/brain/night_session.dart';
import 'package:slowave/core/brain/release_decision.dart';
import 'package:slowave/core/brain/session_turn.dart';
import 'package:slowave/core/brain/turn_response_stance.dart';
import 'package:slowave/core/brain/utterance_guard.dart';
import 'package:slowave/core/brain/validated_understanding.dart';
import 'package:slowave/core/brain/working_mind_view.dart';

void main() {
  const policy = ConversationPolicy();
  const enough = EnoughIntelligence();
  const compiler = ConversationCompiler();
  const guard = UtteranceGuard();

  final enoughStage = ConversationBlueprintCanon.instance
      .bindingFor(ConversationPhase.continuity)!;

  NightSession sessionEndingIn(ConversationPhase phase) {
    final mind = HcosLiveEntry.emptyMindModel();
    return NightSession(
      workingMind: WorkingMindView(model: mind),
      turns: [
        SessionTurn(
          releaseDecision: const ReleaseDecision(
            readiness: ReleaseReadiness.settling,
            confidence: 1,
          ),
          phase: phase,
        ),
      ],
    );
  }

  group('Soul / Enough anti-repeat V1', () {
    test('second Enough after continuity does not speak again', () {
      final session = sessionEndingIn(ConversationPhase.continuity);
      final decision = policy.decide(
        releaseDecision: const ReleaseDecision(
          readiness: ReleaseReadiness.receptive,
          confidence: 1,
        ),
        message: 'ok',
        session: session,
        understanding: const ValidatedUnderstanding(
          turnResponseStance: TurnResponseStance.softeningAcceptance,
        ),
      );
      expect(decision.phase, ConversationPhase.continuity);
      expect(decision.shouldSpeak, isFalse);
    });

    test('settling after continuity stays quiet (no restamp)', () {
      final session = sessionEndingIn(ConversationPhase.continuity);
      final decision = policy.decide(
        releaseDecision: const ReleaseDecision(
          readiness: ReleaseReadiness.settling,
          confidence: 1,
        ),
        message: 'tmm',
        session: session,
      );
      expect(decision.phase, ConversationPhase.continuity);
      expect(decision.shouldSpeak, isFalse);
    });

    test('first Enough after Release may still speak', () {
      final session = sessionEndingIn(ConversationPhase.release);
      final decision = policy.decide(
        releaseDecision: const ReleaseDecision(
          readiness: ReleaseReadiness.receptive,
          confidence: 1,
        ),
        message: 'ok',
        session: session,
        understanding: const ValidatedUnderstanding(
          turnResponseStance: TurnResponseStance.softeningAcceptance,
        ),
      );
      // After release + softening: continuity or audio; if continuity, speak once.
      if (decision.phase == ConversationPhase.continuity) {
        expect(decision.shouldSpeak, isTrue);
      }
    });

    test('EnoughIntelligence forbids default catchphrase stamp', () {
      final slice = enough.compile(
        stage: enoughStage,
        authorizeRestAudioHandoff: true,
      );
      final all = '${slice.userContent}\n${slice.systemAppendix}\n'
          '${slice.forbiddenMoves.join('\n')}';
      expect(EnoughIntelligence.version, '1.3');
      expect(all, contains('Anti-catchphrase'));
      expect(all.toLowerCase(), contains('enough for now'));
      expect(all, contains('do not default'));
      expect(all.toLowerCase(), contains('human'));
      expect(enoughStage.sealedWhatSignature.toLowerCase(),
          isNot(contains('enough for now')));
    });

    test('compiler Enough overlay carries Enough Intelligence', () {
      final compiled = compiler.compile(
        LlmInvocationPackage(
          what: ConversationPhase.continuity,
          exitDecision: ExitDecision.transitionToAudio,
        ),
      )!;
      expect(compiled.systemContent, contains('Enough Intelligence v1.3'));
      expect(compiled.systemContent, contains('Anti-catchphrase'));
      expect(compiled.systemContent, contains('Do not reuse Release night-hold'));
      expect(compiled.userContent, contains('No catchphrase stamp'));
      expect(compiled.userContent, contains('no second night-hold sentence'));
    });

    test('Guard admits warmer Enough closes and classic stems', () {
      for (final text in const [
        'Nothing more is needed right now.',
        "That's enough for now.",
        'The words can rest here tonight.',
        "I'm preparing a little quiet for you now.",
        "It's time to let the day settle. I'm preparing a little quiet for you now.",
        "That's all for tonight.",
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

    test('Guard admits two-line Release put-down + night-hold', () {
      expect(
        guard.allow(
          utterance: const ConversationUtterance(
            text:
                "Perhaps it's time to gently set this down. The night can hold what you no longer need to carry.",
          ),
          what: ConversationPhase.release,
        ),
        isNotNull,
      );
    });
  });
}
