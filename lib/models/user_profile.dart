class SomniaUserProfile {
  final int sleepLatencyMinutes;
  final bool hasRacingThoughts;
  final int stressLevel;
  final String sleepGoal;

  const SomniaUserProfile({
    required this.sleepLatencyMinutes,
    required this.hasRacingThoughts,
    required this.stressLevel,
    required this.sleepGoal,
  });

  SomniaUserProfile copyWith({
    int? sleepLatencyMinutes,
    bool? hasRacingThoughts,
    int? stressLevel,
    String? sleepGoal,
  }) {
    return SomniaUserProfile(
      sleepLatencyMinutes:
          sleepLatencyMinutes ?? this.sleepLatencyMinutes,
      hasRacingThoughts:
          hasRacingThoughts ?? this.hasRacingThoughts,
      stressLevel: stressLevel ?? this.stressLevel,
      sleepGoal: sleepGoal ?? this.sleepGoal,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'sleepLatencyMinutes': sleepLatencyMinutes,
      'hasRacingThoughts': hasRacingThoughts,
      'stressLevel': stressLevel,
      'sleepGoal': sleepGoal,
    };
  }

  factory SomniaUserProfile.fromMap(Map<String, dynamic> map) {
    return SomniaUserProfile(
      sleepLatencyMinutes: map['sleepLatencyMinutes'] as int,
      hasRacingThoughts: map['hasRacingThoughts'] as bool,
      stressLevel: map['stressLevel'] as int,
      sleepGoal: map['sleepGoal'] as String,
    );
  }
}