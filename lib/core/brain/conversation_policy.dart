import 'closure_readiness_gate.dart';
import 'conversation_arc_reader.dart';
import 'conversation_decision.dart';
import 'conversation_expression_mode.dart';
import 'conversation_grounding_buffer.dart';
import 'conversation_phase.dart';
import 'explicit_exit_intent.dart';
import 'light_conversation_detector.dart';
import 'neutral_entry_detector.dart';
import 'night_session.dart';
import 'post_audio_re_engagement.dart';
import 'reframe_admission_gate.dart';
import 'reframe_readiness_gate.dart';
import 'release_decision.dart';
import 'release_progression_gate.dart';
import 'turn_response_stance.dart';
import 'validated_understanding.dart';

/// ConversationPolicy
///
/// Purpose:
/// Maps ReleaseDecision into the appropriate
/// ConversationDecision according to the
/// HCOS Conversation Protocol.
///
/// Neutral Entry V1: on first-turn hold with a content-free greeting and no
/// mental/emotional load evidence, routes to [ConversationPhase.neutralEntry]
/// instead of Receipt.
///
/// Naming once V1: after a spoken Receipt on the same night, while readiness
/// is still hold and load evidence remains, routes exactly one Naming turn
/// before Permission/Release climb. Never restamps Naming.
///
/// Turn-Response Progression V1: uses prior sealed phase + turn stance so
/// Release is not re-issued after resistance or softening unless readiness
/// has genuinely rebuilt through a non-Release path.
class ConversationPolicy {
  const ConversationPolicy({
    this.neutralEntryDetector = const NeutralEntryDetector(),
    this.explicitExitIntent = const ExplicitExitIntent(),
    this.postAudioReEngagement = const PostAudioReEngagement(),
    this.lightConversationDetector = const LightConversationDetector(),
    this.reframeReadinessGate = const ReframeReadinessGate(),
    this.reframeAdmissionGate = const ReframeAdmissionGate(),
    this.closureReadinessGate = const ClosureReadinessGate(),
    this.releaseProgressionGate = const ReleaseProgressionGate(),
  });

  final NeutralEntryDetector neutralEntryDetector;
  final ExplicitExitIntent explicitExitIntent;
  final PostAudioReEngagement postAudioReEngagement;
  final LightConversationDetector lightConversationDetector;
  final ReframeReadinessGate reframeReadinessGate;
  final ReframeAdmissionGate reframeAdmissionGate;
  final ClosureReadinessGate closureReadinessGate;
  final ReleaseProgressionGate releaseProgressionGate;

