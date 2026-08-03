import 'conversation_phase.dart';
import 'release_decision.dart';

/// Represents a single turn within a NightSession.
///
/// SessionTurn is immutable.
///
/// It captures only the information required to
/// understand the progression of the current night.
///
/// It is discarded when the NightSession ends.
class SessionTurn {
  final ReleaseDecision releaseDecision;

  final ConversationPhase phase;

  const SessionTurn({required this.releaseDecision, required this.phase});
}
