import 'confidence_engine.dart';
import 'detection_candidate.dart';
import 'need.dart';

class NeedMerger {
  final ConfidenceEngine confidenceEngine;

  const NeedMerger({this.confidenceEngine = const ConfidenceEngine()});

  List<Need> merge(List<Need> existing, List<DetectionCandidate> candidates) {
    final needs = List<Need>.from(existing);

    for (final candidate in candidates) {
      final index = needs.indexWhere((need) => need.id == candidate.id);

      if (index == -1) {
        needs.add(
          Need(
            id: candidate.id,
            name: candidate.name,
            description: candidate.description,
            confidence: confidenceEngine.create(),
            observations: 1,
          ),
        );
        continue;
      }

      final current = needs[index];

      needs[index] = Need(
        id: current.id,
        name: current.name,
        description: candidate.description,
        confidence: confidenceEngine.strengthen(current.confidence),
        observations: current.observations + 1,
      );
    }

    return needs;
  }
}
