import 'confidence_engine.dart';
import 'need.dart';

/// NeedMerger
///
/// Merges durable Need knowledge into the Living Mind Model.
///
/// Used only by MemoryEngine.
class NeedMerger {
  final ConfidenceEngine confidenceEngine;

  const NeedMerger({this.confidenceEngine = const ConfidenceEngine()});

  List<Need> merge(List<Need> existing, List<Need> incoming) {
    final needs = List<Need>.from(existing);

    for (final need in incoming) {
      final index = needs.indexWhere((item) => item.id == need.id);

      if (index == -1) {
        needs.add(
          Need(
            id: need.id,
            name: need.name,
            description: need.description,
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
        description: need.description,
        confidence: confidenceEngine.strengthen(current.confidence),
        observations: current.observations + 1,
      );
    }

    return needs;
  }
}
