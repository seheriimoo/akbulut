import 'conversation_decision.dart';
import 'conversation_phase.dart';
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
    if (conversationDecision.phase == ConversationPhase.audio) {
      return ExitDecision.transitionToAudio;
    }

    if (!conversationDecision.shouldSpeak) {
      return ExitDecision.silence;
    }

    return ExitDecision.continueConversation;
  }
}
