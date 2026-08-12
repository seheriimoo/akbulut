/// Deterministic Neutral Entry / greeting detector V1.
///
/// Expression/protocol aid only. Does not choose Release, Exit, or memory.
/// Full-message match only — never hijacks meaningful emotional content.
class NeutralEntryDetector {
  const NeutralEntryDetector();

  /// True when [message] is a content-free greeting opener.
  ///
  /// Requires the entire trimmed message to match a greeting form.
  /// Rejects any extra content (e.g. "hi I'm spiraling").
  bool isNeutralGreeting(String message) {
    final normalized = message.trim().toLowerCase();
    if (normalized.isEmpty) return false;
    return _greetingPattern.hasMatch(normalized);
  }

  /// Full-message greeting forms only.
  static final RegExp _greetingPattern = RegExp(
    r'^(?:'
    r'h+i+|h+e+y+|hello+'
    r'|good\s+evening|good\s+night|good\s+morning'
    r')'
    r'(?:\s+there)?'
    r'[.!?…]*'
    r'$',
  );
}
