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
  /// Trailing punctuation and emoji (e.g. "selam 👋") are allowed.
  bool isNeutralGreeting(String message) {
    final core = _greetingCore(message);
    if (core.isEmpty) return false;
    return _greetingPattern.hasMatch(core);
  }

  /// Lowercase greeting text with trailing punctuation / emoji removed.
  static String _greetingCore(String message) {
    var s = message.trim().toLowerCase();
    if (s.isEmpty) return '';
    // Drop common emoji / variation selectors / ZWJ so "selam 👋" matches.
    s = s.replaceAll(
      RegExp(
        r'[\u{1F300}-\u{1FAFF}\u{2600}-\u{27BF}\u{FE0F}\u{200D}]+',
        unicode: true,
      ),
      ' ',
    );
    s = s.replaceAll(RegExp(r'[.!?…,;:]+'), ' ');
    s = s.replaceAll(RegExp(r'\s+'), ' ').trim();
    return s;
  }

  /// Full-message greeting forms only (after [_greetingCore]).
  static final RegExp _greetingPattern = RegExp(
    r'^(?:'
    r'h+i+|h+e+y+|hello+'
    r'|good\s+evening|good\s+night|good\s+morning'
    r'|selam(?:lar)?'
    r'|merhaba(?:lar)?'
    r')'
    r'(?:\s+there)?'
    r'$',
  );
}
