import 'detection_candidate.dart';
import 'emotional_pattern.dart';
import 'mental_pattern.dart';
import 'preference.dart';

class ValidatedUnderstanding {
  final List<MentalPattern> mentalPatterns;
  final List<EmotionalPattern> emotionalPatterns;
  final List<DetectionCandidate> beliefCandidates;
  final List<DetectionCandidate> needCandidates;
  final List<Preference> preferences;

  const ValidatedUnderstanding({
    this.mentalPatterns = const [],
    this.emotionalPatterns = const [],
    this.beliefCandidates = const [],
    this.needCandidates = const [],
    this.preferences = const [],
  });
}
