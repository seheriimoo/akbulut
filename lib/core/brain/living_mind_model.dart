import 'belief.dart';
import 'emotional_pattern.dart';
import 'identity.dart';
import 'mental_pattern.dart';
import 'need.dart';
import 'preference.dart';
import 'trigger.dart';

class LivingMindModel {
  final Identity identity;

  final List<MentalPattern> mentalPatterns;

  final List<EmotionalPattern> emotionalPatterns;

  final List<Trigger> triggers;

  final List<Belief> beliefs;

  final List<Need> needs;

  final List<Preference> preferences;

  const LivingMindModel({
    required this.identity,
    required this.mentalPatterns,
    required this.emotionalPatterns,
    required this.triggers,
    required this.beliefs,
    required this.needs,
    required this.preferences,
  });

  LivingMindModel copyWith({
    Identity? identity,
    List<MentalPattern>? mentalPatterns,
    List<EmotionalPattern>? emotionalPatterns,
    List<Trigger>? triggers,
    List<Belief>? beliefs,
    List<Need>? needs,
    List<Preference>? preferences,
  }) {
    return LivingMindModel(
      identity: identity ?? this.identity,
      mentalPatterns: mentalPatterns ?? this.mentalPatterns,
      emotionalPatterns: emotionalPatterns ?? this.emotionalPatterns,
      triggers: triggers ?? this.triggers,
      beliefs: beliefs ?? this.beliefs,
      needs: needs ?? this.needs,
      preferences: preferences ?? this.preferences,
    );
  }
}
