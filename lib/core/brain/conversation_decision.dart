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

  /// Narrow-only: refine hypothesis after partial reframe confirm (Slice 2.1).
  final bool narrowRefinementAfterPartial;

  /// Post-Recognition: one integrate-lite deepen turn (not re-Recognition).
  final bool postRecognitionDeepen;

  const ConversationDecision({
    required this.phase,
    required this.shouldSpeak,
    this.expressionMode = ConversationExpressionMode.standard,
    this.repairRepetitionProtest = false,
    this.narrowRefinementAfterPartial = false,
    this.postRecognitionDeepen = false,
  });
}
