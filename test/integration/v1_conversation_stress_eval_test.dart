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
import 'package:slowave/core/brain/release_decision.dart';
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
    final run = await _runNights(
      nights: nights,
      live: false,
      vendor: const FaithfulTestVendorProvider(),
    );
    // ignore: avoid_print
    print(run.report);
    _assertTargetRoutingContracts(run.nights);
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

    final run = await _runNights(
      nights: nights,
      live: true,
      vendor: OpenAIVendorProvider.fromEnv(),
    );
    File('/tmp/nocta_v1_live_stress.txt').writeAsStringSync(run.report);
    // ignore: avoid_print
    print(run.report);
  }, timeout: const Timeout(Duration(seconds: 1200)));
}

class _TurnTrace {
  const _TurnTrace({
    required this.phase,
    required this.readiness,
    required this.exit,
    required this.hasLoad,
    required this.spoken,
    required this.dropped,
  });

  final ConversationPhase phase;
  final ReleaseReadiness readiness;
  final ExitDecision exit;
  final bool hasLoad;
  final String? spoken;
  final bool dropped;
}

class _NightTrace {
  const _NightTrace({
    required this.id,
    required this.turns,
    required this.audio,
    required this.firstSystem,
  });

  final String id;
  final List<_TurnTrace> turns;
  final bool audio;
  final String? firstSystem;
}

class _RoutingRun {
  const _RoutingRun({required this.report, required this.nights});

  final String report;
  final List<_NightTrace> nights;
}

_NightTrace _night(List<_NightTrace> nights, String idPrefix) {
  return nights.firstWhere(
    (night) => night.id.startsWith(idPrefix),
    orElse: () => throw StateError('missing night $idPrefix'),
  );
}

void _assertTargetRoutingContracts(List<_NightTrace> nights) {
  _assertR07(_night(nights, 'R07'));
  _assertR08(_night(nights, 'R08'));
  _assertR10(_night(nights, 'R10'));
  _assertR12(_night(nights, 'R12'));
  _assertR13(_night(nights, 'R13'));
  _assertR14(_night(nights, 'R14'));
  _assertR16(_night(nights, 'R16'));
  _assertR05(_night(nights, 'R05'));
  _assertR15(_night(nights, 'R15'));
}

void _assertHoldReceiptOpen(
  _NightTrace night, {
  required bool expectLoad,
}) {
  expect(night.turns, isNotEmpty, reason: '${night.id} ran no turns');
  final t1 = night.turns.first;
  expect(
    t1.phase,
    ConversationPhase.validation,
    reason: '${night.id} T1 must be Receipt, not greeting/close',
  );
  expect(
    t1.readiness,
    ReleaseReadiness.hold,
    reason: '${night.id} T1 must stay on hold',
  );
  expect(
    t1.exit,
    ExitDecision.continueConversation,
    reason: '${night.id} T1 must not exit',
  );
  if (expectLoad) {
    expect(t1.hasLoad, isTrue, reason: '${night.id} T1 must register load');
  }
}

void _assertNoAudio(_NightTrace night) {
  expect(night.audio, isFalse, reason: '${night.id} must not go to audio');
  expect(
    night.turns.any((turn) => turn.exit == ExitDecision.transitionToAudio),
    isFalse,
    reason: '${night.id} must not emit transitionToAudio',
  );
}

void _assertTurkishLanguageLock(_NightTrace night) {
  expect(night.firstSystem, isNotNull, reason: '${night.id} compiled no system');
  expect(
    night.firstSystem!.toLowerCase(),
    contains('reply in turkish only'),
    reason: '${night.id} must lock Turkish on a TR turn',
  );
}

void _assertR07(_NightTrace night) {
  _assertHoldReceiptOpen(night, expectLoad: true);
  _assertNoAudio(night);
  _assertTurkishLanguageLock(night);
}

void _assertR08(_NightTrace night) {
  _assertHoldReceiptOpen(night, expectLoad: false);
  _assertNoAudio(night);
}

void _assertR10(_NightTrace night) {
  _assertHoldReceiptOpen(night, expectLoad: false);
  _assertNoAudio(night);
  _assertTurkishLanguageLock(night);
  for (final turn in night.turns) {
    final spoken = turn.spoken?.toLowerCase() ?? '';
    expect(
      spoken.contains('tomorrow'),
      isFalse,
      reason: '${night.id} must not invent tomorrow on thin turns',
    );
  }
}

