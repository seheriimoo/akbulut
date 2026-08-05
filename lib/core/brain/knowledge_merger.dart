import 'belief.dart';
import 'confidence_engine.dart';

/// KnowledgeMerger
///
/// Merges durable Belief knowledge into the Living Mind Model.
///
/// Used only by MemoryEngine.
class KnowledgeMerger {
  final ConfidenceEngine confidenceEngine;

  const KnowledgeMerger({this.confidenceEngine = const ConfidenceEngine()});

  List<Belief> merge(List<Belief> existing, List<Belief> incoming) {
    final beliefs = List<Belief>.from(existing);

    for (final belief in incoming) {
      final index = beliefs.indexWhere((item) => item.id == belief.id);

      if (index == -1) {
        beliefs.add(
          Belief(
            id: belief.id,
            name: belief.name,
            description: belief.description,
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
        description: belief.description,
        confidence: confidenceEngine.strengthen(current.confidence),
        observations: current.observations + 1,
      );
    }

    return beliefs;
  }
}
