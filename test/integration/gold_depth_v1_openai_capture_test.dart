import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:slowave/config/app_config.dart';
import 'package:slowave/core/brain/belief_detector.dart';
import 'package:slowave/core/brain/cognitive_orchestrator.dart';
import 'package:slowave/core/brain/conversation_engine.dart';
import 'package:slowave/core/brain/conversation_grounding_buffer.dart';
import 'package:slowave/core/brain/conversation_phase.dart';
import 'package:slowave/core/brain/conversation_policy.dart';
import 'package:slowave/core/brain/conversation_utterance.dart';
import 'package:slowave/core/brain/emotional_pattern_detector.dart';
import 'package:slowave/core/brain/exit_intelligence.dart';
import 'package:slowave/core/brain/hcos_live_entry.dart';
import 'package:slowave/core/brain/language_model_client.dart';
import 'package:slowave/core/brain/memory_engine.dart';
import 'package:slowave/core/brain/mental_pattern_detector.dart';
import 'package:slowave/core/brain/need_detector.dart';
import 'package:slowave/core/brain/openai_vendor_provider.dart';
import 'package:slowave/core/brain/perception_engine.dart';
import 'package:slowave/core/brain/preference_detector.dart';
import 'package:slowave/core/brain/release_engine.dart';
import 'package:slowave/core/brain/session_summarizer.dart';
import 'package:slowave/core/brain/thinking_function_detector.dart';
import 'package:slowave/core/brain/utterance_guard.dart';
import 'package:slowave/core/brain/vendor_provider.dart';

/// GOLD DEPTH V1 — real OpenAI qualitative capture (report only; no retune).
///
/// flutter test --dart-define-from-file=config/secrets.local.json \
///   test/integration/gold_depth_v1_openai_capture_test.dart
void main() {
  test('GOLD DEPTH V1 three-turn OpenAI capture', () async {
    WidgetsFlutterBinding.ensureInitialized();

    final previousOverrides = HttpOverrides.current;
    HttpOverrides.global = _RealHttpOverrides();
    addTearDown(() {
      HttpOverrides.global = previousOverrides;
    });

    await AppConfig.load();
    expect(AppConfig.hasOpenAiApiKey, isTrue);

    final inner = OpenAIVendorProvider.fromEnv();
    final capture = _CapturingVendorProvider(inner);
    const guard = UtteranceGuard();
    const detector = ThinkingFunctionDetector();
    const perception = PerceptionEngine();

    final orchestrator = CognitiveOrchestrator(
      perceptionEngine: perception,
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
      memoryEngine: MemoryEngine(),
      thinkingFunctionDetector: detector,
    );

    final mind = HcosLiveEntry.emptyMindModel();
    var session = HcosLiveEntry.openNightSession(mind);
    ConversationGroundingBuffer? grounding;

    const turns = <String>[
      "I can't stop thinking about tomorrow.",
      'I keep thinking about everything that could go wrong.',
      'I know nothing has happened yet, but my mind keeps preparing for the worst.',
    ];

    final report = StringBuffer()
      ..writeln('=== GOLD DEPTH V1 REAL OPENAI CAPTURE ===');

    for (var i = 0; i < turns.length; i++) {
      final message = turns[i];
      capture.lastCompletedText = null;

      final priors = grounding?.priorUserUtterances ?? const <String>[];
      final hypothesis = detector.detect(
        currentMessage: message,
        conversationGrounding:
            (grounding ?? const ConversationGroundingBuffer.empty())
                .appendUserUtterance(message),
        perceptionEvidence: perception.perceive(message),
      );

      final result = await orchestrator.processTurn(
        message: message,
        session: session,
        workingMind: HcosLiveEntry.workingMindOf(session),
        conversationGroundingBuffer: grounding,
      );
      session = HcosLiveEntry.applyTurnResult(result);
      grounding = HcosLiveEntry.groundingBufferOf(result);

      final raw = capture.lastCompletedText;
      final phase = result.conversationDecision.phase;
      final finalText = result.utterance?.text;

      String guardResult;
      if (raw == null || raw.trim().isEmpty) {
        guardResult = 'NO_RAW_CANDIDATE';
      } else if (finalText != null && finalText == raw) {
        guardResult = 'ADMITTED';
      } else if (finalText == null) {
        final probe = guard.allow(
          utterance: ConversationUtterance(text: raw),
          what: phase,
        );
        guardResult = probe == null ? 'REJECTED' : 'REJECTED_OR_DROPPED';
      } else {
        guardResult = 'ADMITTED_WITH_DIFF';
      }

      report
        ..writeln()
        ..writeln('--- TURN ${i + 1} ---')
        ..writeln('USER: $message')
        ..writeln(
          'HYPOTHESIS: ${hypothesis?.kind.name ?? 'null'} '
          'confidence=${hypothesis?.confidence ?? 'n/a'} '
          'evidence=${hypothesis?.evidenceIds ?? const []}',
        )
        ..writeln('PRIORS_USED: $priors')
        ..writeln('PHASE: ${phase.name}')
        ..writeln('RAW_CANDIDATE: ${raw ?? '(none)'}')
        ..writeln('GUARD: $guardResult')
        ..writeln('FINAL: ${finalText ?? '(null)'}');
    }

    // Print once for the human report (honest; no retune).
    // ignore: avoid_print
    print(report.toString());
  }, timeout: const Timeout(Duration(seconds: 180)));
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

class _RealHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    HttpOverrides.global = null;
    try {
      return HttpClient(context: context);
    } finally {
      HttpOverrides.global = this;
    }
  }
}
