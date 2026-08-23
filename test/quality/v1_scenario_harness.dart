import 'package:slowave/core/brain/belief_detector.dart';
import 'package:slowave/core/brain/cognitive_orchestrator.dart';
import 'package:slowave/core/brain/conversation_blueprint_binding.dart';
import 'package:slowave/core/brain/conversation_compiler.dart';
import 'package:slowave/core/brain/conversation_engine.dart';
import 'package:slowave/core/brain/conversation_grounding_buffer.dart';
import 'package:slowave/core/brain/conversation_phase.dart';
import 'package:slowave/core/brain/conversation_policy.dart';
import 'package:slowave/core/brain/emotional_pattern_detector.dart';
import 'package:slowave/core/brain/exit_decision.dart';
import 'package:slowave/core/brain/exit_intelligence.dart';
import 'package:slowave/core/brain/hcos_live_entry.dart';
import 'package:slowave/core/brain/identity.dart';
import 'package:slowave/core/brain/language_model_client.dart';
import 'package:slowave/core/brain/living_mind_model.dart';
import 'package:slowave/core/brain/llm_invocation_package.dart';
import 'package:slowave/core/brain/memory_engine.dart';
import 'package:slowave/core/brain/mental_pattern_detector.dart';
import 'package:slowave/core/brain/need_detector.dart';
import 'package:slowave/core/brain/perception_engine.dart';
import 'package:slowave/core/brain/preference_detector.dart';
import 'package:slowave/core/brain/release_decision.dart';
import 'package:slowave/core/brain/release_engine.dart';
import 'package:slowave/core/brain/session_summarizer.dart';
import 'package:slowave/core/brain/vendor_provider.dart';

import '../core/brain/faithful_test_vendor_provider.dart';
import 'v1_scenario_fixtures.dart';

/// Structural outcome for one V1 scenario (Step 1 only).
class V1ScenarioStructuralResult {
  final String id;
  final String title;
  final bool passed;
  final List<String> failures;

  const V1ScenarioStructuralResult({
    required this.id,
    required this.title,
    required this.passed,
    required this.failures,
  });
}

/// Minimum executable V1 scenario harness — deterministic structural checks only.
///
/// Does not score warmth, naturalness, or Human Gold.
/// Does not modify production conversation behavior.
class V1ScenarioHarness {
  const V1ScenarioHarness();

