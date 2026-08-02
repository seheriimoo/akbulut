import 'living_mind_model.dart';
import 'mental_pattern.dart';
import 'emotional_pattern.dart';

class LearningEngine {
  const LearningEngine();

  LivingMindModel update(
    LivingMindModel model, {
    List<MentalPattern> mentalPatterns = const [],
    List<EmotionalPattern> emotionalPatterns = const [],
  }) {
    return model.copyWith(
      mentalPatterns: mentalPatterns.isEmpty
          ? model.mentalPatterns
          : mentalPatterns,
      emotionalPatterns: emotionalPatterns.isEmpty
          ? model.emotionalPatterns
          : emotionalPatterns,
    );
  }
}
