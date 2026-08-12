import 'belief_detector.dart';
import 'cognitive_orchestrator.dart';
import 'cognitive_turn_result.dart';
import 'conversation_engine.dart';
import 'conversation_grounding_buffer.dart';
import 'conversation_policy.dart';
import 'emotional_pattern_detector.dart';
import 'exit_intelligence.dart';
import 'identity.dart';
import 'language_model_client.dart';
import 'living_mind_model.dart';
import 'memory_engine.dart';
import 'mental_pattern_detector.dart';
import 'need_detector.dart';
import 'night_session.dart';
import 'openai_vendor_provider.dart';
import 'perception_engine.dart';
import 'preference_detector.dart';
import 'release_engine.dart';
import 'session_summarizer.dart';
import 'turn_response_stance_detector.dart';
import 'working_mind_view.dart';

/// HCOS live production entry and temporary session lifecycle host helpers.
///
/// Sprint 6 Cutover:
/// - [CognitiveOrchestrator.processTurn] is the sole production cognitive entry.
/// - [NightSession] is carried across turns by the app shell.
/// - [WorkingMindView] is read only from the current [NightSession].
/// - Mid-session [NightSession] updates come only from [CognitiveTurnResult].
/// - Temporary [ConversationGroundingBuffer] is owned by CognitiveOrchestrator,
///   carried across turns via [CognitiveTurnResult], and discarded at session end.
///
/// Owns no cognitive judgment.
class HcosLiveEntry {
  const HcosLiveEntry._();

  /// Production CognitiveOrchestrator with canonical component wiring.
  ///
  /// Vendor transport is nested only behind [LanguageModelClient].
  static CognitiveOrchestrator createOrchestrator() {
    return CognitiveOrchestrator(
      perceptionEngine: const PerceptionEngine(),
      mentalPatternDetector: const MentalPatternDetector(),
      emotionalPatternDetector: const EmotionalPatternDetector(),
      beliefDetector: const BeliefDetector(),
      needDetector: const NeedDetector(),
      preferenceDetector: const PreferenceDetector(),
      turnResponseStanceDetector: const TurnResponseStanceDetector(),
      releaseEngine: const ReleaseEngine(),
      conversationPolicy: const ConversationPolicy(),
      conversationEngine: ConversationEngine(
        languageModelClient: LanguageModelClient(
          vendorProvider: OpenAIVendorProvider.fromEnv(),
        ),
      ),
      exitIntelligence: const ExitIntelligence(),
      sessionSummarizer: const SessionSummarizer(),
      memoryEngine: const MemoryEngine(),
    );
  }

  /// Temporary empty Living Mind Model for a local night session host.
  static LivingMindModel emptyMindModel({String userId = 'local'}) {
    final now = DateTime.now().toUtc();
    return LivingMindModel(
      identity: Identity(
        userId: userId,
        preferredLanguage: 'en',
        timezone: 'UTC',
        createdAt: now,
        lastInteractionAt: now,
        totalSessions: 0,
      ),
      mentalPatterns: const [],
      emotionalPatterns: const [],
      triggers: const [],
      beliefs: const [],
      needs: const [],
      preferences: const [],
    );
  }

  /// Opens a temporary NightSession. WorkingMindView is owned by the session.
  static NightSession openNightSession(LivingMindModel model) {
    return NightSession(
      workingMind: WorkingMindView(model: model),
      turns: const [],
    );
  }

  /// WorkingMindView for a turn — always from the carried NightSession.
  static WorkingMindView workingMindOf(NightSession session) =>
      session.workingMind;

  /// Sole allowed mid-session NightSession update path.
  static NightSession applyTurnResult(CognitiveTurnResult result) =>
      result.session;

  /// Temporary grounding snapshot from the turn result for session-host carry.
  ///
  /// Not SessionTurn data. Not durable memory.
  static ConversationGroundingBuffer groundingBufferOf(
    CognitiveTurnResult result,
  ) =>
      result.conversationGroundingBuffer;

  /// Session-end durable write through the canonical MemoryEngine path.
  ///
  /// Discards the Orchestrator-owned grounding buffer before durable write.
  /// Returns the updated LivingMindModel. The NightSession must be discarded
  /// by the app shell after this call.
  static LivingMindModel completeNightSession({
    required CognitiveOrchestrator orchestrator,
    required NightSession session,
    required LivingMindModel model,
  }) {
    return orchestrator.completeSession(session: session, model: model);
  }
}
