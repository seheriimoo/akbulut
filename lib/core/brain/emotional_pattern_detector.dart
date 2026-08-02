import 'evidence.dart';
import 'emotional_pattern.dart';

class EmotionalPatternDetector {
  const EmotionalPatternDetector();

  List<EmotionalPattern> detect(List<Evidence> evidence) {
    final hasFutureUncertainty = evidence.any(
      (e) => e.value == 'future_uncertainty',
    );

    if (hasFutureUncertainty) {
      return const [
        EmotionalPattern(
          id: 'anxiety',
          name: 'Anxiety',
          description: 'Recurring emotional state of uncertainty.',
          confidence: 0.80,
          observations: 1,
        ),
      ];
    }

    return [];
  }
}
