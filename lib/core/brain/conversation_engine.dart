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
    if (!conversationDecision.shouldSpeak) {
      return const ConversationUtterance(text: '');
    }

    switch (conversationDecision.phase) {
      case ConversationPhase.validation:
        return const ConversationUtterance(text: "I'm here with you.");

      case ConversationPhase.naming:
        return const ConversationUtterance(
          text: "Let's gently name what's happening.",
        );

      case ConversationPhase.permission:
        return const ConversationUtterance(
          text: "It's okay to let this be here.",
        );

      case ConversationPhase.release:
        return const ConversationUtterance(
          text: "You don't have to carry everything tonight.",
        );

      case ConversationPhase.continuity:
        return const ConversationUtterance(
          text: "We'll take this one step at a time.",
        );

      case ConversationPhase.audio:
        return const ConversationUtterance(text: "");

      case ConversationPhase.silence:
        return const ConversationUtterance(text: "");
    }
  }
}
