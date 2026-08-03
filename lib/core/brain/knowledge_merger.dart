import 'belief.dart';
import 'confidence_engine.dart';
import 'detection_candidate.dart';

class KnowledgeMerger {
  final ConfidenceEngine confidenceEngine;

  const KnowledgeMerger({this.confidenceEngine = const ConfidenceEngine()});

  List<Belief> merge(
    List<Belief> existing,
    List<DetectionCandidate> candidates,
  ) {
    final beliefs = List<Belief>.from(existing);

    for (final candidate in candidates) {
      final index = beliefs.indexWhere((belief) => belief.id == candidate.id);

      if (index == -1) {
        beliefs.add(
          Belief(
            id: candidate.id,
            name: candidate.name,
            description: candidate.description,
            confidence: confidenceEngine.create(),
            observations: 1,
          ),
        );

        continue;
      }

      final current = beliefs[index];

      beliefs[index] = Belief(
        id: current.id,
        name: current.name,
        description: candidate.description,
        confidence: confidenceEngine.strengthen(current.confidence),
        observations: current.observations + 1,
      );
    }

    return beliefs;
  }
}
