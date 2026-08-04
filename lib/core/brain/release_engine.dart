import 'release_decision.dart';
import 'validated_understanding.dart';
import 'working_mind_view.dart';

/// ReleaseEngine
///
/// Estimates release readiness.
///
/// Reads persistent knowledge only through WorkingMindView.
///
/// Owns no conversation protocol.
///
/// Owns no exit decisions.
///
/// Owns no memory writes.
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
    required WorkingMindView workingMind,
  }) {
    // Persistent knowledge is available only through workingMind.
    // Current V1 rules use understanding signals only.
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
