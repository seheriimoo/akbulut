import 'belief_detector.dart';
import 'brain_turn_result.dart';
import 'emotional_pattern_detector.dart';
import 'living_mind_model.dart';
import 'memory_engine.dart';
import 'mental_pattern_detector.dart';
import 'need_detector.dart';
import 'perception_engine.dart';
import 'preference_detector.dart';
import 'reasoning_engine.dart';
import 'validated_understanding.dart';

/// NoctaAIBrain
///
/// Transitional entry point pending cutover to CognitiveOrchestrator.
///
/// Mid-turn persistent memory writes are not part of the
/// canonical HCOS Architecture v1.1 path.
///
/// MemoryEngine remains the sole LivingMindModel writer and accepts
/// SessionSummary at session end only.
class NoctaAIBrain {
  final LivingMindModel mindModel;

  final PerceptionEngine perceptionEngine;
  final MentalPatternDetector mentalPatternDetector;
  final EmotionalPatternDetector emotionalPatternDetector;
  final BeliefDetector beliefDetector;
  final NeedDetector needDetector;
  final PreferenceDetector preferenceDetector;

  /// Retained for transitional cutover.
  ///
  /// Not invoked mid-turn. Session-end writes use SessionSummary.
  // ignore: unused_field
  final MemoryEngine memoryEngine;
  final ReasoningEngine reasoningEngine;

  const NoctaAIBrain({
    required this.mindModel,
    required this.perceptionEngine,
    required this.mentalPatternDetector,
    required this.emotionalPatternDetector,
    required this.beliefDetector,
    required this.needDetector,
    required this.preferenceDetector,
    required this.memoryEngine,
    required this.reasoningEngine,
  });

  BrainTurnResult processMessage(String message) {
    final evidence = perceptionEngine.perceive(message);

    final understanding = ValidatedUnderstanding(
      mentalPatterns: mentalPatternDetector.detect(evidence),
      emotionalPatterns: emotionalPatternDetector.detect(evidence),
      beliefCandidates: beliefDetector.detect(evidence),
      needCandidates: needDetector.detect(evidence),
      preferences: preferenceDetector.detect(evidence),
    );

    // Obsolete mid-turn MemoryEngine.update(ValidatedUnderstanding) removed.
    // LivingMindModel is unchanged during the turn.

    final decision = reasoningEngine.decide(
      mentalPatterns: understanding.mentalPatterns.isNotEmpty
          ? understanding.mentalPatterns
          : mindModel.mentalPatterns,
      beliefs: mindModel.beliefs,
      needs: mindModel.needs,
      preferences: understanding.preferences.isNotEmpty
          ? understanding.preferences
          : mindModel.preferences,
    );

    return BrainTurnResult(model: mindModel, decision: decision);
  }
}
