import 'package:flutter_test/flutter_test.dart';
import 'package:slowave/core/brain/belief_detector.dart';
import 'package:slowave/core/brain/cognitive_orchestrator.dart';
import 'package:slowave/core/brain/conversation_decision.dart';
import 'package:slowave/core/brain/conversation_engine.dart';
import 'package:slowave/core/brain/conversation_grounding_buffer.dart';
import 'package:slowave/core/brain/conversation_phase.dart';
import 'package:slowave/core/brain/conversation_policy.dart';
import 'package:slowave/core/brain/conversation_utterance.dart';
import 'package:slowave/core/brain/emotional_pattern_detector.dart';
import 'package:slowave/core/brain/exit_decision.dart';
import 'package:slowave/core/brain/exit_intelligence.dart';
import 'package:slowave/core/brain/identity.dart';
import 'package:slowave/core/brain/language_model_client.dart';
import 'package:slowave/core/brain/living_mind_model.dart';
import 'package:slowave/core/brain/memory_engine.dart';
import 'package:slowave/core/brain/mental_pattern_detector.dart';
import 'package:slowave/core/brain/need_detector.dart';
import 'package:slowave/core/brain/night_session.dart';
import 'package:slowave/core/brain/perception_engine.dart';
import 'package:slowave/core/brain/preference_detector.dart';
import 'package:slowave/core/brain/prior_admitted_expression.dart';
import 'package:slowave/core/brain/release_decision.dart';
import 'package:slowave/core/brain/release_engine.dart';
import 'package:slowave/core/brain/session_summary.dart';
import 'package:slowave/core/brain/session_summarizer.dart';
import 'package:slowave/core/brain/validated_understanding.dart';
import 'package:slowave/core/brain/working_mind_view.dart';

import 'faithful_test_vendor_provider.dart';

