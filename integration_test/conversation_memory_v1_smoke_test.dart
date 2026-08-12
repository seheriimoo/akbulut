import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:slowave/core/brain/belief_detector.dart';
import 'package:slowave/core/brain/cognitive_orchestrator.dart';
import 'package:slowave/core/brain/cognitive_turn_result.dart';
import 'package:slowave/core/brain/compiled_instruction_package.dart';
import 'package:slowave/core/brain/conversation_compiler.dart';
import 'package:slowave/core/brain/conversation_engine.dart';
import 'package:slowave/core/brain/conversation_grounding_buffer.dart';
import 'package:slowave/core/brain/conversation_phase.dart';
import 'package:slowave/core/brain/conversation_policy.dart';
import 'package:slowave/core/brain/emotional_pattern_detector.dart';
import 'package:slowave/core/brain/exit_intelligence.dart';
import 'package:slowave/core/brain/hcos_live_entry.dart';
import 'package:slowave/core/brain/language_model_client.dart';
import 'package:slowave/core/brain/living_mind_model.dart';
import 'package:slowave/core/brain/llm_invocation_package.dart';
import 'package:slowave/core/brain/memory_engine.dart';
import 'package:slowave/core/brain/mental_pattern_detector.dart';
import 'package:slowave/core/brain/need_detector.dart';
import 'package:slowave/core/brain/night_session.dart';
import 'package:slowave/core/brain/perception_engine.dart';
import 'package:slowave/core/brain/preference_detector.dart';
import 'package:slowave/core/brain/release_engine.dart';
import 'package:slowave/core/brain/session_summary.dart';
import 'package:slowave/core/brain/session_summarizer.dart';
import 'package:slowave/core/brain/vendor_provider.dart';

/// Task 13 — Conversation Memory V1 end-to-end smoke on device/simulator.
///
/// Mirrors AISleepChatScreen host lifecycle via [HcosLiveEntry]:
/// open night → multi-turn processTurn with grounding carry → complete night.
///
/// Uses FaithfulTestVendorProvider so smoke does not require live OpenAI keys.
/// Vendor wrapper captures compiled packages for grounding assertions.
///
/// Run:
///   flutter test integration_test/conversation_memory_v1_smoke_test.dart \
///     -d <ios-simulator-id>
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'Conversation Memory V1 night smoke: grounding lifecycle + discard',
    (tester) async {
      final vendor = _CapturingVendorProvider(const _SmokeVendorProvider());
      final memory = _CapturingMemoryEngine();
      final orchestrator = _smokeOrchestrator(vendor: vendor, memory: memory);

      // 1. Start a new NightSession (same helpers as production chat host).
      var mindModel = HcosLiveEntry.emptyMindModel(userId: 'smoke-task13');
      NightSession? session = HcosLiveEntry.openNightSession(mindModel);
      CognitiveTurnResult? lastTurn;
      final assistantTexts = <String>[];
      final userMessages = <String>[
        'my mind will not settle',
        'I keep replaying tomorrow',
        'the loops will not stop',
        'still holding onto the day',
      ];

      // 2–6. Multiple user turns; grounding updates; user-only; window size.
      for (final message in userMessages) {
        final priorGrounding = lastTurn == null
            ? null
            : HcosLiveEntry.groundingBufferOf(lastTurn!);
        final result = await orchestrator.processTurn(
          message: message,
          session: session!,
          workingMind: HcosLiveEntry.workingMindOf(session),
          conversationGroundingBuffer: priorGrounding,
        );
        session = HcosLiveEntry.applyTurnResult(result);
        lastTurn = result;

        final reply = result.utterance?.text;
        if (reply != null && reply.isNotEmpty) {
          assistantTexts.add(reply);
        }

        final grounding = result.conversationGroundingBuffer;
        expect(grounding.isEmpty, isFalse);
        expect(grounding.currentUserUtterance, message);
        expect(grounding.userUtterances.length, lessThanOrEqualTo(3));
        for (final assistant in assistantTexts) {
          expect(grounding.userUtterances, isNot(contains(assistant)));
        }
      }

      final nightGrounding = lastTurn!.conversationGroundingBuffer;
      expect(nightGrounding.userUtterances, [
        'I keep replaying tomorrow',
        'the loops will not stop',
        'still holding onto the day',
      ]);
      expect(nightGrounding.priorUserUtterances.length, 2);
      expect(nightGrounding.currentUserUtterance, 'still holding onto the day');

      // 3. Orchestrator-owned buffer matches carried result.
      expect(
        orchestrator.conversationGroundingBuffer.userUtterances,
        nightGrounding.userUtterances,
      );

      // 7–8. Receipt / Naming + Compiler materialization from admitted grounding.
      expect(vendor.compiledSnapshots, isNotEmpty);
      final liveCompiled = vendor.compiledSnapshots.last;
      expect(
        liveCompiled.systemContent,
        contains('Same-night conversation grounding'),
      );
      for (final u in nightGrounding.userUtterances) {
        expect(liveCompiled.systemContent, contains('- $u'));
      }
      for (final assistant in assistantTexts) {
        expect(liveCompiled.systemContent, isNot(contains(assistant)));
      }

      const compiler = ConversationCompiler();
      final receiptCompiled = compiler.compile(
        LlmInvocationPackage(
          what: ConversationPhase.validation,
          conversationGrounding: nightGrounding,
        ),
      )!;
      expect(
        receiptCompiled.userContent,
        contains('Current-turn conversation grounding to receive'),
      );
      expect(
        receiptCompiled.userContent,
        contains(nightGrounding.currentUserUtterance!),
      );
      expect(receiptCompiled.userContent, isNot(contains('I keep replaying tomorrow')));

      final namingCompiled = compiler.compile(
        LlmInvocationPackage(
          what: ConversationPhase.naming,
          conversationGrounding: nightGrounding,
        ),
      )!;
      expect(namingCompiled.userContent, contains('already admitted'));
      expect(
        namingCompiled.userContent,
        contains(nightGrounding.currentUserUtterance!),
      );
      expect(namingCompiled.userContent, isNot(contains('I keep replaying tomorrow')));

      // Deterministic materialization: same package → same compile.
      final again = compiler.compile(
        LlmInvocationPackage(
          what: ConversationPhase.permission,
          conversationGrounding: nightGrounding,
        ),
      )!;
      final again2 = compiler.compile(
        LlmInvocationPackage(
          what: ConversationPhase.permission,
          conversationGrounding: nightGrounding,
        ),
      )!;
      expect(again.systemContent, again2.systemContent);

      // livedExpression alone must not ground Receipt (cutover check).
      final livedOnly = compiler.compile(
        LlmInvocationPackage(
          what: ConversationPhase.validation,
          livedExpression: 'should not ground receipt alone',
        ),
      )!;
      expect(
        livedOnly.userContent,
        isNot(contains('should not ground receipt alone')),
      );

      // 9–12. Complete night; discard grounding; MemoryEngine/LMM no dialogue.
      final dialogueMarker = nightGrounding.currentUserUtterance!;
      mindModel = HcosLiveEntry.completeNightSession(
        orchestrator: orchestrator,
        session: session!,
        model: mindModel,
      );
      session = null;

      expect(orchestrator.conversationGroundingBuffer.isEmpty, isTrue);
      expect(memory.updateCount, 1);
      expect(memory.lastSummary, isNotNull);
      expect(_summaryHasText(memory.lastSummary!, dialogueMarker), isFalse);
      expect(_modelHasText(mindModel, dialogueMarker), isFalse);
      for (final u in userMessages) {
        expect(_summaryHasText(memory.lastSummary!, u), isFalse);
        expect(_modelHasText(mindModel, u), isFalse);
      }
    },
  );
}

