import 'package:flutter_test/flutter_test.dart';
import 'package:slowave/core/brain/belief_detector.dart';
import 'package:slowave/core/brain/cognitive_orchestrator.dart';
import 'package:slowave/core/brain/conversation_engine.dart';
import 'package:slowave/core/brain/conversation_grounding_buffer.dart';
import 'package:slowave/core/brain/conversation_phase.dart';
import 'package:slowave/core/brain/conversation_policy.dart';
import 'package:slowave/core/brain/emotional_pattern_detector.dart';
import 'package:slowave/core/brain/exit_intelligence.dart';
import 'package:slowave/core/brain/hcos_live_entry.dart';
import 'package:slowave/core/brain/language_model_client.dart';
import 'package:slowave/core/brain/memory_engine.dart';
import 'package:slowave/core/brain/mental_pattern_detector.dart';
import 'package:slowave/core/brain/need_detector.dart';
import 'package:slowave/core/brain/night_session.dart';
import 'package:slowave/core/brain/perception_engine.dart';
import 'package:slowave/core/brain/preference_detector.dart';
import 'package:slowave/core/brain/release_decision.dart';
import 'package:slowave/core/brain/release_engine.dart';
import 'package:slowave/core/brain/session_summarizer.dart';
import 'package:slowave/core/brain/session_turn.dart';
import 'package:slowave/core/brain/turn_response_stance.dart';
import 'package:slowave/core/brain/turn_response_stance_detector.dart';
import 'package:slowave/core/brain/validated_understanding.dart';
import 'package:slowave/core/brain/working_mind_view.dart';

import 'faithful_test_vendor_provider.dart';

