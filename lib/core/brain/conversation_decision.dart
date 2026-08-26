import 'conversation_expression_mode.dart';
import 'conversation_phase.dart';
import 'discovery/discovery_act.dart';
import 'discovery/discovery_objective.dart';

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

  /// Adaptive discovery: emit Sleep Mind Mirror this turn.
  final bool sleepMindMirror;

  /// Planner act for this turn (defer = existing arc owns HOW).
  final DiscoveryAct discoveryAct;

  /// WHAT to learn — LLM realizes wording; never a fixed question bank.
  final DiscoveryObjective? discoveryObjective;

  const ConversationDecision({
    required this.phase,
    required this.shouldSpeak,
    this.expressionMode = ConversationExpressionMode.standard,
    this.repairRepetitionProtest = false,
    this.narrowRefinementAfterPartial = false,
    this.postRecognitionDeepen = false,
    this.sleepMindMirror = false,
    this.discoveryAct = DiscoveryAct.deferToArc,
    this.discoveryObjective,
  });
}
