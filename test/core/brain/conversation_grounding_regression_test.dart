import 'package:flutter_test/flutter_test.dart';
import 'package:slowave/core/brain/belief_detector.dart';
import 'package:slowave/core/brain/cognitive_orchestrator.dart';
import 'package:slowave/core/brain/conversation_compiler.dart';
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
import 'package:slowave/core/brain/llm_invocation_package.dart';
import 'package:slowave/core/brain/memory_engine.dart';
import 'package:slowave/core/brain/mental_pattern_detector.dart';
import 'package:slowave/core/brain/naming_intelligence.dart';
import 'package:slowave/core/brain/need_detector.dart';
import 'package:slowave/core/brain/night_session.dart';
import 'package:slowave/core/brain/perception_engine.dart';
import 'package:slowave/core/brain/preference_detector.dart';
import 'package:slowave/core/brain/prior_admitted_expression.dart';
import 'package:slowave/core/brain/prompt_architecture.dart';
import 'package:slowave/core/brain/receipt_intelligence.dart';
import 'package:slowave/core/brain/release_engine.dart';
import 'package:slowave/core/brain/session_summary.dart';
import 'package:slowave/core/brain/session_summarizer.dart';
import 'package:slowave/core/brain/validated_understanding.dart';
import 'package:slowave/core/brain/working_mind_view.dart';

import 'faithful_test_vendor_provider.dart';

