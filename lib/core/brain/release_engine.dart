import 'living_mind_model.dart';
import 'release_decision.dart';
import 'validated_understanding.dart';

/// ReleaseEngine
///
/// Decision Rules (V1)
///
/// HOLD → High activation
/// REGULATED → User feels received
/// SETTLING → Activation decreasing
/// RECEPTIVE → Ready for gentle release
/// TRANSITION_READY → Conversation should end
class ReleaseEngine {
  const ReleaseEngine();

  ReleaseDecision evaluate({
    required ValidatedUnderstanding understanding,
    required LivingMindModel model,
  }) {
    if (understanding.emotionalPatterns.isNotEmpty) {
      return const ReleaseDecision(
        readiness: ReleaseReadiness.regulated,
        confidence: 0.70,
      );
    }

    return const ReleaseDecision(
      readiness: ReleaseReadiness.hold,
      confidence: 0.40,
    );
  }
}
