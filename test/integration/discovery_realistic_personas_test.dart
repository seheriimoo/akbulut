import 'package:flutter_test/flutter_test.dart';

import 'discovery_realistic_personas.dart';

void main() {
  test('C07 relational follow-ups do not inject prep/rehearsal language', () {
    final c07 = discoveryRealisticFollowUps['C07']!;
    expect(c07, isNotEmpty);
    for (final line in c07) {
      final n = line.toLowerCase();
      for (final banned in discoveryHarnessBannedOnNonRehearsal) {
        expect(n.contains(banned), isFalse, reason: 'C07: $line');
      }
      expect(
        n.contains('mesaj') ||
            n.contains('kavga') ||
            n.contains('keşke') ||
            n.contains('keske') ||
            n.contains('cümle') ||
            n.contains('cumle') ||
            n.contains('onarım') ||
            n.contains('onarim'),
        isTrue,
        reason: 'C07 should stay relational: $line',
      );
    }
  });

  test('C14 follow-ups stay on loneliness', () {
    for (final line in discoveryRealisticFollowUps['C14']!) {
      final n = line
          .toLowerCase()
          .replaceAll('ı', 'i')
          .replaceAll('ö', 'o')
          .replaceAll('ü', 'u')
          .replaceAll('ş', 's')
          .replaceAll('ç', 'c')
          .replaceAll('ğ', 'g');
      expect(
        n.contains('yalniz') ||
            n.contains('kimse') ||
            n.contains('sessiz') ||
            n.contains('yanimda'),
        isTrue,
        reason: line,
      );
    }
  });
}
