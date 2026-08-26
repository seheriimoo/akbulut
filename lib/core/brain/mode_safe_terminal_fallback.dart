import 'conversation_expression_mode.dart';
import 'conversation_grounding_buffer.dart';
import 'conversation_phase.dart';
import 'conversation_utterance.dart';
import 'hold_act_dedup.dart';
import 'narrow_fallback_builder.dart';
import 'night_session.dart';
import 'surface_text_fuzzy.dart';
import 'surface_utterance_kind.dart';
import 'thinking_function_hypothesis.dart';
import 'thinking_function_intelligence_shaping.dart';
import 'user_object_mirror.dart';

/// B1 — Mode-safe terminal fallback after Guard rejects both LLM and
/// [GuardSafeFallback].
///
/// Non-interpretive semantic retreat only. No new insight, diagnosis, or
/// reframe invention. Lines are sealed against [UtteranceGuard] contracts and
/// verified in [mode_safe_terminal_fallback_test.dart].
///
/// Phase 1: prefer evidence-bound object mirrors over repeating shallow
/// empathy terminals (“That sounds hard tonight.”).
class ModeSafeTerminalFallback {
  const ModeSafeTerminalFallback._();

  static const String _enShallowHard = 'That sounds hard tonight.';
  static const String _trShallowHard = 'Bu gece söylediğin zor geliyor gibi.';
  static const String _enStillThere = 'What you named is still here tonight.';
  static const String _trStillThere = 'Az önce söylediğin hâlâ orada.';

  /// Last-resort utterance when [shouldSpeak] is true and upstream paths fail.
  ///
  /// Returns null only for non-speakable WHAT (audio/silence) or when
  /// [shouldSpeak] is false upstream (caller should not invoke).
  static ConversationUtterance? forExpression({
    required ConversationPhase what,
    required ConversationExpressionMode expressionMode,
    String? userUtterance,
    bool narrowRefinementAfterPartial = false,
    bool postRecognitionDeepen = false,
    bool sleepMindMirror = false,
    NightSession? session,
    ConversationGroundingBuffer? grounding,
    String? groundingBlob,
    ThinkingFunctionHypothesis? thinkingFunctionHypothesis,
  }) {
    if (!_isSpeakable(what)) return null;

    final turkish = SurfaceTextFuzzy.prefersTurkish(userUtterance, groundingBlob);

    if (what == ConversationPhase.validation && sleepMindMirror) {
      return ConversationUtterance(
        text: turkish
            ? 'Bu gece zihninin ne yaptığını biraz daha net görüyoruz; '
                'hazır hissetme ihtiyacı düşünmeyi sürdürüyor olabilir.'
            : 'We can see a little more clearly what your mind is doing tonight; '
                'needing to feel prepared may itself keep thinking going.',
      );
    }

    if (what == ConversationPhase.validation &&
        expressionMode == ConversationExpressionMode.observePurity) {
      final shiftAck = HoldActDedup.concernShiftAcknowledge(
        userUtterance: userUtterance,
        groundingBlob: groundingBlob,
        session: session,
        grounding: grounding,
      );
      if (shiftAck != null) return shiftAck;
    }

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

    // TF-present Narrow: prefer mechanism fork over thin still-here retreat.
    if (expressionMode == ConversationExpressionMode.narrow &&
        ThinkingFunctionIntelligenceShaping.isSupportedOrStrong(
          thinkingFunctionHypothesis,
        )) {
      final mechanism = NarrowFallbackBuilder.forValidation(
        userUtterance: userUtterance,
        priorUserUtterance: grounding?.priorUserUtterances.isNotEmpty == true
            ? grounding!.priorUserUtterances.last
            : null,
        refinementAfterPartial: narrowRefinementAfterPartial,
        groundingBlob: groundingBlob,
        thinkingFunctionHypothesis: thinkingFunctionHypothesis,
      );
      if (mechanism != null) return mechanism;
    }

    // Post-Recognition deepen: prefer soft integrate-lite over still-here.
    if (expressionMode == ConversationExpressionMode.standard &&
        postRecognitionDeepen) {
      final deepen = _deepenTerminal(
        turkish: turkish,
        session: session,
      );
      if (deepen != null) return deepen;
    }

    // Phase 1 — evidence-bound before shallow empathy terminals.
    if (_prefersEvidenceBoundTerminal(expressionMode)) {
      final bound = _evidenceBoundValidationTerminal(
        expressionMode: expressionMode,
        userUtterance: userUtterance,
        groundingBlob: groundingBlob,
        session: session,
        grounding: grounding,
        turkish: turkish,
        preferStillHere: !postRecognitionDeepen,
      );
      if (bound != null) return bound;
    }

    final text = turkish
        ? _terminalValidationTr(
            expressionMode: expressionMode,
            narrowRefinementAfterPartial: narrowRefinementAfterPartial,
            userUtterance: userUtterance,
            session: session,
          )
        : _terminalValidationEn(
            expressionMode: expressionMode,
            narrowRefinementAfterPartial: narrowRefinementAfterPartial,
            userUtterance: userUtterance,
            session: session,
          );

    return ConversationUtterance(text: text);
  }

