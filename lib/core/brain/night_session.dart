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

  const NightSession({required this.workingMind, required this.turns});

  /// Records one temporary turn for the current night.
  ///
  /// Returns a new NightSession.
  ///
  /// Does not write persistent memory.
  NightSession recordTurn(SessionTurn turn) {
    return NightSession(
      workingMind: workingMind,
      turns: [...turns, turn],
    );
  }
}
