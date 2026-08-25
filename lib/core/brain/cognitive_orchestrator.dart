import 'belief_detector.dart';
import 'conversation_decision.dart';
import 'conversation_engine.dart';
import 'conversation_grounding_buffer.dart';
import 'conversation_phase.dart';
import 'conversation_policy.dart';
import 'conversation_utterance.dart';
import 'cognitive_turn_result.dart';
import 'emotional_pattern_detector.dart';
import 'exit_decision.dart';
import 'exit_intelligence.dart';
import 'grounded_progression.dart';
import 'input_boundary_gate.dart';
import 'living_mind_model.dart';
import 'memory_engine.dart';
import 'mental_pattern_detector.dart';
import 'need_detector.dart';
import 'night_session.dart';
import 'perception_engine.dart';
import 'preference_detector.dart';
import 'prior_admitted_expression.dart';
import 'release_decision.dart';
import 'release_engine.dart';
import 'session_summarizer.dart';
import 'session_turn.dart';
import 'thinking_function_continuity.dart';
import 'thinking_function_detector.dart';
import 'thinking_function_hypothesis.dart';
import 'turn_response_stance_detector.dart';
import 'validated_understanding.dart';
import 'working_mind_view.dart';

/// CognitiveOrchestrator
///
/// Central coordinator of the HCOS cognitive pipeline.
///
/// Owns no business logic.
///
/// Wires components together in a forward-only pipeline.
///
/// Sole owner of the temporary [ConversationGroundingBuffer] for the night.
class CognitiveOrchestrator {
  final PerceptionEngine perceptionEngine;

  final MentalPatternDetector mentalPatternDetector;

  final EmotionalPatternDetector emotionalPatternDetector;

  final BeliefDetector beliefDetector;

  final NeedDetector needDetector;

  final PreferenceDetector preferenceDetector;

  final TurnResponseStanceDetector turnResponseStanceDetector;

  final ThinkingFunctionDetector thinkingFunctionDetector;

  final ThinkingFunctionContinuity thinkingFunctionContinuity;

  final ReleaseEngine releaseEngine;

  final ConversationPolicy conversationPolicy;

  final ConversationEngine conversationEngine;

  final ExitIntelligence exitIntelligence;

  final SessionSummarizer sessionSummarizer;

  final MemoryEngine memoryEngine;

  final InputBoundaryGate inputBoundaryGate;

  /// Temporary same-night user grounding. Orchestrator-owned only.
  ConversationGroundingBuffer _conversationGroundingBuffer =
      const ConversationGroundingBuffer.empty();

  /// Session-level vent latch — survives the 3-turn grounding window.
  String _sessionVentCorpus = '';

  /// Night-scoped last supported Thinking Function (Phase 2 continuity).
  /// Cleared on correction, topic jump, or decay-to-null. Not durable memory.
  ThinkingFunctionHypothesis? _sessionThinkingFunction;

  CognitiveOrchestrator({
    required this.perceptionEngine,
    required this.mentalPatternDetector,
    required this.emotionalPatternDetector,
    required this.beliefDetector,
    required this.needDetector,
    required this.preferenceDetector,
    this.turnResponseStanceDetector = const TurnResponseStanceDetector(),
    this.thinkingFunctionDetector = const ThinkingFunctionDetector(),
    this.thinkingFunctionContinuity = const ThinkingFunctionContinuity(),
    required this.releaseEngine,
    required this.conversationPolicy,
    required this.conversationEngine,
    required this.exitIntelligence,
    required this.sessionSummarizer,
    required this.memoryEngine,
    this.inputBoundaryGate = const InputBoundaryGate(),
  });

  /// Read-only view of the Orchestrator-owned grounding buffer.
  ConversationGroundingBuffer get conversationGroundingBuffer =>
      _conversationGroundingBuffer;