  static bool _prefersEvidenceBoundTerminal(
    ConversationExpressionMode expressionMode,
  ) {
    switch (expressionMode) {
      case ConversationExpressionMode.standard:
      case ConversationExpressionMode.lightChat:
        return true;
      case ConversationExpressionMode.observePurity:
      case ConversationExpressionMode.narrow:
      case ConversationExpressionMode.reframe:
      case ConversationExpressionMode.integrate:
      case ConversationExpressionMode.closure:
      case ConversationExpressionMode.repair:
      case ConversationExpressionMode.groundedHold:
      case ConversationExpressionMode.postReframeListen:
        return false;
    }
  }

  /// Object-preserving retreat; never invents mechanism psychology.
  static ConversationUtterance? _evidenceBoundValidationTerminal({
    required ConversationExpressionMode expressionMode,
    required String? userUtterance,
    required String? groundingBlob,
    required NightSession? session,
    required ConversationGroundingBuffer? grounding,
    required bool turkish,
    bool preferStillHere = true,
  }) {
    if (!SurfaceUtteranceReader.isSubstantiveUserTurn(userUtterance)) {
      return null;
    }

    final mirror = UserObjectMirror.forValidation(
      userUtterance: userUtterance,
      groundingBlob: groundingBlob,
      expressionMode: expressionMode,
      session: session,
      grounding: grounding,
    );
    if (mirror != null &&
        !HoldActDedup.wouldRepeatText(session, mirror.text) &&
        !HoldActDedup.sessionContainsNormalized(session, mirror.text)) {
      // Skip still-here family mirrors when deepen/TF path should stay active.
      if (!preferStillHere &&
          (mirror.text.toLowerCase().contains('still here tonight') ||
              mirror.text.toLowerCase().contains('hâlâ orada') ||
              mirror.text.toLowerCase().contains('hala orada'))) {
        // fall through
      } else {
        return mirror;
      }
    }

    if (!preferStillHere) return null;

    final stillThere = turkish ? _trStillThere : _enStillThere;
    if (!HoldActDedup.sessionContainsNormalized(session, stillThere) &&
        !HoldActDedup.wouldRepeatText(session, stillThere)) {
      // Prefer still-there over repeating shallow-hard when standard/observe.
      if (expressionMode == ConversationExpressionMode.standard ||
          HoldActDedup.sessionContainsNormalized(session, _enShallowHard) ||
          HoldActDedup.sessionContainsNormalized(session, _trShallowHard)) {
        return ConversationUtterance(text: stillThere);
      }
    }

    return null;
  }

  /// Soft deepen / integrate-lite ModeSafe lines (reasoning types, not a bank).
  static ConversationUtterance? _deepenTerminal({
    required bool turkish,
    required NightSession? session,
  }) {
    final candidates = turkish
        ? const [
            'Hazırlıklı hissetmek istemek, bu gece düşünmeyi sürdürüyor olabilir.',
            'Hazırlıklı olmak istemek, bu gece düşünmeyi sürdürüyor olabilir.',
          ]
        : const [
            'Wanting to feel prepared may itself keep thinking going tonight.',
            'Needing to feel prepared may itself keep thinking going tonight.',
          ];
    for (final text in candidates) {
      if (HoldActDedup.sessionContainsNormalized(session, text)) continue;
      if (HoldActDedup.wouldRepeatText(session, text)) continue;
      return ConversationUtterance(text: text);
    }
    return null;
  }