  ConversationDecision decide({
    required ReleaseDecision releaseDecision,
    String? message,
    NightSession? session,
    ValidatedUnderstanding? understanding,
    ConversationGroundingBuffer? conversationGrounding,
  }) {
    // Explicit exit intent → Enough close that may soft-handoff into audio.
    // Readiness ladder is not required when the person clearly asks to leave.
    if (message != null && explicitExitIntent.matches(message)) {
      return const ConversationDecision(
        phase: ConversationPhase.continuity,
        shouldSpeak: true,
      );
    }

    // Conversation protest / correction: genuine repair — not Permission ease.
    if (_isConversationProtestOrCorrection(message)) {
      return ConversationDecision(
        phase: ConversationPhase.validation,
        shouldSpeak: true,
        expressionMode: ConversationExpressionMode.repair,
        repairRepetitionProtest: _isRepetitionProtest(message),
      );
    }

    // Post-audio re-engagement: meaningful new turn reopens Receipt path.
    if (_isPostAudioReEngagement(message: message, session: session)) {
      return _arcValidationDecision(
        session: session,
        message: message,
        understanding: understanding,
        conversationGrounding: conversationGrounding,
      );
    }

    // Light-chat loop: stay warm after a light turn unless load appears.
    if (_isLightChatContinuation(message: message, session: session)) {
      return const ConversationDecision(
        phase: ConversationPhase.neutralEntry,
        shouldSpeak: true,
        expressionMode: ConversationExpressionMode.lightChat,
      );
    }

    if (_isLightConversationTurn(
      releaseDecision: releaseDecision,
      message: message,
      understanding: understanding,
    )) {
      return const ConversationDecision(
        phase: ConversationPhase.neutralEntry,
        shouldSpeak: true,
        expressionMode: ConversationExpressionMode.lightChat,
      );
    }

    if (_isNeutralEntry(
      releaseDecision: releaseDecision,
      message: message,
      session: session,
      understanding: understanding,
    )) {
      return const ConversationDecision(
        phase: ConversationPhase.neutralEntry,
        shouldSpeak: true,
      );
    }

    final priorPhase =
        (session == null || session.turns.isEmpty) ? null : session.turns.last.phase;
    final stance =
        understanding?.turnResponseStance ?? TurnResponseStance.unclear;
    final hasLoad = _hasLoadEvidence(understanding);
    final arc = ConversationArcReader.fromSession(session);

    // After personalized closure, wind-down → Enough — not another Receipt arc.
    if (message != null &&
        arc.hadClosure &&
        releaseProgressionGate.hasWindDownEvidence(message) &&
        releaseDecision.readiness != ReleaseReadiness.hold) {
      if (priorPhase == ConversationPhase.continuity) {
        return const ConversationDecision(
          phase: ConversationPhase.continuity,
          shouldSpeak: false,
        );
      }
      return const ConversationDecision(
        phase: ConversationPhase.continuity,
        shouldSpeak: true,
      );
    }

    if (priorPhase == ConversationPhase.release) {
      return _decideAfterRelease(
        releaseDecision: releaseDecision,
        stance: stance,
        hasLoad: hasLoad,
        priorPhase: ConversationPhase.release,
        message: message,
        session: session,
        understanding: understanding,
        conversationGrounding: conversationGrounding,
      );
    }

    return _decideBase(
      releaseDecision: releaseDecision,
      priorPhase: priorPhase,
      session: session,
      hasLoad: hasLoad,
      message: message,
      understanding: understanding,
      conversationGrounding: conversationGrounding,
    );
  }

