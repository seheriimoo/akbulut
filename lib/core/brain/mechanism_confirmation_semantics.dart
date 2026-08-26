import 'thinking_function_kind.dart';

/// Shared semantics: user confirms/elaborates the *function* of a prior
/// mechanism (e.g. rehearsal → preparedness utility) without requiring the
/// prior's negative-outcome vocabulary.
///
/// Expression-plane cognition aid only. Never upgrades to protection/safety.
class MechanismConfirmationSemantics {
  const MechanismConfirmationSemantics._();

  /// True when [message] is only a soft hedge / bare ack (insufficient alone).
  static bool isBareSoftOnly(String message) {
    final n = _normalize(message).replaceAll(RegExp(r'[.!?…,]+'), ' ').trim();
    if (n.isEmpty) return true;
    if (n.length < 10) return true;
    return RegExp(
      r'^(maybe|perhaps|possibly|i guess|i suppose|olabilir|belki|galiba|'
      r'evet|aynen|tamam|ok|okay|yes|yeah|yep|hm+|hmm+)$',
    ).hasMatch(n);
  }

  /// True when remaining content after stripping a leading hedge is still thin.
  static bool isSubstantive(String message) {
    if (isBareSoftOnly(message)) return false;
    final stripped = _stripLeadingHedge(_normalize(message));
    if (stripped.length < 12) return false;
    return !RegExp(
      r'^(maybe|perhaps|olabilir|belki|evet|aynen|tamam|ok|okay|yes|yeah)$',
    ).hasMatch(stripped);
  }

  /// Same-job confirmation/elaboration for a supported prior mechanism kind.
  ///
  /// Does not assert protection. Does not invent safety motives.
  static bool confirmsOrElaboratesSameJob(
    String message,
    ThinkingFunctionKind priorKind,
  ) {
    if (!isSubstantive(message)) return false;
    final text = _normalize(message);

    switch (priorKind) {
      case ThinkingFunctionKind.worstCaseRehearsal:
        return _preparationUtilityOfRehearsal(text) ||
            _scenarioGenerationConfirm(text) ||
            _continuedRehearsalConfirm(text);
      case ThinkingFunctionKind.preparationRehearsal:
        return _preparationUtilityOfRehearsal(text);
      case ThinkingFunctionKind.earlyTomorrowCarry:
        return RegExp(
          r'\b(tomorrow|yarin|carry|carrying|already (in|at|with)|'
          r'next day|morning)\b',
        ).hasMatch(text);
      case ThinkingFunctionKind.certaintyChase:
        return RegExp(
          r'\b(one more|figure|almost|certainty|emin|bir daha|'
          r'if i (just )?know|need to know)\b',
        ).hasMatch(text);
      case ThinkingFunctionKind.protectiveHolding:
        // Confirmation of holding job only when holding language is present —
        // never invent protection from preparation wording.
        return RegExp(
          r"\b(can'?t let go|holding|keep watch|unsafe to stop|"
          r'birakamiyorum|birakamiyorum)\b',
        ).hasMatch(text);
    }
  }

  /// Rehearsal / possibility-running framed as readiness utility.
  static bool _preparationUtilityOfRehearsal(String text) {
    final running = RegExp(
      r'\b(think through|thinking through|run through|running through|'
      r'go(ing)? through|every possibility|all (the )?possibilit|'
      r'possibilities|what could happen|olabilecek|'
      r'her ihtimal|ihtimalleri?|kafadan gecir|kafadan geçir|'
      r'zihinden gecir|zihinden geçir|prova et|prova etmek|'
      r'mentally (going|run)|imagining outcomes?)\b',
    ).hasMatch(text);
    final prep = RegExp(
      r'\b(more prepared|be prepared|feel prepared|feel(ing)? ready|'
      r'prepared|preparation|get ready|getting ready|'
      r'hazir|hazır|hazirlikli|hazırlıklı|hazirlan|hazırlan|'
      r'off guard|blindsid|yakalanmamak|hazirliksiz|hazırlıksız|'
      r'nothing catches|catches me)\b',
    ).hasMatch(text);
    // Structural: possibility-running + preparedness motive.
    if (running && prep) return true;
    // Soft confirm of prep-by-thinking after recognition (hedge + prep utility).
    if (prep &&
        RegExp(
          r'\b(if i|so (that )?i|somehow|so i|feels? like|'
          r'gibi|diye|icin|için)\b',
        ).hasMatch(text)) {
      return true;
    }
    return false;
  }

  static bool _scenarioGenerationConfirm(String text) {
    final gen = RegExp(
      r'\b(scenario|scenarios|senaryo|possibilit|ihtimal|'
      r'think through|every (bad )?outcome|creating|invent)\b',
    ).hasMatch(text);
    final function = RegExp(
      r'\b(prepared|ready|hazir|hazır|catch|off guard|blindsid|'
      r'yakalan|prova)\b',
    ).hasMatch(text);
    return gen && function;
  }

  /// Continued worst-case / scenario rehearsal (same job, not prep utility).
  static bool _continuedRehearsalConfirm(String text) {
    final gen = RegExp(
      r'\b(scenario|scenarios|senaryo|possibilit|ihtimal|creating|'
      r'invent|rehears|ends? badly|ending badly|could go wrong|'
      r'different scenarios|yenisi|baska kotu)\b',
    ).hasMatch(text);
    final bad = RegExp(
      r'\b(badly|worse|worst|disaster|catastrop|kotu|ends? bad|'
      r'go wrong|embarrass|ruin|fall)\b',
    ).hasMatch(text);
    return gen && bad;
  }

  static String _stripLeadingHedge(String text) {
    return text
        .replaceFirst(
          RegExp(
            r'^(maybe|perhaps|possibly|i guess|olabilir|belki|galiba)'
            r'[\s,.]+',
          ),
          '',
        )
        .trim();
  }

  static String _normalize(String message) {
    return message
        .toLowerCase()
        .replaceAll('’', "'")
        .replaceAll('‘', "'")
        .replaceAll('`', "'")
        .replaceAll('ö', 'o')
        .replaceAll('ü', 'u')
        .replaceAll('ı', 'i')
        .replaceAll('ğ', 'g')
        .replaceAll('ş', 's')
        .replaceAll('ç', 'c')
        .trim();
  }
}
