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
  /// Temporary conversation progression is discarded.
  SessionSummary summarize(NightSession session) {
    // session.turns: temporary release/phase progression — discarded.
    // session.workingMind: existing persistent read view — not session extract.
    // No durable Belief, Need, Preference, Pattern, or Trigger entities
    // are present on NightSession turns to promote into SessionSummary.
    return const SessionSummary();
  }
}
