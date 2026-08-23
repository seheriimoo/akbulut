import 'conversation_expression_mode.dart';
import 'conversation_phase.dart';
import 'night_session.dart';

/// Minimum arc state derived from sealed [NightSession] turns (Slice 2).
///
/// No durable memory. Rebuilt each policy decision from expression modes
/// recorded on prior turns.
class ConversationArcReader {
  const ConversationArcReader({
    required this.hadObservePurity,
    required this.hadNarrow,
    required this.hadReframe,
    required this.reframeAwaitingResponse,
    required this.reframeConfirmed,
    required this.loadTurnCount,
  });

  final bool hadObservePurity;
  final bool hadNarrow;
  final bool hadReframe;
  final bool reframeAwaitingResponse;
  final bool reframeConfirmed;
  final int loadTurnCount;

  factory ConversationArcReader.fromSession(NightSession? session) {
    if (session == null || session.turns.isEmpty) {
      return const ConversationArcReader(
        hadObservePurity: false,
        hadNarrow: false,
        hadReframe: false,
        reframeAwaitingResponse: false,
        reframeConfirmed: false,
        loadTurnCount: 0,
      );
    }

    var hadObserve = false;
    var hadNarrow = false;
    var hadReframe = false;
    var reframeConfirmed = false;
    var loadTurns = 0;
    ConversationExpressionMode? lastAssistantMode;

    for (final turn in session.turns) {
      final mode = turn.expressionMode;
      if (mode == ConversationExpressionMode.observePurity) hadObserve = true;
      if (mode == ConversationExpressionMode.narrow) hadNarrow = true;
      if (mode == ConversationExpressionMode.reframe) hadReframe = true;
      if (turn.phase == ConversationPhase.validation ||
          turn.phase == ConversationPhase.naming) {
        loadTurns++;
      }
      if (turn.admittedExpression != null) {
        lastAssistantMode = mode;
      }
    }

    return ConversationArcReader(
      hadObservePurity: hadObserve,
      hadNarrow: hadNarrow,
      hadReframe: hadReframe,
      reframeAwaitingResponse:
          lastAssistantMode == ConversationExpressionMode.reframe,
      reframeConfirmed: reframeConfirmed,
      loadTurnCount: loadTurns,
    );
  }

  ConversationArcReader withReframeConfirmed() {
    return ConversationArcReader(
      hadObservePurity: hadObservePurity,
      hadNarrow: hadNarrow,
      hadReframe: hadReframe,
      reframeAwaitingResponse: false,
      reframeConfirmed: true,
      loadTurnCount: loadTurnCount,
    );
  }
}
