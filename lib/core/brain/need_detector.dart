import 'evidence.dart';
import 'need.dart';

class NeedDetector {
  const NeedDetector();

  List<Need> detect(List<Evidence> evidence) {
    final needs = <Need>[];

    for (final item in evidence) {
      if (item.type != 'need') {
        continue;
      }

      needs.add(
        Need(
          id: item.value.toLowerCase().replaceAll(' ', '_'),
          name: item.value,
          description: item.value,
          confidence: item.confidence,
          observations: 1,
        ),
      );
    }

    return needs;
  }
}
