/// Release configuration for response language selection.
///
/// Does not change HCOS routing, boundaries, Guard contracts, or Conversation
/// DNA. Only selects Turkish vs English *output variants* and LLM language lock.
///
/// V1 production default: follow detected session language (`false`).
/// Set [forceTurkishResponses] to `true` only for local/TestFlight Turkish QA.
class TemporaryLanguageOverride {
  const TemporaryLanguageOverride._();

  /// When `true`, Nocta always speaks Turkish (same WHAT, same brevity).
  static const bool forceTurkishResponses = false;

  static String? effectiveNightLanguage(String? detected) {
    if (forceTurkishResponses) return 'tr';
    return detected;
  }

  static bool responseIsTurkish({required bool detectedTurkish}) {
    if (forceTurkishResponses) return true;
    return detectedTurkish;
  }
}
