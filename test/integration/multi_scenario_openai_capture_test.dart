import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:slowave/billing/premium_product_access.dart';
import 'package:slowave/billing/sleep_bed_catalog.dart';
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
import 'package:slowave/core/brain/night_audio_handoff.dart';
import 'package:slowave/core/brain/openai_vendor_provider.dart';
import 'package:slowave/core/brain/perception_engine.dart';
import 'package:slowave/core/brain/preference_detector.dart';
import 'package:slowave/core/brain/release_engine.dart';
import 'package:slowave/core/brain/session_summarizer.dart';
import 'package:slowave/core/brain/vendor_provider.dart';
import 'package:slowave/quality/conversation_evaluator.dart';

/// Multi-scenario nights + Conversation Evaluator gate.
///
/// flutter test --dart-define-from-file=config/secrets.local.json \
///   test/integration/multi_scenario_openai_capture_test.dart
void main() {
  test('Multi-scenario nights pass evaluator into audio', () async {
    WidgetsFlutterBinding.ensureInitialized();

    final previousOverrides = HttpOverrides.current;
    HttpOverrides.global = _RealHttpOverrides();
    addTearDown(() {
      HttpOverrides.global = previousOverrides;
    });

    await AppConfig.load();
    expect(AppConfig.hasOpenAiApiKey, isTrue);

    const evaluator = ConversationEvaluator();
    const beds = SleepBedCatalog();
    const handoff = NightAudioHandoff();

    final scenarios = <String, List<String>>{
      'EN_future_anxiety': [
        "I can't stop thinking about tomorrow.",
        'I keep thinking about everything that could go wrong.',
        'A little quieter now.',
        'Softening.',
        'ok',
      ],
      'EN_overthinking': [
        "My mind won't stop.",
        'It keeps searching for one more answer.',
        'A little quieter now.',
        'Yeah… softening.',
        'ok',
      ],
      'TR_loneliness': [
        'Bu gece kendimi çok yalnız hissediyorum.',
        'Eksiklik gibi bir şey var içimde.',
        'Biraz daha sessiz şimdi.',
        'Evet… yumuşuyor.',
        'tamam',
      ],
      'TR_overthinking': [
        'Zihnim bir türlü durmuyor.',
        'Hep bir cevap daha arıyor.',
        'Biraz daha sessiz şimdi.',
        'Evet… yumuşuyor.',
        'tamam',
      ],
      'TR_future_anxiety': [
        'Yarını düşünmeden duramıyorum.',
        'Her şeyin ters gidebileceğini aklımdan çıkaramıyorum.',
        'Biraz daha sessiz şimdi.',
        'Yumuşuyor.',
        'tamam',
      ],
    };

    final report = StringBuffer()..writeln('=== MULTI-SCENARIO + EVALUATOR ===');

    for (final entry in scenarios.entries) {
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
      ExitDecision? lastExit;
      final traces = <NightTurnTrace>[];

      report
        ..writeln()
        ..writeln('--- ${entry.key} ---');

      for (final message in entry.value) {
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

        final text = result.utterance?.text;
        final raw = capture.lastCompletedText;
        final dropped = text == null &&
            raw != null &&
            raw.trim().isNotEmpty;
        traces.add(
          NightTurnTrace(
            phase: result.conversationDecision.phase.name,
            spoken: text,
            guardDropped: dropped,
            language: ConversationEvaluator.detectLanguage(text ?? raw),
          ),
        );

        report.writeln('You: $message');
        report.writeln(
          text == null || text.trim().isEmpty
              ? 'Nocta [${result.conversationDecision.phase.name}]: (silence'
                  '${dropped ? ' | GUARD_DROP' : ''})'
              : 'Nocta [${result.conversationDecision.phase.name}]: $text',
        );
        if (dropped && raw != null) {
          report.writeln('RAW_DROP: $raw');
        }

        if (result.exitDecision == ExitDecision.transitionToAudio) {
          final blocker = handoff.blockerFor(
            session: session,
            grounding: grounding,
          );
          final asset = beds.assetFor(
            blocker: blocker,
            access: const PremiumProductAccess(isPremium: false),
          );
          report.writeln('>>> AUDIO blocker=$blocker asset=$asset');
          break;
        }
      }

      final eval = evaluator.scoreNight(traces);
      report.writeln(
        'eval: ${eval.disposition.name} spoken=${eval.spokenTurns} '
        'drops=${eval.guardDrops} handoff=${eval.handoffPresent} '
        'notes=${eval.notes.join('; ')}',
      );

      expect(
        lastExit,
        ExitDecision.transitionToAudio,
        reason: '${entry.key} must reach audio',
      );
      expect(
        eval.disposition,
        isNot(EvalDisposition.reject),
        reason: '${entry.key} must not reject: ${eval.notes}',
      );
      expect(eval.handoffPresent || eval.spokenTurns >= 2, isTrue);
    }

    // ignore: avoid_print
    print(report.toString());
  }, timeout: const Timeout(Duration(seconds: 420)));
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
