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

import '../core/brain/faithful_test_vendor_provider.dart';

/// Same 18 realistic nights as the V1 conversation-quality baseline.
///
/// flutter test --dart-define-from-file=config/secrets.local.json \
///   test/integration/v1_conversation_stress_eval_test.dart
void main() {
  final nights = <String, List<String>>{
    'R01 overthinking': [
      'kafam durmuyor ya. ayni seyi donup duruyorum.',
      'yani yarin toplantida bir sey kaciracagim gibi. durmuyor.',
      'biliyorum ki dusunmek ise yaramıyor ama durduramiyorum.',
      'hala ayni yerdeyim.',
      'bilmiyorum.',
    ],
    'R02 relationship rumination': [
      'az once yine kavga ettik. mesajini okuyup duruyorum.',
      'keşke o cumleyi soylemeseydim. su an her seyi mahvettim gibi.',
      'yazsam mi yazmasam mi diye donup duruyorum.',
      'yok yaznicam ama aklımdan da cikmiyo.',
    ],
    'R03 missing someone': [
      'onu ozledim yine.',
      'odanin sessizligi daha da kotu yapiyo.',
      'hala aklımda. bir sey yapamiyorum.',
    ],
    'R04 loneliness': [
      'bu gece kendimi cok yalniz hissediyorum.',
      'kimse yok. boyle bos bir sey var icimde.',
      'anlatacak bir sey de yok aslinda. sadece bu.',
    ],
    'R05 future anxiety': [
      "I can't stop thinking about tomorrow.",
      'What if I walk in and everything falls apart.',
      'I keep running the worst version so I am not surprised.',
      'Still there. Same loop.',
    ],
    'R06 money/work stress': [
      'faturalar kafamda donuyor. yetmeyecek gibi.',
      'isin uzerine bir de yarin teslim etmem gereken seyler var.',
      'uyusam bile cozulmicek ama duramiyorum.',
    ],
    'R07 uyuyamiyorum': [
      'uyuyamiyorum.',
      'gozlerim acik yatiyorum. hicbir sey yok aslinda.',
      'sadece uyuyamiyorum iste.',
    ],
    'R08 very short user': [
      'idk',
      'tired',
      'hm',
      'evet',
    ],
    'R09 very long narrator': [
      'yani bak bugun is yerinde mudur yine o bakisi atti sonra slackten bir mesaj geldi ve ben o mesaji 40 kere okudum cunku belki bir ima vardir belki yarın beni cagiracak belki de hicbir sey yoktur ama duramiyorum, eve geldim yemek yemedim, duş aldım yine ayni yerdeyim, yarin da toplantı var ve ben daha slaytlari bitirmedim, bitirmesem bile uyusam daha iyi olacak biliyorum ama beynim “bir tur daha bak” diyor.',
      'evet tam olarak o. bir tur daha bakayim diyorum.',
      'hala durmuyor.',
    ],
    'R10 always I dont know': [
      'bilmiyorum.',
      'bilmiyorum ki.',
      'ne diyecegimi de bilmiyorum.',
      'idk',
    ],
    'R11 repeats the same thing': [
      'aklim durmuyor.',
      'aklim durmuyor ya.',
      'durmuyor iste.',
      'aynı şey. durmuyor.',
    ],
    'R12 topic change': [
      'is kafamda. yarin yetisemeyecegim.',
      'aslinda is degil. onunla kavga ettik. o donuyor.',
      'para da var bir yandan ama asıl o.',
    ],
    'R13 angry at Nocta': [
      'kafam durmuyor.',
      'ya yeter bu robot gibi konusma. beni anlamıyosun.',
      'sürekli aynı şeyi söylüyosun. sinir oluyorum.',
    ],
    'R14 dont want to talk': [
      'konusmak istemiyorum.',
      'sadece burdayim. konusmak istemiyorum.',
    ],
    'R15 direct to audio': [
      'sese gec.',
    ],
    'R16 TR slang no diacritics': [
      'kafayi yicem ya bu gece.',
      'yani o kadar dusunuyom ki duramiyom.',
      'bi turlu birakamiyom.',
    ],
    'R17 English natural': [
      "Can't sleep. Keep going over the conversation from earlier.",
      "I know I can't fix it at 1am. Still doing it.",
      'Same thing. I just want my brain to shut up.',
    ],
    'R18 mixed TR/EN': [
      'I miss him ya. cok kotu bu gece.',
      "bilmiyorum, I just can't drop it.",
      'yeter artik. sese gecelim.',
    ],
  };

  test('ROUTING 18 nights', () async {
    final report = await _runNights(
      nights: nights,
      live: false,
      vendor: const FaithfulTestVendorProvider(),
    );
    // ignore: avoid_print
    print(report);
  });

  test('LIVE OpenAI 18 nights', () async {
    WidgetsFlutterBinding.ensureInitialized();
    final previousOverrides = HttpOverrides.current;
    HttpOverrides.global = _RealHttpOverrides();
    addTearDown(() {
      HttpOverrides.global = previousOverrides;
    });

    await AppConfig.load();
    expect(
      AppConfig.hasOpenAiApiKey,
      isTrue,
      reason: 'OPENAI_API_KEY via --dart-define-from-file=config/secrets.local.json',
    );

    final report = await _runNights(
      nights: nights,
      live: true,
      vendor: OpenAIVendorProvider.fromEnv(),
    );
    File('/tmp/nocta_v1_live_stress.txt').writeAsStringSync(report);
    // ignore: avoid_print
    print(report);
  }, timeout: const Timeout(Duration(seconds: 1200)));
}