  static String _terminalValidationTr({
    required ConversationExpressionMode expressionMode,
    required bool narrowRefinementAfterPartial,
    String? userUtterance,
    NightSession? session,
  }) {
    switch (expressionMode) {
      case ConversationExpressionMode.observePurity:
        return _antiRepeatShallow(
          session: session,
          primary: _trStillThere,
          alternate: 'Söylediğin bu gece hâlâ duruyor.',
        );
      case ConversationExpressionMode.standard:
      case ConversationExpressionMode.lightChat:
        return _antiRepeatShallow(
          session: session,
          primary: _trShallowHard,
          alternate: _trStillThere,
        );
      case ConversationExpressionMode.postReframeListen:
        // Bare Tamam/Okay only when the user turn itself is a minimal confirm.
        if (SurfaceUtteranceReader.isSubstantiveUserTurn(userUtterance)) {
          return _antiRepeatShallow(
            session: session,
            primary: _trStillThere,
            alternate: 'Söylediğin bu gece hâlâ duruyor.',
          );
        }
        return 'Tamam.';
      case ConversationExpressionMode.narrow:
        if (narrowRefinementAfterPartial) {
          return 'Peki tam oturmayan taraf ne?';
        }
        return 'Hangisi daha ağır geliyor, yoksa henüz net değil mi?';
      case ConversationExpressionMode.reframe:
        return 'Söylediğin hâlâ açık duruyor olabilir.';
      case ConversationExpressionMode.integrate:
        return 'O zaman zihnin bu gece hâlâ orada çalışıyor.';
      case ConversationExpressionMode.closure:
        return 'Bu gece bunu taşımak zorunda değilsin.';
      case ConversationExpressionMode.repair:
        return 'Tamam, orayı yanlış okudum. Seni uyanık tutan ne?';
      case ConversationExpressionMode.groundedHold:
        return _antiRepeatShallow(
          session: session,
          primary:
              'Bu düşünceyi bu gece bitirmek zorunda değilsin. Buradayım.',
          alternate:
              'Daha ileri itmeden, burada olanla kalabiliriz.',
        );
    }
  }

  static String _terminalValidationEn({
    required ConversationExpressionMode expressionMode,
    required bool narrowRefinementAfterPartial,
    String? userUtterance,
    NightSession? session,
  }) {
    switch (expressionMode) {
      case ConversationExpressionMode.observePurity:
        return _antiRepeatShallow(
          session: session,
          primary: _enStillThere,
          alternate: 'What you named is still here tonight.',
        );
      case ConversationExpressionMode.standard:
      case ConversationExpressionMode.lightChat:
        return _antiRepeatShallow(
          session: session,
          primary: _enShallowHard,
          alternate: _enStillThere,
        );
      case ConversationExpressionMode.postReframeListen:
        if (SurfaceUtteranceReader.isSubstantiveUserTurn(userUtterance)) {
          return _antiRepeatShallow(
            session: session,
            primary: _enStillThere,
            alternate: 'What you named is still here tonight.',
          );
        }
        return 'Okay.';
      case ConversationExpressionMode.narrow:
        if (narrowRefinementAfterPartial) {
          return 'What part still does not fit?';
        }
        return 'Which part feels heavier, or is it still unclear?';
      case ConversationExpressionMode.reframe:
        return 'What you said might still be open tonight.';
      case ConversationExpressionMode.integrate:
        return 'Then your mind is still trying to settle this tonight.';
      case ConversationExpressionMode.closure:
        return "You don't have to carry this tonight.";
      case ConversationExpressionMode.repair:
        return 'Okay, I read that wrong. What is keeping you up tonight?';
      case ConversationExpressionMode.groundedHold:
        return _antiRepeatShallow(
          session: session,
          primary:
              "You don't have to finish this thought tonight. I'm with you here.",
          alternate: 'We can stay with what is present without pushing further.',
        );
    }
  }

  /// Never re-admit the same shallow terminal across the night.
  static String _antiRepeatShallow({
    required NightSession? session,
    required String primary,
    required String alternate,
  }) {
    if (HoldActDedup.sessionContainsNormalized(session, primary) ||
        HoldActDedup.wouldRepeatText(session, primary)) {
      if (!HoldActDedup.sessionContainsNormalized(session, alternate) &&
          !HoldActDedup.wouldRepeatText(session, alternate)) {
        return alternate;
      }
    }
    return primary;
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
}
