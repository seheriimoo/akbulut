import 'arc_evidence_context.dart';
import 'conversation_expression_mode.dart';
import 'conversation_grounding_buffer.dart';
import 'conversation_phase.dart';
import 'conversation_utterance.dart';
import 'closure_fallback_builder.dart';
import 'conversational_landing.dart';
import 'discovery/discovery_act.dart';
import 'grounded_progression.dart';
import 'hold_act_dedup.dart';
import 'integrate_fallback_builder.dart';
import 'narrow_fallback_builder.dart';
import 'night_session.dart';
import 'observe_fallback_builder.dart';
import 'deterministic_reframe_builder.dart';
import 'light_conversation_detector.dart';
import 'listen_only_preference.dart';
import 'mode_safe_terminal_fallback.dart';
import 'reframe_evidence_reader.dart';
import 'surface_text_fuzzy.dart';
import 'surface_utterance_kind.dart';
import 'thinking_function_hypothesis.dart';
import 'user_object_mirror.dart';

/// Deterministic Guard-legal lines after [UtteranceGuard] rejects a model
/// candidate.
///
/// Expression-plane only. Does not reopen WHAT / Exit / Release.
/// Does not rewrite the rejected text. Does not call an LLM.
///
/// Never emits exact `Anlıyorum.` on validation/observe — mode-safe terminal only.
class GuardSafeFallback {
  const GuardSafeFallback._();

  static ConversationUtterance? forPhase({
    required ConversationPhase what,
    String? userUtterance,
    ConversationExpressionMode expressionMode =
        ConversationExpressionMode.standard,
    bool narrowRefinementAfterPartial = false,
    bool postRecognitionDeepen = false,
    bool sleepMindMirror = false,
    String? sleepMindMirrorText,
    DiscoveryAct discoveryAct = DiscoveryAct.deferToArc,
    NightSession? session,
    ConversationGroundingBuffer? grounding,
    String sessionVentCorpus = '',
    bool listenOnlyActive = false,
    ThinkingFunctionHypothesis? thinkingFunctionHypothesis,
  }) {
    if (!_isSpeakable(what)) return null;

    var effectiveMode = expressionMode;
    final arc = ArcEvidenceContext.fromNight(session: session, grounding: grounding);
    final groundingBlob = arc.userEvidenceBlob;
    final prefersTurkish = arc.prefersTurkish ||
        SurfaceTextFuzzy.prefersTurkish(userUtterance, groundingBlob);

    if (listenOnlyActive &&
        what == ConversationPhase.validation &&
        (effectiveMode == ConversationExpressionMode.narrow ||
            effectiveMode == ConversationExpressionMode.reframe ||
            effectiveMode == ConversationExpressionMode.integrate)) {
      effectiveMode = ConversationExpressionMode.groundedHold;
    }

    // Sleep Mind Mirror: never collapse to still-here / Phase-1 mirror.
    if (sleepMindMirror && what == ConversationPhase.validation) {
      final text = sleepMindMirrorText?.trim();
      if (text != null && text.isNotEmpty) {
        return ConversationUtterance(text: text);
      }
      final mirror = ModeSafeTerminalFallback.forExpression(
        what: what,
        expressionMode: ConversationExpressionMode.integrate,
        userUtterance: userUtterance,
        sleepMindMirror: true,
        session: session,
        grounding: grounding,
        groundingBlob: groundingBlob,
        thinkingFunctionHypothesis: thinkingFunctionHypothesis,
      );
      if (mirror != null) return mirror;
    }

    // Preserve post-Recognition deepen: ModeSafe deepen terminals only —
    // never Phase-1 still-here UserObjectMirror family.
    if (postRecognitionDeepen &&
        what == ConversationPhase.validation &&
        effectiveMode == ConversationExpressionMode.standard) {
      final deepen = ModeSafeTerminalFallback.forExpression(
        what: what,
        expressionMode: effectiveMode,
        userUtterance: userUtterance,
        narrowRefinementAfterPartial: narrowRefinementAfterPartial,
        postRecognitionDeepen: true,
        session: session,
        grounding: grounding,
        groundingBlob: groundingBlob,
        thinkingFunctionHypothesis: thinkingFunctionHypothesis,
      );
      if (deepen != null) return deepen;
    }

    if (what == ConversationPhase.validation &&
        effectiveMode == ConversationExpressionMode.observePurity) {
      final shiftAck = HoldActDedup.concernShiftAcknowledge(
        userUtterance: userUtterance,
        groundingBlob: groundingBlob,
        session: session,
        grounding: grounding,
      );
      if (shiftAck != null) return shiftAck;
    }

    if (what == ConversationPhase.validation &&
        effectiveMode == ConversationExpressionMode.groundedHold) {
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
        effectiveMode == ConversationExpressionMode.narrow) {
      final fork = NarrowFallbackBuilder.forValidation(
        userUtterance: userUtterance,
        priorUserUtterance: _priorUserLine(grounding),
        refinementAfterPartial: narrowRefinementAfterPartial,
        groundingBlob: groundingBlob,
        thinkingFunctionHypothesis: thinkingFunctionHypothesis,
      );
      if (fork != null) return fork;
    }

    if (what == ConversationPhase.validation &&
        effectiveMode == ConversationExpressionMode.postReframeListen) {
      // Bare Okay/Tamam only for minimal post-reframe confirms.
      if (!SurfaceUtteranceReader.isSubstantiveUserTurn(userUtterance)) {
        return ConversationUtterance(text: prefersTurkish ? 'Tamam.' : 'Okay.');
      }
      // Substantive turn: continue as observe — never terminal bare ack.
      effectiveMode = ConversationExpressionMode.observePurity;
    }

    if (what == ConversationPhase.validation &&
        effectiveMode == ConversationExpressionMode.reframe) {
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
        effectiveMode == ConversationExpressionMode.integrate) {
      final integrate = IntegrateFallbackBuilder.forValidation(
        userUtterance: userUtterance ?? groundingBlob,
        session: session,
      );
      if (integrate != null) return integrate;
    }

    if (what == ConversationPhase.validation &&
        effectiveMode == ConversationExpressionMode.closure) {
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
        expressionMode: effectiveMode,
        session: session,
      );
      if (landing != null) return landing;
    }

