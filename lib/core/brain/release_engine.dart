import 'conversation_phase.dart';
import 'night_session.dart';
import 'post_audio_re_engagement.dart';
import 'release_decision.dart';
import 'turn_response_stance.dart';
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
/// HOLD → High activation / active load
/// REGULATED → Load eased; user feels received enough to soften
/// SETTLING → Activation decreasing
/// RECEPTIVE → Ready for gentle release
/// TRANSITION_READY → Conversation should end
///
/// Progression is one step at a time (Release Engine Spec), except the
/// post-Release softening path may advance out of the Release dwell so
/// absence of load is never treated as permission to repeat Release.
class ReleaseEngine {
  const ReleaseEngine({
    this.postAudioReEngagement = const PostAudioReEngagement(),
  });

  final PostAudioReEngagement postAudioReEngagement;

  ReleaseDecision evaluate({
    required ValidatedUnderstanding understanding,
    required WorkingMindView workingMind,
    required NightSession session,
    String? message,
  }) {
    // Persistent knowledge available through workingMind (read-only).
    final _ = workingMind.model.identity.userId;

    final previous = session.turns.isEmpty
        ? null
        : session.turns.last.releaseDecision.readiness;
    final previousPhase =
        session.turns.isEmpty ? null : session.turns.last.phase;

    // Post-audio meaningful re-engagement: reset climb so conversation reopens.
    if (previousPhase == ConversationPhase.audio &&
        message != null &&
        postAudioReEngagement.isMeaningful(message)) {
      return ReleaseDecision(
        readiness: ReleaseReadiness.hold,
        confidence: _confidenceFor(ReleaseReadiness.hold),
      );
    }

    // Mental OR emotional patterns both mean active night load.
    // Emotional load must never be read as "feels received".
    final highActivation = understanding.mentalPatterns.isNotEmpty ||
        understanding.emotionalPatterns.isNotEmpty;

    final readiness = _nextReadiness(
      previous: previous,
      previousPhase: previousPhase,
      highActivation: highActivation,
      stance: understanding.turnResponseStance,
    );

    return ReleaseDecision(
      readiness: readiness,
      confidence: _confidenceFor(readiness),
    );
  }

  ReleaseReadiness _nextReadiness({
    required ReleaseReadiness? previous,
    required ConversationPhase? previousPhase,
    required bool highActivation,
    required TurnResponseStance stance,
  }) {
    if (previous == null) {
      // First turn: always begin at hold. Load or not, Receipt comes first.
      return ReleaseReadiness.hold;
    }

    final priorWasRelease = previousPhase == ConversationPhase.release;
    final resisting = stance == TurnResponseStance.holdingAgainstEase ||
        stance == TurnResponseStance.continuedLoad ||
        highActivation;

    // Resistance / continued load after a Release (or while still in the
    // Release readiness band) must leave the Release-capable band.
    if (resisting) {
      if (priorWasRelease ||
          previous == ReleaseReadiness.settling ||
          previous == ReleaseReadiness.receptive) {
        return _stepBackAtMostRegulated(previous);
      }
      return _stepBack(previous);
    }

    // Softening after Release / Release-band: advance toward transition;
    // do not dwell for another Release-capable turn.
    if (stance == TurnResponseStance.softeningAcceptance &&
        (priorWasRelease ||
            previous == ReleaseReadiness.settling ||
            previous == ReleaseReadiness.receptive)) {
      return ReleaseReadiness.transitionReady;
    }

    // Fail-closed after a spoken Release: unclear must not invent acceptance
    // and absence of load alone must not advance into another Release dwell.
    if (priorWasRelease && stance == TurnResponseStance.unclear) {
      return previous;
    }

    // Pre-Release calm continuation: move one step toward rest.
    return _stepForward(previous);
  }

  /// Step back, but never remain on settling/receptive while resisting ease.
  ReleaseReadiness _stepBackAtMostRegulated(ReleaseReadiness current) {
    switch (current) {
      case ReleaseReadiness.hold:
        return ReleaseReadiness.hold;
      case ReleaseReadiness.regulated:
        return ReleaseReadiness.hold;
      case ReleaseReadiness.settling:
        return ReleaseReadiness.regulated;
      case ReleaseReadiness.receptive:
        return ReleaseReadiness.regulated;
      case ReleaseReadiness.transitionReady:
        return ReleaseReadiness.regulated;
    }
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