void main() {
  const perception = PerceptionEngine();
  const mental = MentalPatternDetector();
  const emotional = EmotionalPatternDetector();
  const stanceDetector = TurnResponseStanceDetector();
  const release = ReleaseEngine();
  const policy = ConversationPolicy();

  ValidatedUnderstanding understand(
    String message, {
    ConversationPhase? priorPhase,
  }) {
    final evidence = perception.perceive(message);
    final mentalPatterns = mental.detect(evidence);
    final emotionalPatterns = emotional.detect(evidence);
    return ValidatedUnderstanding(
      mentalPatterns: mentalPatterns,
      emotionalPatterns: emotionalPatterns,
      turnResponseStance: stanceDetector.detect(
        evidence: evidence,
        hasLoad: mentalPatterns.isNotEmpty || emotionalPatterns.isNotEmpty,
        priorPhase: priorPhase,
      ),
    );
  }

  NightSession sessionWith({
    required ReleaseReadiness readiness,
    required ConversationPhase phase,
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
        ),
      ],
    );
  }

  group('Apostrophe normalization', () {
    test('curly and ASCII apostrophe both yield load/holding evidence', () {
      const ascii = "I can't let go";
      const curly = "I can’t let go"; // U+2019

      final asciiEvidence = perception.perceive(ascii);
      final curlyEvidence = perception.perceive(curly);

      expect(
        asciiEvidence.any((e) => e.value == 'mental_overload'),
        isTrue,
      );
      expect(
        curlyEvidence.any((e) => e.value == 'mental_overload'),
        isTrue,
      );
      expect(
        asciiEvidence.any((e) => e.value == 'holding_against_ease'),
        isTrue,
      );
      expect(
        curlyEvidence.any((e) => e.value == 'holding_against_ease'),
        isTrue,
      );

      final asciiStance = understand(ascii, priorPhase: ConversationPhase.release);
      final curlyStance = understand(curly, priorPhase: ConversationPhase.release);
      expect(asciiStance.turnResponseStance, TurnResponseStance.holdingAgainstEase);
      expect(curlyStance.turnResponseStance, TurnResponseStance.holdingAgainstEase);
    });
  });

  group('Post-Release resistance', () {
    test('from settling: readiness ≤ regulated and phase ≠ release', () {
      final session = sessionWith(
        readiness: ReleaseReadiness.settling,
        phase: ConversationPhase.release,
      );
      final understanding = understand(
        "I can't let go",
        priorPhase: ConversationPhase.release,
      );

      final decision = release.evaluate(
        understanding: understanding,
        workingMind: session.workingMind,
        session: session,
      );
      final conversation = policy.decide(
        releaseDecision: decision,
        message: "I can't let go",
        session: session,
        understanding: understanding,
      );

      expect(understanding.turnResponseStance, TurnResponseStance.holdingAgainstEase);
      expect(
        decision.readiness == ReleaseReadiness.hold ||
            decision.readiness == ReleaseReadiness.regulated,
        isTrue,
      );
      expect(conversation.phase, isNot(ConversationPhase.release));
      expect(
        conversation.phase == ConversationPhase.validation ||
            conversation.phase == ConversationPhase.permission,
        isTrue,
      );
    });

    test('from receptive: step-back must not re-select Release', () {
      final session = sessionWith(
        readiness: ReleaseReadiness.receptive,
        phase: ConversationPhase.release,
      );
      final understanding = understand(
        'still stuck in my head',
        priorPhase: ConversationPhase.release,
      );

      final decision = release.evaluate(
        understanding: understanding,
        workingMind: session.workingMind,
        session: session,
      );
      final conversation = policy.decide(
        releaseDecision: decision,
        message: 'still stuck in my head',
        session: session,
        understanding: understanding,
      );

      expect(decision.readiness, isNot(ReleaseReadiness.settling));
      expect(decision.readiness, isNot(ReleaseReadiness.receptive));
      expect(
        decision.readiness == ReleaseReadiness.hold ||
            decision.readiness == ReleaseReadiness.regulated,
        isTrue,
      );
      expect(conversation.phase, isNot(ConversationPhase.release));
    });

    test('resistance generalizes beyond exact phrase via load stance', () {
      final session = sessionWith(
        readiness: ReleaseReadiness.settling,
        phase: ConversationPhase.release,
      );
      final understanding = understand(
        "My mind won't stop racing",
        priorPhase: ConversationPhase.release,
      );

      final decision = release.evaluate(
        understanding: understanding,
        workingMind: session.workingMind,
        session: session,
      );
      final conversation = policy.decide(
        releaseDecision: decision,
        message: "My mind won't stop racing",
        session: session,
        understanding: understanding,
      );

      expect(
        understanding.turnResponseStance ==
                TurnResponseStance.holdingAgainstEase ||
            understanding.turnResponseStance == TurnResponseStance.continuedLoad,
        isTrue,
      );
      expect(conversation.phase, isNot(ConversationPhase.release));
    });
  });

  group('Post-Release softening / acceptance', () {
    test('softening does not issue a second Release', () {
      final session = sessionWith(
        readiness: ReleaseReadiness.settling,
        phase: ConversationPhase.release,
      );
      final understanding = understand(
        'ok',
        priorPhase: ConversationPhase.release,
      );

      final decision = release.evaluate(
        understanding: understanding,
        workingMind: session.workingMind,
        session: session,
      );
      final conversation = policy.decide(
        releaseDecision: decision,
        message: 'ok',
        session: session,
        understanding: understanding,
      );

      expect(
        understanding.turnResponseStance,
        TurnResponseStance.softeningAcceptance,
      );
      expect(decision.readiness, ReleaseReadiness.transitionReady);
      expect(conversation.phase, isNot(ConversationPhase.release));
      expect(
        conversation.phase == ConversationPhase.continuity ||
            conversation.phase == ConversationPhase.audio,
        isTrue,
      );
    });

    test('no consecutive Release after acceptance', () {
      final mind = HcosLiveEntry.emptyMindModel();
      var session = NightSession(
        workingMind: WorkingMindView(model: mind),
        turns: const [],
      );

      // Climb calmly to first Release.
      for (final message in ['still here', 'a little quieter', 'softening']) {
        final understanding = understand(
          message,
          priorPhase:
              session.turns.isEmpty ? null : session.turns.last.phase,
        );
        final decision = release.evaluate(
          understanding: understanding,
          workingMind: session.workingMind,
          session: session,
        );
        final conversation = policy.decide(
          releaseDecision: decision,
          message: message,
          session: session,
          understanding: understanding,
        );
        session = session.recordTurn(
          SessionTurn(
            releaseDecision: decision,
            phase: conversation.phase,
          ),
        );
      }

      expect(session.turns.last.phase, ConversationPhase.release);

      final afterOk = understand('ok', priorPhase: ConversationPhase.release);
      final decision = release.evaluate(
        understanding: afterOk,
        workingMind: session.workingMind,
        session: session,
      );
      final conversation = policy.decide(
        releaseDecision: decision,
        message: 'ok',
        session: session,
        understanding: afterOk,
      );

      expect(conversation.phase, isNot(ConversationPhase.release));
    });
  });

  group('Fail-closed unclear stance', () {
    test('unclear after Release must not invent acceptance or force audio', () {
      final session = sessionWith(
        readiness: ReleaseReadiness.settling,
        phase: ConversationPhase.release,
      );
      const understanding = ValidatedUnderstanding(
        turnResponseStance: TurnResponseStance.unclear,
      );

      final decision = release.evaluate(
        understanding: understanding,
        workingMind: session.workingMind,
        session: session,
      );
      final conversation = policy.decide(
        releaseDecision: decision,
        message: '...',
        session: session,
        understanding: understanding,
      );

      expect(decision.readiness, ReleaseReadiness.settling);
      expect(decision.readiness, isNot(ReleaseReadiness.transitionReady));
      expect(conversation.phase, isNot(ConversationPhase.release));
      expect(conversation.phase, isNot(ConversationPhase.audio));
      expect(conversation.phase, ConversationPhase.continuity);
    });

    test('soft ack without prior ease offer stays unclear', () {
      final understanding = understand('ok', priorPhase: null);
      expect(understanding.turnResponseStance, TurnResponseStance.unclear);
    });
  });

  group('Regression boundaries', () {
    test('emotional first-turn still routes to Receipt, not Neutral Entry', () {
      final mind = HcosLiveEntry.emptyMindModel();
      final session = NightSession(
        workingMind: WorkingMindView(model: mind),
        turns: const [],
      );
      final understanding = understand("I'm very stressed");
      final decision = release.evaluate(
        understanding: understanding,
        workingMind: session.workingMind,
        session: session,
      );
      final conversation = policy.decide(
        releaseDecision: decision,
        message: "I'm very stressed",
        session: session,
        understanding: understanding,
      );

      expect(decision.readiness, ReleaseReadiness.hold);
      expect(conversation.phase, ConversationPhase.validation);
    });

    test('Neutral Entry greeting unchanged', () {
      final mind = HcosLiveEntry.emptyMindModel();
      final session = NightSession(
        workingMind: WorkingMindView(model: mind),
        turns: const [],
      );
      const understanding = ValidatedUnderstanding();
      const decision = ReleaseDecision(
        readiness: ReleaseReadiness.hold,
        confidence: 1,
      );
      final conversation = policy.decide(
        releaseDecision: decision,
        message: 'hi',
        session: session,
        understanding: understanding,
      );
      expect(conversation.phase, ConversationPhase.neutralEntry);
    });

    test('Orchestrator order unchanged and stance not in grounding/memory',
        () async {
      final order = <String>[];
      final orchestrator = CognitiveOrchestrator(
        perceptionEngine: const PerceptionEngine(),
        mentalPatternDetector: const MentalPatternDetector(),
        emotionalPatternDetector: const EmotionalPatternDetector(),
        beliefDetector: const BeliefDetector(),
        needDetector: const NeedDetector(),
        preferenceDetector: const PreferenceDetector(),
        turnResponseStanceDetector: const TurnResponseStanceDetector(),
        releaseEngine: _OrderReleaseEngine(order),
        conversationPolicy: _OrderConversationPolicy(order),
        conversationEngine: ConversationEngine(
          languageModelClient: LanguageModelClient(
            vendorProvider: const FaithfulTestVendorProvider(),
          ),
        ),
        exitIntelligence: _OrderExitIntelligence(order),
        sessionSummarizer: const SessionSummarizer(),
        memoryEngine: const MemoryEngine(),
      );

      final mind = HcosLiveEntry.emptyMindModel();
      var session = HcosLiveEntry.openNightSession(mind);
      final result = await orchestrator.processTurn(
        message: 'ok',
        session: session,
        workingMind: HcosLiveEntry.workingMindOf(session),
      );
      session = result.session;

      expect(order, ['release', 'policy', 'exit']);
      expect(
        result.conversationGroundingBuffer.userUtterances,
        ['ok'],
      );
      // Grounding remains user-only shaping; no assistant / stance records.
      expect(
        result.conversationGroundingBuffer,
        isA<ConversationGroundingBuffer>(),
      );

      final updatedMind = orchestrator.completeSession(
        session: session,
        model: mind,
      );
      // SessionSummarizer still extracts nothing durable from stance/turns.
      expect(updatedMind.mentalPatterns, isEmpty);
      expect(updatedMind.emotionalPatterns, isEmpty);
      expect(updatedMind.beliefs, isEmpty);
      expect(updatedMind.needs, isEmpty);
      expect(updatedMind.preferences, isEmpty);
    });

    test('ReleaseEngine evaluate accepts optional message for gating', () {
      expect(
        const ReleaseEngine().evaluate,
        isA<
            ReleaseDecision Function({
              required ValidatedUnderstanding understanding,
              required WorkingMindView workingMind,
              required NightSession session,
              String? message,
            })>(),
      );
    });
  });
}

