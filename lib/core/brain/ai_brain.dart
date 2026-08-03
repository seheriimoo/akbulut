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

class NoctaAIBrain {
  final LivingMindModel mindModel;

  final PerceptionEngine perceptionEngine;
  final MentalPatternDetector mentalPatternDetector;
  final EmotionalPatternDetector emotionalPatternDetector;
  final BeliefDetector beliefDetector;
  final NeedDetector needDetector;
  final PreferenceDetector preferenceDetector;
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

    final updatedModel = memoryEngine.update(mindModel, understanding);

    final decision = reasoningEngine.decide(
      mentalPatterns: updatedModel.mentalPatterns,
      beliefs: updatedModel.beliefs,
      needs: updatedModel.needs,
      preferences: updatedModel.preferences,
    );

    return BrainTurnResult(model: updatedModel, decision: decision);
  }
}
