/// Conversation Evaluator V1 — measure-only night quality gate.
///
/// Does not speak, compile, rewrite, or reopen HCOS decisions.
/// Scores structural night fidelity from turn traces only.
enum EvalDisposition { pass, warning, reject }

/// One sealed turn after expression (Guard admit or drop).
class NightTurnTrace {
  final String phase;
  final String? spoken;
  final bool guardDropped;
  final String? language; // en | tr | mixed | null

  const NightTurnTrace({
    required this.phase,
    required this.spoken,
    required this.guardDropped,
    this.language,
  });
}

class ConversationEvalReport {
  final EvalDisposition disposition;
  final int spokenTurns;
  final int guardDrops;
  final bool handoffPresent;
  final bool languageMixDetected;
  final List<String> notes;

  const ConversationEvalReport({
    required this.disposition,
    required this.spokenTurns,
    required this.guardDrops,
    required this.handoffPresent,
    required this.languageMixDetected,
    required this.notes,
  });
}

class ConversationEvaluator {
  const ConversationEvaluator();

  static const String version = '1.0';

  ConversationEvalReport scoreNight(List<NightTurnTrace> turns) {
    final notes = <String>[];
    var spoken = 0;
    var drops = 0;
    var handoff = false;
    var mixed = false;

    for (final turn in turns) {
      if (turn.spoken != null && turn.spoken!.trim().isNotEmpty) {
        spoken++;
        final text = turn.spoken!.toLowerCase();
        if (turn.phase == 'continuity' &&
            (text.contains('preparing') ||
                text.contains('leave you with') ||
                text.contains('sessizlik') ||
                text.contains('dinlenmeyle') ||
                text.contains('a little quiet') ||
                text.contains('a little rest'))) {
          handoff = true;
        }
      }
      if (turn.guardDropped) drops++;
      if (turn.language == 'mixed') mixed = true;
    }

    if (mixed) {
      notes.add('mixed-language utterance detected');
    }
    if (drops > 0) {
      notes.add('guard_drops=$drops');
    }
    if (!handoff) {
      notes.add('missing soft audio handoff line');
    }
    if (spoken == 0) {
      notes.add('no spoken turns');
    }

    // Hard reject: silent night, language mix, or majority drops.
    if (spoken == 0 || mixed || (turns.isNotEmpty && drops / turns.length > 0.5)) {
      return ConversationEvalReport(
        disposition: EvalDisposition.reject,
        spokenTurns: spoken,
        guardDrops: drops,
        handoffPresent: handoff,
        languageMixDetected: mixed,
        notes: notes,
      );
    }

    // Warning: any drop or missing handoff.
    if (drops > 0 || !handoff) {
      return ConversationEvalReport(
        disposition: EvalDisposition.warning,
        spokenTurns: spoken,
        guardDrops: drops,
        handoffPresent: handoff,
        languageMixDetected: mixed,
        notes: notes,
      );
    }

    notes.add('night structural fidelity ok');
    return ConversationEvalReport(
      disposition: EvalDisposition.pass,
      spokenTurns: spoken,
      guardDrops: drops,
      handoffPresent: handoff,
      languageMixDetected: mixed,
      notes: notes,
    );
  }

  /// Heuristic language tag for evaluator traces and sticky UI chrome.
  ///
  /// Includes common ASCII-only Turkish night stems (mobile keyboards without
  /// diacritics), e.g. "uyuyamiyorum", without treating single English words
  /// as Turkish.
  static String? detectLanguage(String? text) {
    if (text == null || text.trim().isEmpty) return null;
    final lower = text.toLowerCase();
    final hasTr = RegExp(r'[ğüşıöç]').hasMatch(lower) ||
        lower.contains('zorunda') ||
        lower.contains('gece') ||
        lower.contains('belki') ||
        lower.contains('sanki') ||
        lower.contains('sessizlik') ||
        lower.contains('yalnız') ||
        lower.contains('bırak') ||
        lower.contains('konuş') ||
        lower.contains('hisset') ||
        _hasAsciiTurkishNightStem(lower);
    final hasEn = RegExp(
      r"\b(you|your|the|tonight|don't|need|perhaps|mind|leave|preparing|"
      r"thinking|can't|cannot|about|tomorrow|feel|feeling)\b",
    ).hasMatch(lower);
    if (hasTr && hasEn) return 'mixed';
    if (hasTr) return 'tr';
    if (hasEn) return 'en';
    return null;
  }

  /// Mobile ASCII Turkish stems that reliably signal TR without diacritics.
  static bool _hasAsciiTurkishNightStem(String lower) {
    if (lower.contains('uyuyamiyorum')) return true;
    if (lower.contains('uyuyamıyorum')) return true;
    if (lower.contains('uyuyamiyor')) return true;
    if (lower.contains('yorgunum')) return true;
    if (lower.contains('zihnim')) return true;
    if (lower.contains('susmuyor')) return true;
    if (lower.contains('dusunmekten')) return true;
    if (lower.contains('düşünmekten')) return true;
    if (lower.contains('dusunuyorum')) return true;
    if (lower.contains('düşünüyorum')) return true;
    if (lower.contains('konusamiyorum')) return true;
    if (lower.contains('konusmak')) return true;
    return false;
  }
}
