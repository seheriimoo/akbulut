import 'conversation_expression_mode.dart';
import 'conversation_phase.dart';
import 'conversation_utterance.dart';

/// B1 — Mode-safe terminal fallback after Guard rejects both LLM and
/// [GuardSafeFallback].
///
/// Non-interpretive semantic retreat only. No new insight, diagnosis, or
/// reframe invention. Lines are sealed against [UtteranceGuard] contracts and
/// verified in [mode_safe_terminal_fallback_test.dart].
class ModeSafeTerminalFallback {
  const ModeSafeTerminalFallback._();

  /// Last-resort utterance when [shouldSpeak] is true and upstream paths fail.
  ///
  /// Returns null only for non-speakable WHAT (audio/silence) or when
  /// [shouldSpeak] is false upstream (caller should not invoke).
  static ConversationUtterance? forExpression({
    required ConversationPhase what,
    required ConversationExpressionMode expressionMode,
    String? userUtterance,
    bool narrowRefinementAfterPartial = false,
  }) {
    if (!_isSpeakable(what)) return null;

    final turkish = _prefersTurkish(userUtterance);

    if (what == ConversationPhase.neutralEntry &&
        expressionMode == ConversationExpressionMode.lightChat) {
      return ConversationUtterance(
        text: turkish ? 'Anladım.' : 'Got it.',
      );
    }

    if (what != ConversationPhase.validation) {
      return ConversationUtterance(
        text: turkish
            ? _terminalForNonValidation(what)
            : _terminalForNonValidationEn(what),
      );
    }

    final text = turkish
        ? _terminalValidationTr(
            expressionMode: expressionMode,
            narrowRefinementAfterPartial: narrowRefinementAfterPartial,
          )
        : _terminalValidationEn(
            expressionMode: expressionMode,
            narrowRefinementAfterPartial: narrowRefinementAfterPartial,
          );

    return ConversationUtterance(text: text);
  }

  static String _terminalValidationTr({
    required ConversationExpressionMode expressionMode,
    required bool narrowRefinementAfterPartial,
  }) {
    switch (expressionMode) {
      case ConversationExpressionMode.observePurity:
        return 'Az önce söylediğin hâlâ orada.';
      case ConversationExpressionMode.standard:
      case ConversationExpressionMode.lightChat:
        return 'Bu gece söylediğin zor geliyor gibi.';
      case ConversationExpressionMode.postReframeListen:
        return 'Tamam.';
      case ConversationExpressionMode.narrow:
        if (narrowRefinementAfterPartial) {
          return 'Peki tam oturmayan taraf ne?';
        }
        return 'Hangisi daha ağır geliyor, yoksa henüz net değil mi?';
      case ConversationExpressionMode.reframe:
        return 'Bu gece söylediğin şey hâlâ orada duruyor gibi görünüyor olabilir.';
      case ConversationExpressionMode.integrate:
        return 'O zaman zihnin bu gece hâlâ orada çalışıyor.';
      case ConversationExpressionMode.closure:
        return 'Bu gece bunu taşımak zorunda değilsin.';
      case ConversationExpressionMode.repair:
        return 'Tamam, orayı yanlış okudum. Seni uyanık tutan ne?';
    }
  }

  static String _terminalValidationEn({
    required ConversationExpressionMode expressionMode,
    required bool narrowRefinementAfterPartial,
  }) {
    switch (expressionMode) {
      case ConversationExpressionMode.observePurity:
        return 'What you said is still there tonight.';
      case ConversationExpressionMode.standard:
      case ConversationExpressionMode.lightChat:
        return 'That sounds hard tonight.';
      case ConversationExpressionMode.postReframeListen:
        return 'Okay.';
      case ConversationExpressionMode.narrow:
        if (narrowRefinementAfterPartial) {
          return 'What part still does not fit?';
        }
        return 'Which part feels heavier, or is it still unclear?';
      case ConversationExpressionMode.reframe:
        return 'What you shared might still be open tonight.';
      case ConversationExpressionMode.integrate:
        return 'Then your mind is still trying to settle this tonight.';
      case ConversationExpressionMode.closure:
        return "You don't have to carry this tonight.";
      case ConversationExpressionMode.repair:
        return 'Okay, I read that wrong. What is keeping you up tonight?';
    }
  }

  static String _terminalForNonValidation(ConversationPhase what) {
    switch (what) {
      case ConversationPhase.naming:
        return 'Bir şey hâlâ aklında duruyor.';
      case ConversationPhase.permission:
        return 'Bu gece bunu çözmek zorunda değilsin.';
      case ConversationPhase.release:
        return 'Şimdilik burada bırakabilirsin.';
      case ConversationPhase.continuity:
        return 'Bu kadar yeter.';
      case ConversationPhase.neutralEntry:
        return 'Merhaba, hazır olduğunda.';
      case ConversationPhase.validation:
      case ConversationPhase.audio:
      case ConversationPhase.silence:
        return 'Az önce söylediğin hâlâ orada.';
    }
  }

  static String _terminalForNonValidationEn(ConversationPhase what) {
    switch (what) {
      case ConversationPhase.naming:
        return 'Something is still holding on.';
      case ConversationPhase.permission:
        return 'You do not have to solve this tonight.';
      case ConversationPhase.release:
        return 'You can let this rest for now.';
      case ConversationPhase.continuity:
        return 'Nothing more is needed right now.';
      case ConversationPhase.neutralEntry:
        return "Hi whenever you're ready.";
      case ConversationPhase.validation:
      case ConversationPhase.audio:
      case ConversationPhase.silence:
        return 'What you said is still there tonight.';
    }
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

  static bool _prefersTurkish(String? userUtterance) {
    if (userUtterance == null || userUtterance.trim().isEmpty) {
      return false;
    }
    final lower = userUtterance.toLowerCase();
    if (RegExp(r'[ğüşıöçâîû]').hasMatch(lower)) return true;
    const markers = [
      'bilmiyorum',
      'uyuyamiyorum',
      'uyuyamıyorum',
      'kafam',
      'gece',
      'yarin',
      'yarın',
      'evet',
      'tamam',
      'degil',
      'değil',
      'yalniz',
      'yalnız',
      'miyim',
      'mıyım',
    ];
    for (final marker in markers) {
      if (lower.contains(marker)) return true;
    }
    return false;
  }
}
