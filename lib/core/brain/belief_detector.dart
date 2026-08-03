import 'detection_candidate.dart';
import 'evidence.dart';

class BeliefDetector {
  const BeliefDetector();

  List<DetectionCandidate> detect(List<Evidence> evidence) {
    final beliefs = <DetectionCandidate>[];

    for (final item in evidence) {
      if (item.type != 'belief') {
        continue;
      }

      beliefs.add(
        DetectionCandidate(
          id: item.value.toLowerCase().replaceAll(' ', '_'),
          name: item.value,
          description: item.value,
        ),
      );
    }

    return beliefs;
  }
}
