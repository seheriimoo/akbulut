import 'conversation_expression_mode.dart';
import 'conversation_phase.dart';
import 'conversation_utterance.dart';

/// Deterministic Guard-legal lines after [UtteranceGuard] rejects a model
/// candidate.
///
/// Expression-plane only. Does not reopen WHAT / Exit / Release.
/// Does not rewrite the rejected text. Does not call an LLM.
///
/// Lines are closed stems known to pass phase contracts for EN/TR.
class GuardSafeFallback {
  const GuardSafeFallback._();

  /// Returns a short, non-clinical fallback for [what], or `null` when [what]
  /// is non-speakable (audio / silence) — those turns stay silent by design.
  static ConversationUtterance? forPhase({
    required ConversationPhase what,
    String? userUtterance,
    ConversationExpressionMode expressionMode =
        ConversationExpressionMode.standard,
  }) {
    if (!_isSpeakable(what)) return null;

    final turkish = _looksTurkish(userUtterance);
    final text = turkish
        ? _turkishFor(what, expressionMode: expressionMode)
        : _englishFor(what, expressionMode: expressionMode);
    return ConversationUtterance(text: text);
  }

  static bool _isSpeakable(ConversationPhase what) {
    switch (what) {
      case ConversationPhase.validation:
      case ConversationPhase.naming:
      case ConversationPhase.permission:
      case ConversationPhase.release:
      case ConversationPhase.continuity:
      case ConversationPhase.neutralEntry:
        return true;
      case ConversationPhase.audio:
      case ConversationPhase.silence:
        return false;
    }
  }

  static String _englishFor(
    ConversationPhase what, {
    ConversationExpressionMode expressionMode =
        ConversationExpressionMode.standard,
  }) {
    switch (what) {
      case ConversationPhase.validation:
        if (expressionMode == ConversationExpressionMode.repair) {
          return 'Okay, I read that wrong. What is keeping you up tonight?';
        }
        return 'I hear that.';
      case ConversationPhase.naming:
        return 'Something is still holding on.';
      case ConversationPhase.permission:
        return 'You do not have to solve this tonight.';
      case ConversationPhase.release:
        return 'You can let this rest for now.';
      case ConversationPhase.continuity:
        return 'Nothing more is needed right now.';
      case ConversationPhase.neutralEntry:
        if (expressionMode == ConversationExpressionMode.lightChat) {
          return 'Oh, nice.';
        }
        return "Hi whenever you're ready.";
      case ConversationPhase.audio:
      case ConversationPhase.silence:
        return '';
    }
  }

  static String _turkishFor(
    ConversationPhase what, {
    ConversationExpressionMode expressionMode =
        ConversationExpressionMode.standard,
  }) {
    switch (what) {
      case ConversationPhase.validation:
        if (expressionMode == ConversationExpressionMode.repair) {
          return 'Tamam, orayı yanlış okudum. Seni uyanık tutan ne?';
        }
        return 'Anlıyorum.';
      case ConversationPhase.naming:
        return 'Bir şey hâlâ aklında duruyor.';
      case ConversationPhase.permission:
        return 'Bu gece bunu çözmek zorunda değilsin.';
      case ConversationPhase.release:
        return 'Şimdilik burada bırakabilirsin.';
      case ConversationPhase.continuity:
        return 'Bu kadar yeter.';
      case ConversationPhase.neutralEntry:
        if (expressionMode == ConversationExpressionMode.lightChat) {
          return 'Güzel :)';
        }
        return 'Merhaba, hazır olduğunda.';
      case ConversationPhase.audio:
      case ConversationPhase.silence:
        return '';
    }
  }

  /// Lightweight EN/TR hint from the current user line only.
  static bool _looksTurkish(String? text) {
    if (text == null || text.trim().isEmpty) return false;
    final lower = text.toLowerCase();
    if (RegExp(r'[ğüşıöçâîû]').hasMatch(lower)) return true;
    // ASCII Turkish night slang / common particles (no diacritics).
    const markers = [
      'bilmiyorum',
      'uyuyamiyorum',
      'uyuyamıyorum',
      'kafam',
      'kafa',
      'aklim',
      'aklım',
      'durmuyor',
      'donup',
      'dönüp',
      'gece',
      'yarin',
      'yarın',
      'degil',
      'değil',
      'icin',
      'için',
      'cok',
      'çok',
      'sadece',
      'belki',
      'bence',
      'hayir',
      'hayır',
      'evet',
      'ama ',
      ' yani',
      'ya.',
      ' ya ',
      'miyim',
      'mıyım',
      'misin',
      'mısın',
    ];
    for (final marker in markers) {
      if (lower.contains(marker)) return true;
    }
    return false;
  }
}
