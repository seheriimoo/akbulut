import 'conversation_decision.dart';
import 'exit_decision.dart';
import 'night_session.dart';
import 'release_decision.dart';

/// ExitIntelligence
///
/// Determines whether HCOS should:
///
/// - Continue the conversation
/// - Transition to audio
/// - End in silence
///
/// Owns no language generation.
///
/// Owns no release estimation.
///
/// Owns no memory.
class ExitIntelligence {
  const ExitIntelligence();

  ExitDecision decide({
    required ReleaseDecision releaseDecision,
    required ConversationDecision conversationDecision,
    required NightSession session,
  }) {
    throw UnimplementedError();
  }
}
