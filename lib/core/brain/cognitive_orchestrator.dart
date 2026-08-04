import 'belief_detector.dart';
import 'conversation_engine.dart';
import 'conversation_policy.dart';
import 'conversation_utterance.dart';
import 'cognitive_turn_result.dart';
import 'emotional_pattern_detector.dart';
import 'exit_decision.dart';
import 'exit_intelligence.dart';
import 'mental_pattern_detector.dart';
import 'need_detector.dart';
import 'night_session.dart';
import 'perception_engine.dart';
import 'preference_detector.dart';
import 'release_engine.dart';
import 'session_turn.dart';
import 'validated_understanding.dart';
import 'working_mind_view.dart';

/// CognitiveOrchestrator
///
/// Central coordinator of the HCOS cognitive pipeline.
///
/// Owns no business logic.
///
/// Wires components together in a forward-only pipeline.
class CognitiveOrchestrator {
  final PerceptionEngine perceptionEngine;

  final MentalPatternDetector mentalPatternDetector;

  final EmotionalPatternDetector emotionalPatternDetector;

  final BeliefDetector beliefDetector;

  final NeedDetector needDetector;

  final PreferenceDetector preferenceDetector;

  final ReleaseEngine releaseEngine;

  final ConversationPolicy conversationPolicy;

  final ConversationEngine conversationEngine;

  final ExitIntelligence exitIntelligence;

  const CognitiveOrchestrator({
    required this.perceptionEngine,
    required this.mentalPatternDetector,
    required this.emotionalPatternDetector,
    required this.beliefDetector,
    required this.needDetector,
    required this.preferenceDetector,
    required this.releaseEngine,
    required this.conversationPolicy,
    required this.conversationEngine,
    required this.exitIntelligence,
  });

  /// Forward-only turn coordinator.
  ///
  /// Pipeline:
  /// Perception → ValidatedUnderstanding → WorkingMindView →
  /// Release → ConversationPolicy → Exit → Conversation →
  /// CognitiveTurnResult
  ///
  /// Updates temporary NightSession state only.
  /// Does not write persistent memory.
  CognitiveTurnResult processTurn({
    required String message,
    required NightSession session,
    required WorkingMindView workingMind,
  }) {
    final evidence = perceptionEngine.perceive(message);

    final understanding = ValidatedUnderstanding(
      mentalPatterns: mentalPatternDetector.detect(evidence),
      emotionalPatterns: emotionalPatternDetector.detect(evidence),
      beliefCandidates: beliefDetector.detect(evidence),
      needCandidates: needDetector.detect(evidence),
      preferences: preferenceDetector.detect(evidence),
    );

    final releaseDecision = releaseEngine.evaluate(
      understanding: understanding,
      model: workingMind.model,
    );

    final conversationDecision = conversationPolicy.decide(
      releaseDecision: releaseDecision,
    );

    final exitDecision = exitIntelligence.decide(
      releaseDecision: releaseDecision,
      conversationDecision: conversationDecision,
      session: session,
    );

    // Canonical order: Release → ConversationPolicy → Exit → Conversation.
    // Exit decides whether Conversation executes; Conversation ownership stays after Exit.
    final ConversationUtterance? utterance =
        exitDecision == ExitDecision.continueConversation
            ? conversationEngine.generate(
                conversationDecision: conversationDecision,
                understanding: understanding,
                workingMind: workingMind,
              )
            : null;

    final updatedSession = session.recordTurn(
      SessionTurn(
        releaseDecision: releaseDecision,
        phase: conversationDecision.phase,
      ),
    );

    return CognitiveTurnResult(
      session: updatedSession,
      releaseDecision: releaseDecision,
      conversationDecision: conversationDecision,
      exitDecision: exitDecision,
      utterance: utterance,
    );
  }
}