  /// Slice 2–3 arc: Observe → Narrow → Reframe → Integrate → Closure.
  ConversationDecision _arcValidationDecision({
    required NightSession? session,
    required String? message,
    required ValidatedUnderstanding? understanding,
    ConversationGroundingBuffer? conversationGrounding,
  }) {
    final arc = ConversationArcReader.fromSession(session);

    if (arc.reframeAwaitingResponse && message != null) {
      if (_isReframeFullConfirmation(message)) {
        return const ConversationDecision(
          phase: ConversationPhase.validation,
          shouldSpeak: true,
          expressionMode: ConversationExpressionMode.integrate,
        );
      }
      if (_isPartialReframeResponse(message)) {
        return const ConversationDecision(
          phase: ConversationPhase.validation,
          shouldSpeak: true,
          expressionMode: ConversationExpressionMode.narrow,
          narrowRefinementAfterPartial: true,
        );
      }
    }

    if (arc.integrateAwaitingResponse && message != null) {
      if (_isArcResistance(message)) {
        return ConversationDecision(
          phase: ConversationPhase.validation,
          shouldSpeak: true,
          expressionMode: ConversationExpressionMode.narrow,
          narrowRefinementAfterPartial: true,
        );
      }
      if (_isIntegratePositiveAck(message)) {
        return const ConversationDecision(
          phase: ConversationPhase.validation,
          shouldSpeak: true,
          expressionMode: ConversationExpressionMode.closure,
        );
      }
    }

    if (arc.closureAwaitingResponse && message != null) {
      if (_isArcResistance(message)) {
        return ConversationDecision(
          phase: ConversationPhase.validation,
          shouldSpeak: true,
          expressionMode: ConversationExpressionMode.narrow,
        );
      }
    }

    if (_isFirstReceiptTurn(session)) {
      return const ConversationDecision(
        phase: ConversationPhase.validation,
        shouldSpeak: true,
        expressionMode: ConversationExpressionMode.observePurity,
      );
    }

    final admission = reframeAdmissionGate.evaluate(
      session: session,
      message: message,
      understanding: understanding,
      conversationGrounding: conversationGrounding,
      arc: arc,
    );

    if (admission.outcome == ReframeAdmissionOutcome.earned &&
        !arc.reframeAwaitingResponse &&
        !arc.integrateAwaitingResponse &&
        !arc.closureAwaitingResponse &&
        !(arc.hadIntegrate && !arc.hadClosure) &&
        !_isBareAcknowledgment(message ?? '') &&
        _shouldOfferReframe(session: session, arc: arc)) {
      return const ConversationDecision(
        phase: ConversationPhase.validation,
        shouldSpeak: true,
        expressionMode: ConversationExpressionMode.reframe,
      );
    }

    if (admission.outcome == ReframeAdmissionOutcome.plausibleUnproven &&
        arc.hadNarrow &&
        message != null &&
        !_isBareAcknowledgment(message)) {
      return const ConversationDecision(
        phase: ConversationPhase.validation,
        shouldSpeak: true,
        expressionMode: ConversationExpressionMode.narrow,
        narrowRefinementAfterPartial: true,
      );
    }

    final reframeReady = admission.outcome == ReframeAdmissionOutcome.earned;

    if (arc.hadNarrow &&
        message != null &&
        !reframeReady &&
        reframeReadinessGate.isThinEvidenceAfterNarrow(message)) {
      return const ConversationDecision(
        phase: ConversationPhase.validation,
        shouldSpeak: true,
        expressionMode: ConversationExpressionMode.narrow,
        narrowRefinementAfterPartial: true,
      );
    }

    if (!arc.hadNarrow ||
        _shouldRenarrowAfterAck(message, arc) ||
        _isPartialReframeResponse(message ?? '')) {
      return ConversationDecision(
        phase: ConversationPhase.validation,
        shouldSpeak: true,
        expressionMode: ConversationExpressionMode.narrow,
        narrowRefinementAfterPartial:
            message != null && _isPartialReframeResponse(message),
      );
    }

    // Not reframe-ready: listen/observe — never default Belki reframe (standard).
    return const ConversationDecision(
      phase: ConversationPhase.validation,
      shouldSpeak: true,
      expressionMode: ConversationExpressionMode.observePurity,
    );
  }

  bool _shouldRenarrowAfterAck(String? message, ConversationArcReader arc) {
    if (message == null) return false;
    if (!arc.hadObservePurity || arc.hadNarrow) return false;
    return _isBareAcknowledgment(message);
  }

  bool _shouldOfferReframe({
    required NightSession? session,
    required ConversationArcReader arc,
  }) {
    if (!arc.hadReframe) return true;
    if (_recentReframeCompleted(session)) return false;
    return _narrowedAfterLastReframe(session);
  }

  bool _recentReframeCompleted(NightSession? session) {
    if (session == null) return false;
    for (var i = session.turns.length - 1; i >= 0; i--) {
      final mode = session.turns[i].expressionMode;
      if (mode == ConversationExpressionMode.integrate ||
          mode == ConversationExpressionMode.closure ||
          mode == ConversationExpressionMode.postReframeListen) {
        return true;
      }
      if (mode == ConversationExpressionMode.reframe) return false;
    }
    return false;
  }

  bool _narrowedAfterLastReframe(NightSession? session) {
    if (session == null) return false;
    var sawReframe = false;
    for (var i = session.turns.length - 1; i >= 0; i--) {
      final mode = session.turns[i].expressionMode;
      if (mode == ConversationExpressionMode.narrow) return sawReframe;
      if (mode == ConversationExpressionMode.reframe) sawReframe = true;
    }
    return false;
  }

