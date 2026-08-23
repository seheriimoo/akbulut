import 'package:flutter/foundation.dart';

import 'conversation_decision.dart';
import 'conversation_grounding_buffer.dart';
import 'conversation_utterance.dart';
import 'exit_decision.dart';
import 'guard_safe_fallback.dart';
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
  /// Does not reopen WHAT, Exit, Release, or protocol.
  ///
  /// After [UtteranceGuard] rejection: never surface the rejected text; emit a
  /// deterministic [GuardSafeFallback] only if that fallback itself admits.
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
      debugPrint('Nocta expression abstain: no LLM package');
      return null;
    }

    final ConversationUtterance utterance;
    try {
      utterance = await languageModelClient.realize(package);
    } on VendorError catch (error) {
      debugPrint(
        'Nocta expression vendor fail: ${error.kind.name} ${error.message}',
      );
      return null;
    } on StateError catch (error) {
      debugPrint('Nocta expression compile/config fail: $error');
      return null;
    }

    final userUtterance =
        package.conversationGrounding?.currentUserUtterance ?? livedExpression;

    final admitted = utteranceGuard.allow(
      utterance: utterance,
      what: package.what,
      userUtterance: userUtterance,
      expressionMode: package.expressionMode,
    );
    if (admitted != null) return admitted;

    debugPrint(
      'Nocta expression Guard reject WHAT=${package.what.name} '
      'text="${utterance.text}"',
    );

    // Guard-safe fallback: never show rejected model text; never LLM rewrite.
    final fallback = GuardSafeFallback.forPhase(
      what: package.what,
      userUtterance: userUtterance,
      expressionMode: package.expressionMode,
      narrowRefinementAfterPartial: package.narrowRefinementAfterPartial,
    );
    if (fallback == null) return null;

    final fallbackAdmitted = utteranceGuard.allow(
      utterance: fallback,
      what: package.what,
      userUtterance: userUtterance,
      expressionMode: package.expressionMode,
    );
    if (fallbackAdmitted == null) {
      debugPrint(
        'Nocta expression Guard fallback also rejected WHAT='
        '${package.what.name} text="${fallback.text}"',
      );
      return null;
    }
    debugPrint(
      'Nocta expression Guard fallback admitted WHAT=${package.what.name}',
    );
    return fallbackAdmitted;
  }
}
