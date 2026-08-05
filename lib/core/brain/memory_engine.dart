import 'knowledge_merger.dart';
import 'living_mind_model.dart';
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
      mentalPatterns: summary.mentalPatterns.isEmpty
          ? model.mentalPatterns
          : summary.mentalPatterns,
      emotionalPatterns: summary.emotionalPatterns.isEmpty
          ? model.emotionalPatterns
          : summary.emotionalPatterns,
      triggers: summary.triggers.isEmpty ? model.triggers : summary.triggers,
      beliefs: beliefs,
      needs: needs,
      preferences: summary.preferences.isEmpty
          ? model.preferences
          : summary.preferences,
    );
  }
}