void _assertR12(_NightTrace night) {
  _assertHoldReceiptOpen(night, expectLoad: true);
  _assertNoAudio(night);
  expect(night.turns.length, greaterThanOrEqualTo(2), reason: '${night.id} T2 missing');
  expect(
    night.turns[1].phase,
    ConversationPhase.naming,
    reason: '${night.id} T2 must Name remaining load after Receipt',
  );
  expect(
    night.turns[1].exit,
    ExitDecision.continueConversation,
    reason: '${night.id} topic change is not an exit',
  );
}

void _assertR13(_NightTrace night) {
  expect(night.turns.length, greaterThanOrEqualTo(3), reason: '${night.id} protest turns missing');
  expect(night.turns.first.phase, ConversationPhase.validation);
  for (var i = 1; i < night.turns.length; i++) {
    final turn = night.turns[i];
    expect(
      turn.phase,
      ConversationPhase.permission,
      reason: '${night.id} T${i + 1} protest recalibrates to Permission (P1-2)',
    );
    expect(
      turn.phase,
      isNot(anyOf(
        ConversationPhase.release,
        ConversationPhase.audio,
        ConversationPhase.continuity,
      )),
      reason: '${night.id} protest must not climb to release or close',
    );
  }
  _assertNoAudio(night);
}

void _assertR14(_NightTrace night) {
  expect(night.turns, hasLength(1));
  expect(
    night.turns.first.phase,
    ConversationPhase.continuity,
    reason: '${night.id} ASCII close must route Enough',
  );
  expect(
    night.turns.first.exit,
    ExitDecision.transitionToAudio,
    reason: '${night.id} ASCII close must go to audio',
  );
  expect(night.audio, isTrue);
}

void _assertR16(_NightTrace night) {
  _assertHoldReceiptOpen(night, expectLoad: true);
  _assertNoAudio(night);
  _assertTurkishLanguageLock(night);
  expect(night.turns.length, greaterThanOrEqualTo(2));
  expect(
    night.turns[1].phase,
    ConversationPhase.naming,
    reason: '${night.id} T2 must Name remaining ASCII TR load',
  );
  expect(night.turns[1].readiness, ReleaseReadiness.hold);
}

void _assertR05(_NightTrace night) {
  _assertHoldReceiptOpen(night, expectLoad: true);
  _assertNoAudio(night);
  expect(night.firstSystem, isNotNull);
  expect(
    night.firstSystem!.toLowerCase(),
    contains('reply in english only'),
    reason: '${night.id} must lock English on an EN turn',
  );
  expect(
    night.turns.first.spoken,
    isNotNull,
    reason: '${night.id} English Receipt must still be admitted',
  );
  expect(night.turns.first.dropped, isFalse);
  expect(night.turns.length, greaterThanOrEqualTo(2));
  expect(
    night.turns[1].phase,
    ConversationPhase.naming,
    reason: '${night.id} T2 Naming after Receipt must not regress',
  );
}

void _assertR15(_NightTrace night) {
  expect(night.turns, hasLength(1));
  expect(
    night.turns.first.phase,
    ConversationPhase.continuity,
    reason: '${night.id} sese gec must route Enough',
  );
  expect(
    night.turns.first.exit,
    ExitDecision.transitionToAudio,
    reason: '${night.id} sese gec must go to audio',
  );
  expect(night.audio, isTrue);
}

Future<_RoutingRun> _runNights({
  required Map<String, List<String>> nights,
  required bool live,
  required VendorProvider vendor,
}) async {
  final report = StringBuffer()
    ..writeln(live ? '=== LIVE OPENAI STRESS ===' : '=== ROUTING STRESS ===')
    ..writeln();
  final traces = <_NightTrace>[];

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
    final turns = <_TurnTrace>[];
    var drops = 0;
    var audio = false;
    String? firstSystem;

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
      turns.add(
        _TurnTrace(
          phase: result.conversationDecision.phase,
          readiness: result.releaseDecision.readiness,
          exit: result.exitDecision,
          hasLoad: mental.isNotEmpty || emo.isNotEmpty,
          spoken: spoken,
          dropped: dropped,
        ),
      );

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
        firstSystem = capture.lastSystem;
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

    traces.add(
      _NightTrace(
        id: entry.key,
        turns: turns,
        audio: audio,
        firstSystem: firstSystem,
      ),
    );

    report
      ..writeln(
        'SUMMARY phases=${phases.join(' > ')} audio=$audio drops=$drops '
        'grounding=${grounding?.userUtterances.length ?? 0}',
      )
      ..writeln()
      ..writeln();
  }

  return _RoutingRun(report: report.toString(), nights: traces);
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
