import 'package:flutter/foundation.dart';

import 'closure_fallback_builder.dart';
import 'conversation_decision.dart';
import 'conversation_expression_mode.dart';
import 'conversation_grounding_buffer.dart';
import 'conversation_phase.dart';
import 'conversation_utterance.dart';
import 'discovery/discovery_act.dart';
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
import 'surface_text_fuzzy.dart';
import 'surface_utterance_kind.dart';
import 'thinking_function_hypothesis.dart';
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
    String? sleepMindMirrorText,
    String? noctaTransitionText,
    String? deterministicExpression,
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
    final thinkingFunctionHypothesis =
        understanding?.thinkingFunctionHypothesis;

    // Deterministic safety / special surfaces — no LLM rewrite.
    if (deterministicExpression != null &&
        deterministicExpression.trim().isNotEmpty) {
      return ConversationUtterance(text: deterministicExpression.trim());
    }

    // Deterministic Sleep Mind Mirror — no LLM invents the map realization.
    if (conversationDecision.sleepMindMirror &&
        sleepMindMirrorText != null &&
        sleepMindMirrorText.trim().isNotEmpty) {
      final mirrorUtterance = ConversationUtterance(text: sleepMindMirrorText);
      final admitted = utteranceGuard.allow(
        utterance: mirrorUtterance,
        what: conversationDecision.phase,
        userUtterance: userUtterance,
        mirrorGroundingUtterance: expressionGrounding,
        expressionMode: conversationDecision.expressionMode,
        nightSession: nightSession,
      );
      if (admitted != null) return admitted;
      // Soft admit if Guard rejects (mirror is evidence-bound compiler output).
      return mirrorUtterance;
    }

    // Deterministic Nocta Transition from carried TransitionProfile.transitionNeed.
    if (conversationDecision.noctaTransition &&
        noctaTransitionText != null &&
        noctaTransitionText.trim().isNotEmpty) {
      final transitionUtterance =
          ConversationUtterance(text: noctaTransitionText.trim());
      final admitted = utteranceGuard.allow(
        utterance: transitionUtterance,
        what: conversationDecision.phase,
        userUtterance: userUtterance,
        mirrorGroundingUtterance: expressionGrounding,
        expressionMode: conversationDecision.expressionMode,
        nightSession: nightSession,
      );
      if (admitted != null) return admitted;
      return transitionUtterance;
    }

    final package = promptArchitecture.package(
      conversationDecision: conversationDecision,
      exitDecision: exitDecision,
      understanding: understanding,
      workingMind: workingMind,
      livedExpression: livedExpression,
      conversationGrounding: conversationGrounding,
      priorAdmittedExpression: priorAdmittedExpression,
      sleepMindMirrorText: sleepMindMirrorText,
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
        thinkingFunctionHypothesis: thinkingFunctionHypothesis,
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
        thinkingFunctionHypothesis: thinkingFunctionHypothesis,
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
        thinkingFunctionHypothesis: thinkingFunctionHypothesis,
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
      nightSession: nightSession,
    );
    if (admitted != null &&
        !_blocksStillHereSink(package.discoveryAct, admitted.text)) {
      return admitted;
    }
    if (admitted != null) {
      debugPrint(
        'Nocta expression blocked still-here sink act='
        '${package.discoveryAct.name}',
      );
    }

    debugPrint(
      'Nocta expression Guard reject WHAT=${package.what.name} '
      'text="${utterance.text}"',
    );

    final fallback = GuardSafeFallback.forPhase(
      what: package.what,
      userUtterance: userUtterance,
      expressionMode: package.expressionMode,
      narrowRefinementAfterPartial: package.narrowRefinementAfterPartial,
      postRecognitionDeepen: package.postRecognitionDeepen,
      sleepMindMirror: package.sleepMindMirror,
      sleepMindMirrorText: package.sleepMindMirrorText,
      discoveryAct: package.discoveryAct,
      session: nightSession,
      grounding: package.conversationGrounding,
      sessionVentCorpus: sessionVentCorpus,
      listenOnlyActive: listenOnlyActive,
      thinkingFunctionHypothesis: thinkingFunctionHypothesis,
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
          nightSession: nightSession,
        );
        if (closureAdmitted != null) return closureAdmitted;
      }
      return _admitTerminalFallback(
        what: package.what,
        expressionMode: package.expressionMode,
        narrowRefinementAfterPartial: package.narrowRefinementAfterPartial,
        postRecognitionDeepen: package.postRecognitionDeepen,
        sleepMindMirror: package.sleepMindMirror,
        sleepMindMirrorText: package.sleepMindMirrorText,
        userUtterance: userUtterance,
        priorRejectedText: utterance.text,
        reason: 'primary fallback null',
        nightSession: nightSession,
        conversationGrounding: package.conversationGrounding,
        groundingBlob: expressionGrounding,
        listenOnlyActive: listenOnlyActive,
        sessionVentCorpus: sessionVentCorpus,
        thinkingFunctionHypothesis: thinkingFunctionHypothesis,
        discoveryAct: package.discoveryAct,
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
      nightSession: nightSession,
    );
    if (fallbackAdmitted != null &&
        !_blocksStillHereSink(package.discoveryAct, fallbackAdmitted.text)) {
      debugPrint(
        'Nocta expression Guard fallback admitted WHAT=${package.what.name}',
      );
      return fallbackAdmitted;
    }
    if (fallbackAdmitted != null) {
      debugPrint(
        'Nocta expression blocked still-here sink on fallback act='
        '${package.discoveryAct.name}',
      );
    }
    return _admitTerminalFallback(
      what: package.what,
      expressionMode: package.expressionMode,
      narrowRefinementAfterPartial: package.narrowRefinementAfterPartial,
      postRecognitionDeepen: package.postRecognitionDeepen,
      sleepMindMirror: package.sleepMindMirror,
      sleepMindMirrorText: package.sleepMindMirrorText,
      userUtterance: userUtterance,
      priorRejectedText: fallback.text,
      reason: 'fallback double-reject',
      nightSession: nightSession,
      conversationGrounding: package.conversationGrounding,
      groundingBlob: expressionGrounding,
      listenOnlyActive: listenOnlyActive,
      sessionVentCorpus: sessionVentCorpus,
      thinkingFunctionHypothesis: thinkingFunctionHypothesis,
      discoveryAct: package.discoveryAct,
    );
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
    ThinkingFunctionHypothesis? thinkingFunctionHypothesis,
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
      postRecognitionDeepen: package?.postRecognitionDeepen ??
          conversationDecision.postRecognitionDeepen,
      sleepMindMirror: package?.sleepMindMirror ??
          conversationDecision.sleepMindMirror,
      sleepMindMirrorText: package?.sleepMindMirrorText,
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
      thinkingFunctionHypothesis: thinkingFunctionHypothesis,
      discoveryAct: package?.discoveryAct ?? conversationDecision.discoveryAct,
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
    ThinkingFunctionHypothesis? thinkingFunctionHypothesis,
    bool postRecognitionDeepen = false,
    bool sleepMindMirror = false,
    String? sleepMindMirrorText,
    DiscoveryAct discoveryAct = DiscoveryAct.deferToArc,
  }) {
    if (sleepMindMirror &&
        sleepMindMirrorText != null &&
        sleepMindMirrorText.trim().isNotEmpty) {
      return ConversationUtterance(text: sleepMindMirrorText);
    }
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
          nightSession: nightSession,
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
      postRecognitionDeepen: postRecognitionDeepen,
      sleepMindMirror: sleepMindMirror,
      session: nightSession,
      grounding: conversationGrounding,
      groundingBlob: groundingBlob,
      thinkingFunctionHypothesis: thinkingFunctionHypothesis,
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
      nightSession: nightSession,
    );
    if (admitted != null &&
        !_blocksStillHereSink(discoveryAct, admitted.text)) {
      debugPrint(
        'Nocta expression terminal fallback admitted WHAT=${what.name} '
        'mode=${expressionMode.name} reason=$reason',
      );
      return admitted;
    }
    // Last-resort soft meet/hold lines — never still-here.
    if (discoveryAct == DiscoveryAct.meet ||
        discoveryAct == DiscoveryAct.hold) {
      final turkish =
          SurfaceTextFuzzy.prefersTurkish(userUtterance, groundingBlob);
      return ConversationUtterance(
        text: turkish
            ? 'Buradayım. Bu gece yanında durabilirim.'
            : "I'm here with you in this tonight.",
      );
    }
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
        ]) {
          final retreat = ModeSafeTerminalFallback.forExpression(
            what: what,
            expressionMode: retreatMode,
            userUtterance: userUtterance,
            narrowRefinementAfterPartial: narrowRefinementAfterPartial,
            groundingBlob: groundingBlob,
            session: nightSession,
            grounding: conversationGrounding,
            thinkingFunctionHypothesis: thinkingFunctionHypothesis,
          );
          if (retreat == null) continue;
          final retreatAdmitted = utteranceGuard.allow(
            utterance: retreat,
            what: what,
            userUtterance: userUtterance,
            mirrorGroundingUtterance: groundingBlob,
            expressionMode: retreatMode,
            listenOnlyActive: listenOnlyActive,
            nightSession: nightSession,
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
            thinkingFunctionHypothesis: thinkingFunctionHypothesis,
          );
          if (listen != null) {
            final listenAdmitted = utteranceGuard.allow(
              utterance: listen,
              what: what,
              userUtterance: userUtterance,
              mirrorGroundingUtterance: groundingBlob,
              expressionMode: ConversationExpressionMode.postReframeListen,
              listenOnlyActive: listenOnlyActive,
              nightSession: nightSession,
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
        thinkingFunctionHypothesis: thinkingFunctionHypothesis,
      );
    }
    return _zeroSilenceSurfaceRetreat(
      what: what,
      userUtterance: userUtterance,
      expressionMode: expressionMode,
      nightSession: nightSession,
      conversationGrounding: conversationGrounding,
      groundingBlob: groundingBlob,
      listenOnlyActive: listenOnlyActive,
      thinkingFunctionHypothesis: thinkingFunctionHypothesis,
    );
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
    ThinkingFunctionHypothesis? thinkingFunctionHypothesis,
  }) {
    if (what != ConversationPhase.validation) return null;

    // TF-present Narrow must not erase into thin still-here before trying
    // a mechanism fork under narrow mode again.
    if (expressionMode == ConversationExpressionMode.narrow) {
      final mechanism = ModeSafeTerminalFallback.forExpression(
        what: what,
        expressionMode: ConversationExpressionMode.narrow,
        userUtterance: userUtterance,
        groundingBlob: groundingBlob,
        session: nightSession,
        grounding: conversationGrounding,
        thinkingFunctionHypothesis: thinkingFunctionHypothesis,
      );
      if (mechanism != null) {
        final ok = utteranceGuard.allow(
          utterance: mechanism,
          what: what,
          userUtterance: userUtterance,
          mirrorGroundingUtterance: groundingBlob,
          expressionMode: ConversationExpressionMode.narrow,
          listenOnlyActive: listenOnlyActive,
          nightSession: nightSession,
        );
        if (ok != null) {
          debugPrint(
            'Nocta expression zero-silence mechanism Narrow admitted',
          );
          return ok;
        }
      }
    }

    final mirrorMode =
        expressionMode == ConversationExpressionMode.narrow
            ? ConversationExpressionMode.standard
            : expressionMode;
    final mirror = UserObjectMirror.forValidation(
      userUtterance: userUtterance,
      groundingBlob: groundingBlob,
      expressionMode: mirrorMode,
      session: nightSession,
      grounding: conversationGrounding,
    );
    if (mirror != null) {
      final admitted = utteranceGuard.allow(
        utterance: mirror,
        what: what,
        userUtterance: userUtterance,
        mirrorGroundingUtterance: groundingBlob,
        expressionMode: mirrorMode,
        listenOnlyActive: listenOnlyActive,
        nightSession: nightSession,
      );
      if (admitted != null) {
        debugPrint(
          'Nocta expression zero-silence surface retreat admitted WHAT='
          '${what.name}',
        );
        return admitted;
      }
    }

    final retreatModes = <ConversationExpressionMode>[
      if (expressionMode == ConversationExpressionMode.narrow)
        ConversationExpressionMode.narrow,
      ConversationExpressionMode.observePurity,
      ConversationExpressionMode.standard,
      ConversationExpressionMode.groundedHold,
      ConversationExpressionMode.postReframeListen,
    ];

    for (final fallbackMode in retreatModes) {
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
        thinkingFunctionHypothesis: thinkingFunctionHypothesis,
      );
      if (line == null) continue;
      final ok = utteranceGuard.allow(
        utterance: line,
        what: what,
        userUtterance: userUtterance,
        mirrorGroundingUtterance: groundingBlob,
        expressionMode: fallbackMode,
        listenOnlyActive: listenOnlyActive,
        nightSession: nightSession,
      );
      if (ok != null) {
        debugPrint(
          'Nocta expression zero-silence mode retreat admitted WHAT='
          '${what.name} mode=${fallbackMode.name}',
        );
        return ok;
      }
    }

    // Absolute last resort for substantive validation — never silence.
    final absolute = _absoluteEvidenceBoundRescue(
      userUtterance: userUtterance,
      groundingBlob: groundingBlob,
      nightSession: nightSession,
      conversationGrounding: conversationGrounding,
      listenOnlyActive: listenOnlyActive,
    );
    if (absolute != null) return absolute;

    debugPrint(
      'Nocta expression CRITICAL zero-silence exhausted WHAT=${what.name}',
    );
    return null;
  }

  /// Last non-null surface for substantive Receipt turns.
  ConversationUtterance? _absoluteEvidenceBoundRescue({
    required String? userUtterance,
    required String? groundingBlob,
    required NightSession? nightSession,
    required ConversationGroundingBuffer? conversationGrounding,
    required bool listenOnlyActive,
  }) {
    final turkish =
        SurfaceTextFuzzy.prefersTurkish(userUtterance, groundingBlob);
    // Complete natural terminals only — never truncated user-clause paste.
    final candidates = <String>[
      if (turkish) ...[
        'Az önce söylediğin hâlâ orada.',
        'Söylediğin bu gece hâlâ duruyor.',
        'Bu gece söylediklerin hâlâ yakında.',
      ] else ...[
        'What you named is still here tonight.',
        'What you said is still here tonight.',
        'That part is still with you tonight.',
      ],
    ];
    final object = _shortNightObject(userUtterance, groundingBlob, turkish);
    if (object != null) {
      candidates.insert(0, object);
    }

    for (final text in candidates) {
      if (HoldActDedup.sessionContainsNormalized(nightSession, text)) {
        continue;
      }
      for (final mode in const [
        ConversationExpressionMode.observePurity,
        ConversationExpressionMode.standard,
        ConversationExpressionMode.groundedHold,
      ]) {
        final ok = utteranceGuard.allow(
          utterance: ConversationUtterance(text: text),
          what: ConversationPhase.validation,
          userUtterance: userUtterance,
          mirrorGroundingUtterance: groundingBlob,
          expressionMode: mode,
          listenOnlyActive: listenOnlyActive,
          nightSession: nightSession,
        );
        if (ok != null) {
          debugPrint(
            'Nocta expression absolute evidence-bound rescue admitted '
            'mode=${mode.name}',
          );
          return ok;
        }
      }
    }
    return null;
  }

  /// Short grounded night-object mirror — never truncated clause paste.
  static String? _shortNightObject(
    String? userUtterance,
    String? groundingBlob,
    bool turkish,
  ) {
    final blob = '${userUtterance ?? ''} ${groundingBlob ?? ''}'.toLowerCase();
    if (blob.trim().isEmpty) return null;
    if (turkish) {
      if (blob.contains('yarın') || blob.contains('yarin')) {
        return 'Yarın hâlâ sende duruyor.';
      }
      if (blob.contains('iş ') || blob.contains('is ') || blob.contains('değerlendirme')) {
        return 'İş tarafı hâlâ sende duruyor.';
      }
      if (RegExp(r'utanc|prova|senaryo|ihtimal').hasMatch(blob)) {
        return 'O senaryolar hâlâ sende duruyor.';
      }
      return null;
    }
    if (blob.contains('tomorrow')) {
      return 'Tomorrow is still with you tonight.';
    }
    if (blob.contains('work') || blob.contains('meeting') || blob.contains('review')) {
      return 'Work thoughts are still with you tonight.';
    }
    if (RegExp(r'embarrass|rehears|scenario|disaster|worst').hasMatch(blob)) {
      return 'Those rehearsed scenes are still with you tonight.';
    }
    return null;
  }

  static bool _blocksStillHereSink(DiscoveryAct act, String text) {
    if (act != DiscoveryAct.meet &&
        act != DiscoveryAct.hold &&
        act != DiscoveryAct.deferToArc) {
      return false;
    }
    // Only block still-here on meet/hold; defer blocks only exact sink lines.
    final t = text.toLowerCase();
    final isSink = t.contains('still here tonight') ||
        t.contains('hâlâ orada') ||
        t.contains('hala orada') ||
        t.contains('az önce söylediğin') ||
        t.contains('az once soyledigin') ||
        t.contains('what you named is still') ||
        (act != DiscoveryAct.deferToArc &&
            t.contains('still with you tonight'));
    if (!isSink) return false;
    if (act == DiscoveryAct.deferToArc) {
      // Block only the worst still-here stamps on defer.
      return t.contains('still here tonight') ||
          t.contains('hâlâ orada') ||
          t.contains('hala orada') ||
          t.contains('az önce söylediğin') ||
          t.contains('what you named is still');
    }
    return true;
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
