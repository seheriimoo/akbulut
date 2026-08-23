import 'conversation_arc_reader.dart';
import 'explicit_exit_intent.dart';
import 'light_conversation_detector.dart';
import 'release_progression_gate.dart';

/// Deterministic gate: problem-focused nights may not Release/audio until
/// Integrate→Closure arc completes or the user shows genuine wind-down.
class ClosureReadinessGate {
  const ClosureReadinessGate({
    this.lightConversation = const LightConversationDetector(),
    this.explicitExitIntent = const ExplicitExitIntent(),
    this.progressionGate = const ReleaseProgressionGate(),
  });

  final LightConversationDetector lightConversation;
  final ExplicitExitIntent explicitExitIntent;
  final ReleaseProgressionGate progressionGate;

  /// True when Release / settling climb is allowed this turn.
  bool allowsRelease({
    required ConversationArcReader arc,
    required String? message,
    required bool isLightConversation,
  }) {
    if (isLightConversation) return true;
    if (message != null && explicitExitIntent.matches(message)) return true;
    if (!arc.problemFocusedArcIncomplete) return true;
    if (arc.hadClosure) return true;
    if (message != null && progressionGate.hasWindDownEvidence(message)) {
      return arc.hadIntegrate;
    }
    return false;
  }

  /// True when readiness must not climb toward Release (arc still open).
  bool blocksReadinessClimb({
    required ConversationArcReader arc,
    required String? message,
    required bool isLightConversation,
  }) {
    if (isLightConversation) return false;
    if (message != null && explicitExitIntent.matches(message)) return false;
    if (!arc.problemFocusedArcIncomplete) return false;
    if (message != null && progressionGate.hasWindDownEvidence(message)) {
      return !arc.hadIntegrate;
    }
    return true;
  }

  /// Arc milestones for metrics / policy (Integrate produced after confirm).
  bool isClosureReady(ConversationArcReader arc) =>
      arc.hadIntegrate && (arc.hadClosure || arc.closureAwaitingResponse);
}