/// Task 12 — Conversation Grounding regression suite (post Task 11 cutover).
void main() {
  const architecture = PromptArchitecture();
  const compiler = ConversationCompiler();
  const receipt = ReceiptIntelligence();
  const naming = NamingIntelligence();

  group('ConversationGroundingBuffer unit contracts', () {
    test('3–5. stores only user utterances; max window current + two prior', () {
      var buffer = const ConversationGroundingBuffer.empty();
      buffer = buffer.appendUserUtterance('u1');
      buffer = buffer.appendUserUtterance('u2');
      buffer = buffer.appendUserUtterance('u3');
      buffer = buffer.appendUserUtterance('u4');

      expect(buffer.userUtterances, ['u2', 'u3', 'u4']);
      expect(buffer.currentUserUtterance, 'u4');
      expect(buffer.priorUserUtterances, ['u2', 'u3']);
      expect(buffer.userUtterances.length, ConversationGroundingBuffer.maxUserUtterances);
      // API surface is user-only; no assistant append path exists.
      expect(buffer.userUtterances, isNot(contains(contains('assistant'))));
    });

    test('7. discard empties buffer', () {
      final buffer = const ConversationGroundingBuffer.empty()
          .appendUserUtterance('keep')
          .discard();
      expect(buffer.isEmpty, isTrue);
      expect(buffer.currentUserUtterance, isNull);
    });
  });

  group('PromptArchitecture admit / omit / never invent', () {
    test('1. non-empty ConversationGrounding is admitted onto package', () {
      final grounding = const ConversationGroundingBuffer.empty()
          .appendUserUtterance('admitted user text');
      final package = architecture.package(
        conversationDecision: const ConversationDecision(
          phase: ConversationPhase.validation,
          shouldSpeak: true,
        ),
        exitDecision: ExitDecision.continueConversation,
        conversationGrounding: grounding,
      )!;

      expect(package.conversationGrounding, same(grounding));
      expect(package.conversationGrounding!.currentUserUtterance, 'admitted user text');
    });

    test('2+10. null grounding omitted; PA never invents grounding', () {
      final package = architecture.package(
        conversationDecision: const ConversationDecision(
          phase: ConversationPhase.permission,
          shouldSpeak: true,
        ),
        exitDecision: ExitDecision.continueConversation,
        conversationGrounding: null,
      )!;

      expect(package.conversationGrounding, isNull);
    });
  });

  group('Orchestrator buffer lifecycle', () {
    test('1+2. admits non-empty grounding; omits empty', () async {
      final conversation = _CapturingConversationEngine();
      final orchestrator = _buildOrchestrator(conversationEngine: conversation);
      final workingMind = WorkingMindView(model: _emptyModel());

      await orchestrator.processTurn(
        message: 'user turn one',
        session: NightSession(workingMind: workingMind, turns: const []),
        workingMind: workingMind,
      );

      expect(conversation.lastConversationGrounding, isNotNull);
      expect(conversation.lastConversationGrounding!.isEmpty, isFalse);
      expect(
        conversation.lastConversationGrounding!.currentUserUtterance,
        'user turn one',
      );
    });

    test('4+6. assistant text never enters; grounding survives across turns', () async {
      final conversation = _CapturingConversationEngine();
      final orchestrator = _buildOrchestrator(conversationEngine: conversation);
      final workingMind = WorkingMindView(model: _emptyModel());

      final first = await orchestrator.processTurn(
        message: 'first user',
        session: NightSession(workingMind: workingMind, turns: const []),
        workingMind: workingMind,
      );
      final assistantText = first.utterance?.text;
      expect(assistantText, isNotNull);
      expect(assistantText, isNotEmpty);

      final second = await orchestrator.processTurn(
        message: 'second user',
        session: first.session,
        workingMind: workingMind,
        conversationGroundingBuffer: first.conversationGroundingBuffer,
      );

      final grounding = second.conversationGroundingBuffer;
      expect(grounding.userUtterances, ['first user', 'second user']);
      expect(grounding.userUtterances, isNot(contains(assistantText)));
      expect(
        conversation.lastConversationGrounding!.userUtterances,
        ['first user', 'second user'],
      );
    });

    test('5. window keeps current + two prior user utterances only', () async {
      final conversation = _CapturingConversationEngine();
      final orchestrator = _buildOrchestrator(conversationEngine: conversation);
      final workingMind = WorkingMindView(model: _emptyModel());

      var session = NightSession(workingMind: workingMind, turns: const []);
      var buffer = const ConversationGroundingBuffer.empty();
      for (final message in ['a', 'b', 'c', 'd']) {
        final result = await orchestrator.processTurn(
          message: message,
          session: session,
          workingMind: workingMind,
          conversationGroundingBuffer: buffer,
        );
        session = result.session;
        buffer = result.conversationGroundingBuffer;
      }

      expect(buffer.userUtterances, ['b', 'c', 'd']);
      expect(conversation.lastConversationGrounding!.userUtterances, ['b', 'c', 'd']);
    });

    test('7+8+9. discard at session end; MemoryEngine/LMM never get raw dialogue', () async {
      final memory = _CapturingMemoryEngine();
      final conversation = _CapturingConversationEngine();
      final orchestrator = _buildOrchestrator(
        conversationEngine: conversation,
        memoryEngine: memory,
      );
      final model = _emptyModel();
      final workingMind = WorkingMindView(model: model);

      const userDialogue = 'raw dialogue must never become durable memory';
      final turn = await orchestrator.processTurn(
        message: userDialogue,
        session: NightSession(workingMind: workingMind, turns: const []),
        workingMind: workingMind,
      );
      expect(turn.conversationGroundingBuffer.isEmpty, isFalse);

      final updated = orchestrator.completeSession(
        session: turn.session,
        model: model,
      );

      expect(orchestrator.conversationGroundingBuffer.isEmpty, isTrue);
      expect(memory.updateCount, 1);
      expect(memory.lastSummary, isNotNull);
      expect(_summaryContainsText(memory.lastSummary!, userDialogue), isFalse);
      expect(_modelContainsText(updated, userDialogue), isFalse);
      expect(_modelContainsText(memory.lastModel!, userDialogue), isFalse);

      // SessionTurn progression carries no dialogue fields.
      for (final t in turn.session.turns) {
        expect(t.toString(), isNot(contains(userDialogue)));
      }
    });
  });

  group('Compiler Stage F shaping modes', () {
    test('11. identical packages compile deterministically', () {
      final grounding = const ConversationGroundingBuffer.empty()
          .appendUserUtterance('same night line');
      final package = LlmInvocationPackage(
        what: ConversationPhase.permission,
        conversationGrounding: grounding,
        understanding: const ValidatedUnderstanding(),
      );

      final a = compiler.compile(package)!;
      final b = compiler.compile(package)!;
      expect(a.systemContent, b.systemContent);
      expect(a.userContent, b.userContent);
      expect(a.shapingNote, b.shapingNote);
    });

    test('12+13. understanding and workingMind remain presence-only', () {
      final model = _emptyModel(userId: 'wm-secret-user');
      final compiled = compiler.compile(
        LlmInvocationPackage(
          what: ConversationPhase.continuity,
          understanding: const ValidatedUnderstanding(),
          workingMind: WorkingMindView(model: model),
        ),
      )!;

      expect(compiled.shapingNote, contains('Attentive wording'));
      expect(
        compiled.shapingNote,
        contains('Do not render understanding or WorkingMind contents'),
      );
      expect(compiled.systemContent, isNot(contains('wm-secret-user')));
      expect(compiled.shapingNote, isNot(contains('wm-secret-user')));
      expect(compiled.systemContent, isNot(contains('Same-night conversation grounding')));
    });

    test('14+18. conversationGrounding materialized; no assistant lines', () {
      final grounding = const ConversationGroundingBuffer.empty()
          .appendUserUtterance('prior user')
          .appendUserUtterance('current user');
      final compiled = compiler.compile(
        LlmInvocationPackage(
          what: ConversationPhase.permission,
          conversationGrounding: grounding,
        ),
      )!;

      expect(compiled.systemContent, contains('Same-night conversation grounding'));
      expect(compiled.systemContent, contains('- prior user'));
      expect(compiled.systemContent, contains('- current user'));
      expect(compiled.systemContent, contains('Do not infer, summarize'));
      expect(compiled.systemContent, isNot(contains('assistant:')));
      expect(compiled.systemContent, isNot(contains('Assistant')));
    });

    test('19. absence of grounding does not block valid expression', () {
      final compiled = compiler.compile(
        LlmInvocationPackage(what: ConversationPhase.permission),
      );
      expect(compiled, isNotNull);
      expect(compiled!.shapingNote, contains('No additional shaping'));
      expect(compiled.userContent, isNotEmpty);
      expect(compiled.systemContent, isNotEmpty);
    });

    test('20. fail-closed remains applicable for illegal package WHAT', () {
      expect(
        () => LlmInvocationPackage(what: ConversationPhase.audio),
        throwsA(isA<ArgumentError>()),
      );
      expect(
        () => LlmInvocationPackage(what: ConversationPhase.silence),
        throwsA(isA<ArgumentError>()),
      );
      // Valid speakable package still compiles (positive control).
      expect(
        compiler.compile(LlmInvocationPackage(what: ConversationPhase.permission)),
        isNotNull,
      );
    });
  });

  group('Receipt / Naming cutover (Task 11)', () {
    final receiptStage = compiler.compile(
      LlmInvocationPackage(what: ConversationPhase.validation),
    )!.stage;

    test('15. Receipt uses currentUserUtterance from conversationGrounding only', () {
      final grounding = const ConversationGroundingBuffer.empty()
          .appendUserUtterance('prior')
          .appendUserUtterance('current receipt line');
      final slice = receipt.compile(
        stage: receiptStage,
        conversationGrounding: grounding,
      );

      expect(slice.userContent, contains('current receipt line'));
      expect(slice.userContent, isNot(contains('prior')));
      expect(
        slice.userContent,
        contains('Current-turn conversation grounding to receive'),
      );
    });

    test('16. Naming uses currentUserUtterance from conversationGrounding only', () {
      final namingStage = compiler.compile(
        LlmInvocationPackage(what: ConversationPhase.naming),
      )!.stage;
      final grounding = const ConversationGroundingBuffer.empty()
          .appendUserUtterance('prior')
          .appendUserUtterance('current naming line');
      final slice = naming.compile(
        stage: namingStage,
        conversationGrounding: grounding,
      );

      expect(slice.userContent, contains('current naming line'));
      expect(slice.userContent, isNot(contains('prior')));
      expect(slice.userContent, contains('already admitted'));
    });

    test('17. livedExpression alone must not ground Receipt or Naming', () {
      final receiptCompiled = compiler.compile(
        LlmInvocationPackage(
          what: ConversationPhase.validation,
          livedExpression: 'lived alone must not appear in Receipt grounding',
        ),
      )!;
      expect(
        receiptCompiled.userContent,
        isNot(contains('lived alone must not appear in Receipt grounding')),
      );
      expect(
        receiptCompiled.userContent,
        contains('No current-turn conversation grounding was supplied'),
      );

      final namingCompiled = compiler.compile(
        LlmInvocationPackage(
          what: ConversationPhase.naming,
          livedExpression: 'lived alone must not appear in Naming grounding',
        ),
      )!;
      expect(
        namingCompiled.userContent,
        isNot(contains('lived alone must not appear in Naming grounding')),
      );
      expect(
        namingCompiled.userContent,
        contains('No current-turn conversation grounding was supplied'),
      );
    });
  });
}

