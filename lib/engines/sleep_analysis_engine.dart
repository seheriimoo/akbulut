import '../models/sleep_analysis_result.dart';

class SleepAnalysisEngine {
  static SleepAnalysisResult analyze({
    required List<int> answers,
    String extraNote = '',
  }) {
    int overthinking = 0;
    int stress = 0;
    int dopamine = 0;
    int physical = 0;

    if (answers.length >= 6) {
      overthinking += answers[0];
      stress += answers[1];
      dopamine += answers[2];
      physical += answers[3];
      overthinking += answers[4];
      stress += answers[5];
    }

    final note = extraNote.toLowerCase();

    if (note.contains('kafa') ||
        note.contains('düşün') ||
        note.contains('susmuyor')) {
      overthinking += 2;
    }

    if (note.contains('stres') ||
        note.contains('kaygı') ||
        note.contains('gergin')) {
      stress += 2;
    }

    if (note.contains('telefon') ||
        note.contains('ekran') ||
        note.contains('sosyal medya')) {
      dopamine += 2;
    }

    if (note.contains('beden') ||
        note.contains('gerilim') ||
        note.contains('çarpıntı')) {
      physical += 2;
    }

    final scores = {
      'overthinking': overthinking,
      'stress': stress,
      'dopamine': dopamine,
      'physical': physical,
    };

    final topCategory =
        scores.entries.reduce((a, b) => a.value >= b.value ? a : b).key;

    switch (topCategory) {
      case 'overthinking':
        return const SleepAnalysisResult(
          category: 'overthinking',
          title: 'Zihnin Hâlâ Aktif',
          summary:
              'Vücudun dinlenmeye hazır olsa da zihnin düşünmeye devam ediyor. Bu gece yumuşak bir geçiş gerekli.',
          recommendedSessionId: 'soft_sleep_entry',
          recommendedSessionTitle: 'Soft Sleep Entry',
        );

      case 'stress':
        return const SleepAnalysisResult(
          category: 'stress',
          title: 'İç Sistem Hâlâ Gergin',
          summary:
              'Bedenin uyumak istiyor ama sinir sistemin henüz tam sakinleşmedi.',
          recommendedSessionId: 'calm_nervous_system',
          recommendedSessionTitle: 'Calm Nervous System',
        );

      case 'dopamine':
        return const SleepAnalysisResult(
          category: 'dopamine',
          title: 'Zihnin Fazla Uyarılmış',
          summary:
              'Bugün fazla uyaran vardı. Daha sade ve yavaş bir geçiş gerekli.',
          recommendedSessionId: 'low_stimulation_winddown',
          recommendedSessionTitle: 'Low Stimulation Wind-down',
        );

      case 'physical':
        return const SleepAnalysisResult(
          category: 'physical',
          title: 'Beden Gevşemekte Zorlanıyor',
          summary:
              'Uykuya geçişi zorlaştıran şey bedensel gerginlik olabilir.',
          recommendedSessionId: 'body_release_sleep',
          recommendedSessionTitle: 'Body Release Sleep',
        );

      default:
        return const SleepAnalysisResult(
          category: 'general',
          title: 'Yumuşak Bir Geçiş Gerekli',
          summary:
              'Sisteminin daha sakin ve güvenli bir uyku geçişine ihtiyacı var.',
          recommendedSessionId: 'soft_sleep_entry',
          recommendedSessionTitle: 'Soft Sleep Entry',
        );
    }
  }
}