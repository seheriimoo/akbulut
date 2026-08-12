import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:slowave/config/app_config.dart';
import 'package:slowave/core/brain/belief_detector.dart';
import 'package:slowave/core/brain/cognitive_orchestrator.dart';
import 'package:slowave/core/brain/conversation_engine.dart';
import 'package:slowave/core/brain/conversation_grounding_buffer.dart';
import 'package:slowave/core/brain/conversation_policy.dart';
import 'package:slowave/core/brain/emotional_pattern_detector.dart';
import 'package:slowave/core/brain/exit_decision.dart';
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
import 'package:slowave/core/brain/vendor_provider.dart';

/// Full night path → audio. Report only.
///
/// flutter test --dart-define-from-file=config/secrets.local.json \
///   test/integration/night_to_audio_openai_capture_test.dart
void main() {
  test('Night softens through Enough into audio', () async {
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
      memoryEngine: MemoryEngine(),
    );

    final mind = HcosLiveEntry.emptyMindModel();
    var session = HcosLiveEntry.openNightSession(mind);
    ConversationGroundingBuffer? grounding;

    // Soften after first load so the night can climb to Release → Enough → Audio.
    const turns = <String>[
      "I can't stop thinking about tomorrow.",
      'A little quieter now.',
      'Softening.',
      'ok',
      'tmm',
    ];

    final report = StringBuffer()
      ..writeln('=== NIGHT → AUDIO OPENAI CAPTURE ===');

    ExitDecision? lastExit;
    for (var i = 0; i < turns.length; i++) {
      final message = turns[i];
      capture.lastCompletedText = null;

      final result = await orchestrator.processTurn(
        message: message,
        session: session,
        workingMind: HcosLiveEntry.workingMindOf(session),
        conversationGroundingBuffer: grounding,
      );
      session = HcosLiveEntry.applyTurnResult(result);
      grounding = HcosLiveEntry.groundingBufferOf(result);
      lastExit = result.exitDecision;

      report
        ..writeln()
        ..writeln('--- TURN ${i + 1} ---')
        ..writeln('USER: $message')
        ..writeln('READINESS: ${result.releaseDecision.readiness.name}')
        ..writeln('PHASE: ${result.conversationDecision.phase.name}')
        ..writeln('SHOULD_SPEAK: ${result.conversationDecision.shouldSpeak}')
        ..writeln('EXIT: ${result.exitDecision.name}')
        ..writeln('RAW: ${capture.lastCompletedText ?? '(none)'}')
        ..writeln('FINAL: ${result.utterance?.text ?? '(null / no speech)'}');

      if (result.exitDecision == ExitDecision.transitionToAudio) {
        report.writeln('>>> AUDIO BRIDGE HIT');
        break;
      }
    }

    // ignore: avoid_print
    print(report.toString());

    expect(
      lastExit,
      ExitDecision.transitionToAudio,
      reason: 'Night must reach audio after Enough quiet / softening path',
    );
  }, timeout: const Timeout(Duration(seconds: 240)));
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
