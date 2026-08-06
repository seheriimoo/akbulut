import 'belief.dart';
import 'mental_pattern.dart';
import 'need.dart';
import 'preference.dart';

// ignore_for_file: deprecated_member_use_from_same_package

/// Deprecated decision producer output.
///
/// Sprint 6 Cutover: production decisions are owned by ReleaseEngine,
/// ConversationPolicy, and ExitIntelligence. Do not use in production paths.
@Deprecated(
  'Sprint 6 Cutover: ReasoningDecision is deprecated; use CognitiveTurnResult',
)
enum ReasoningDecision { askQuestion, provideReflection }

/// Deprecated decision producer.
///
/// Sprint 6 Cutover: not a production cognitive owner.
@Deprecated(
  'Sprint 6 Cutover: ReasoningEngine is deprecated as a decision producer',
)
class ReasoningEngine {
  const ReasoningEngine();

  @Deprecated(
    'Sprint 6 Cutover: ReasoningEngine is deprecated as a decision producer',
  )
  ReasoningDecision decide({
    required List<MentalPattern> mentalPatterns,
    required List<Belief> beliefs,
    required List<Need> needs,
    required List<Preference> preferences,
  }) {
    if (mentalPatterns.isNotEmpty) {
      return ReasoningDecision.askQuestion;
    }

    if (beliefs.isNotEmpty) {
      return ReasoningDecision.askQuestion;
    }

    if (needs.isNotEmpty) {
      return ReasoningDecision.provideReflection;
    }

    if (preferences.isNotEmpty) {
      return ReasoningDecision.provideReflection;
    }

    return ReasoningDecision.provideReflection;
  }
}