bool _summaryContainsText(SessionSummary summary, String text) {
  final haystacks = <String>[
    ...summary.mentalPatterns.map((e) => e.toString()),
    ...summary.emotionalPatterns.map((e) => e.toString()),
    ...summary.beliefs.map((e) => e.toString()),
    ...summary.needs.map((e) => e.toString()),
    ...summary.preferences.map((e) => e.toString()),
    ...summary.triggers.map((e) => e.toString()),
  ];
  return haystacks.any((h) => h.contains(text));
}

bool _modelContainsText(LivingMindModel model, String text) {
  final haystacks = <String>[
    model.identity.userId,
    ...model.mentalPatterns.map((e) => e.toString()),
    ...model.emotionalPatterns.map((e) => e.toString()),
    ...model.beliefs.map((e) => e.toString()),
    ...model.needs.map((e) => e.toString()),
    ...model.preferences.map((e) => e.toString()),
    ...model.triggers.map((e) => e.toString()),
  ];
  return haystacks.any((h) => h.contains(text));
}

CognitiveOrchestrator _buildOrchestrator({
  ConversationEngine? conversationEngine,
  MemoryEngine? memoryEngine,
}) {
  return CognitiveOrchestrator(
    perceptionEngine: const PerceptionEngine(),
    mentalPatternDetector: const MentalPatternDetector(),
    emotionalPatternDetector: const EmotionalPatternDetector(),
    beliefDetector: const BeliefDetector(),
    needDetector: const NeedDetector(),
    preferenceDetector: const PreferenceDetector(),
    releaseEngine: const ReleaseEngine(),
    conversationPolicy: const ConversationPolicy(),
    conversationEngine: conversationEngine ??
        const ConversationEngine(
          languageModelClient: LanguageModelClient(
            vendorProvider: FaithfulTestVendorProvider(),
          ),
        ),
    exitIntelligence: const ExitIntelligence(),
    sessionSummarizer: const SessionSummarizer(),
    memoryEngine: memoryEngine ?? MemoryEngine(),
  );
}

LivingMindModel _emptyModel({String userId = 'grounding-regression'}) {
  final now = DateTime.utc(2026, 1, 1);
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

class _CapturingMemoryEngine extends MemoryEngine {
  int updateCount = 0;
  SessionSummary? lastSummary;
  LivingMindModel? lastModel;

  @override
  LivingMindModel update(LivingMindModel model, SessionSummary summary) {
    updateCount++;
    lastSummary = summary;
    final next = super.update(model, summary);
    lastModel = next;
    return next;
  }
}

class _CapturingConversationEngine extends ConversationEngine {
  ConversationGroundingBuffer? lastConversationGrounding;
  String? lastLivedExpression;

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
    lastLivedExpression = livedExpression;
    lastConversationGrounding = conversationGrounding;
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