    // B2 — structural user-object mirror before generic empathy filler.
    // Skip when deepen/mirror/discovery-hold: still-here family must not sink.
    final concernShiftFresh = userUtterance != null &&
        ConcernShiftDetector.isShift(
          currentMessage: userUtterance,
          grounding: grounding,
          session: session,
        );
    final avoidStillHereSink = postRecognitionDeepen ||
        sleepMindMirror ||
        discoveryAct == DiscoveryAct.hold ||
        discoveryAct == DiscoveryAct.meet;
    if (what == ConversationPhase.validation &&
        !postRecognitionDeepen &&
        !sleepMindMirror &&
        (!ProgressionStateReader.isMirrorSaturated(session) ||
            concernShiftFresh)) {
      final objectMirror = UserObjectMirror.forValidation(
        userUtterance: userUtterance,
        groundingBlob: groundingBlob,
        expressionMode: effectiveMode,
        session: session,
        grounding: grounding,
      );
      if (objectMirror != null) {
        final t = objectMirror.text.toLowerCase();
        final isStillHereFamily = t.contains('still here tonight') ||
            t.contains('hâlâ orada') ||
            t.contains('hala orada') ||
            t.contains('az önce söylediğin') ||
            t.contains('az once soyledigin');
        if (!(avoidStillHereSink && isStillHereFamily)) {
          return objectMirror;
        }
      }
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
        expressionMode: effectiveMode,
        session: session,
        grounding: grounding,
      );
      if (priorMirror != null) return priorMirror;
    }

    if (what == ConversationPhase.validation &&
        effectiveMode == ConversationExpressionMode.groundedHold) {
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
        effectiveMode == ConversationExpressionMode.observePurity) {
      final observe = ObserveFallbackBuilder.forValidation(
        userUtterance: userUtterance,
        groundingBlob: groundingBlob,
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
          groundingBlob: groundingBlob,
        );
        if (fromCtx != null) return fromCtx;
      }
    }

    if (what == ConversationPhase.neutralEntry &&
        effectiveMode == ConversationExpressionMode.lightChat) {
      const light = LightConversationDetector();
      if (userUtterance != null && light.hasRealLoadMarkers(userUtterance)) {
        final hold = _holdFallback(
          userUtterance: userUtterance,
          groundingBlob: groundingBlob,
          prefersTurkish: prefersTurkish,
          session: session,
          grounding: grounding,
        );
        if (hold != null) return hold;
        final mirror = UserObjectMirror.forValidation(
          userUtterance: userUtterance,
          groundingBlob: groundingBlob,
          expressionMode: ConversationExpressionMode.observePurity,
          session: session,
          grounding: grounding,
        );
        if (mirror != null) return mirror;
      }
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
        effectiveMode == ConversationExpressionMode.lightChat) {
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
      final mirror = UserObjectMirror.forValidation(
        userUtterance: userUtterance,
        groundingBlob: groundingBlob,
        expressionMode: ConversationExpressionMode.observePurity,
        session: session,
        grounding: grounding,
      );
      if (mirror != null) return mirror;
      final hold = _holdFallback(
        userUtterance: userUtterance,
        groundingBlob: groundingBlob,
        prefersTurkish: prefersTurkish,
        session: session,
        grounding: grounding,
      );
      if (hold != null) return hold;
    }

    return ModeSafeTerminalFallback.forExpression(
      what: what,
      expressionMode: effectiveMode,
      userUtterance: userUtterance,
      narrowRefinementAfterPartial: narrowRefinementAfterPartial,
      postRecognitionDeepen: postRecognitionDeepen,
      sleepMindMirror: sleepMindMirror,
      session: session,
      grounding: grounding,
      groundingBlob: groundingBlob,
      thinkingFunctionHypothesis: thinkingFunctionHypothesis,
    );
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
}
