import 'belief.dart';
import 'emotional_pattern.dart';
import 'living_mind_model.dart';
import 'mental_pattern.dart';
import 'need.dart';
import 'preference.dart';

class LearningEngine {
  const LearningEngine();

  LivingMindModel update(
    LivingMindModel model, {
    List<MentalPattern> mentalPatterns = const [],
    List<EmotionalPattern> emotionalPatterns = const [],
    List<Belief> beliefs = const [],
    List<Need> needs = const [],
    List<Preference> preferences = const [],
  }) {
    return model.copyWith(
      mentalPatterns: mentalPatterns.isEmpty
          ? model.mentalPatterns
          : mentalPatterns,
      emotionalPatterns: emotionalPatterns.isEmpty
          ? model.emotionalPatterns
          : emotionalPatterns,
      beliefs: beliefs.isEmpty ? model.beliefs : beliefs,
      needs: needs.isEmpty ? model.needs : needs,
      preferences: preferences.isEmpty ? model.preferences : preferences,
    );
  }
}
