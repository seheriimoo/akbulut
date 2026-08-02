import 'evidence.dart';
import 'mental_pattern.dart';
import 'mental_pattern_status.dart';

class MentalPatternDetector {
  const MentalPatternDetector();

  List<MentalPattern> detect(List<Evidence> evidence) {
    final hasThinking = evidence.any((e) => e.value == 'repetitive_thinking');

    final hasUncertainty = evidence.any((e) => e.value == 'future_uncertainty');

    final hasMentalOverload = evidence.any((e) => e.value == 'mental_overload');

    if (hasThinking && (hasUncertainty || hasMentalOverload)) {
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
