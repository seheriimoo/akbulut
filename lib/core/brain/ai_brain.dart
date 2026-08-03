import 'belief_detector.dart';
import 'learning_engine.dart';
import 'living_mind_model.dart';
import 'mental_pattern_detector.dart';
import 'emotional_pattern_detector.dart';
import 'perception_engine.dart';
import 'reasoning_engine.dart';

class NoctaAIBrain {
  final LivingMindModel mindModel;

  final PerceptionEngine perceptionEngine;
  final MentalPatternDetector mentalPatternDetector;
  final EmotionalPatternDetector emotionalPatternDetector;
  final BeliefDetector beliefDetector;
  final LearningEngine learningEngine;
  final ReasoningEngine reasoningEngine;

  const NoctaAIBrain({
    required this.mindModel,
    required this.perceptionEngine,
    required this.mentalPatternDetector,
    required this.emotionalPatternDetector,
    required this.beliefDetector,
    required this.learningEngine,
    required this.reasoningEngine,
  });

  ReasoningDecision processMessage(String message) {
    final evidence = perceptionEngine.perceive(message);

    final mentalPatterns = mentalPatternDetector.detect(evidence);

    final emotionalPatterns = emotionalPatternDetector.detect(evidence);

    final beliefs = beliefDetector.detect(evidence);

    final updatedModel = learningEngine.update(
      mindModel,
      mentalPatterns: mentalPatterns,
      emotionalPatterns: emotionalPatterns,
      beliefs: beliefs,
    );

    return reasoningEngine.decide(updatedModel.mentalPatterns);
  }
}
