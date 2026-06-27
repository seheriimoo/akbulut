class SleepSession {
  final String id;
  final String title;
  final Duration duration;
  final String backgroundAsset;
  final String? voiceAsset;
  final double backgroundVolume;
  final double voiceVolume;
  final Duration fadeOutDuration;

  const SleepSession({
    required this.id,
    required this.title,
    required this.duration,
    required this.backgroundAsset,
    this.voiceAsset,
    this.backgroundVolume = 0.22,
    this.voiceVolume = 1.0,
    this.fadeOutDuration = const Duration(seconds: 20),
  });
}