void main() {
  group('CognitiveOrchestrator conversation flow', () {
    test('preserves canonical Release → Policy → Exit → Conversation order', () async {
      final order = <String>[];
      final orchestrator = _buildOrchestrator(
        releaseEngine: _TrackingReleaseEngine(order),
        conversationPolicy: _TrackingConversationPolicy(order),
        exitIntelligence: _TrackingExitIntelligence(order),
        conversationEngine: _TrackingConversationEngine(order),
        memoryEngine: _CountingMemoryEngine(),
      );

      final workingMind = WorkingMindView(model: _emptyModel());
      final session = NightSession(workingMind: workingMind, turns: const []);

      await orchestrator.processTurn(
        message: 'I am thinking',
        session: session,
        workingMind: workingMind,
      );

      expect(order, [
        'release',
        'policy',
        'exit',
        'conversation',
      ]);
    });

    test('invokes Conversation once and emits one speech outcome when speaking', () async {
      final conversation = _TrackingConversationEngine([]);
      final memory = _CountingMemoryEngine();
      final orchestrator = _buildOrchestrator(
        conversationEngine: conversation,
        memoryEngine: memory,
      );

      final workingMind = WorkingMindView(model: _emptyModel());
      final result = await orchestrator.processTurn(
        message: 'I am thinking',
        session: NightSession(workingMind: workingMind, turns: const []),
        workingMind: workingMind,
      );

      expect(conversation.invokeCount, 1);
      expect(result.utterance, isA<ConversationUtterance>());
      expect(result.utterance!.text, isNotEmpty);
      expect(result.utterance!.text.contains('\n'), isFalse);
      expect(result.exitDecision, ExitDecision.continueConversation);
      expect(result.conversationDecision.shouldSpeak, isTrue);
    });

    test('non-speech path yields no conversational language', () async {
      final conversation = _TrackingConversationEngine([]);
      final memory = _CountingMemoryEngine();
      final orchestrator = _buildOrchestrator(
        releaseEngine: const _TransitionReadyReleaseEngine(),
        conversationEngine: conversation,
        memoryEngine: memory,
      );

      final workingMind = WorkingMindView(model: _emptyModel());
      final result = await orchestrator.processTurn(
        message: 'I am thinking',
        session: NightSession(workingMind: workingMind, turns: const []),
        workingMind: workingMind,
      );

      expect(conversation.invokeCount, 1);
      expect(result.conversationDecision.phase, ConversationPhase.audio);
      expect(result.exitDecision, ExitDecision.transitionToAudio);
      expect(result.utterance, isNull);
    });

    test('passes authorized Conversation inputs only and unchanged', () async {
      final conversation = _CapturingConversationEngine();
      final orchestrator = _buildOrchestrator(
        conversationEngine: conversation,
        memoryEngine: _CountingMemoryEngine(),
      );

      final workingMind = WorkingMindView(model: _emptyModel());
      final result = await orchestrator.processTurn(
        message: 'I am thinking',
        session: NightSession(workingMind: workingMind, turns: const []),
        workingMind: workingMind,
      );

      expect(conversation.lastConversationDecision, result.conversationDecision);
      expect(conversation.lastExitDecision, result.exitDecision);
      expect(conversation.lastWorkingMind, same(workingMind));
      expect(conversation.lastUnderstanding, isNotNull);
      expect(conversation.receivedReleaseDecision, isFalse);
    });

    test('does not write memory mid-turn', () async {
      final memory = _CountingMemoryEngine();
      final orchestrator = _buildOrchestrator(memoryEngine: memory);
      final model = _emptyModel();
      final workingMind = WorkingMindView(model: model);

      await orchestrator.processTurn(
        message: 'I am thinking',
        session: NightSession(workingMind: workingMind, turns: const []),
        workingMind: workingMind,
      );

      expect(memory.updateCount, 0);
    });

    test('Neutral Entry greeting yields non-null short utterance', () async {
      final conversation = _TrackingConversationEngine([]);
      final orchestrator = _buildOrchestrator(
        conversationEngine: conversation,
        memoryEngine: _CountingMemoryEngine(),
      );
      final workingMind = WorkingMindView(model: _emptyModel());

      final result = await orchestrator.processTurn(
        message: 'hi',
        session: NightSession(workingMind: workingMind, turns: const []),
        workingMind: workingMind,
      );

      expect(result.conversationDecision.phase, ConversationPhase.neutralEntry);
      expect(result.utterance, isNotNull);
      expect(result.utterance!.text.toLowerCase(), contains('whenever'));
      expect(result.utterance!.text.contains('?'), isFalse);
      expect(conversation.invokeCount, 1);
    });

    test('emotional first turn still routes to Receipt/validation', () async {
      final conversation = _CapturingConversationEngine();
      final orchestrator = _buildOrchestrator(
        conversationEngine: conversation,
        memoryEngine: _CountingMemoryEngine(),
      );
      final workingMind = WorkingMindView(model: _emptyModel());

      final result = await orchestrator.processTurn(
        message: 'I keep replaying tomorrow and my mind will not settle.',
        session: NightSession(workingMind: workingMind, turns: const []),
        workingMind: workingMind,
      );

      expect(result.conversationDecision.phase, ConversationPhase.validation);
      expect(result.utterance, isNotNull);
    });

    test('session-end memory write remains outside the turn path', () async {
      final memory = _CountingMemoryEngine();
      final orchestrator = _buildOrchestrator(memoryEngine: memory);
      final model = _emptyModel();
      final workingMind = WorkingMindView(model: model);
      final session = NightSession(workingMind: workingMind, turns: const []);

      final turnResult = await orchestrator.processTurn(
        message: 'I am thinking',
        session: session,
        workingMind: workingMind,
      );
      expect(memory.updateCount, 0);

      orchestrator.completeSession(
        session: turnResult.session,
        model: model,
      );
      expect(memory.updateCount, 1);
    });
  });
}

CognitiveOrchestrator _buildOrchestrator({
  ReleaseEngine releaseEngine = const ReleaseEngine(),
  ConversationPolicy conversationPolicy = const ConversationPolicy(),
  ExitIntelligence exitIntelligence = const ExitIntelligence(),
  ConversationEngine conversationEngine = const ConversationEngine(
    languageModelClient: LanguageModelClient(
      vendorProvider: FaithfulTestVendorProvider(),
    ),
  ),
  required MemoryEngine memoryEngine,
}) {
  return CognitiveOrchestrator(
    perceptionEngine: const PerceptionEngine(),
    mentalPatternDetector: const MentalPatternDetector(),
    emotionalPatternDetector: const EmotionalPatternDetector(),
    beliefDetector: const BeliefDetector(),
    needDetector: const NeedDetector(),
    preferenceDetector: const PreferenceDetector(),
    releaseEngine: releaseEngine,
    conversationPolicy: conversationPolicy,
    conversationEngine: conversationEngine,
    exitIntelligence: exitIntelligence,
    sessionSummarizer: const SessionSummarizer(),
    memoryEngine: memoryEngine,
  );
}

