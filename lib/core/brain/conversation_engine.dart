import 'conversation_decision.dart';
import 'conversation_grounding_buffer.dart';
import 'conversation_utterance.dart';
import 'exit_decision.dart';
import 'language_model_client.dart';
import 'prior_admitted_expression.dart';
import 'prompt_architecture.dart';
import 'utterance_guard.dart';
import 'validated_understanding.dart';
import 'vendor_provider.dart';
import 'working_mind_view.dart';

/// ConversationEngine
///
/// Expression stage only. Renders language after upstream decisions.
///
/// Required inputs: ConversationDecision, ExitDecision.
/// Optional inputs: ValidatedUnderstanding, WorkingMindView,
/// ConversationGroundingBuffer, livedExpression (shaping only).
///
/// Output: one ConversationUtterance, or no conversational language.
///
/// Owns no release, protocol, exit, or memory decisions.
/// Does not own or invent conversation grounding.
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
  /// PromptArchitecture → (abstain | LanguageModelClient
  ///   [ConversationCompiler → VendorProvider]) → UtteranceGuard.
  ///
  /// On [LanguageModelClient] / [VendorError] failure, fails closed to `null`.
  /// Does not reopen WHAT, Exit, Release, or protocol. Does not retry after
  /// [UtteranceGuard] rejection.
  Future<ConversationUtterance?> generate({
    required ConversationDecision conversationDecision,
    required ExitDecision exitDecision,
    ValidatedUnderstanding? understanding,
    WorkingMindView? workingMind,
    String? livedExpression,
    ConversationGroundingBuffer? conversationGrounding,
    PriorAdmittedExpression? priorAdmittedExpression,
  }) async {
    final package = promptArchitecture.package(
      conversationDecision: conversationDecision,
      exitDecision: exitDecision,
      understanding: understanding,
      workingMind: workingMind,
      livedExpression: livedExpression,
      conversationGrounding: conversationGrounding,
      priorAdmittedExpression: priorAdmittedExpression,
    );

    if (package == null) {
      return null;
    }

    final ConversationUtterance utterance;
    try {
      utterance = await languageModelClient.realize(package);
    } on VendorError {
      // Expression-plane failure → no conversational language.
      // Upstream ExitDecision / protocol remain authoritative.
      return null;
    } on StateError {
      // Package integrity / configuration failure before a candidate exists.
      return null;
    }

    // Guard reject → null. Not a retry trigger.
    return utteranceGuard.allow(
      utterance: utterance,
      what: package.what,
    );
  }
}
