import 'detection_candidate.dart';
import 'emotional_pattern.dart';
import 'mental_pattern.dart';
import 'preference.dart';
import 'thinking_function_hypothesis.dart';
import 'turn_response_stance.dart';

class ValidatedUnderstanding {
  final List<MentalPattern> mentalPatterns;
  final List<EmotionalPattern> emotionalPatterns;
  final List<DetectionCandidate> beliefCandidates;
  final List<DetectionCandidate> needCandidates;
  final List<Preference> preferences;

  /// Temporary turn-response stance. Not persisted into LivingMindModel.
  final TurnResponseStance turnResponseStance;

  /// Soft thinking-function hypothesis. Cognition/shaping evidence only.
  /// Night-scoped; not persisted into LivingMindModel.
  /// Must not choose phase, readiness, exit, memory, or live wording by itself.
  final ThinkingFunctionHypothesis? thinkingFunctionHypothesis;

  const ValidatedUnderstanding({
    this.mentalPatterns = const [],
    this.emotionalPatterns = const [],
    this.beliefCandidates = const [],
    this.needCandidates = const [],
    this.preferences = const [],
    this.turnResponseStance = TurnResponseStance.unclear,
    this.thinkingFunctionHypothesis,
  });
}
