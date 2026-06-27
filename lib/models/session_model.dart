class SomniaSession {
  final String id;
  final String title;
  final String backgroundAssetPath;
  final Duration totalDuration;
  final String breathingType;
  final String goal;

  const SomniaSession({
    required this.id,
    required this.title,
    required this.backgroundAssetPath,
    required this.totalDuration,
    required this.breathingType,
    required this.goal,
  });

  SomniaSession copyWith({
    String? id,
    String? title,
    String? backgroundAssetPath,
    Duration? totalDuration,
    String? breathingType,
    String? goal,
  }) {
    return SomniaSession(
      id: id ?? this.id,
      title: title ?? this.title,
      backgroundAssetPath: backgroundAssetPath ?? this.backgroundAssetPath,
      totalDuration: totalDuration ?? this.totalDuration,
      breathingType: breathingType ?? this.breathingType,
      goal: goal ?? this.goal,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'backgroundAssetPath': backgroundAssetPath,
      'totalDurationInSeconds': totalDuration.inSeconds,
      'breathingType': breathingType,
      'goal': goal,
    };
  }

  factory SomniaSession.fromMap(Map<String, dynamic> map) {
    return SomniaSession(
      id: map['id'] as String,
      title: map['title'] as String,
      backgroundAssetPath: map['backgroundAssetPath'] as String,
      totalDuration: Duration(
        seconds: map['totalDurationInSeconds'] as int,
      ),
      breathingType: map['breathingType'] as String,
      goal: map['goal'] as String,
    );
  }
}