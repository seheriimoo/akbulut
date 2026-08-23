import 'conversation_expression_mode.dart';
import 'conversation_phase.dart';

class ConversationDecision {
  final ConversationPhase phase;

  final bool shouldSpeak;

  /// HOW-only compile/guard steering for this turn (Slice 1+).
  final ConversationExpressionMode expressionMode;

  /// When [expressionMode] is [ConversationExpressionMode.repair], true if the
  /// user protested repetition rather than a factual misread.
  final bool repairRepetitionProtest;

  const ConversationDecision({
    required this.phase,
    required this.shouldSpeak,
    this.expressionMode = ConversationExpressionMode.standard,
    this.repairRepetitionProtest = false,
  });
}
