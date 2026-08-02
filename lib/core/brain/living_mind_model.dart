import 'identity.dart';
import 'mental_pattern.dart';
import 'emotional_pattern.dart';
import 'trigger.dart';

class LivingMindModel {
  final Identity identity;

  final List<MentalPattern> mentalPatterns;

  final List<EmotionalPattern> emotionalPatterns;

  final List<Trigger> triggers;

  const LivingMindModel({
    required this.identity,
    required this.mentalPatterns,
    required this.emotionalPatterns,
    required this.triggers,
  });

  LivingMindModel copyWith({
    Identity? identity,
    List<MentalPattern>? mentalPatterns,
    List<EmotionalPattern>? emotionalPatterns,
    List<Trigger>? triggers,
  }) {
    return LivingMindModel(
      identity: identity ?? this.identity,
      mentalPatterns: mentalPatterns ?? this.mentalPatterns,
      emotionalPatterns: emotionalPatterns ?? this.emotionalPatterns,
      triggers: triggers ?? this.triggers,
    );
  }
}
