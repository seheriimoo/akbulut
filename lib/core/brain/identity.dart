class Identity {
  final String userId;
  final String preferredLanguage;
  final String timezone;
  final DateTime createdAt;
  final DateTime lastInteractionAt;
  final int totalSessions;

  const Identity({
    required this.userId,
    required this.preferredLanguage,
    required this.timezone,
    required this.createdAt,
    required this.lastInteractionAt,
    required this.totalSessions,
  });

  Identity copyWith({
    String? userId,
    String? preferredLanguage,
    String? timezone,
    DateTime? createdAt,
    DateTime? lastInteractionAt,
    int? totalSessions,
  }) {
    return Identity(
      userId: userId ?? this.userId,
      preferredLanguage: preferredLanguage ?? this.preferredLanguage,
      timezone: timezone ?? this.timezone,
      createdAt: createdAt ?? this.createdAt,
      lastInteractionAt: lastInteractionAt ?? this.lastInteractionAt,
      totalSessions: totalSessions ?? this.totalSessions,
    );
  }
}
