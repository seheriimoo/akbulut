import 'emotional_pattern.dart';
import 'knowledge_merger.dart';
import 'living_mind_model.dart';
import 'mental_pattern.dart';
import 'need_merger.dart';
import 'session_summary.dart';

/// MemoryEngine
///
/// Sole writer of the Living Mind Model.
///
/// Accepts durable SessionSummary knowledge only.
///
/// Does not extract session knowledge.
///
/// Does not own conversation or exit decisions.
class MemoryEngine {
  final KnowledgeMerger knowledgeMerger;
  final NeedMerger needMerger;

  const MemoryEngine({
    this.knowledgeMerger = const KnowledgeMerger(),
    this.needMerger = const NeedMerger(),
  });

  LivingMindModel update(LivingMindModel model, SessionSummary summary) {
    final beliefs = knowledgeMerger.merge(model.beliefs, summary.beliefs);
    final needs = needMerger.merge(model.needs, summary.needs);

    return model.copyWith(
      identity: model.identity.copyWith(
        totalSessions: model.identity.totalSessions + 1,
        lastInteractionAt: DateTime.now().toUtc(),
      ),
      mentalPatterns: _mergeMental(model.mentalPatterns, summary.mentalPatterns),
      emotionalPatterns:
          _mergeEmotional(model.emotionalPatterns, summary.emotionalPatterns),
      triggers: summary.triggers.isEmpty ? model.triggers : summary.triggers,
      beliefs: beliefs,
      needs: needs,
      preferences: summary.preferences.isEmpty
          ? model.preferences
          : summary.preferences,
    );
  }

  List<MentalPattern> _mergeMental(
    List<MentalPattern> prior,
    List<MentalPattern> incoming,
  ) {
    if (incoming.isEmpty) return prior;
    final map = <String, MentalPattern>{
      for (final p in prior) p.id: p,
    };
    for (final p in incoming) {
      final old = map[p.id];
      if (old == null) {
        map[p.id] = p;
      } else {
        map[p.id] = p.copyWith(
          observations: old.observations + p.observations,
          confidence:
              p.confidence > old.confidence ? p.confidence : old.confidence,
        );
      }
    }
    return map.values.toList(growable: false);
  }

  List<EmotionalPattern> _mergeEmotional(
    List<EmotionalPattern> prior,
    List<EmotionalPattern> incoming,
  ) {
    if (incoming.isEmpty) return prior;
    final map = <String, EmotionalPattern>{
      for (final p in prior) p.id: p,
    };
    for (final p in incoming) {
      final old = map[p.id];
      if (old == null) {
        map[p.id] = p;
      } else {
        map[p.id] = p.copyWith(
          observations: old.observations + p.observations,
          confidence:
              p.confidence > old.confidence ? p.confidence : old.confidence,
        );
      }
    }
    return map.values.toList(growable: false);
  }
}
