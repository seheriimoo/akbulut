import 'conversation_expression_mode.dart';
import 'conversation_phase.dart';
import 'discovery/transition_profile.dart';
import 'session_turn.dart';
import 'working_mind_view.dart';

/// Temporary cognitive state for a single night.
///
/// NightSession lives only during the current session.
///
/// It is never persisted.
///
/// At the end of the session it is summarized,
/// then discarded.
class NightSession {
  final WorkingMindView workingMind;

  final List<SessionTurn> turns;

  /// Durable within this night: a grounded Sleep Mind Mirror was surfaced.
  final bool mirrorSurfaced;

  /// Durable within this night: ready for Nocta Transition after Mirror.
  final bool transitionReady;

  /// Compact TransitionProfile from the Mirror turn (for T+1 routing/handoff).
  final TransitionProfile? transitionProfile;

  const NightSession({
    required this.workingMind,
    required this.turns,
    this.mirrorSurfaced = false,
    this.transitionReady = false,
    this.transitionProfile,
  });

  /// Records one temporary turn for the current night.
  ///
  /// Returns a new NightSession.
  ///
  /// Does not write persistent memory.
  NightSession recordTurn(SessionTurn turn) {
    return NightSession(
      workingMind: workingMind,
      turns: [...turns, turn],
      mirrorSurfaced: mirrorSurfaced,
      transitionReady: transitionReady,
      transitionProfile: transitionProfile,
    );
  }

  /// After an admitted Sleep Mind Mirror — enter MIRROR_SURFACED / TRANSITION_READY.
  NightSession withMirrorSurfaced(TransitionProfile profile) {
    return NightSession(
      workingMind: workingMind,
      turns: turns,
      mirrorSurfaced: true,
      transitionReady: true,
      transitionProfile: profile,
    );
  }

  /// Clear post-Mirror bridge so Discovery may reopen (correction / new topic).
  NightSession clearPostMirrorBridge() {
    return NightSession(
      workingMind: workingMind,
      turns: turns,
      mirrorSurfaced: false,
      transitionReady: false,
      transitionProfile: null,
    );
  }
}
