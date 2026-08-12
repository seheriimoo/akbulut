import '../quality/conversation_evaluator.dart';

/// Sticky UI language for night-chat chrome (CTA copy). Not HCOS cognition.
enum SessionUiLanguage {
  unknown,
  tr,
  en,
}

/// Resolves strong TR/EN signals into a sticky session UI language.
///
/// Uses [ConversationEvaluator.detectLanguage] as the shared language signal
/// (including ASCII Turkish night stems). Short / unstable tokens never flip
/// language. Assistant replies may reinforce the sticky language when strong.
class SessionUiLanguageResolver {
  const SessionUiLanguageResolver();

  static const int _minStrongChars = 10;

  /// Apply [message] (user or assistant) to [current].
  /// Never jumps on short/unstable lines.
  SessionUiLanguage resolveNext({
    required SessionUiLanguage current,
    required String message,
  }) {
    final signal = strongSignal(message);
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

    final detected = ConversationEvaluator.detectLanguage(raw);
    if (detected == 'tr') return SessionUiLanguage.tr;
    if (detected == 'en') return SessionUiLanguage.en;
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
}