  bool _isIntegratePositiveAck(String message) {
    final n = _normalizeProtestText(message).replaceAll(RegExp(r'[.!?…]+$'), '');
    if (_isBareAcknowledgment(message)) return true;
    return _containsAnyNormalized(n, const [
      'dogru',
      'doğru',
      'aynen',
      'kesinlikle',
      'evet',
      'tamam',
      'exactly',
      'that is right',
      "that's right",
    ]);
  }

  bool _isArcResistance(String message) {
    final n = _normalizeProtestText(message);
    if (_isPartialReframeResponse(message)) return true;
    return _containsAnyNormalized(n, const [
      'ama yine',
      'ama hala',
      'ama hâlâ',
      'hala cok',
      'hâlâ çok',
      'hala kork',
      'hâlâ kork',
      'duramiyorum',
      'duramıyorum',
      'dusunmeden duram',
      'düşünmeden duram',
      'yine de dusun',
      'yine de düşün',
      'olmuyor',
      'durmuyor',
      'still scared',
      'still afraid',
      "can't stop",
      'cannot stop',
      'wont stop',
      "won't stop",
    ]);
  }

  bool _isBareAcknowledgment(String message) {
    final n = _normalizeProtestText(message).replaceAll(RegExp(r'[.!?…]+$'), '');
    return RegExp(
      r'^(evet|aynen|tamam|ok|okay|hm+|hmm+|mm+|he+|ha+|yes|yeah|yep)$',
    ).hasMatch(n);
  }

  bool _isReframeFullConfirmation(String message) {
    final n = _normalizeProtestText(message);
    return _containsAnyNormalized(n, const [
      'evet tam',
      'tam olarak',
      'aynen oyle',
      'aynen öyle',
      'kesinlikle',
      'exactly',
      'yes exactly',
      'that is it',
      "that's it",
    ]) ||
        RegExp(r'^evet\.?$').hasMatch(n.trim());
  }

  bool _isPartialReframeResponse(String message) {
    if (_isReframeFullConfirmation(message)) return false;
    final n = _normalizeProtestText(message);
    if (_containsAnyNormalized(n, const [
      'biraz ama',
      'kismen',
      'kısmen',
      'tam degil',
      'tam değil',
      'not exactly',
      'partly',
      'sort of',
      'evet ama',
      'sadece o degil',
      'sadece o değil',
      'baska bir sey',
      'başka bir şey',
      'kismi dogru',
      'kısmı doğru',
      'baski kismi',
      'baskı kısmı',
      'ama sadece',
      'dogru ama',
      'doğru ama',
    ])) {
      return true;
    }
    if (n.contains('evet') &&
        _containsAnyNormalized(n, const [
          'ama',
          'kismi',
          'kısmı',
          'sadece',
          'degil',
          'değil',
        ])) {
      return true;
    }
    return false;
  }

  bool _containsAnyNormalized(String n, List<String> markers) {
    for (final marker in markers) {
      if (n.contains(marker)) return true;
    }
    return false;
  }

  bool _isLightChatContinuation({
    required String? message,
    required NightSession? session,
  }) {
    if (message == null || session == null || session.turns.isEmpty) {
      return false;
    }
    final last = session.turns.last;
    if (last.expressionMode != ConversationExpressionMode.lightChat) {
      return false;
    }
    return lightConversationDetector.isLightConversation(message);
  }

  bool _isFirstReceiptTurn(NightSession? session) {
    if (session == null || session.turns.isEmpty) return true;
    for (final turn in session.turns) {
      if (turn.phase == ConversationPhase.validation ||
          turn.phase == ConversationPhase.naming) {
        return false;
      }
    }
    return true;
  }

