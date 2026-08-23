import 'arc_evidence_context.dart';
import 'conversation_expression_mode.dart';
import 'conversation_grounding_buffer.dart';
import 'conversation_phase.dart';
import 'conversation_utterance.dart';
import 'closure_fallback_builder.dart';
import 'integrate_fallback_builder.dart';
import 'narrow_fallback_builder.dart';
import 'night_session.dart';
import 'observe_fallback_builder.dart';
import 'reframe_fallback_builder.dart';

/// Deterministic Guard-legal lines after [UtteranceGuard] rejects a model
/// candidate.
///
/// Expression-plane only. Does not reopen WHAT / Exit / Release.
/// Does not rewrite the rejected text. Does not call an LLM.
///
/// `Anlıyorum.` is ultimate last-resort only for validation standard mode.
class GuardSafeFallback {
  const GuardSafeFallback._();

  static ConversationUtterance? forPhase({
    required ConversationPhase what,
    String? userUtterance,
    ConversationExpressionMode expressionMode =
        ConversationExpressionMode.standard,
    bool narrowRefinementAfterPartial = false,
    NightSession? session,
    ConversationGroundingBuffer? grounding,
  }) {
    if (!_isSpeakable(what)) return null;

    final arc = ArcEvidenceContext.fromNight(session: session, grounding: grounding);
    final prefersTurkish = arc.prefersTurkish || _looksTurkish(userUtterance);
    final groundingBlob = arc.userEvidenceBlob;

    if (what == ConversationPhase.validation &&
        expressionMode == ConversationExpressionMode.observePurity) {
      final mirror = ObserveFallbackBuilder.forValidation(
        userUtterance: userUtterance,
      );
      if (mirror != null) return mirror;
      if (prefersTurkish && groundingBlob != null && groundingBlob.isNotEmpty) {
        final fromCtx = ObserveFallbackBuilder.forValidation(
          userUtterance: groundingBlob,
        );
        if (fromCtx != null) return fromCtx;
      }
    }

    if (what == ConversationPhase.validation &&
        expressionMode == ConversationExpressionMode.narrow) {
      final fork = NarrowFallbackBuilder.forValidation(
        userUtterance: userUtterance,
        priorUserUtterance: _priorUserLine(grounding),
        refinementAfterPartial: narrowRefinementAfterPartial,
        groundingBlob: groundingBlob,
      );
      if (fork != null) return fork;
    }

    if (what == ConversationPhase.validation &&
        expressionMode == ConversationExpressionMode.postReframeListen) {
      return ConversationUtterance(text: prefersTurkish ? 'Tamam.' : 'Okay.');
    }

    if (what == ConversationPhase.validation &&
        expressionMode == ConversationExpressionMode.reframe) {
      final reframe = ReframeFallbackBuilder.forValidation(
        userUtterance: userUtterance ?? groundingBlob,
      );
      if (reframe != null) return reframe;
    }

    if (what == ConversationPhase.validation &&
        expressionMode == ConversationExpressionMode.integrate) {
      final integrate = IntegrateFallbackBuilder.forValidation(
        userUtterance: userUtterance ?? groundingBlob,
        session: session,
      );
      if (integrate != null) return integrate;
    }

    if (what == ConversationPhase.validation &&
        expressionMode == ConversationExpressionMode.closure) {
      return ClosureFallbackBuilder.forValidation(
        userUtterance: userUtterance,
        session: session,
        grounding: grounding,
        arcEvidence: arc,
      );
    }

    if (prefersTurkish) {
      final tr = _turkishFor(what, expressionMode: expressionMode);
      if (tr.isNotEmpty) return ConversationUtterance(text: tr);
    }

    final en = _englishFor(what, expressionMode: expressionMode);
    return ConversationUtterance(text: en);
  }

  static String? _priorUserLine(ConversationGroundingBuffer? grounding) {
    if (grounding == null || grounding.priorUserUtterances.isEmpty) {
      return null;
    }
    return grounding.priorUserUtterances.last;
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

  static bool _looksTurkish(String? text) {
    if (text == null || text.trim().isEmpty) return false;
    final lower = text.toLowerCase();
    if (RegExp(r'[ğüşıöçâîû]').hasMatch(lower)) return true;
    const markers = [
      'bilmiyorum',
      'uyuyamiyorum',
      'uyuyamıyorum',
      'kafam',
      'aklim',
      'aklım',
      'durmuyor',
      'gece',
      'yarin',
      'yarın',
      'degil',
      'değil',
      'belki',
      'evet',
      'sakin',
      'rahat',
      'dogru',
      'doğru',
      'yalniz',
      'yalnız',
      'ozle',
      'miyim',
      'mıyım',
    ];
    for (final marker in markers) {
      if (lower.contains(marker)) return true;
    }
    return false;
  }
}
