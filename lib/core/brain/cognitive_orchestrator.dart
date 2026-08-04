import 'belief_detector.dart';
import 'conversation_engine.dart';
import 'conversation_policy.dart';
import 'cognitive_turn_result.dart';
import 'emotional_pattern_detector.dart';
import 'exit_intelligence.dart';
import 'mental_pattern_detector.dart';
import 'need_detector.dart';
import 'night_session.dart';
import 'perception_engine.dart';
import 'preference_detector.dart';
import 'release_engine.dart';
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

  CognitiveTurnResult processTurn({
    required String message,
    required NightSession session,
    required WorkingMindView workingMind,
  }) {
    // TODO 1
    final evidence = perceptionEngine.perceive(message);

    // TODO 2
    final understanding = ValidatedUnderstanding(
      mentalPatterns: mentalPatternDetector.detect(evidence),
      emotionalPatterns: emotionalPatternDetector.detect(evidence),
      beliefCandidates: beliefDetector.detect(evidence),
      needCandidates: needDetector.detect(evidence),
      preferences: preferenceDetector.detect(evidence),
    );

    // TODO 3 will consume this.
    understanding;

    // TODO 3
    // ReleaseEngine

    // TODO 4
    // ConversationPolicy

    // TODO 5
    // ExitIntelligence

    // TODO 6
    // ConversationEngine

    // TODO 7
    // Return CognitiveTurnResult

    throw UnimplementedError();
  }
}
