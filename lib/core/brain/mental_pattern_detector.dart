import 'evidence.dart';
import 'mental_pattern.dart';
import 'mental_pattern_status.dart';

class MentalPatternDetector {
  const MentalPatternDetector();

  List<MentalPattern> detect(List<Evidence> evidence) {
    final hasLightConversation = evidence.any(
      (e) => e.value == 'light_conversation',
    );
    final hasHardLoad = evidence.any(
      (e) =>
          e.value == 'mental_overload' ||
          e.value == 'holding_against_ease',
    );
    if (hasLightConversation && !hasHardLoad) {
      return [];
    }

    final hasThinking = evidence.any((e) => e.value == 'repetitive_thinking');
    final hasUncertainty = evidence.any((e) => e.value == 'future_uncertainty');
    final hasMentalOverload = evidence.any((e) => e.value == 'mental_overload');

    // Any cognitive-load signal is enough to mark an active mental pattern.
    // Previously required thinking AND (uncertainty|overload), which missed
    // common night language like "I'm spiraling" / "I can't let go".
    if (hasMentalOverload || hasThinking || hasUncertainty) {
      return [
        const MentalPattern(
          id: 'overanalyzing',
          name: 'Overanalyzing',
          description: 'Repeated attempts to mentally solve uncertainty.',
          confidence: 0.80,
          observations: 1,
          status: MentalPatternStatus.observed,
        ),
      ];
    }

    return [];
  }
}
