import 'belief.dart';
import 'evidence.dart';

class BeliefDetector {
  const BeliefDetector();

  List<Belief> detect(List<Evidence> evidence) {
    final beliefs = <Belief>[];

    for (final item in evidence) {
      if (item.type != 'belief') {
        continue;
      }

      beliefs.add(
        Belief(
          id: item.value.toLowerCase().replaceAll(' ', '_'),
          name: item.value,
          description: item.value,
          confidence: item.confidence,
          observations: 1,
        ),
      );
    }

    return beliefs;
  }
}
