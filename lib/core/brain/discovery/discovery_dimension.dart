/// Cognitive dimensions the Adaptive Night Mind Discovery layer may resolve.
///
/// Semantic memory keys — not user-facing question strings.
enum DiscoveryDimension {
  /// Past / present / future orientation of the night concern.
  temporalOrientation,

  /// Domain object (tomorrow, meeting, relationship, body, unfinished task…).
  topicDomain,

  /// Form of thought (single worry vs multiplying scenarios vs replay…).
  thoughtForm,

  /// Soft job of thinking (preparedness, certainty, holding…).
  thinkingFunction,

  /// What the person believes thinking gives them.
  perceivedUtility,

  /// Whether that job actually closes or perpetuates the loop.
  actualEffect,

  /// Sketch of the repeating structure.
  loopStructure,

  /// Affective driver when evidenced (not invented).
  emotionalDriver,

  /// Cognitive vs somatic arousal emphasis.
  arousalType,

  /// What still feels unfinished if they stop.
  unresolvedNeed,
}
