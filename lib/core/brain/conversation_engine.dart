import 'package:flutter/foundation.dart';

import 'closure_fallback_builder.dart';
import 'conversation_decision.dart';
import 'conversation_expression_mode.dart';
import 'conversation_grounding_buffer.dart';
import 'conversation_phase.dart';
import 'conversation_utterance.dart';
import 'exit_decision.dart';
import 'guard_safe_fallback.dart';
import 'hold_act_dedup.dart';
import 'language_model_client.dart';
import 'llm_invocation_package.dart';
import 'mode_safe_terminal_fallback.dart';
import 'night_session.dart';
import 'prior_admitted_expression.dart';
import 'prompt_architecture.dart';
import 'reframe_evidence_reader.dart';
import 'user_object_mirror.dart';
import 'listen_only_preference.dart';
import 'session_locale.dart';
import 'surface_utterance_kind.dart';
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
    String sessionVentCorpus = '',
  }) async {
    final userUtterance =
        conversationGrounding?.currentUserUtterance ?? livedExpression;
    final expressionGrounding = _expressionGroundingBlob(
      conversationGrounding: conversationGrounding,
      sessionVentCorpus: sessionVentCorpus,
    );
    final listenOnlyActive = ListenOnlyPreference.isActive(
      currentMessage: userUtterance,
      grounding: conversationGrounding,
      sessionVentCorpus: sessionVentCorpus,
    );

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
        nightSession: nightSession,
        conversationGrounding: conversationGrounding,
        expressionGrounding: expressionGrounding,
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
        nightSession: nightSession,
        conversationGrounding: conversationGrounding,
        expressionGrounding: expressionGrounding,
      );
    } on StateError catch (error) {
      debugPrint('Nocta expression compile/config fail: $error');
      return _zeroSilenceTerminal(
        conversationDecision: conversationDecision,
        exitDecision: exitDecision,
        userUtterance: userUtterance,
        reason: 'compile fail',
        package: package,
        nightSession: nightSession,
        conversationGrounding: conversationGrounding,
        expressionGrounding: expressionGrounding,
      );
    }

    final reframeLedger =
        package.expressionMode == ConversationExpressionMode.reframe
            ? ReframeEvidenceReader.fromGrounding(package.conversationGrounding)
            : null;

    final admitted = utteranceGuard.allow(
      utterance: utterance,
      what: package.what,
      userUtterance: userUtterance,
      mirrorGroundingUtterance: expressionGrounding,
      expressionMode: package.expressionMode,
      reframeEvidenceLedger: reframeLedger,
      listenOnlyActive: listenOnlyActive,
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
      sessionVentCorpus: sessionVentCorpus,
      listenOnlyActive: listenOnlyActive,
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
        nightSession: nightSession,
        conversationGrounding: package.conversationGrounding,
        groundingBlob: expressionGrounding,
        listenOnlyActive: listenOnlyActive,
        sessionVentCorpus: sessionVentCorpus,
      );
    }

    final fallbackAdmitted = utteranceGuard.allow(
      utterance: fallback,
      what: package.what,
      userUtterance: userUtterance,
      mirrorGroundingUtterance: expressionGrounding,
      expressionMode: package.expressionMode,
      reframeEvidenceLedger: reframeLedger,
      listenOnlyActive: listenOnlyActive,
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
        nightSession: nightSession,
        conversationGrounding: package.conversationGrounding,
        groundingBlob: expressionGrounding,
        listenOnlyActive: listenOnlyActive,
        sessionVentCorpus: sessionVentCorpus,
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
    NightSession? nightSession,
    ConversationGroundingBuffer? conversationGrounding,
    String? expressionGrounding,
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
      nightSession: nightSession,
      conversationGrounding:
          package?.conversationGrounding ?? conversationGrounding,
      groundingBlob: expressionGrounding,
      listenOnlyActive: ListenOnlyPreference.isActive(
        currentMessage: userUtterance,
        grounding: package?.conversationGrounding ?? conversationGrounding,
        sessionVentCorpus: '',
      ),
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
    NightSession? nightSession,
    ConversationGroundingBuffer? conversationGrounding,
    String? groundingBlob,
    bool listenOnlyActive = false,
    String sessionVentCorpus = '',
  }) {
    if (what == ConversationPhase.validation &&
        expressionMode == ConversationExpressionMode.observePurity) {
      final shiftAck = HoldActDedup.concernShiftAcknowledge(
        userUtterance: userUtterance,
        groundingBlob: groundingBlob,
        session: nightSession,
        grounding: conversationGrounding,
      );
      if (shiftAck != null) {
        final shiftAdmitted = utteranceGuard.allow(
          utterance: shiftAck,
          what: what,
          userUtterance: userUtterance,
          mirrorGroundingUtterance: groundingBlob,
          expressionMode: expressionMode,
          listenOnlyActive: listenOnlyActive,
        );
        if (shiftAdmitted != null) {
          debugPrint(
            'Nocta expression concern-shift ack admitted WHAT=${what.name}',
          );
          return shiftAdmitted;
        }
      }
    }

    final terminal = ModeSafeTerminalFallback.forExpression(
      what: what,
      expressionMode: expressionMode,
      userUtterance: userUtterance,
      narrowRefinementAfterPartial: narrowRefinementAfterPartial,
      session: nightSession,
      grounding: conversationGrounding,
      groundingBlob: groundingBlob,
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
      mirrorGroundingUtterance: groundingBlob,
      expressionMode: expressionMode,
      listenOnlyActive: listenOnlyActive,
    );
    if (admitted == null) {
      debugPrint(
        'Nocta expression CRITICAL terminal rejected WHAT=${what.name} '
        'mode=${expressionMode.name} text="${terminal.text}" '
        'reason=$reason prior="$priorRejectedText"',
      );
      if (expressionMode == ConversationExpressionMode.reframe) {
        for (final retreatMode in const [
          ConversationExpressionMode.narrow,
          ConversationExpressionMode.observePurity,
          // postReframeListen only when user turn is a minimal confirm —
          // substantive turns must not land on bare Okay via this retreat.
        ]) {
          final retreat = ModeSafeTerminalFallback.forExpression(
            what: what,
            expressionMode: retreatMode,
            userUtterance: userUtterance,
            narrowRefinementAfterPartial: narrowRefinementAfterPartial,
            groundingBlob: groundingBlob,
            session: nightSession,
            grounding: conversationGrounding,
          );
          if (retreat == null) continue;
          final retreatAdmitted = utteranceGuard.allow(
            utterance: retreat,
            what: what,
            userUtterance: userUtterance,
            mirrorGroundingUtterance: groundingBlob,
            expressionMode: retreatMode,
            listenOnlyActive: listenOnlyActive,
          );
          if (retreatAdmitted != null) {
            debugPrint(
              'Nocta expression reframe terminal mode retreat '
              '${retreatMode.name}',
            );
            return retreatAdmitted;
          }
        }
        if (!SurfaceUtteranceReader.isSubstantiveUserTurn(userUtterance)) {
          final listen = ModeSafeTerminalFallback.forExpression(
            what: what,
            expressionMode: ConversationExpressionMode.postReframeListen,
            userUtterance: userUtterance,
            narrowRefinementAfterPartial: narrowRefinementAfterPartial,
            groundingBlob: groundingBlob,
            session: nightSession,
            grounding: conversationGrounding,
          );
          if (listen != null) {
            final listenAdmitted = utteranceGuard.allow(
              utterance: listen,
              what: what,
              userUtterance: userUtterance,
              mirrorGroundingUtterance: groundingBlob,
              expressionMode: ConversationExpressionMode.postReframeListen,
              listenOnlyActive: listenOnlyActive,
            );
            if (listenAdmitted != null) {
              debugPrint(
                'Nocta expression reframe terminal mode retreat '
                'postReframeListen',
              );
              return listenAdmitted;
            }
          }
        }
      }
      return _zeroSilenceSurfaceRetreat(
        what: what,
        userUtterance: userUtterance,
        expressionMode: expressionMode,
        nightSession: nightSession,
        conversationGrounding: conversationGrounding,
        groundingBlob: groundingBlob,
        listenOnlyActive: listenOnlyActive,
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
    NightSession? nightSession,
    ConversationGroundingBuffer? conversationGrounding,
    String? groundingBlob,
    bool listenOnlyActive = false,
  }) {
    if (what != ConversationPhase.validation) return null;

    final mirror = UserObjectMirror.forValidation(
      userUtterance: userUtterance,
      groundingBlob: groundingBlob,
      expressionMode: expressionMode,
      session: nightSession,
      grounding: conversationGrounding,
    );
    if (mirror != null) {
      final admitted = utteranceGuard.allow(
        utterance: mirror,
        what: what,
        userUtterance: userUtterance,
        mirrorGroundingUtterance: groundingBlob,
        expressionMode: expressionMode,
        listenOnlyActive: listenOnlyActive,
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
      ConversationExpressionMode.observePurity,
      ConversationExpressionMode.standard,
      ConversationExpressionMode.postReframeListen,
    ]) {
      // Never prefer bare Okay retreat on a substantive user turn.
      if (fallbackMode == ConversationExpressionMode.postReframeListen &&
          SurfaceUtteranceReader.isSubstantiveUserTurn(userUtterance)) {
        continue;
      }
      final line = ModeSafeTerminalFallback.forExpression(
        what: what,
        expressionMode: fallbackMode,
        userUtterance: userUtterance,
        groundingBlob: groundingBlob,
        session: nightSession,
        grounding: conversationGrounding,
      );
      if (line == null) continue;
      final ok = utteranceGuard.allow(
        utterance: line,
        what: what,
        userUtterance: userUtterance,
        mirrorGroundingUtterance: groundingBlob,
        expressionMode: fallbackMode,
        listenOnlyActive: listenOnlyActive,
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

  static String? _expressionGroundingBlob({
    ConversationGroundingBuffer? conversationGrounding,
    String sessionVentCorpus = '',
  }) {
    return SessionLocale.userEvidenceBlob(
      conversationGrounding: conversationGrounding,
      sessionVentCorpus: sessionVentCorpus,
    );
  }
}
