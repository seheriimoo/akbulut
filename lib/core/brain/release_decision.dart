enum ReleaseReadiness { hold, regulated, settling, receptive, transitionReady }

class ReleaseDecision {
  final ReleaseReadiness readiness;

  final double confidence;

  const ReleaseDecision({required this.readiness, required this.confidence});
}