  /// Forward-only turn coordinator.
  ///
  /// Canonical decision order:
  /// Release → ConversationPolicy → Exit → Conversation.
  ///
  /// Updates temporary NightSession state only.
  /// Does not write persistent memory.
  ///
  /// Awaitable so Conversation expression (LanguageModelClient) may be async.
  Future<CognitiveTurnResult> processTurn({
    required String message,
    required NightSession session,
    required WorkingMindView workingMind,
    ConversationGroundingBuffer? conversationGroundingBuffer,
  }) async {
    // Session host may rehydrate the Orchestrator-owned buffer from the prior
    // CognitiveTurnResult. Buffer is never SessionTurn decision data.
    if (conversationGroundingBuffer != null) {
      _conversationGroundingBuffer = conversationGroundingBuffer;
    }

    if (session.turns.isEmpty) {
      _sessionVentCorpus = '';
      _sessionThinkingFunction = null;
    }

    // Temporary Conversation Memory buffer: user utterances only.
    // Not decision authority. Not durable. Not expression-plane input yet.
    _conversationGroundingBuffer =
        _conversationGroundingBuffer.appendUserUtterance(message);

    _sessionVentCorpus = SessionVentMemory.advanceVentCorpus(
      currentCorpus: _sessionVentCorpus,
      message: message,
    );

    // P1 minimal input boundaries — before HCOS climb / sleep handoff.
    final boundary = inputBoundaryGate.evaluate(message);
    if (boundary != null) {
      return _boundaryTurnResult(
        session: session,
        utterance: boundary.utterance,
        kind: boundary.kind,
      );
    }

    final evidence = perceptionEngine.perceive(message);

    final mentalPatterns = mentalPatternDetector.detect(evidence);
    final emotionalPatterns = emotionalPatternDetector.detect(evidence);
    final priorPhase =
        session.turns.isEmpty ? null : session.turns.last.phase;
    final turnResponseStance = turnResponseStanceDetector.detect(
      evidence: evidence,
      hasLoad: mentalPatterns.isNotEmpty || emotionalPatterns.isNotEmpty,
      priorPhase: priorPhase,
    );

    // Cognition only: soft function hypothesis. Continuity may persist a
    // supported prior when this turn elaborates the same job (Phase 2).
    // Must not choose Release / Exit; Policy load check may see TF.
    final freshThinkingFunction = thinkingFunctionDetector.detect(
      currentMessage: message,
      conversationGrounding: _conversationGroundingBuffer,
      perceptionEvidence: evidence,
    );
    final priorThinkingFunction = _sessionThinkingFunction;
    final thinkingFunctionHypothesis = thinkingFunctionContinuity.resolve(
      fresh: freshThinkingFunction,
      prior: priorThinkingFunction,
      currentMessage: message,
      conversationGrounding: _conversationGroundingBuffer,
      session: session,
    );
    if (ThinkingFunctionContinuity.shouldClearSessionStore(
      resolved: thinkingFunctionHypothesis,
      currentMessage: message,
      prior: priorThinkingFunction,
      conversationGrounding: _conversationGroundingBuffer,
      session: session,
    )) {
      _sessionThinkingFunction = null;
    } else if (thinkingFunctionHypothesis != null &&
        thinkingFunctionHypothesis.confidence >=
            ThinkingFunctionDetector.supportedFloor) {
      _sessionThinkingFunction = thinkingFunctionHypothesis;
    } else {
      // Tentative-only results must not permanently lock a strong prior.
      _sessionThinkingFunction = null;
    }

    final understanding = ValidatedUnderstanding(
      mentalPatterns: mentalPatterns,
      emotionalPatterns: emotionalPatterns,
      beliefCandidates: beliefDetector.detect(evidence),
      needCandidates: needDetector.detect(evidence),
      preferences: preferenceDetector.detect(evidence),
      turnResponseStance: turnResponseStance,
      thinkingFunctionHypothesis: thinkingFunctionHypothesis,
    );

    final releaseDecision = releaseEngine.evaluate(
      understanding: understanding,
      workingMind: workingMind,
      session: session,
      message: message,
    );

    final conversationDecision = conversationPolicy.decide(
      releaseDecision: releaseDecision,
      message: message,
      session: session,
      understanding: understanding,
      conversationGrounding: _conversationGroundingBuffer.isEmpty
          ? null
          : _conversationGroundingBuffer,
      sessionVentCorpus: _sessionVentCorpus,
    );
    final exitDecision = exitIntelligence.decide(
      releaseDecision: releaseDecision,
      conversationDecision: conversationDecision,
      session: session,
      message: message,
    );

    // Conversation handoff: authorized inputs only.
    // ConversationEngine is invoked exactly once after Exit.
    // livedExpression + conversationGrounding are shaping-only (not authority).
    final ConversationUtterance? utterance = await _handoffToConversation(
      conversationDecision: conversationDecision,
      exitDecision: exitDecision,
      understanding: understanding,
      workingMind: workingMind,
      livedExpression: message,
      conversationGrounding: _conversationGroundingBuffer.isEmpty
          ? null
          : _conversationGroundingBuffer,
      priorAdmittedExpression: _lastAdmittedExpression(session),
      nightSession: session,
    );

    final updatedSession = session.recordTurn(
      SessionTurn(
        releaseDecision: releaseDecision,
        phase: conversationDecision.phase,
        expressionMode: conversationDecision.expressionMode,
        admittedExpression: utterance == null
            ? null
            : PriorAdmittedExpression(
                phase: conversationDecision.phase,
                text: utterance.text,
              ),
        mentalPatterns: mentalPatterns,
        emotionalPatterns: emotionalPatterns,
      ),
    );

    return CognitiveTurnResult(
      session: updatedSession,
      releaseDecision: releaseDecision,
      conversationDecision: conversationDecision,
      exitDecision: exitDecision,
      utterance: utterance,
      conversationGroundingBuffer: _conversationGroundingBuffer,
    );
  }

