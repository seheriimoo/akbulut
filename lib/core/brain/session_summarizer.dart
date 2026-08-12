import 'emotional_pattern.dart';
import 'mental_pattern.dart';
import 'night_session.dart';
import 'session_summary.dart';

/// SessionSummarizer
///
/// Converts one completed NightSession into one
/// immutable SessionSummary.
///
/// Owns durable knowledge extraction only.
///
/// Performs no persistence.
///
/// Does not call MemoryEngine.
///
/// Does not modify LivingMindModel.
///
/// Does not perform memory merging.
class SessionSummarizer {
  const SessionSummarizer();

  /// Extracts durable knowledge from a completed NightSession.
  ///
  /// Temporary conversation progression (phases/readiness) is discarded.
  /// Dialogue text is never copied into SessionSummary.
  SessionSummary summarize(NightSession session) {
    final mentalById = <String, MentalPattern>{};
    final emotionalById = <String, EmotionalPattern>{};

    for (final turn in session.turns) {
      for (final pattern in turn.mentalPatterns) {
        final prior = mentalById[pattern.id];
        if (prior == null || pattern.confidence >= prior.confidence) {
          mentalById[pattern.id] = prior == null
              ? pattern
              : pattern.copyWith(
                  observations: prior.observations + 1,
                  confidence: pattern.confidence > prior.confidence
                      ? pattern.confidence
                      : prior.confidence,
                );
        } else {
          mentalById[pattern.id] = prior.copyWith(
            observations: prior.observations + 1,
          );
        }
      }

      for (final pattern in turn.emotionalPatterns) {
        final prior = emotionalById[pattern.id];
        if (prior == null || pattern.confidence >= prior.confidence) {
          emotionalById[pattern.id] = prior == null
              ? pattern
              : pattern.copyWith(
                  observations: prior.observations + 1,
                  confidence: pattern.confidence > prior.confidence
                      ? pattern.confidence
                      : prior.confidence,
                );
        } else {
          emotionalById[pattern.id] = prior.copyWith(
            observations: prior.observations + 1,
          );
        }
      }
    }

    return SessionSummary(
      mentalPatterns: mentalById.values.toList(growable: false),
      emotionalPatterns: emotionalById.values.toList(growable: false),
    );
  }
}
