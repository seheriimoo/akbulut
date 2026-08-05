import 'conversation_phase.dart';
import 'conversation_utterance.dart';
import 'llm_invocation_package.dart';

/// LanguageModelClient
///
/// HOW-only expression adapter for the Conversation plane.
///
/// Accepts exactly one [LlmInvocationPackage] and returns exactly one
/// [ConversationUtterance] realizing the sealed WHAT as natural language.
///
/// Does not decide WHAT, release, protocol, or exit.
/// Does not write memory.
/// Does not call an external LLM API (deterministic placeholder only).
class LanguageModelClient {
  const LanguageModelClient();

  /// Realize [package.what] as a single natural-language utterance.
  ConversationUtterance realize(LlmInvocationPackage package) {
    return ConversationUtterance(text: _placeholderFor(package.what));
  }

  /// Deterministic placeholder. No external model. No decision ownership.
  String _placeholderFor(ConversationPhase what) {
    switch (what) {
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
      case ConversationPhase.silence:
        // Non-speech phases are abstained by Prompt Architecture before invoke.
        // Exhaustiveness only; not an authorized HOW path.
        return '';
    }
  }
}