  ConversationDecision _decideAfterRelease({
    required ReleaseDecision releaseDecision,
    required TurnResponseStance stance,
    required bool hasLoad,
    required ConversationPhase priorPhase,
    String? message,
    NightSession? session,
    ValidatedUnderstanding? understanding,
    ConversationGroundingBuffer? conversationGrounding,
  }) {
    if (message != null &&
        !hasLoad &&
        lightConversationDetector.isLightConversation(message)) {
      return const ConversationDecision(
        phase: ConversationPhase.neutralEntry,
        shouldSpeak: true,
        expressionMode: ConversationExpressionMode.lightChat,
      );
    }

    if (releaseDecision.readiness == ReleaseReadiness.transitionReady) {
      // Softening after Release: speak one Enough close before audio.
      // Do not skip the spoken night-close into immediate audio.
      if (priorPhase == ConversationPhase.release) {
        return const ConversationDecision(
          phase: ConversationPhase.continuity,
          shouldSpeak: true,
        );
      }
      return const ConversationDecision(
        phase: ConversationPhase.audio,
        shouldSpeak: false,
      );
    }

    final resisting = stance == TurnResponseStance.holdingAgainstEase ||
        stance == TurnResponseStance.continuedLoad ||
        hasLoad;

    if (resisting) {
      // Resistance after Release → Receipt/Permission, never Release.
      if (releaseDecision.readiness == ReleaseReadiness.hold) {
        return _arcValidationDecision(
          session: session,
          message: message,
          understanding: understanding,
          conversationGrounding: conversationGrounding,
        );
      }
      return const ConversationDecision(
        phase: ConversationPhase.permission,
        shouldSpeak: true,
      );
    }

    if (stance == TurnResponseStance.softeningAcceptance) {
      return const ConversationDecision(
        phase: ConversationPhase.continuity,
        shouldSpeak: true,
      );
    }

    // Unclear after Release: fail closed on acceptance/audio, but never
    // re-issue Release merely because load was absent.
    if (releaseDecision.readiness == ReleaseReadiness.hold) {
      return _arcValidationDecision(
        session: session,
        message: message,
        understanding: understanding,
        conversationGrounding: conversationGrounding,
      );
    }
    if (releaseDecision.readiness == ReleaseReadiness.regulated) {
      return const ConversationDecision(
        phase: ConversationPhase.permission,
        shouldSpeak: true,
      );
    }
    return const ConversationDecision(
      phase: ConversationPhase.continuity,
      shouldSpeak: true,
    );
  }

