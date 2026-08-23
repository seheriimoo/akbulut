import 'package:flutter/foundation.dart';

import 'closure_fallback_builder.dart';
import 'conversation_decision.dart';
import 'conversation_expression_mode.dart';
import 'conversation_grounding_buffer.dart';
import 'conversation_phase.dart';
import 'conversation_utterance.dart';
import 'exit_decision.dart';
import 'guard_safe_fallback.dart';
import 'language_model_client.dart';
import 'llm_invocation_package.dart';
import 'mode_safe_terminal_fallback.dart';
import 'night_session.dart';
import 'prior_admitted_expression.dart';
import 'prompt_architecture.dart';
import 'user_object_mirror.dart';
import 'utterance_guard.dart';
import 'validated_understanding.dart';
import 'vendor_provider.dart';
import 'working_mind_view.dart';

/// ConversationEngine
///
/// Expression stage only. Renders language after upstream decisions.
class ConversationEngine {
  final PromptArchitecture promptArchitecture;

  final LanguageModelClient languageModelClient;

  final UtteranceGuard utteranceGuard;

  const ConversationEngine({
    this.promptArchitecture = const PromptArchitecture(),
    this.languageModelClient = const LanguageModelClient(),
    this.utteranceGuard = const UtteranceGuard(),
  });

  Future<ConversationUtterance?> generate({
    required ConversationDecision conversationDecision,
    required ExitDecision exitDecision,
    ValidatedUnderstanding? understanding,
    WorkingMindView? workingMind,
    String? livedExpression,
    ConversationGroundingBuffer? conversationGrounding,
    PriorAdmittedExpression? priorAdmittedExpression,
    NightSession? nightSession,
  }) async {
    final userUtterance =
        conversationGrounding?.currentUserUtterance ?? livedExpression;

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
      return _zeroSilenceTerminal(
        conversationDecision: conversationDecision,
        exitDecision: exitDecision,
        userUtterance: userUtterance,
        reason: 'package abstain',
      );
    }

    final ConversationUtterance utterance;
    try {
      utterance = await languageModelClient.realize(package);
    } on VendorError catch (error) {
      debugPrint(
        'Nocta expression vendor fail: ${error.kind.name} ${error.message}',
      );
      return _zeroSilenceTerminal(
        conversationDecision: conversationDecision,
        exitDecision: exitDecision,
        userUtterance: userUtterance,
        reason: 'vendor fail',
        package: package,
      );
    } on StateError catch (error) {
      debugPrint('Nocta expression compile/config fail: $error');
      return _zeroSilenceTerminal(
        conversationDecision: conversationDecision,
        exitDecision: exitDecision,
        userUtterance: userUtterance,
        reason: 'compile fail',
        package: package,
      );
    }

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

    final fallback = GuardSafeFallback.forPhase(
      what: package.what,
      userUtterance: userUtterance,
      expressionMode: package.expressionMode,
      narrowRefinementAfterPartial: package.narrowRefinementAfterPartial,
      session: nightSession,
      grounding: package.conversationGrounding,
    );
    if (fallback == null) {
      if (package.expressionMode == ConversationExpressionMode.closure) {
        final closureOnly = ClosureFallbackBuilder.forValidation(
          userUtterance: userUtterance,
          session: nightSession,
          grounding: package.conversationGrounding,
        );
        final closureAdmitted = utteranceGuard.allow(
          utterance: closureOnly,
          what: package.what,
          userUtterance: userUtterance,
          expressionMode: package.expressionMode,
        );
        if (closureAdmitted != null) return closureAdmitted;
      }
      return _admitTerminalFallback(
        what: package.what,
        expressionMode: package.expressionMode,
        narrowRefinementAfterPartial: package.narrowRefinementAfterPartial,
        userUtterance: userUtterance,
        priorRejectedText: utterance.text,
        reason: 'primary fallback null',
      );
    }

