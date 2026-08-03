import 'detection_candidate.dart';
import 'evidence.dart';

class NeedDetector {
  const NeedDetector();

  List<DetectionCandidate> detect(List<Evidence> evidence) {
    final needs = <DetectionCandidate>[];

    for (final item in evidence) {
      if (item.type != 'need') {
        continue;
      }

      needs.add(
        DetectionCandidate(
          id: item.value.toLowerCase().replaceAll(' ', '_'),
          name: item.value,
          description: item.value,
        ),
      );
    }

    return needs;
  }
}