  ConversationDecision _decideBase({
    required ReleaseDecision releaseDecision,
    required ConversationPhase? priorPhase,
    required NightSession? session,
    required bool hasLoad,
    String? message,
    ValidatedUnderstanding? understanding,
    ConversationGroundingBuffer? conversationGrounding,
  }) {
    if (message != null) {
      final arc = ConversationArcReader.fromSession(session);
      if (arc.reframeAwaitingResponse && _isPartialReframeResponse(message)) {
        return const ConversationDecision(
          phase: ConversationPhase.validation,
          shouldSpeak: true,
          expressionMode: ConversationExpressionMode.narrow,
          narrowRefinementAfterPartial: true,
        );
      }
      final admission = reframeAdmissionGate.evaluate(
        session: session,
        message: message,
        understanding: understanding,
        conversationGrounding: conversationGrounding,
        arc: arc,
      );
      if (admission.outcome == ReframeAdmissionOutcome.earned &&
          !arc.reframeAwaitingResponse &&
          !arc.integrateAwaitingResponse &&
          !arc.closureAwaitingResponse &&
          !(arc.hadIntegrate && !arc.hadClosure) &&
          !_isPartialReframeResponse(message) &&
          !_isBareAcknowledgment(message) &&
          _shouldOfferReframe(session: session, arc: arc)) {
        return const ConversationDecision(
          phase: ConversationPhase.validation,
          shouldSpeak: true,
          expressionMode: ConversationExpressionMode.reframe,
        );
      }
    }

    switch (releaseDecision.readiness) {
      case ReleaseReadiness.hold:
        if (hasLoad) {
          return _arcValidationDecision(
            session: session,
            message: message,
            understanding: understanding,
            conversationGrounding: conversationGrounding,
          );
        }
        if (_shouldSpeakNamingOnce(
          session: session,
          priorPhase: priorPhase,
          hasLoad: hasLoad,
        )) {
          return const ConversationDecision(
            phase: ConversationPhase.naming,
            shouldSpeak: true,
          );
        }
        return _arcValidationDecision(
          session: session,
          message: message,
          understanding: understanding,
          conversationGrounding: conversationGrounding,
        );

      case ReleaseReadiness.regulated:
        if (!hasLoad &&
            message != null &&
            lightConversationDetector.isLightConversation(message)) {
          return const ConversationDecision(
            phase: ConversationPhase.neutralEntry,
            shouldSpeak: true,
            expressionMode: ConversationExpressionMode.lightChat,
          );
        }
        if (!hasLoad) {
          return _arcValidationDecision(
          session: session,
          message: message,
          understanding: understanding,
          conversationGrounding: conversationGrounding,
        );
        }
        return const ConversationDecision(
          phase: ConversationPhase.permission,
          shouldSpeak: true,
        );

      case ReleaseReadiness.settling:
        // Slice 3: resistance after closure reopens arc, not Release.
        if (message != null) {
          final arcForResistance = ConversationArcReader.fromSession(session);
          if (_isArcResistance(message) &&
              (arcForResistance.closureAwaitingResponse ||
                  arcForResistance.hadClosure)) {
            return _arcValidationDecision(
              session: session,
              message: message,
              understanding: understanding,
              conversationGrounding: conversationGrounding,
            );
          }
        }
        // Slice 3: block premature Release while problem arc is incomplete.
        {
          final arc = ConversationArcReader.fromSession(session);
          final light = message != null &&
              lightConversationDetector.isLightConversation(message);
          if (!closureReadinessGate.allowsRelease(
            arc: arc,
            message: message,
            isLightConversation: light,
          )) {
            return _arcValidationDecision(
              session: session,
              message: message,
              understanding: understanding,
              conversationGrounding: conversationGrounding,
            );
          }
        }
        // One Release issuance per climb. A second Enough after Enough must
        // not re-stamp the close — speak once, then stay quiet.
        if (priorPhase == ConversationPhase.continuity) {
          return const ConversationDecision(
            phase: ConversationPhase.continuity,
            shouldSpeak: false,
          );
        }
        return const ConversationDecision(
          phase: ConversationPhase.release,
          shouldSpeak: true,
        );

      case ReleaseReadiness.receptive:
        // Receptive is Enough / continuity — not a second Release WHAT.
        // If Enough already spoke, do not emit another identical close.
        if (priorPhase == ConversationPhase.continuity) {
          return const ConversationDecision(
            phase: ConversationPhase.continuity,
            shouldSpeak: false,
          );
        }
        return const ConversationDecision(
          phase: ConversationPhase.continuity,
          shouldSpeak: true,
        );

      case ReleaseReadiness.transitionReady:
        return const ConversationDecision(
          phase: ConversationPhase.audio,
          shouldSpeak: false,
        );
    }
  }

  /// Exactly one Naming after Receipt while still holding load.
  bool _shouldSpeakNamingOnce({
    required NightSession? session,
    required ConversationPhase? priorPhase,
    required bool hasLoad,
  }) {
    if (!hasLoad) return false;
    if (priorPhase != ConversationPhase.validation) return false;
    if (session == null) return false;
    for (final turn in session.turns) {
      if (turn.phase == ConversationPhase.naming) return false;
    }
    return true;
  }

  /// After terminal audio, a meaningful user turn reopens conversation.
  bool _isPostAudioReEngagement({
    required String? message,
    required NightSession? session,
  }) {
    if (session == null || session.turns.isEmpty) return false;
    if (session.turns.last.phase != ConversationPhase.audio) return false;
    if (message == null) return false;
    return postAudioReEngagement.isMeaningful(message);
  }