LivingMindModel _emptyModel() {
  final now = DateTime.utc(2026, 1, 1);
  return LivingMindModel(
    identity: Identity(
      userId: 'test',
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

class _CountingMemoryEngine extends MemoryEngine {
  int updateCount = 0;

  @override
  LivingMindModel update(LivingMindModel model, SessionSummary summary) {
    updateCount++;
    return super.update(model, summary);
  }
}

class _TrackingReleaseEngine extends ReleaseEngine {
  final List<String> order;

  _TrackingReleaseEngine(this.order);

  @override
  ReleaseDecision evaluate({
    required ValidatedUnderstanding understanding,
    required WorkingMindView workingMind,
    required NightSession session,
    String? message,
  }) {
    order.add('release');
    return super.evaluate(
      understanding: understanding,
      workingMind: workingMind,
      session: session,
      message: message,
    );
  }
}

class _TransitionReadyReleaseEngine extends ReleaseEngine {
  const _TransitionReadyReleaseEngine();

  @override
  ReleaseDecision evaluate({
    required ValidatedUnderstanding understanding,
    required WorkingMindView workingMind,
    required NightSession session,
    String? message,
  }) {
    return const ReleaseDecision(
      readiness: ReleaseReadiness.transitionReady,
      confidence: 0.95,
    );
  }
}

class _TrackingConversationPolicy extends ConversationPolicy {
  final List<String> order;

  _TrackingConversationPolicy(this.order);

  @override
  ConversationDecision decide({
    required ReleaseDecision releaseDecision,
    String? message,
    NightSession? session,
    ValidatedUnderstanding? understanding,
    ConversationGroundingBuffer? conversationGrounding,
  }) {
    order.add('policy');
    return super.decide(
      releaseDecision: releaseDecision,
      message: message,
      session: session,
      understanding: understanding,
      conversationGrounding: conversationGrounding,
    );
  }
}

class _TrackingExitIntelligence extends ExitIntelligence {
  final List<String> order;

  _TrackingExitIntelligence(this.order);

  @override
  ExitDecision decide({
    required ReleaseDecision releaseDecision,
    required ConversationDecision conversationDecision,
    required NightSession session,
    String? message,
  }) {
    order.add('exit');
    return super.decide(
      releaseDecision: releaseDecision,
      conversationDecision: conversationDecision,
      session: session,
      message: message,
    );
  }
}

class _TrackingConversationEngine extends ConversationEngine {
  final List<String> order;
  int invokeCount = 0;

  _TrackingConversationEngine(this.order)
      : super(
          languageModelClient: const LanguageModelClient(
            vendorProvider: FaithfulTestVendorProvider(),
          ),
        );

  @override
  Future<ConversationUtterance?> generate({
    required ConversationDecision conversationDecision,
    required ExitDecision exitDecision,
    ValidatedUnderstanding? understanding,
    WorkingMindView? workingMind,
    String? livedExpression,
    ConversationGroundingBuffer? conversationGrounding,
    PriorAdmittedExpression? priorAdmittedExpression,
  }) async {
    order.add('conversation');
    invokeCount++;
    return super.generate(
      conversationDecision: conversationDecision,
      exitDecision: exitDecision,
      understanding: understanding,
      workingMind: workingMind,
      livedExpression: livedExpression,
      conversationGrounding: conversationGrounding,
      priorAdmittedExpression: priorAdmittedExpression,
    );
  }
}

class _CapturingConversationEngine extends ConversationEngine {
  ConversationDecision? lastConversationDecision;
  ExitDecision? lastExitDecision;
  ValidatedUnderstanding? lastUnderstanding;
  WorkingMindView? lastWorkingMind;
  String? lastLivedExpression;
  ConversationGroundingBuffer? lastConversationGrounding;
  bool receivedReleaseDecision = false;

  _CapturingConversationEngine()
      : super(
          languageModelClient: const LanguageModelClient(
            vendorProvider: FaithfulTestVendorProvider(),
          ),
        );

  @override
  Future<ConversationUtterance?> generate({
    required ConversationDecision conversationDecision,
    required ExitDecision exitDecision,
    ValidatedUnderstanding? understanding,
    WorkingMindView? workingMind,
    String? livedExpression,
    ConversationGroundingBuffer? conversationGrounding,
    PriorAdmittedExpression? priorAdmittedExpression,
  }) async {
    lastConversationDecision = conversationDecision;
    lastExitDecision = exitDecision;
    lastUnderstanding = understanding;
    lastWorkingMind = workingMind;
    lastLivedExpression = livedExpression;
    lastConversationGrounding = conversationGrounding;
    // ReleaseDecision is not a ConversationEngine parameter; capture stays false.
    receivedReleaseDecision = false;
    return super.generate(
      conversationDecision: conversationDecision,
      exitDecision: exitDecision,
      understanding: understanding,
      workingMind: workingMind,
      livedExpression: livedExpression,
      conversationGrounding: conversationGrounding,
      priorAdmittedExpression: priorAdmittedExpression,
    );
  }
}