Future<String> _runNights({
  required Map<String, List<String>> nights,
  required bool live,
  required VendorProvider vendor,
}) async {
  final report = StringBuffer()
    ..writeln(live ? '=== LIVE OPENAI STRESS ===' : '=== ROUTING STRESS ===')
    ..writeln();

  for (final entry in nights.entries) {
    if (live) {
      await Future<void>.delayed(const Duration(seconds: 2));
    }
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
      memoryEngine: MemoryEngine(),
    );

    final mind = HcosLiveEntry.emptyMindModel();
    var session = HcosLiveEntry.openNightSession(mind);
    ConversationGroundingBuffer? grounding;
    final phases = <String>[];
    var drops = 0;
    var audio = false;

    report.writeln('--- ${entry.key} live=$live ---');

    for (var i = 0; i < entry.value.length; i++) {
      if (live && i > 0) {
        await Future<void>.delayed(const Duration(milliseconds: 800));
      }
      final message = entry.value[i];
      capture.lastCompletedText = null;
      final result = await orchestrator.processTurn(
        message: message,
        session: session,
        workingMind: HcosLiveEntry.workingMindOf(session),
        conversationGroundingBuffer: grounding,
      );
      session = HcosLiveEntry.applyTurnResult(result);
      grounding = HcosLiveEntry.groundingBufferOf(result);

      final last = session.turns.isEmpty ? null : session.turns.last;
      final mental = last?.mentalPatterns.map((p) => p.id).toList() ?? const [];
      final emo = last?.emotionalPatterns.map((p) => p.id).toList() ?? const [];
      final spoken = result.utterance?.text;
      final raw = capture.lastCompletedText;
      final dropped = spoken == null && raw != null && raw.trim().isNotEmpty;
      if (dropped) drops += 1;

      final phaseTag =
          '${result.conversationDecision.phase.name}/${result.releaseDecision.readiness.name}';
      var summaryBit = phaseTag;
      if (result.exitDecision == ExitDecision.transitionToAudio) {
        summaryBit = '$phaseTag/AUDIO';
        audio = true;
      }
      phases.add(summaryBit);

      report
        ..writeln('T${i + 1} USER: $message')
        ..writeln(
          '    meta phase=${result.conversationDecision.phase.name} '
          'ready=${result.releaseDecision.readiness.name} '
          'exit=${result.exitDecision.name} '
          'mental=$mental emo=$emo fn=- '
          '${dropped ? 'GUARD_DROP' : ''}',
        )
        ..writeln(
          spoken == null || spoken.trim().isEmpty
              ? '    NOCTA: (silence${dropped ? ' | dropped: $raw' : ''})'
              : '    NOCTA: $spoken',
        );

      if (i == 0 && capture.lastSystem != null) {
        final snip = capture.lastSystem!;
        report.writeln(
          '    SYS_SNIP: ${snip.substring(0, snip.length.clamp(0, 280))}',
        );
      }

      if (result.exitDecision == ExitDecision.transitionToAudio) {
        report.writeln('    >>> AUDIO');
        break;
      }
    }

    report
      ..writeln(
        'SUMMARY phases=${phases.join(' > ')} audio=$audio drops=$drops '
        'grounding=${grounding?.userUtterances.length ?? 0}',
      )
      ..writeln()
      ..writeln();
  }

  return report.toString();
}

class _CapturingVendorProvider implements VendorProvider {
  _CapturingVendorProvider(this._inner);

  final VendorProvider _inner;
  String? lastCompletedText;
  String? lastSystem;

  @override
  Future<VendorResponse> complete(VendorRequest request) async {
    lastSystem = request.compiled.systemContent;
    VendorError? lastError;
    for (var attempt = 0; attempt < 5; attempt++) {
      try {
        final response = await _inner.complete(request);
        lastCompletedText = response.text;
        return response;
      } on VendorError catch (error) {
        lastError = error;
        final rateLimited = error.message.contains('429');
        if (!rateLimited || attempt == 4) rethrow;
        await Future<void>.delayed(Duration(seconds: 3 * (attempt + 1)));
      }
    }
    throw lastError!;
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
