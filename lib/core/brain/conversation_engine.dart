import 'conversation_decision.dart';
import 'conversation_phase.dart';
import 'conversation_utterance.dart';
import 'validated_understanding.dart';
import 'working_mind_view.dart';

/// ConversationEngine
///
/// Generates the minimum helpful language.
///
/// It never decides whether HCOS should speak.
///
/// It only renders language when permitted by
/// ConversationPolicy and ExitIntelligence.
///
/// Owns no release estimation.
///
/// Owns no memory.
///
/// Owns no exit decisions.
class ConversationEngine {
  const ConversationEngine();

  ConversationUtterance generate({
    required ConversationDecision conversationDecision,
    required ValidatedUnderstanding understanding,
    required WorkingMindView workingMind,
  }) {
    // Language generation only.
    // Release, exit, readiness, and memory ownership remain elsewhere.
    // understanding and workingMind are accepted for the orchestrator
    // contract; this placeholder does not read them.
    return ConversationUtterance(
      text: _placeholderTextFor(conversationDecision.phase),
    );
  }

  /// Deterministic production placeholder.
  ///
  /// Renders protocol phase as fixed language.
  /// No prompting. No personality. No memory.
  String _placeholderTextFor(ConversationPhase phase) {
    switch (phase) {
      case ConversationPhase.validation:
        return 'That makes sense.';
      case ConversationPhase.naming:
        return 'Something is still holding on.';
      case ConversationPhase.permission:
        return 'You do not have to solve this tonight.';
      case ConversationPhase.release:
        return 'You can let this rest for now.';
      case ConversationPhase.continuity:
        return 'Nothing more is needed right now.';
      case ConversationPhase.audio:
        return '';
      case ConversationPhase.silence:
        return '';
    }
  }
}
