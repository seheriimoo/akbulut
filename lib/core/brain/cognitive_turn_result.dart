import 'conversation_decision.dart';
import 'conversation_utterance.dart';
import 'exit_decision.dart';
import 'night_session.dart';
import 'release_decision.dart';

/// Result of one HCOS cognitive turn.
///
/// Returned by CognitiveOrchestrator.
///
/// Immutable.
class CognitiveTurnResult {
  final NightSession session;

  final ReleaseDecision releaseDecision;

  final ConversationDecision conversationDecision;

  final ExitDecision exitDecision;

  final ConversationUtterance? utterance;

  const CognitiveTurnResult({
    required this.session,
    required this.releaseDecision,
    required this.conversationDecision,
    required this.exitDecision,
    this.utterance,
  });
}
