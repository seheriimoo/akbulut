import 'package:flutter_test/flutter_test.dart';

import 'v1_scenario_fixtures.dart';
import 'v1_scenario_harness.dart';

/// Conversation Quality Validation V1 — Step 1.
///
/// Deterministic structural checks only. No Human Gold. No Evaluator scoring.
void main() {
  const harness = V1ScenarioHarness();

  test('V1 Step 1 fixtures are exactly S01–S20', () {
    expect(v1ScenarioFixtures.length, 20);
    expect(
      v1ScenarioFixtures.map((s) => s.id).toList(),
      [
        'S01',
        'S02',
        'S03',
        'S04',
        'S05',
        'S06',
        'S07',
        'S08',
        'S09',
        'S10',
        'S11',
        'S12',
        'S13',
        'S14',
        'S15',
        'S16',
        'S17',
        'S18',
        'S19',
        'S20',
      ],
    );
  });

  test('V1 Step 1 structural harness runs all 20 scenarios', () async {
    final results = await harness.runAll(v1ScenarioFixtures);

    expect(results.length, 20);

    final failed = results.where((r) => !r.passed).toList();
    if (failed.isNotEmpty) {
      final detail = failed
          .map((r) => '${r.id} ${r.title}:\n  - ${r.failures.join('\n  - ')}')
          .join('\n');
      fail('Structural FAIL (${failed.length}/20):\n$detail');
    }

    for (final r in results) {
      // ignore: avoid_print
      print('PASS ${r.id} ${r.title}');
    }
  });
}
