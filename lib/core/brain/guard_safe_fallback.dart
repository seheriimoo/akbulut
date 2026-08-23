import 'arc_evidence_context.dart';
import 'conversation_expression_mode.dart';
import 'conversation_grounding_buffer.dart';
import 'conversation_phase.dart';
import 'conversation_utterance.dart';
import 'closure_fallback_builder.dart';
import 'conversational_landing.dart';
import 'grounded_progression.dart';
import 'hold_act_dedup.dart';
import 'integrate_fallback_builder.dart';
import 'narrow_fallback_builder.dart';
import 'night_session.dart';
import 'observe_fallback_builder.dart';
import 'deterministic_reframe_builder.dart';
import 'reframe_evidence_reader.dart';
import 'surface_text_fuzzy.dart';
import 'surface_utterance_kind.dart';
import 'user_object_mirror.dart';

/// Deterministic Guard-legal lines after [UtteranceGuard] rejects a model
/// candidate.
///
/// Expression-plane only. Does not reopen WHAT / Exit / Release.
/// Does not rewrite the rejected text. Does not call an LLM.
///
/// `Anlıyorum.` is ultimate last-resort only when [UserObjectMirror] cannot
/// extract a substantive user clause.
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
    String sessionVentCorpus = '',
  }) {
    if (!_isSpeakable(what)) return null;

    final arc = ArcEvidenceContext.fromNight(session: session, grounding: grounding);
    final groundingBlob = arc.userEvidenceBlob;
    final prefersTurkish = arc.prefersTurkish ||
        SurfaceTextFuzzy.prefersTurkish(userUtterance, groundingBlob);

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

    if (what == ConversationPhase.validation &&
        expressionMode == ConversationExpressionMode.groundedHold) {
      final hold = _holdFallback(
        userUtterance: userUtterance,
        groundingBlob: groundingBlob,
        prefersTurkish: prefersTurkish,
        session: session,
        grounding: grounding,
      );
      if (hold != null) return hold;
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
      final ledger = ReframeEvidenceReader.fromGrounding(grounding);
      final deterministic = DeterministicReframeBuilder.forValidation(
        ledger: ledger,
        prefersTurkish: prefersTurkish,
      );
      if (deterministic != null) return deterministic;
      final narrow = NarrowFallbackBuilder.forValidation(
        userUtterance: userUtterance,
        priorUserUtterance: _priorUserLine(grounding),
        groundingBlob: groundingBlob,
      );
      if (narrow != null) return narrow;
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

    // B2.2 — conversational landing before mirror for closing/minimal ack.
    if (what == ConversationPhase.validation) {
      final landing = ConversationalLanding.forValidation(
        userUtterance: userUtterance,
        groundingBlob: groundingBlob,
        expressionMode: expressionMode,
        session: session,
      );
      if (landing != null) return landing;
    }

    // B2 — structural user-object mirror before generic empathy filler.
    final concernShiftFresh = userUtterance != null &&
        ConcernShiftDetector.isShift(
          currentMessage: userUtterance,
          grounding: grounding,
          session: session,
        );
    if (what == ConversationPhase.validation &&
        (!ProgressionStateReader.isMirrorSaturated(session) ||
            concernShiftFresh)) {
      final objectMirror = UserObjectMirror.forValidation(
        userUtterance: userUtterance,
        groundingBlob: groundingBlob,
        expressionMode: expressionMode,
        session: session,
        grounding: grounding,
      );
      if (objectMirror != null) return objectMirror;
    }

    if (what == ConversationPhase.validation &&
        _isDismissMinimization(userUtterance) &&
        groundingBlob != null &&
        groundingBlob.trim().length >= 8) {
      final hold = _holdFallback(
        userUtterance: userUtterance,
        groundingBlob: groundingBlob,
        prefersTurkish: prefersTurkish,
        session: session,
        grounding: grounding,
      );
      if (hold != null) return hold;
      final priorMirror = UserObjectMirror.forValidation(
        userUtterance: groundingBlob,
        groundingBlob: groundingBlob,
        expressionMode: expressionMode,
        session: session,
        grounding: grounding,
      );
      if (priorMirror != null) return priorMirror;
    }

    if (what == ConversationPhase.validation &&
        expressionMode == ConversationExpressionMode.groundedHold) {
      final hold = _holdFallback(
        userUtterance: userUtterance,
        groundingBlob: groundingBlob,
        prefersTurkish: prefersTurkish,
        session: session,
        grounding: grounding,
      );
      if (hold != null) return hold;
    }

    if (what == ConversationPhase.validation &&
        ProgressionStateReader.isMirrorSaturated(session) &&
        NarrowExhaustionGate.isExhausted(
          session,
          grounding: grounding,
          currentMessage: userUtterance,
        )) {
      final hold = _holdFallback(
        userUtterance: userUtterance,
        groundingBlob: groundingBlob,
        prefersTurkish: prefersTurkish,
        session: session,
        grounding: grounding,
      );
      if (hold != null) return hold;
    }

    if (what == ConversationPhase.validation &&
        ProgressionStateReader.isMirrorSaturated(session)) {
      final hold = _holdFallback(
        userUtterance: userUtterance,
        groundingBlob: groundingBlob,
        prefersTurkish: prefersTurkish,
        session: session,
        grounding: grounding,
      );
      if (hold != null) return hold;
    }

    if (what == ConversationPhase.validation &&
        NarrowExhaustionGate.isExhausted(
          session,
          grounding: grounding,
          currentMessage: userUtterance,
        )) {
      final hold = _holdFallback(
        userUtterance: userUtterance,
        groundingBlob: groundingBlob,
        prefersTurkish: prefersTurkish,
        session: session,
        grounding: grounding,
      );
      if (hold != null) return hold;
    }

    // Legacy keyword observe mirrors — only after B2 surface mirror abstains.
    if (what == ConversationPhase.validation &&
        expressionMode == ConversationExpressionMode.observePurity) {
      final observe = ObserveFallbackBuilder.forValidation(
        userUtterance: userUtterance,
      );
      if (observe != null) return observe;
      final minimalCurrent = userUtterance != null &&
          SurfaceUtteranceReader.isMinimalAck(userUtterance);
      if (minimalCurrent &&
          prefersTurkish &&
          groundingBlob != null &&
          groundingBlob.isNotEmpty) {
        final fromCtx = ObserveFallbackBuilder.forValidation(
          userUtterance: groundingBlob,
        );
        if (fromCtx != null) return fromCtx;
      }
    }

    if (what == ConversationPhase.neutralEntry &&
        expressionMode == ConversationExpressionMode.lightChat) {
      if (SessionVentMemory.blocksPlayfulLight(
        session: session,
        grounding: grounding,
        currentMessage: userUtterance,
        sessionVentCorpus: sessionVentCorpus,
      )) {
        final hold = _holdFallback(
          userUtterance: userUtterance,
          groundingBlob: groundingBlob,
          prefersTurkish: prefersTurkish,
          session: session,
          grounding: grounding,
        );
        if (hold != null) return hold;
      }
    }

    if (what == ConversationPhase.neutralEntry &&
        expressionMode == ConversationExpressionMode.lightChat) {
      final vent = VentStackDetector.ventAcknowledgement(
        userUtterance: userUtterance,
        groundingBlob: groundingBlob,
      );
      if (vent != null &&
          GroundedHoldContract.admits(
            noctaText: vent,
            userUtterance: userUtterance,
            groundingBlob: groundingBlob,
          )) {
        return ConversationUtterance(text: vent);
      }
    }

    if (prefersTurkish) {
      final tr = _turkishFor(
        what,
        expressionMode: expressionMode,
        userUtterance: userUtterance,
        groundingBlob: groundingBlob,
      );
      if (tr.isNotEmpty) return ConversationUtterance(text: tr);
    }

    final en = _englishFor(what, expressionMode: expressionMode);
    return ConversationUtterance(text: en);
  }

  static ConversationUtterance? _holdFallback({
    required String? userUtterance,
    required String? groundingBlob,
    required bool prefersTurkish,
    NightSession? session,
    ConversationGroundingBuffer? grounding,
  }) {
    if (session != null && HoldActDedup.sessionUsedGroundedHold(session)) {
      return HoldActDedup.alternateGroundedHold(
        userUtterance: userUtterance,
        groundingBlob: groundingBlob,
        session: session,
        grounding: grounding,
        prefersTurkish: prefersTurkish,
      );
    }
    final hold = HonestSynthesisBuilder.forValidation(
      userUtterance: userUtterance,
      groundingBlob: groundingBlob,
      prefersTurkish: prefersTurkish,
    );
    if (hold != null &&
        session != null &&
        HoldActDedup.wouldRepeatText(session, hold.text)) {
      return HoldActDedup.alternateGroundedHold(
        userUtterance: userUtterance,
        groundingBlob: groundingBlob,
        session: session,
        grounding: grounding,
        prefersTurkish: prefersTurkish,
      );
    }
    return hold;
  }

  static String? _priorUserLine(ConversationGroundingBuffer? grounding) {
    if (grounding == null || grounding.priorUserUtterances.isEmpty) {
      return null;
    }
    return grounding.priorUserUtterances.last;
  }

  static bool _isDismissMinimization(String? text) {
    if (text == null || text.trim().isEmpty) return false;
    final n = text
        .toLowerCase()
        .replaceAll('ö', 'o')
        .replaceAll('ü', 'u')
        .replaceAll('ı', 'i')
        .replaceAll('ğ', 'g')
        .replaceAll('ş', 's')
        .replaceAll('ç', 'c');
    return RegExp(
      r'\b(onemli degil|sorun degil|hallederim|halledecegim|abartiyorum|abartıyorum)\b',
    ).hasMatch(n);
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
    String? userUtterance,
    String? groundingBlob,
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
}
