class SleepAnalysisResult {
  final String category;
  final String title;
  final String summary;
  final String recommendedSessionId;
  final String recommendedSessionTitle;

  const SleepAnalysisResult({
    required this.category,
    required this.title,
    required this.summary,
    required this.recommendedSessionId,
    required this.recommendedSessionTitle,
  });
}