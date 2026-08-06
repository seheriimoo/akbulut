import 'belief_detector.dart';
import 'conversation_decision.dart';
import 'conversation_engine.dart';
import 'conversation_policy.dart';
import 'conversation_utterance.dart';
import 'cognitive_turn_result.dart';
import 'emotional_pattern_detector.dart';
import 'exit_decision.dart';
import 'exit_intelligence.dart';
import 'living_mind_model.dart';
import 'memory_engine.dart';
import 'mental_pattern_detector.dart';
import 'need_detector.dart';
import 'night_session.dart';
import 'perception_engine.dart';
import 'preference_detector.dart';
import 'release_engine.dart';
import 'session_summarizer.dart';
import 'session_turn.dart';
import 'validated_understanding.dart';
import 'working_mind_view.dart';

/// CognitiveOrchestrator
///
/// Central coordinator of the HCOS cognitive pipeline.
///
/// Owns no business logic.
///
/// Wires components together in a forward-only pipeline.
class CognitiveOrchestrator {
  final PerceptionEngine perceptionEngine;

  final MentalPatternDetector mentalPatternDetector;

  final EmotionalPatternDetector emotionalPatternDetector;

  final BeliefDetector beliefDetector;

  final NeedDetector needDetector;

  final PreferenceDetector preferenceDetector;

  final ReleaseEngine releaseEngine;

  final ConversationPolicy conversationPolicy;

  final ConversationEngine conversationEngine;

  final ExitIntelligence exitIntelligence;

  final SessionSummarizer sessionSummarizer;

  final MemoryEngine memoryEngine;

  const CognitiveOrchestrator({
    required this.perceptionEngine,
    required this.mentalPatternDetector,
    required this.emotionalPatternDetector,
    required this.beliefDetector,
    required this.needDetector,
    required this.preferenceDetector,
    required this.releaseEngine,
    required this.conversationPolicy,
    required this.conversationEngine,
    required this.exitIntelligence,
    required this.sessionSummarizer,
    required this.memoryEngine,
  });

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
  }) async {
    final evidence = perceptionEngine.perceive(message);

    final understanding = ValidatedUnderstanding(
      mentalPatterns: mentalPatternDetector.detect(evidence),
      emotionalPatterns: emotionalPatternDetector.detect(evidence),
      beliefCandidates: beliefDetector.detect(evidence),
      needCandidates: needDetector.detect(evidence),
      preferences: preferenceDetector.detect(evidence),
    );

    final releaseDecision = releaseEngine.evaluate(
      understanding: understanding,
      workingMind: workingMind,
      session: session,
    );

    final conversationDecision = conversationPolicy.decide(
      releaseDecision: releaseDecision,
    );

    final exitDecision = exitIntelligence.decide(
      releaseDecision: releaseDecision,
      conversationDecision: conversationDecision,
      session: session,
    );

    // Sprint 4 Conversation handoff: authorized inputs only, unchanged.
    // ConversationEngine is invoked exactly once after Exit.
    final ConversationUtterance? utterance = await _handoffToConversation(
      conversationDecision: conversationDecision,
      exitDecision: exitDecision,
      understanding: understanding,
      workingMind: workingMind,
    );

    final updatedSession = session.recordTurn(
      SessionTurn(
        releaseDecision: releaseDecision,
        phase: conversationDecision.phase,
      ),
    );

    return CognitiveTurnResult(
      session: updatedSession,
      releaseDecision: releaseDecision,
      conversationDecision: conversationDecision,
      exitDecision: exitDecision,
      utterance: utterance,
    );
  }

  /// Passes frozen Conversation Input Contract fields unchanged.
  ///
  /// Required: [conversationDecision], [exitDecision].
  /// Optional shaping: [understanding], [workingMind].
  ///
  /// Does not pass release decisions, memory-write authority, or other
  /// forbidden Conversation inputs. Does not write memory.
  Future<ConversationUtterance?> _handoffToConversation({
    required ConversationDecision conversationDecision,
    required ExitDecision exitDecision,
    ValidatedUnderstanding? understanding,
    WorkingMindView? workingMind,
  }) {
    return conversationEngine.generate(
      conversationDecision: conversationDecision,
      exitDecision: exitDecision,
      understanding: understanding,
      workingMind: workingMind,
    );
  }

  /// Session-end memory lifecycle.
  ///
  /// NightSession → SessionSummarizer → SessionSummary →
  /// MemoryEngine → LivingMindModel
  ///
  /// Persistent memory is written once per completed session.
  /// Mid-turn persistent writes are not performed here.
  LivingMindModel completeSession({
    required NightSession session,
    required LivingMindModel model,
  }) {
    final summary = sessionSummarizer.summarize(session);

    return memoryEngine.update(model, summary);
  }
}