  bool _isLightConversationTurn({
    required ReleaseDecision releaseDecision,
    required String? message,
    required ValidatedUnderstanding? understanding,
  }) {
    if (message == null) return false;
    if (!lightConversationDetector.isLightConversation(message)) return false;
    if (_hasLoadEvidence(understanding)) return false;
    if (releaseDecision.readiness != ReleaseReadiness.hold &&
        releaseDecision.readiness != ReleaseReadiness.regulated &&
        releaseDecision.readiness != ReleaseReadiness.settling &&
        releaseDecision.readiness != ReleaseReadiness.receptive &&
        releaseDecision.readiness != ReleaseReadiness.transitionReady) {
      return false;
    }
    return true;
  }

  bool _isNeutralEntry({
    required ReleaseDecision releaseDecision,
    required String? message,
    required NightSession? session,
    required ValidatedUnderstanding? understanding,
  }) {
    if (releaseDecision.readiness != ReleaseReadiness.hold) {
      return false;
    }
    if (session == null || session.turns.isNotEmpty) {
      return false;
    }
    if (message == null || !neutralEntryDetector.isNeutralGreeting(message)) {
      return false;
    }
    if (_hasLoadEvidence(understanding)) {
      return false;
    }
    return true;
  }

  bool _hasLoadEvidence(ValidatedUnderstanding? understanding) {
    if (understanding == null) return false;
    if (understanding.mentalPatterns.isNotEmpty ||
        understanding.emotionalPatterns.isNotEmpty) {
      return true;
    }
    final hyp = understanding.thinkingFunctionHypothesis;
    return hyp != null && hyp.confidence >= 0.55;
  }

  bool _isRepetitionProtest(String? message) {
    if (message == null) return false;
    final n = _normalizeProtestText(message);
    if (n.contains('robot gibi')) return true;
    if (n.contains('surekli ayni')) return true;
    if (n.contains('ayni seyi soyl')) return true;
    if (n.contains('bunu zaten soyled')) return true;
    if (n.contains('bu soruyu zaten')) return true;
    if (n.contains('tekrar ediyorsun')) return true;
    if (n.contains('tekrarliyorsun')) return true;
    if (n.contains('like a robot')) return true;
    if (n.contains('talking like a robot')) return true;
    if (n.contains('same thing over')) return true;
    if (n.contains('keep saying the same')) return true;
    if (n.contains('you already said')) return true;
    if (n.contains('you already asked')) return true;
    if (n.contains('stop repeating')) return true;
    return false;
  }

  String _normalizeProtestText(String message) {
    return message
        .trim()
        .toLowerCase()
        .replaceAll('ş', 's')
        .replaceAll('ğ', 'g')
        .replaceAll('ü', 'u')
        .replaceAll('ö', 'o')
        .replaceAll('ı', 'i')
        .replaceAll('ç', 'c');
  }

  /// Conversation feedback: objecting to Nocta's speech or correcting a
  /// misread. Private helper — not a new engine.
  bool _isConversationProtestOrCorrection(String? message) {
    if (message == null) return false;
    final n = _normalizeProtestText(message);
    if (n.isEmpty) return false;

    if (_isRepetitionProtest(message)) return true;

    // Protest — objecting to Nocta's style / understanding.
    if (n.contains('beni anlam')) return true;
    if (n.contains('anlamiyosun')) return true;
    if (n.contains('anlamiyorsun')) return true;
    if (RegExp(r"you don'?t understand( me)?").hasMatch(n)) return true;

    // Correction — rejecting Nocta's interpretation / attributed feeling.
    if (n.contains('yanlis anlad')) return true;
    if (n.contains('alakasi yok')) return true;
    if (n.contains('oyle demedim')) return true;
    if (n.contains('demedim')) {
      if (n.contains('oyle') || n.contains('ben')) return true;
    }
    if (n.contains('uzgun degilim')) return true;
    if (n.contains("i'm not sad")) return true;
    if (n.contains('i am not sad')) return true;
    if (n.contains("that's not what i")) return true;
    if (n.contains('thats not what i')) return true;
    if (n.contains('you misunderstood')) return true;
    if (n.contains('wrong about')) return true;
    return false;
  }
}
