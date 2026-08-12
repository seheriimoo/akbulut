import 'conversation_phase.dart';
import 'emotional_pattern.dart';
import 'mental_pattern.dart';
import 'prior_admitted_expression.dart';
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

  /// Guard-admitted assistant expression for this turn, if any.
  ///
  /// Expression-plane anti-repeat only for later turns.
  /// Null when the turn did not speak (silence, audio, Guard reject).
  final PriorAdmittedExpression? admittedExpression;

  /// Turn-scoped mental pattern candidates (durable extract at session end).
  final List<MentalPattern> mentalPatterns;

  /// Turn-scoped emotional pattern candidates (durable extract at session end).
  final List<EmotionalPattern> emotionalPatterns;

  const SessionTurn({
    required this.releaseDecision,
    required this.phase,
    this.admittedExpression,
    this.mentalPatterns = const [],
    this.emotionalPatterns = const [],
  });
}
