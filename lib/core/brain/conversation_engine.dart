import 'conversation_decision.dart';
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
    throw UnimplementedError();
  }
}
