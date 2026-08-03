import 'knowledge_merger.dart';
import 'living_mind_model.dart';
import 'need_merger.dart';
import 'validated_understanding.dart';

class MemoryEngine {
  final KnowledgeMerger knowledgeMerger;
  final NeedMerger needMerger;

  const MemoryEngine({
    this.knowledgeMerger = const KnowledgeMerger(),
    this.needMerger = const NeedMerger(),
  });

  LivingMindModel update(
    LivingMindModel model,
    ValidatedUnderstanding understanding,
  ) {
    final beliefs = knowledgeMerger.merge(
      model.beliefs,
      understanding.beliefCandidates,
    );

    final needs = needMerger.merge(model.needs, understanding.needCandidates);

    return model.copyWith(
      mentalPatterns: understanding.mentalPatterns.isEmpty
          ? model.mentalPatterns
          : understanding.mentalPatterns,
      emotionalPatterns: understanding.emotionalPatterns.isEmpty
          ? model.emotionalPatterns
          : understanding.emotionalPatterns,
      beliefs: beliefs,
      needs: needs,
      preferences: understanding.preferences.isEmpty
          ? model.preferences
          : understanding.preferences,
    );
  }
}
