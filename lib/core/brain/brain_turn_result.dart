import 'living_mind_model.dart';
import 'reasoning_engine.dart';

// ignore_for_file: deprecated_member_use_from_same_package

/// Deprecated production turn result.
///
/// Sprint 6 Cutover: [CognitiveTurnResult] is the only production turn result
/// returned to the app. Do not use in production paths.
@Deprecated(
  'Sprint 6 Cutover: CognitiveTurnResult is the only production turn result',
)
class BrainTurnResult {
  final LivingMindModel model;

  final ReasoningDecision decision;

  const BrainTurnResult({required this.model, required this.decision});
}
