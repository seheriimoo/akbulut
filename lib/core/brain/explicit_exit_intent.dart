/// Deterministic detector for explicit conversation→audio exit intent.
///
/// Presentation/policy input only. Does not own readiness, speech, or beds.
class ExplicitExitIntent {
  const ExplicitExitIntent();

  /// True when the user clearly asks to end talk and move to rest audio.
  /// Bare “yeter/enough” inside unrelated sentences must not match.
  bool matches(String message) {
    final normalized = _normalize(message);
    if (normalized.isEmpty) return false;
    if (_isFalsePositive(normalized)) return false;
    if (_matchesAudioMove(normalized)) return true;
    if (_matchesBareEnough(normalized)) return true;
    return false;
  }

  static String _normalize(String message) {
    var s = message.trim().toLowerCase();
    s = s.replaceAll('\u2019', "'");
    s = s.replaceAll(RegExp(r'\s+'), ' ');
    return s;
  }

  static bool _isFalsePositive(String n) {
    // Sleep / volume / time sufficiency — not night-exit intent.
    if (n.contains('yeter mi')) return true;
    if (n.contains('yeterince')) return true;
    if (RegExp(r'\byeterli\b').hasMatch(n)) return true;
    if (n.contains('enough sleep')) return true;
    if (n.contains('loud enough')) return true;
    if (n.contains('enough time')) return true;
    if (RegExp(r'\bget enough\b').hasMatch(n)) return true;
    if (RegExp(r'\bhave enough\b').hasMatch(n)) return true;
    if (RegExp(r'\bis .+ enough\b').hasMatch(n)) return true;
    return false;
  }

  static bool _matchesAudioMove(String n) {
    // Turkish direct audio handoff.
    if (n.contains('sese geç')) return true;
    if (n.contains('sese gec')) return true; // ASCII fallback
    // English direct audio handoff.
    if (n.contains('move to audio')) return true;
    if (n.contains('ready for the audio')) return true;
    if (n.contains('take me to the audio')) return true;
    return false;
  }

  static bool _matchesBareEnough(String n) {
    // Whole-utterance close only (allow light trailing punctuation).
    final stripped = n.replaceAll(RegExp(r'[.!?…,]+$'), '').trim();
    if (stripped == 'yeter') return true;
    if (stripped == 'artık yeter') return true;
    if (stripped == 'artik yeter') return true;
    if (stripped == 'enough') return true;
    if (stripped == "that's enough") return true;
    if (stripped == 'thats enough') return true;
    return false;
  }
}
