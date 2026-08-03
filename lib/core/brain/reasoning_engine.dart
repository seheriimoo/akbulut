import 'belief.dart';
import 'mental_pattern.dart';
import 'need.dart';
import 'preference.dart';

enum ReasoningDecision { askQuestion, provideReflection }

class ReasoningEngine {
  const ReasoningEngine();

  ReasoningDecision decide({
    required List<MentalPattern> mentalPatterns,
    required List<Belief> beliefs,
    required List<Need> needs,
    required List<Preference> preferences,
  }) {
    if (mentalPatterns.isNotEmpty) {
      return ReasoningDecision.askQuestion;
    }

    if (beliefs.isNotEmpty) {
      return ReasoningDecision.askQuestion;
    }

    if (needs.isNotEmpty) {
      return ReasoningDecision.provideReflection;
    }

    if (preferences.isNotEmpty) {
      return ReasoningDecision.provideReflection;
    }

    return ReasoningDecision.provideReflection;
  }
}
