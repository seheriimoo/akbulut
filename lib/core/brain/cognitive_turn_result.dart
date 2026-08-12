import 'conversation_decision.dart';
import 'conversation_grounding_buffer.dart';
import 'conversation_utterance.dart';
import 'exit_decision.dart';
import 'night_session.dart';
import 'release_decision.dart';

/// Result of one HCOS cognitive turn.
///
/// Returned by CognitiveOrchestrator.
///
/// Immutable.
///
/// [conversationGroundingBuffer] is temporary night-scoped user grounding
/// owned by CognitiveOrchestrator and carried by the session host across turns.
/// It is not SessionTurn decision data and must never enter durable memory.
class CognitiveTurnResult {
  final NightSession session;

  final ReleaseDecision releaseDecision;

  final ConversationDecision conversationDecision;

  final ExitDecision exitDecision;

  final ConversationUtterance? utterance;

  /// Snapshot of the Orchestrator-owned temporary grounding buffer after this turn.
  final ConversationGroundingBuffer conversationGroundingBuffer;

  const CognitiveTurnResult({
    required this.session,
    required this.releaseDecision,
    required this.conversationDecision,
    required this.exitDecision,
    this.utterance,
    this.conversationGroundingBuffer = const ConversationGroundingBuffer.empty(),
  });
}
