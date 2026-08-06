import 'night_session.dart';
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
///
/// Progression is one step at a time (Release Engine Spec).
class ReleaseEngine {
  const ReleaseEngine();

  ReleaseDecision evaluate({
    required ValidatedUnderstanding understanding,
    required WorkingMindView workingMind,
    required NightSession session,
  }) {
    // Persistent knowledge available through workingMind (read-only).
    final _ = workingMind.model.identity.userId;

    final previous = session.turns.isEmpty
        ? null
        : session.turns.last.releaseDecision.readiness;

    final highActivation = understanding.mentalPatterns.isNotEmpty;
    final feelsReceived = understanding.emotionalPatterns.isNotEmpty;

    final readiness = _nextReadiness(
      previous: previous,
      highActivation: highActivation,
      feelsReceived: feelsReceived,
    );

    return ReleaseDecision(
      readiness: readiness,
      confidence: _confidenceFor(readiness),
    );
  }

  /// Advances at most one allowed step; may step back under high activation.
  ReleaseReadiness _nextReadiness({
    required ReleaseReadiness? previous,
    required bool highActivation,
    required bool feelsReceived,
  }) {
    if (previous == null) {
      if (highActivation) return ReleaseReadiness.hold;
      if (feelsReceived) return ReleaseReadiness.regulated;
      return ReleaseReadiness.hold;
    }

    if (highActivation) {
      return _stepBack(previous);
    }

    // Calm continuation: move one step toward transition readiness.
    if (previous == ReleaseReadiness.hold && feelsReceived) {
      return ReleaseReadiness.regulated;
    }

    return _stepForward(previous);
  }

  ReleaseReadiness _stepForward(ReleaseReadiness current) {
    switch (current) {
      case ReleaseReadiness.hold:
        return ReleaseReadiness.regulated;
      case ReleaseReadiness.regulated:
        return ReleaseReadiness.settling;
      case ReleaseReadiness.settling:
        return ReleaseReadiness.receptive;
      case ReleaseReadiness.receptive:
        return ReleaseReadiness.transitionReady;
      case ReleaseReadiness.transitionReady:
        return ReleaseReadiness.transitionReady;
    }
  }

  ReleaseReadiness _stepBack(ReleaseReadiness current) {
    switch (current) {
      case ReleaseReadiness.hold:
        return ReleaseReadiness.hold;
      case ReleaseReadiness.regulated:
        return ReleaseReadiness.hold;
      case ReleaseReadiness.settling:
        return ReleaseReadiness.regulated;
      case ReleaseReadiness.receptive:
        return ReleaseReadiness.settling;
      case ReleaseReadiness.transitionReady:
        return ReleaseReadiness.receptive;
    }
  }

  double _confidenceFor(ReleaseReadiness readiness) {
    switch (readiness) {
      case ReleaseReadiness.hold:
        return 0.45;
      case ReleaseReadiness.regulated:
        return 0.70;
      case ReleaseReadiness.settling:
        return 0.78;
      case ReleaseReadiness.receptive:
        return 0.86;
      case ReleaseReadiness.transitionReady:
        return 0.92;
    }
  }
}
