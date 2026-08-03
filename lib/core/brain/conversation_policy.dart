import 'conversation_decision.dart';
import 'conversation_phase.dart';
import 'release_decision.dart';

/// ConversationPolicy
///
/// Purpose:
/// Maps ReleaseDecision into the appropriate
/// ConversationDecision according to the
/// HCOS Conversation Protocol.
class ConversationPolicy {
  const ConversationPolicy();

  ConversationDecision decide({required ReleaseDecision releaseDecision}) {
    switch (releaseDecision.readiness) {
      case ReleaseReadiness.hold:
        return const ConversationDecision(
          phase: ConversationPhase.validation,
          shouldSpeak: true,
        );

      case ReleaseReadiness.regulated:
        return const ConversationDecision(
          phase: ConversationPhase.permission,
          shouldSpeak: true,
        );

      case ReleaseReadiness.settling:
        return const ConversationDecision(
          phase: ConversationPhase.permission,
          shouldSpeak: true,
        );

      case ReleaseReadiness.receptive:
        return const ConversationDecision(
          phase: ConversationPhase.release,
          shouldSpeak: true,
        );

      case ReleaseReadiness.transitionReady:
        return const ConversationDecision(
          phase: ConversationPhase.audio,
          shouldSpeak: false,
        );
    }
  }
}