  Future<V1ScenarioStructuralResult> run(V1ScenarioFixture scenario) async {
    final failures = <String>[];
    void fail(String message) => failures.add(message);

    final vendor = scenario.forceGuardReject
        ? const _GuardRejectVendorProvider()
        : const FaithfulTestVendorProvider();
    final capture = _CapturingVendorProvider(vendor);

    final orchestrator = CognitiveOrchestrator(
      perceptionEngine: const PerceptionEngine(),
      mentalPatternDetector: const MentalPatternDetector(),
      emotionalPatternDetector: const EmotionalPatternDetector(),
      beliefDetector: const BeliefDetector(),
      needDetector: const NeedDetector(),
      preferenceDetector: const PreferenceDetector(),
      releaseEngine: const ReleaseEngine(),
      conversationPolicy: const ConversationPolicy(),
      conversationEngine: ConversationEngine(
        languageModelClient: LanguageModelClient(vendorProvider: capture),
      ),
      exitIntelligence: const ExitIntelligence(),
      sessionSummarizer: const SessionSummarizer(),
      memoryEngine: const MemoryEngine(),
    );

    final mind = _emptyModel();
    var session = HcosLiveEntry.openNightSession(mind);
    ConversationGroundingBuffer? priorGrounding;
    final seenAssistantTexts = <String>[];
    var sawAudioTransition = false;
    var turnIndex = 0;

    try {
      for (final userMessage in scenario.userTurns) {
        turnIndex++;
        final result = await orchestrator.processTurn(
          message: userMessage,
          session: session,
          workingMind: HcosLiveEntry.workingMindOf(session),
          conversationGroundingBuffer: priorGrounding,
        );
        session = HcosLiveEntry.applyTurnResult(result);
        priorGrounding = HcosLiveEntry.groundingBufferOf(result);

        // User-turn order / grounding current.
        final grounding = result.conversationGroundingBuffer;
        if (grounding.currentUserUtterance != userMessage.trim()) {
          fail(
            'turn $turnIndex: grounding current != user message '
            '(got ${grounding.currentUserUtterance})',
          );
        }

        // User utterances only; window = current + up to 2 prior (≤ 3).
        if (grounding.userUtterances.length >
            ConversationGroundingBuffer.maxUserUtterances) {
          fail('turn $turnIndex: grounding window exceeded max');
        }
        final admittedSoFar = scenario.userTurns
            .take(turnIndex)
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList();
        final windowStart = admittedSoFar.length >
                ConversationGroundingBuffer.maxUserUtterances
            ? admittedSoFar.length -
                ConversationGroundingBuffer.maxUserUtterances
            : 0;
        final expectedWindow = admittedSoFar.sublist(windowStart);
        final actualWindow = grounding.userUtterances.toList(growable: false);
        if (actualWindow.join('\u0001') != expectedWindow.join('\u0001')) {
          fail(
            'turn $turnIndex: grounding window mismatch '
            '(got $actualWindow expected $expectedWindow)',
          );
        }
        for (final assistant in seenAssistantTexts) {
          if (grounding.userUtterances.contains(assistant)) {
            fail('turn $turnIndex: assistant text entered grounding');
          }
        }

        // No invented / empty grounding entries.
        for (final u in grounding.userUtterances) {
          if (u.trim().isEmpty) {
            fail('turn $turnIndex: empty grounding utterance');
          }
        }

        final phase = result.conversationDecision.phase;
        final exit = result.exitDecision;
        final readiness = result.releaseDecision.readiness;

        // Exit/audio authorization consistency with frozen ExitIntelligence.
        if (exit == ExitDecision.transitionToAudio) {
          sawAudioTransition = true;
          // Enough may speak once with transition authorized, then audio.
          if (phase != ConversationPhase.audio &&
              phase != ConversationPhase.continuity) {
            fail(
              'turn $turnIndex: transitionToAudio without audio/Enough phase '
              '(phase=${phase.name})',
            );
          }
          if (readiness != ReleaseReadiness.transitionReady) {
            fail(
              'turn $turnIndex: transitionToAudio without transitionReady '
              '(readiness=${readiness.name})',
            );
          }
        }

        if (scenario.forbidAudioTransition &&
            exit == ExitDecision.transitionToAudio) {
          fail('turn $turnIndex: audio transition forbidden for this scenario');
        }

        // Sealed WHAT / stage validity for speakable continues.
        if (exit == ExitDecision.continueConversation &&
            result.conversationDecision.shouldSpeak) {
          final binding =
              ConversationBlueprintCanon.instance.bindingFor(phase);
          if (binding == null) {
            fail(
              'turn $turnIndex: speakable continue without Blueprint binding '
              '(phase=${phase.name})',
            );
          } else if (binding.sealedWhat != phase) {
            fail('turn $turnIndex: Blueprint sealedWhat mismatch');
          }
        }

        // Null / Guard reject: rejected vendor text must never surface.
        final utterance = result.utterance;
        if (utterance != null) {
          if (utterance.text.trim().isEmpty) {
            fail('turn $turnIndex: empty utterance fabricated');
          }
          seenAssistantTexts.add(utterance.text);
          if (scenario.forceGuardReject &&
              capture.lastCompletedText != null &&
              utterance.text.trim() == capture.lastCompletedText!.trim()) {
            fail(
              'turn $turnIndex: rejected vendor text surfaced after Guard',
            );
          }
        } else if (scenario.forceGuardReject &&
            exit == ExitDecision.continueConversation) {
          fail(
            'turn $turnIndex: Guard reject left silence — expected safe '
            'fallback',
          );
        }

        // Non-speech authorized paths may legally have null utterance.
        if (phase == ConversationPhase.audio ||
            phase == ConversationPhase.silence) {
          if (utterance != null) {
            fail('turn $turnIndex: speech emitted on non-speech phase');
          }
        }
      }

      if (scenario.requireAudioTransitionByEnd && !sawAudioTransition) {
        fail('expected audio transition by end of scenario');
      }

      // Compiler determinism for identical sealed package (structural).
      const compiler = ConversationCompiler();
      final package = LlmInvocationPackage(
        what: ConversationPhase.permission,
        conversationGrounding: priorGrounding,
      );
      final a = compiler.compile(package);
      final b = compiler.compile(package);
      if (a == null || b == null) {
        fail('compiler failed closed unexpectedly on permission package');
      } else if (a.systemContent != b.systemContent ||
          a.userContent != b.userContent) {
        fail('compiler non-deterministic for identical package');
      }

      // S20: Guard reject → admitted fallback; never rejected vendor wording.
      if (scenario.forceGuardReject) {
        if (seenAssistantTexts.isEmpty) {
          fail('S20: silence after Guard reject — expected safe fallback');
        }
        final rejected = capture.lastCompletedText?.trim();
        if (rejected != null &&
            seenAssistantTexts.any((t) => t.trim() == rejected)) {
          fail('S20: rejected vendor text was admitted');
        }
        if (rejected != null &&
            seenAssistantTexts.any(
              (t) => t.toLowerCase().contains('tip tonight'),
            )) {
          fail('S20: rejected tip language leaked into fallback');
        }
      }
    } catch (e, st) {
      fail('scenario crashed: $e');
      fail('$st');
    }

    return V1ScenarioStructuralResult(
      id: scenario.id,
      title: scenario.title,
      passed: failures.isEmpty,
      failures: failures,
    );
  }

  Future<List<V1ScenarioStructuralResult>> runAll(
    List<V1ScenarioFixture> fixtures,
  ) async {
    final out = <V1ScenarioStructuralResult>[];
    for (final fixture in fixtures) {
      out.add(await run(fixture));
    }
    return out;
  }
}

LivingMindModel _emptyModel() {
  final now = DateTime.utc(2026, 1, 1);
  return LivingMindModel(
    identity: Identity(
      userId: 'v1-quality-harness',
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

/// Returns DNA-violating multi-insight text so UtteranceGuard rejects.
class _GuardRejectVendorProvider implements VendorProvider {
  const _GuardRejectVendorProvider();

  @override
  Future<VendorResponse> complete(VendorRequest request) async {
    return VendorResponse(
      text: 'That makes sense. Also try this tip tonight.',
    );
  }
}

class _CapturingVendorProvider implements VendorProvider {
  _CapturingVendorProvider(this._inner);

  final VendorProvider _inner;
  String? lastCompletedText;

  @override
  Future<VendorResponse> complete(VendorRequest request) async {
    final response = await _inner.complete(request);
    lastCompletedText = response.text;
    return response;
  }
}
