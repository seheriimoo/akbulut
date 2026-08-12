import 'dart:collection';

/// Temporary same-night user utterance grounding buffer.
///
/// Owned exclusively by [CognitiveOrchestrator].
///
/// Holds the current user utterance plus up to two immediately prior
/// user utterances from the active night.
///
/// Never stores assistant utterances.
/// Never durable. Never written to MemoryEngine or LivingMindModel.
/// Discarded when the NightSession ends.
class ConversationGroundingBuffer {
  /// Current + up to two prior user utterances.
  static const int maxUserUtterances = 3;

  final List<String> _userUtterances;

  const ConversationGroundingBuffer._(this._userUtterances);

  /// Empty buffer (no grounding).
  const ConversationGroundingBuffer.empty() : _userUtterances = const [];

  /// Chronological user utterances in the window (oldest → newest).
  /// Newest entry is the current user utterance when non-empty.
  UnmodifiableListView<String> get userUtterances =>
      UnmodifiableListView<String>(_userUtterances);

  /// Current turn's user utterance, if any.
  String? get currentUserUtterance =>
      _userUtterances.isEmpty ? null : _userUtterances.last;

  /// Up to two prior user utterances (oldest → newest), excluding current.
  UnmodifiableListView<String> get priorUserUtterances {
    if (_userUtterances.length <= 1) {
      return UnmodifiableListView<String>(const <String>[]);
    }
    return UnmodifiableListView<String>(
      _userUtterances.sublist(0, _userUtterances.length - 1),
    );
  }

  bool get isEmpty => _userUtterances.isEmpty;

  /// Records one user utterance into the bounded window.
  ///
  /// Empty/whitespace-only input leaves the buffer unchanged.
  /// Assistant utterances must never be passed here.
  ConversationGroundingBuffer appendUserUtterance(String utterance) {
    final trimmed = utterance.trim();
    if (trimmed.isEmpty) {
      return this;
    }

    final next = <String>[..._userUtterances, trimmed];
    while (next.length > maxUserUtterances) {
      next.removeAt(0);
    }
    return ConversationGroundingBuffer._(List<String>.unmodifiable(next));
  }

  /// Complete discard. Used when the NightSession ends.
  ConversationGroundingBuffer discard() =>
      const ConversationGroundingBuffer.empty();
}