class _OrderReleaseEngine extends ReleaseEngine {
  _OrderReleaseEngine(this.order);
  final List<String> order;

  @override
  ReleaseDecision evaluate({
    required ValidatedUnderstanding understanding,
    required WorkingMindView workingMind,
    required NightSession session,
    String? message,
  }) {
    order.add('release');
    return super.evaluate(
      understanding: understanding,
      workingMind: workingMind,
      session: session,
      message: message,
    );
  }
}

class _OrderConversationPolicy extends ConversationPolicy {
  _OrderConversationPolicy(this.order);
  final List<String> order;

  @override
  decide({
    required releaseDecision,
    message,
    session,
    understanding,
    conversationGrounding,
    sessionVentCorpus = '',
    discoveryPlan,
  }) {
    order.add('policy');
    return super.decide(
      releaseDecision: releaseDecision,
      message: message,
      session: session,
      understanding: understanding,
      conversationGrounding: conversationGrounding,
      sessionVentCorpus: sessionVentCorpus,
      discoveryPlan: discoveryPlan,
    );
  }
}

class _OrderExitIntelligence extends ExitIntelligence {
  _OrderExitIntelligence(this.order);
  final List<String> order;

  @override
  decide({
    required releaseDecision,
    required conversationDecision,
    required session,
    String? message,
  }) {
    order.add('exit');
    return super.decide(
      releaseDecision: releaseDecision,
      conversationDecision: conversationDecision,
      session: session,
      message: message,
    );
  }
}