  /// Passes frozen Conversation Input Contract fields unchanged.
  ///
  /// Required: [conversationDecision], [exitDecision].
  /// Optional shaping: [understanding], [workingMind], [livedExpression],
  /// [conversationGrounding].
  ///
  /// Does not invent or modify grounding. Does not pass release decisions,
  /// memory-write authority, or other forbidden Conversation inputs.
  /// Does not write memory.
  Future<ConversationUtterance?> _handoffToConversation({
    required ConversationDecision conversationDecision,
    required ExitDecision exitDecision,
    ValidatedUnderstanding? understanding,
    WorkingMindView? workingMind,
    String? livedExpression,
    ConversationGroundingBuffer? conversationGrounding,
    PriorAdmittedExpression? priorAdmittedExpression,
    NightSession? nightSession,
  }) {
    return conversationEngine.generate(
      conversationDecision: conversationDecision,
      exitDecision: exitDecision,
      understanding: understanding,
      workingMind: workingMind,
      livedExpression: livedExpression,
      conversationGrounding: conversationGrounding,
      priorAdmittedExpression: priorAdmittedExpression,
      nightSession: nightSession,
      sessionVentCorpus: _sessionVentCorpus,
    );
  }

  /// Most recent Guard-admitted assistant line from this night, if any.
  PriorAdmittedExpression? _lastAdmittedExpression(NightSession session) {
    for (var i = session.turns.length - 1; i >= 0; i--) {
      final admitted = session.turns[i].admittedExpression;
      if (admitted != null) return admitted;
    }
    return null;
  }

  /// Session-end memory lifecycle.
  ///
  /// NightSession → SessionSummarizer → SessionSummary →
  /// MemoryEngine → LivingMindModel
  ///
  /// Persistent memory is written once per completed session.
  /// Mid-turn persistent writes are not performed here.
  ///
  /// Discards the temporary conversation grounding buffer before durable write.
  /// The buffer never enters SessionSummary / MemoryEngine / LivingMindModel.
  LivingMindModel completeSession({
    required NightSession session,
    required LivingMindModel model,
  }) {
    discardConversationGrounding();

    final summary = sessionSummarizer.summarize(session);

    return memoryEngine.update(model, summary);
  }

  /// Completely discards the temporary grounding buffer.
  ///
  /// Called when the NightSession ends. Safe to call more than once.
  void discardConversationGrounding() {
    _conversationGroundingBuffer = _conversationGroundingBuffer.discard();
    _sessionVentCorpus = '';
  }

  /// Fixed boundary reply — continues conversation, never sleep-handoff.
  CognitiveTurnResult _boundaryTurnResult({
    required NightSession session,
    required ConversationUtterance utterance,
    required InputBoundaryKind kind,
  }) {
    final phase = kind == InputBoundaryKind.selfHarmHighRisk
        ? ConversationPhase.validation
        : ConversationPhase.permission;
    final conversationDecision = ConversationDecision(
      phase: phase,
      shouldSpeak: true,
    );
    const releaseDecision = ReleaseDecision(
      readiness: ReleaseReadiness.hold,
      confidence: 1,
    );
    const exitDecision = ExitDecision.continueConversation;

    final updatedSession = session.recordTurn(
      SessionTurn(
        releaseDecision: releaseDecision,
        phase: phase,
        admittedExpression: PriorAdmittedExpression(
          phase: phase,
          text: utterance.text,
        ),
        mentalPatterns: const [],
        emotionalPatterns: const [],
      ),
    );

    return CognitiveTurnResult(
      session: updatedSession,
      releaseDecision: releaseDecision,
      conversationDecision: conversationDecision,
      exitDecision: exitDecision,
      utterance: utterance,
      conversationGroundingBuffer: _conversationGroundingBuffer,
    );
  }
}
