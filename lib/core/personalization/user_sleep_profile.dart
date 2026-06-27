class UserSleepProfile {
  final String sleepLatency;
  final String stressLevel;
  final String sleepGoal;

  const UserSleepProfile({
    required this.sleepLatency,
    required this.stressLevel,
    required this.sleepGoal,
  });

  UserSleepProfile copyWith({
    String? sleepLatency,
    String? stressLevel,
    String? sleepGoal,
  }) {
    return UserSleepProfile(
      sleepLatency: sleepLatency ?? this.sleepLatency,
      stressLevel: stressLevel ?? this.stressLevel,
      sleepGoal: sleepGoal ?? this.sleepGoal,
    );
  }
}
