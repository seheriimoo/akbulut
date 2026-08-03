import 'evidence.dart';
import 'preference.dart';

class PreferenceDetector {
  const PreferenceDetector();

  List<Preference> detect(List<Evidence> evidence) {
    final preferences = <Preference>[];

    for (final item in evidence) {
      if (item.type != 'preference') {
        continue;
      }

      preferences.add(
        Preference(
          id: item.value.toLowerCase().replaceAll(' ', '_'),
          name: item.value,
          description: item.value,
          confidence: item.confidence,
          observations: 1,
        ),
      );
    }

    return preferences;
  }
}
