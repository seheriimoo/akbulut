class ConfidenceEngine {
  const ConfidenceEngine();

  static const double initialConfidence = 0.30;
  static const double step = 0.05;
  static const double maxConfidence = 0.99;
  static const double minConfidence = 0.0;

  double create() {
    return initialConfidence;
  }

  double strengthen(double confidence) {
    return (confidence + step).clamp(minConfidence, maxConfidence);
  }

  double weaken(double confidence) {
    return (confidence - step).clamp(minConfidence, maxConfidence);
  }
}
