import 'mental_pattern.dart';

enum ReasoningDecision { askQuestion, provideReflection }

class ReasoningEngine {
  const ReasoningEngine();

  ReasoningDecision decide(List<MentalPattern> patterns) {
    if (patterns.isNotEmpty) {
      return ReasoningDecision.askQuestion;
    }

    return ReasoningDecision.provideReflection;
  }
}
