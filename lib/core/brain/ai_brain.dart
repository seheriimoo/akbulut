import 'belief_detector.dart';
import 'emotional_pattern_detector.dart';
import 'knowledge_merger.dart';
import 'learning_engine.dart';
import 'living_mind_model.dart';
import 'mental_pattern_detector.dart';
import 'need_detector.dart';
import 'perception_engine.dart';
import 'preference_detector.dart';
import 'reasoning_engine.dart';

class NoctaAIBrain {
  final LivingMindModel mindModel;

  final PerceptionEngine perceptionEngine;
  final MentalPatternDetector mentalPatternDetector;
  final EmotionalPatternDetector emotionalPatternDetector;
  final BeliefDetector beliefDetector;
  final NeedDetector needDetector;
  final PreferenceDetector preferenceDetector;

  final KnowledgeMerger knowledgeMerger;

  final LearningEngine learningEngine;
  final ReasoningEngine reasoningEngine;

  const NoctaAIBrain({
    required this.mindModel,
    required this.perceptionEngine,
    required this.mentalPatternDetector,
    required this.emotionalPatternDetector,
    required this.beliefDetector,
    required this.needDetector,
    required this.preferenceDetector,
    required this.knowledgeMerger,
    required this.learningEngine,
    required this.reasoningEngine,
  });

  ReasoningDecision processMessage(String message) {
    final evidence = perceptionEngine.perceive(message);

    final mentalPatterns = mentalPatternDetector.detect(evidence);
    final emotionalPatterns = emotionalPatternDetector.detect(evidence);

    final beliefCandidates = beliefDetector.detect(evidence);

    final beliefs = knowledgeMerger.merge(mindModel.beliefs, beliefCandidates);

    final needs = needDetector.detect(evidence);

    final preferences = preferenceDetector.detect(evidence);

    final updatedModel = learningEngine.update(
      mindModel,
      mentalPatterns: mentalPatterns,
      emotionalPatterns: emotionalPatterns,
      beliefs: beliefs,
      needs: needs,
      preferences: preferences,
    );

    return reasoningEngine.decide(
      mentalPatterns: updatedModel.mentalPatterns,
      beliefs: updatedModel.beliefs,
      needs: updatedModel.needs,
      preferences: updatedModel.preferences,
    );
  }
}
