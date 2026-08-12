import 'evidence.dart';
import 'emotional_pattern.dart';

class EmotionalPatternDetector {
  const EmotionalPatternDetector();

  List<EmotionalPattern> detect(List<Evidence> evidence) {
    final hasLoneliness = evidence.any(
      (e) => e.value == 'loneliness_activation',
    );
    final hasFutureUncertainty = evidence.any(
      (e) => e.value == 'future_uncertainty',
    );
    final hasEmotionalActivation = evidence.any(
      (e) => e.value == 'emotional_activation',
    );

    if (hasLoneliness) {
      return const [
        EmotionalPattern(
          id: 'loneliness',
          name: 'Loneliness',
          description: 'Recurring felt aloneness or absence texture.',
          confidence: 0.82,
          observations: 1,
        ),
      ];
    }

    if (hasEmotionalActivation || hasFutureUncertainty) {
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
