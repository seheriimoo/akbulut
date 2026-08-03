import 'living_mind_model.dart';
import 'reasoning_engine.dart';

class BrainTurnResult {
  final LivingMindModel model;

  final ReasoningDecision decision;

  const BrainTurnResult({required this.model, required this.decision});
}
