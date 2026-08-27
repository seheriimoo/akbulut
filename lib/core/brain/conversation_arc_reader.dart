import 'conversation_expression_mode.dart';
import 'conversation_phase.dart';
import 'discovery/transition_profile.dart';
import 'night_session.dart';

/// Minimum arc state derived from sealed [NightSession] turns (Slice 2–3).
///
/// No durable memory. Rebuilt each policy decision from expression modes
/// recorded on prior turns, plus night-scoped Mirror/Transition bridge fields.
class ConversationArcReader {
  const ConversationArcReader({
    required this.hadObservePurity,
    required this.hadNarrow,
    required this.hadReframe,
    required this.hadIntegrate,
    required this.hadClosure,
    required this.reframeAwaitingResponse,
    required this.integrateAwaitingResponse,
    required this.closureAwaitingResponse,
    required this.reframeConfirmed,
    required this.loadTurnCount,
    this.lastReframeText,
    this.lastIntegrateText,
    this.mirrorSurfaced = false,
    this.transitionReady = false,
    this.transitionProfile,
  });

  final bool hadObservePurity;
  final bool hadNarrow;
  final bool hadReframe;
  final bool hadIntegrate;
  final bool hadClosure;
  final bool reframeAwaitingResponse;
  final bool integrateAwaitingResponse;
  final bool closureAwaitingResponse;
  final bool reframeConfirmed;
  final int loadTurnCount;
  final String? lastReframeText;
  final String? lastIntegrateText;

  /// Night-scoped: grounded Sleep Mind Mirror already surfaced.
  final bool mirrorSurfaced;

  /// Night-scoped: ready for Nocta Transition after Mirror.
  final bool transitionReady;

  /// Compact profile carried from the Mirror turn.
  final TransitionProfile? transitionProfile;

  /// Problem-focused arc started but has not reached personalized closure.
  bool get problemFocusedArcIncomplete {
    if (hadClosure) return false;
    if (hadReframe || (hadObservePurity && hadNarrow)) return true;
    return false;
  }

  factory ConversationArcReader.fromSession(NightSession? session) {
    if (session == null || session.turns.isEmpty) {
      return ConversationArcReader(
        hadObservePurity: false,
        hadNarrow: false,
        hadReframe: false,
        hadIntegrate: false,
        hadClosure: false,
        reframeAwaitingResponse: false,
        integrateAwaitingResponse: false,
        closureAwaitingResponse: false,
        reframeConfirmed: false,
        loadTurnCount: 0,
        mirrorSurfaced: session?.mirrorSurfaced ?? false,
        transitionReady: session?.transitionReady ?? false,
        transitionProfile: session?.transitionProfile,
      );
    }

    var hadObserve = false;
    var hadNarrow = false;
    var hadReframe = false;
    var hadIntegrate = false;
    var hadClosure = false;
    var loadTurns = 0;
    ConversationExpressionMode? lastAssistantMode;
    var lastWasSleepMindMirror = false;
    String? lastReframeText;
    String? lastIntegrateText;

    for (final turn in session.turns) {
      final mode = turn.expressionMode;
      if (mode == ConversationExpressionMode.observePurity) hadObserve = true;
      if (mode == ConversationExpressionMode.narrow) hadNarrow = true;
      if (mode == ConversationExpressionMode.reframe) {
        hadReframe = true;
        if (turn.admittedExpression != null) {
          lastReframeText = turn.admittedExpression!.text;
        }
      }
      if (mode == ConversationExpressionMode.integrate) {
        hadIntegrate = true;
        if (turn.admittedExpression != null) {
          lastIntegrateText = turn.admittedExpression!.text;
        }
      }
      if (mode == ConversationExpressionMode.closure) hadClosure = true;
      if (turn.phase == ConversationPhase.validation ||
          turn.phase == ConversationPhase.naming) {
        loadTurns++;
      }
      if (turn.admittedExpression != null) {
        lastAssistantMode = mode;
        lastWasSleepMindMirror = turn.sleepMindMirror;
      }
    }

    final reframeConfirmed = hadIntegrate ||
        hadClosure ||
        lastAssistantMode == ConversationExpressionMode.integrate ||
        lastAssistantMode == ConversationExpressionMode.closure;

    // Sleep Mind Mirror is recorded as integrate HOW but must not imply
    // classic Integrate-awaiting confirmation (which falls into Narrow).
    final classicIntegrateAwaiting =
        lastAssistantMode == ConversationExpressionMode.integrate &&
            !lastWasSleepMindMirror &&
            !session.mirrorSurfaced;

    return ConversationArcReader(
      hadObservePurity: hadObserve,
      hadNarrow: hadNarrow,
      hadReframe: hadReframe,
      hadIntegrate: hadIntegrate,
      hadClosure: hadClosure,
      reframeAwaitingResponse:
          lastAssistantMode == ConversationExpressionMode.reframe,
      integrateAwaitingResponse: classicIntegrateAwaiting,
      closureAwaitingResponse:
          lastAssistantMode == ConversationExpressionMode.closure,
      reframeConfirmed: reframeConfirmed,
      loadTurnCount: loadTurns,
      lastReframeText: lastReframeText,
      lastIntegrateText: lastIntegrateText,
      mirrorSurfaced: session.mirrorSurfaced,
      transitionReady: session.transitionReady,
      transitionProfile: session.transitionProfile,
    );
  }

  ConversationArcReader withReframeConfirmed() {
    return ConversationArcReader(
      hadObservePurity: hadObservePurity,
      hadNarrow: hadNarrow,
      hadReframe: hadReframe,
      hadIntegrate: hadIntegrate,
      hadClosure: hadClosure,
      reframeAwaitingResponse: false,
      integrateAwaitingResponse: integrateAwaitingResponse,
      closureAwaitingResponse: closureAwaitingResponse,
      reframeConfirmed: true,
      loadTurnCount: loadTurnCount,
      lastReframeText: lastReframeText,
      lastIntegrateText: lastIntegrateText,
      mirrorSurfaced: mirrorSurfaced,
      transitionReady: transitionReady,
      transitionProfile: transitionProfile,
    );
  }
}
