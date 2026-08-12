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

/// Full multi-turn night → Enough handoff → audio. Report only.
///
/// flutter test --dart-define-from-file=config/secrets.local.json \
///   test/integration/full_night_openai_capture_test.dart
void main() {
  test('Full night conversation through audio handoff', () async {
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

    // Full soft-night arc: load → deepen → permission cue → release → enough.
    // Turkish path exercises same-language mirror + TR Guard stems.
    const turns = <String>[
      'Yarın hakkında düşünmeyi bırakamıyorum.',
      'Aklıma hep bir şeylerin ters gidebileceği geliyor.',
      'Henüz hiçbir şey olmadı ama zihnim en kötüsüne hazırlanıyor.',
      'Biraz daha sessiz şimdi.',
      'Evet… biraz yumuşuyor.',
      'tamam',
      'tmm',
    ];

    final report = StringBuffer()
      ..writeln('=== FULL NIGHT OPENAI CAPTURE ===')
      ..writeln()
      ..writeln('--- TRANSCRIPT ---');

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

      final spoken = result.utterance?.text;
      report
        ..writeln()
        ..writeln('You: $message')
        ..writeln(
          spoken == null || spoken.trim().isEmpty
              ? 'Nocta: (silence)'
              : 'Nocta: $spoken',
        )
        ..writeln(
          '  [${result.conversationDecision.phase.name} | '
          '${result.releaseDecision.readiness.name} | '
          '${result.exitDecision.name}'
          '${spoken == null && (capture.lastCompletedText?.isNotEmpty ?? false) ? ' | GUARD_DROP' : ''}]',
        );

      if (result.exitDecision == ExitDecision.transitionToAudio) {
        report
          ..writeln()
          ..writeln('>>> AUDIO BRIDGE — rest session starts');
        break;
      }
    }

    // ignore: avoid_print
    print(report.toString());

    expect(
      lastExit,
      ExitDecision.transitionToAudio,
      reason: 'Full night must reach audio after Enough handoff',
    );
  }, timeout: const Timeout(Duration(seconds: 300)));
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