CognitiveOrchestrator _smokeOrchestrator({
  required VendorProvider vendor,
  required MemoryEngine memory,
}) {
  // Same component graph as HcosLiveEntry.createOrchestrator, with test
  // vendor + capturing memory for smoke assertions (no production change).
  return CognitiveOrchestrator(
    perceptionEngine: const PerceptionEngine(),
    mentalPatternDetector: const MentalPatternDetector(),
    emotionalPatternDetector: const EmotionalPatternDetector(),
    beliefDetector: const BeliefDetector(),
    needDetector: const NeedDetector(),
    preferenceDetector: const PreferenceDetector(),
    releaseEngine: const ReleaseEngine(),
    conversationPolicy: const ConversationPolicy(),
    conversationEngine: ConversationEngine(
      languageModelClient: LanguageModelClient(vendorProvider: vendor),
    ),
    exitIntelligence: const ExitIntelligence(),
    sessionSummarizer: const SessionSummarizer(),
    memoryEngine: memory,
  );
}

bool _summaryHasText(SessionSummary summary, String text) {
  final parts = <String>[
    ...summary.mentalPatterns.map((e) => e.toString()),
    ...summary.emotionalPatterns.map((e) => e.toString()),
    ...summary.beliefs.map((e) => e.toString()),
    ...summary.needs.map((e) => e.toString()),
    ...summary.preferences.map((e) => e.toString()),
    ...summary.triggers.map((e) => e.toString()),
  ];
  return parts.any((p) => p.contains(text));
}

bool _modelHasText(LivingMindModel model, String text) {
  final parts = <String>[
    model.identity.userId,
    ...model.mentalPatterns.map((e) => e.toString()),
    ...model.emotionalPatterns.map((e) => e.toString()),
    ...model.beliefs.map((e) => e.toString()),
    ...model.needs.map((e) => e.toString()),
    ...model.preferences.map((e) => e.toString()),
    ...model.triggers.map((e) => e.toString()),
  ];
  return parts.any((p) => p.contains(text));
}

class _CapturingVendorProvider implements VendorProvider {
  _CapturingVendorProvider(this._inner);

  final VendorProvider _inner;
  final List<CompiledInstructionPackage> compiledSnapshots = [];

  @override
  Future<VendorResponse> complete(VendorRequest request) async {
    compiledSnapshots.add(request.compiled);
    return _inner.complete(request);
  }
}

/// Transport stub for device smoke only. Not a production vendor.
class _SmokeVendorProvider implements VendorProvider {
  const _SmokeVendorProvider();

  @override
  Future<VendorResponse> complete(VendorRequest request) async {
    switch (request.package.what) {
      case ConversationPhase.validation:
        return VendorResponse(text: 'That pressure is still looping.');
      case ConversationPhase.naming:
        return VendorResponse(text: 'Something is still holding on.');
      case ConversationPhase.permission:
        return VendorResponse(
          text: 'You do not have to solve this tonight.',
        );
      case ConversationPhase.release:
        return VendorResponse(text: 'You can let this rest for now.');
      case ConversationPhase.continuity:
        return VendorResponse(text: 'Nothing more is needed right now.');
      case ConversationPhase.neutralEntry:
        return VendorResponse(text: "Hi whenever you're ready.");
      case ConversationPhase.audio:
      case ConversationPhase.silence:
        throw VendorError(
          kind: VendorErrorKind.unusable,
          message: 'Non-speech WHAT must not reach VendorProvider',
        );
    }
  }
}

class _CapturingMemoryEngine extends MemoryEngine {
  int updateCount = 0;
  SessionSummary? lastSummary;

  @override
  LivingMindModel update(LivingMindModel model, SessionSummary summary) {
    updateCount++;
    lastSummary = summary;
    return super.update(model, summary);
  }
}
