import 'conversation_decision.dart';
import 'conversation_utterance.dart';
import 'exit_decision.dart';
import 'language_model_client.dart';
import 'prompt_architecture.dart';
import 'utterance_guard.dart';
import 'validated_understanding.dart';
import 'working_mind_view.dart';

/// ConversationEngine
///
/// Expression stage only. Renders language after upstream decisions.
///
/// Required inputs: ConversationDecision, ExitDecision.
/// Optional inputs: ValidatedUnderstanding, WorkingMindView (shaping only).
///
/// Output: one ConversationUtterance, or no conversational language.
///
/// Owns no release, protocol, exit, or memory decisions.
class ConversationEngine {
  final PromptArchitecture promptArchitecture;

  final LanguageModelClient languageModelClient;

  final UtteranceGuard utteranceGuard;

  const ConversationEngine({
    this.promptArchitecture = const PromptArchitecture(),
    this.languageModelClient = const LanguageModelClient(),
    this.utteranceGuard = const UtteranceGuard(),
  });

  /// Emits exactly one speech outcome for the turn:
  /// a single [ConversationUtterance], or `null` for no conversational language.
  ///
  /// Expression path:
  /// PromptArchitecture → (abstain | LanguageModelClient) → UtteranceGuard.
  ConversationUtterance? generate({
    required ConversationDecision conversationDecision,
    required ExitDecision exitDecision,
    ValidatedUnderstanding? understanding,
    WorkingMindView? workingMind,
  }) {
    final package = promptArchitecture.package(
      conversationDecision: conversationDecision,
      exitDecision: exitDecision,
      understanding: understanding,
      workingMind: workingMind,
    );

    if (package == null) {
      return null;
    }

    final utterance = languageModelClient.realize(package);

    return utteranceGuard.allow(
      utterance: utterance,
      what: package.what,
    );
  }
}
