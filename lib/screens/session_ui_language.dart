/// Sticky UI language for night-chat chrome (CTA copy). Not HCOS cognition.
enum SessionUiLanguage {
  unknown,
  tr,
  en,
}

/// Resolves strong TR/EN signals into a sticky session UI language.
///
/// Short / unstable tokens (yeter, tmm, ok, emoji, digits) never flip language.
/// Once locked, only a clearly strong opposite long message may switch (V1).
class SessionUiLanguageResolver {
  const SessionUiLanguageResolver();

  static const int _minStrongChars = 12;

  /// Apply [userMessage] to [current]. Never jumps on short/unstable lines.
  SessionUiLanguage resolveNext({
    required SessionUiLanguage current,
    required String userMessage,
  }) {
    final signal = strongSignal(userMessage);
    if (signal == null) return current;
    if (current == SessionUiLanguage.unknown) return signal;
    if (current == signal) return current;
    // Strong opposite language on a long message may switch (mirroring).
    return signal;
  }

  /// Strong language tag, or null when the line is short/unstable/mixed/weak.
  SessionUiLanguage? strongSignal(String message) {
    final raw = message.trim();
    if (raw.isEmpty) return null;
    if (_isUnstableToken(raw)) return null;
    if (raw.runes.length < _minStrongChars) return null;

    final lower = raw.toLowerCase();
    final hasTr = _hasStrongTr(lower);
    final hasEn = _hasStrongEn(lower);
    if (hasTr && hasEn) return null;
    if (hasTr) return SessionUiLanguage.tr;
    if (hasEn) return SessionUiLanguage.en;
    return null;
  }

  /// CTA copy for continue-after-early-leave. Unknown → English safe default.
  String continueAudioLabel(SessionUiLanguage language) {
    switch (language) {
      case SessionUiLanguage.tr:
        return 'Sese devam et';
      case SessionUiLanguage.en:
      case SessionUiLanguage.unknown:
        return 'Continue to audio';
    }
  }

  static bool _isUnstableToken(String raw) {
    final n = raw
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[.!?…,;:]+$'), '')
        .replaceAll(RegExp(r'\s+'), ' ');
    if (n.isEmpty) return true;
    // Affirmations / bare exits / fillers — never set or flip session language.
    const unstable = {
      'yeter',
      'artık yeter',
      'artik yeter',
      'enough',
      "that's enough",
      'thats enough',
      'tmm',
      'tamam',
      'ok',
      'okey',
      'peki',
      'tmm yeter',
      'tamam yeter',
      'tamam artık yeter',
      'tamam artik yeter',
      'ok yeter',
      'okey yeter',
      'peki yeter',
      'yes',
      'no',
      'evet',
      'hayır',
      'hayir',
      'hmm',
      'hm',
      'ok.',
    };
    if (unstable.contains(n)) return true;
    // Digits-only / no letters — never a language lock signal.
    if (RegExp(r'^[\d\s]+$').hasMatch(n)) return true;
    if (!RegExp(r'[a-zA-ZğüşıöçĞÜŞİÖÇ]').hasMatch(raw)) return true;
    return false;
  }

  static bool _hasStrongTr(String lower) {
    if (RegExp(r'[ğüşıöç]').hasMatch(lower)) return true;
    if (lower.contains('zorunda')) return true;
    if (lower.contains('gece')) return true;
    if (lower.contains('belki')) return true;
    if (lower.contains('sanki')) return true;
    if (lower.contains('sessizlik')) return true;
    if (lower.contains('yalnız')) return true;
    if (lower.contains('bırak')) return true;
    if (lower.contains('konuş')) return true;
    if (lower.contains('hisset')) return true;
    return false;
  }

  static bool _hasStrongEn(String lower) {
    return RegExp(
      r"\b(you|your|the|tonight|don't|need|perhaps|mind|leave|preparing|"
      r"thinking|can't|cannot|about|tomorrow|feel|feeling)\b",
    ).hasMatch(lower);
  }
}