    final fallbackAdmitted = utteranceGuard.allow(
      utterance: fallback,
      what: package.what,
      userUtterance: userUtterance,
      mirrorGroundingUtterance: UserObjectMirror.mirrorEvidenceSource(
        userUtterance: userUtterance,
        groundingBlob: package.conversationGrounding?.userUtterances
            .map((u) => u)
            .join(' '),
      ),
      expressionMode: package.expressionMode,
    );
    if (fallbackAdmitted == null) {
      debugPrint(
        'Nocta expression Guard fallback also rejected WHAT='
        '${package.what.name} text="${fallback.text}"',
      );
      return _admitTerminalFallback(
        what: package.what,
        expressionMode: package.expressionMode,
        narrowRefinementAfterPartial: package.narrowRefinementAfterPartial,
        userUtterance: userUtterance,
        priorRejectedText: fallback.text,
        reason: 'fallback double-reject',
      );
    }
    debugPrint(
      'Nocta expression Guard fallback admitted WHAT=${package.what.name}',
    );
    return fallbackAdmitted;
  }

  ConversationUtterance? _zeroSilenceTerminal({
    required ConversationDecision conversationDecision,
    required ExitDecision exitDecision,
    required String? userUtterance,
    required String reason,
    LlmInvocationPackage? package,
  }) {
    if (!_requiresZeroSilence(conversationDecision, exitDecision)) {
      return null;
    }
    return _admitTerminalFallback(
      what: package?.what ?? conversationDecision.phase,
      expressionMode:
          package?.expressionMode ?? conversationDecision.expressionMode,
      narrowRefinementAfterPartial: package?.narrowRefinementAfterPartial ??
          conversationDecision.narrowRefinementAfterPartial,
      userUtterance: userUtterance,
      priorRejectedText: '',
      reason: reason,
    );
  }

  bool _requiresZeroSilence(
    ConversationDecision conversationDecision,
    ExitDecision exitDecision,
  ) {
    if (!conversationDecision.shouldSpeak) return false;
    if (exitDecision == ExitDecision.silence) return false;
    switch (conversationDecision.phase) {
      case ConversationPhase.audio:
      case ConversationPhase.silence:
        return false;
      case ConversationPhase.validation:
      case ConversationPhase.naming:
      case ConversationPhase.permission:
      case ConversationPhase.release:
      case ConversationPhase.continuity:
      case ConversationPhase.neutralEntry:
        return true;
    }
  }

  ConversationUtterance? _admitTerminalFallback({
    required ConversationPhase what,
    required ConversationExpressionMode expressionMode,
    required bool narrowRefinementAfterPartial,
    required String? userUtterance,
    required String priorRejectedText,
    required String reason,
  }) {
    final terminal = ModeSafeTerminalFallback.forExpression(
      what: what,
      expressionMode: expressionMode,
      userUtterance: userUtterance,
      narrowRefinementAfterPartial: narrowRefinementAfterPartial,
    );
    if (terminal == null) {
      debugPrint(
        'Nocta expression terminal abstain WHAT=${what.name} reason=$reason',
      );
      return null;
    }

    final admitted = utteranceGuard.allow(
      utterance: terminal,
      what: what,
      userUtterance: userUtterance,
      expressionMode: expressionMode,
    );
    if (admitted == null) {
      debugPrint(
        'Nocta expression CRITICAL terminal rejected WHAT=${what.name} '
        'mode=${expressionMode.name} text="${terminal.text}" '
        'reason=$reason prior="$priorRejectedText"',
      );
      return _zeroSilenceSurfaceRetreat(
        what: what,
        userUtterance: userUtterance,
        expressionMode: expressionMode,
      );
    }
    debugPrint(
      'Nocta expression terminal fallback admitted WHAT=${what.name} '
      'mode=${expressionMode.name} reason=$reason',
    );
    return admitted;
  }

  /// B2.2.1 — Hard zero-silence retreat when mode terminal fails Guard.
  ConversationUtterance? _zeroSilenceSurfaceRetreat({
    required ConversationPhase what,
    required String? userUtterance,
    required ConversationExpressionMode expressionMode,
  }) {
    if (what != ConversationPhase.validation) return null;

    final mirror = UserObjectMirror.forValidation(
      userUtterance: userUtterance,
      expressionMode: expressionMode,
    );
    if (mirror != null) {
      final admitted = utteranceGuard.allow(
        utterance: mirror,
        what: what,
        userUtterance: userUtterance,
        mirrorGroundingUtterance: UserObjectMirror.mirrorEvidenceSource(
          userUtterance: userUtterance,
        ),
        expressionMode: expressionMode,
      );
      if (admitted != null) {
        debugPrint(
          'Nocta expression zero-silence surface retreat admitted WHAT='
          '${what.name}',
        );
        return admitted;
      }
    }

    for (final fallbackMode in const [
      ConversationExpressionMode.postReframeListen,
      ConversationExpressionMode.standard,
    ]) {
      final line = ModeSafeTerminalFallback.forExpression(
        what: what,
        expressionMode: fallbackMode,
        userUtterance: userUtterance,
      );
      if (line == null) continue;
      final ok = utteranceGuard.allow(
        utterance: line,
        what: what,
        userUtterance: userUtterance,
        expressionMode: fallbackMode,
      );
      if (ok != null) {
        debugPrint(
          'Nocta expression zero-silence mode retreat admitted WHAT='
          '${what.name} mode=${fallbackMode.name}',
        );
        return ok;
      }
    }
    return null;
  }
}
