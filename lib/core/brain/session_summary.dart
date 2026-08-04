import 'belief.dart';
import 'emotional_pattern.dart';
import 'mental_pattern.dart';
import 'need.dart';
import 'preference.dart';
import 'trigger.dart';

/// Durable knowledge extracted from one completed NightSession.
///
/// SessionSummary is immutable.
///
/// It contains only knowledge suitable for later
/// MemoryEngine processing.
///
/// It must not contain temporary conversation state,
/// raw dialogue, or nightly transcripts.
class SessionSummary {
  final List<MentalPattern> mentalPatterns;

  final List<EmotionalPattern> emotionalPatterns;

  final List<Belief> beliefs;

  final List<Need> needs;

  final List<Preference> preferences;

  final List<Trigger> triggers;

  const SessionSummary({
    this.mentalPatterns = const [],
    this.emotionalPatterns = const [],
    this.beliefs = const [],
    this.needs = const [],
    this.preferences = const [],
    this.triggers = const [],
  });
}
