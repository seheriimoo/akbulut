import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:slowave/config/app_config.dart';
import 'package:slowave/core/brain/conversation_expression_mode.dart';
import 'package:slowave/core/brain/conversation_grounding_buffer.dart';
import 'package:slowave/core/brain/hcos_live_entry.dart';
import 'package:slowave/core/brain/perception_engine.dart';
import 'package:slowave/core/brain/thinking_function_continuity.dart';
import 'package:slowave/core/brain/thinking_function_detector.dart';
import 'package:slowave/core/brain/thinking_function_hypothesis.dart';

/// Phase 1+2 GOLD Blind Lock — live pipeline validation only.
///
/// flutter test --dart-define-from-file=config/secrets.local.json \
///   test/integration/phase12_gold_blind_lock_eval_test.dart
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final nights = <_Night>[
    // --- EN families (unseen phrasings) ---
    _Night('en_future_anxiety', 'en', [
      "My head won't quiet down tonight.",
      "I keep running through what tomorrow might ruin.",
      "Not one thing — it keeps inventing new ways it could fall apart.",
      "Yeah… that's closer.",
    ]),
    _Night('en_work', 'en', [
      "Work is stuck in my head.",
      "There's a review tomorrow and my brain won't leave it alone.",
      "It keeps drafting disasters that haven't happened.",
      "I don't know how to put it down.",
    ]),
    _Night('en_relationship', 'en', [
      "I keep checking our last messages.",
      "Part of me is already living the version where they leave.",
      "Every story I invent ends with distance.",
      "No — I'm not saying I'm sure they'll leave. Just that my mind goes there.",
    ]),
    _Night('en_health_wait', 'en', [
      "I'm waiting on results and I can't sleep.",
      "My mind keeps painting different bad lab outcomes.",
      "Each new version feels worse than the last.",
    ]),
    _Night('en_social_eval', 'en', [
      "There's a gathering tomorrow and I'm already tired.",
      "I keep imagining people reading me wrong.",
      "It's like my mind is rehearsing embarrassment on loop.",
    ]),
    _Night('en_financial', 'en', [
      "Money stuff is buzzing tonight.",
      "I keep calculating what goes wrong if one payment slips.",
      "Not helpful — just endless negative forecasts.",
    ]),
    _Night('en_diffuse', 'en', [
      "I don't even know what I'm thinking about.",
      "It's just noise that keeps finding new corners.",
      "Whenever one thought settles, another ugly one shows up.",
    ]),
    _Night('en_regret', 'en', [
      "I keep replaying what I said yesterday.",
      "My mind won't stop editing the conversation.",
      "It keeps finding new ways I messed it up.",
    ]),
    _Night('en_lonely', 'en', [
      "The apartment feels too quiet.",
      "I keep imagining nobody checking in tomorrow either.",
      "Every path ends with me alone in the same room.",
    ]),
    _Night('en_correction_excited', 'en', [
      "I can't stop thinking about tomorrow's trip.",
      "My mind keeps inventing disasters on the road.",
      "No, I'm not imagining bad outcomes. I'm just excited and wired.",
    ]),
    _Night('en_topic_shift_ex', 'en', [
      "Work review tomorrow has me spinning.",
      "I keep thinking about everything that could go wrong in that meeting.",
      "Anyway, my ex texted me and now that's all I can see.",
    ]),
    _Night('en_short_user', 'en', [
      "Can't sleep.",
      "Tomorrow.",
      "Bad endings.",
    ]),
    _Night('en_verbose', 'en', [
      "Okay so tonight my brain is doing that thing again where it won't shut up about next week even though nothing is actually happening yet and I keep building these tiny disaster movies in my head.",
      "Like, not one concrete threat — just a carousel of scenes that all land badly, and I know it's silly but I can't stop generating the next one.",
      "When I try to stop, it feels like I'm leaving something unfinished, so I keep going.",
    ]),
    // --- TR families ---
    _Night('tr_future', 'tr', [
      'Bu gece kafam susmuyor.',
      'Yarın ters gidebilecek şeyleri düşünüyorum.',
      'Tek bir mesele değil, aklım her yolu kötü bir yere bağlıyor.',
      'Evet, daha çok bu.',
    ]),
    _Night('tr_work', 'tr', [
      'İş aklımdan çıkmıyor.',
      'Yarın değerlendirme var, beynim bırakmıyor.',
      'Sürekli kötü senaryolar üretiyor.',
      'Birini bitiriyorum, başka kötü ihtimal geliyor.',
    ]),
    _Night('tr_relationship', 'tr', [
      'Mesajlarını tekrar okuyorum.',
      'Aklım çoktan ayrıldığımız hali yaşıyor gibi.',
      'Her senaryo uzaklıkla bitiyor.',
      'Hayır emin değilim — sadece aklım oraya gidiyor.',
    ]),
    _Night('tr_health', 'tr', [
      'Sonuç bekliyorum, uyuyamıyorum.',
      'Aklım farklı kötü sonuçlar çiziyor.',
      'Her yeni versiyon daha kötü geliyor.',
    ]),
    _Night('tr_social', 'tr', [
      'Yarın bir kalabalık var, şimdiden yorgunum.',
      'İnsanların beni yanlış okuduğu halleri hayal ediyorum.',
      'Aklım utancı prova ediyor gibi.',
    ]),
    _Night('tr_money', 'tr', [
      'Para işleri geceyi açıyor.',
      'Bir ödeme aksarsa ne olur diye hesaplıyorum.',
      'Aklım sürekli başka kötü sonuç buluyor.',
    ]),
    _Night('tr_diffuse', 'tr', [
      'Ne düşündüğümü bile bilmiyorum.',
      'Sadece gürültü, yeni köşeler buluyor.',
      'Biri bitince yenisi geliyor ve hepsi kötü bitiyor.',
    ]),
    _Night('tr_regret', 'tr', [
      'Dün söylediklerimi tekrarlıyorum.',
      'Aklım konuşmayı yeniden yazıyor.',
      'Hep yeni bir hata buluyor.',
    ]),
    _Night('tr_lonely', 'tr', [
      'Ev çok sessiz.',
      'Yarın da kimsenin yazmayacağını hayal ediyorum.',
      'Her yol aynı odada yalnız bitiyor.',
    ]),
    _Night('tr_correction', 'tr', [
      'Yarın yolculuk var, aklım durmuyor.',
      'Kötü şeyler hayal ediyorum sandım.',
      'Hayır, kötü sonuç düşünmüyorum. Sadece heyecanlıyım.',
    ]),
    _Night('tr_topic_shift', 'tr', [
      'Yarın iş toplantısı yüzünden dönüyorum.',
      'Her şeyin ters gidebileceğini düşünüyorum.',
      'Neyse, eski sevgilim yazdı — şimdi aklım orada.',
    ]),
    _Night('tr_continuity_paraphrase', 'tr', [
      'Uyuyamıyorum.',
      'Aklım sürekli kötü senaryolar üretiyor.',
      'Sonra her ihtimali kötüye bağlıyorum.',
      'Birini düşünüyorum sonra yenisi geliyor.',
      'Aklım sürekli başka kötü sonuç buluyor.',
    ]),
    _Night('tr_short', 'tr', [
      'Susmuyor.',
      'Yarın.',
      'Kötü bitiyor.',
    ]),
    // Unseen paraphrases (final refinement) — not used during implementation targeting.
    _Night('en_unseen_rehearsal', 'en', [
      "My head keeps staging little failure clips before they happen.",
      "Each clip lands worse than the last one.",
      "I know it's invented, but the loop won't quit.",
    ]),
    _Night('tr_unseen_prova', 'tr', [
      'Aklım utancı prova ediyor gibi.',
      'Sonra başka bir rezillik sahnesi geliyor.',
      'Hepsi bitmeden yenisini kuruyor.',
    ]),
    // Micro-slice unseen TR paraphrases
    _Night('tr_unseen_micro_a', 'tr', [
      'Bu gece kafam boşalmıyor.',
      'Sürekli utanç sahneleri kuruyorum.',
      'Birini bitiriyorum, hemen yenisi geliyor.',
    ]),
    _Night('tr_unseen_micro_b', 'tr', [
      'Para yüzünden uyuyamıyorum.',
      'Her ödeme gecikmesini felaket gibi canlandırıyorum.',
      'Aklım yeni kötü sonuçlar üretmeye devam ediyor.',
    ]),
    _Night('tr_unseen_micro_c', 'tr', [
      'Yarın kalabalık var.',
      'İnsanların önünde mahcup olacağım halleri hayal ediyorum.',
      'Zihnim aynı utancı tekrar tekrar prova ediyor.',
    ]),
  ];

  test('Phase 1+2 GOLD blind lock matrix', () async {
    final previous = HttpOverrides.current;
    HttpOverrides.global = _RealHttpOverrides();
    addTearDown(() => HttpOverrides.global = previous);

    await AppConfig.load();
    expect(AppConfig.openAiApiKey.trim().isNotEmpty, isTrue);

    final detector = ThinkingFunctionDetector();
    const continuity = ThinkingFunctionContinuity();
    const perception = PerceptionEngine();
    final orchestrator = HcosLiveEntry.createOrchestrator();

    final raw = StringBuffer()
      ..writeln('# PHASE 1+2 GOLD BLIND LOCK RAW')
      ..writeln('Date: ${DateTime.now().toIso8601String()}')
      ..writeln('Nights: ${nights.length}')
      ..writeln('');

    final scored = <_ScoredNight>[];

    for (final night in nights) {
      final mind = HcosLiveEntry.emptyMindModel();
      var session = HcosLiveEntry.openNightSession(mind);
      var grounding = const ConversationGroundingBuffer.empty();
      ThinkingFunctionHypothesis? sessionTf;
      final turns = <_TurnRow>[];

      for (var i = 0; i < night.users.length; i++) {
        final user = night.users[i];
        grounding = grounding.appendUserUtterance(user);
        final evidence = perception.perceive(user);
        final fresh = detector.detect(
          currentMessage: user,
          conversationGrounding: grounding,
          perceptionEvidence: evidence,
        );
        final priorTf = sessionTf;
        final tf = continuity.resolve(
          fresh: fresh,
          prior: priorTf,
          currentMessage: user,
          conversationGrounding: grounding,
          session: session,
        );
        if (ThinkingFunctionContinuity.shouldClearSessionStore(
          resolved: tf,
          currentMessage: user,
          prior: priorTf,
          conversationGrounding: grounding,
          session: session,
        )) {
          sessionTf = null;
        } else if (tf != null &&
            tf.confidence >= ThinkingFunctionDetector.supportedFloor) {
          sessionTf = tf;
        } else {
          sessionTf = null;
        }

        final result = await orchestrator.processTurn(
          message: user,
          session: session,
          workingMind: session.workingMind,
          conversationGroundingBuffer: grounding,
        );
        session = result.session;
        grounding = result.conversationGroundingBuffer ?? grounding;
        final text = result.utterance?.text ?? '<SILENCE>';
        final mode = result.conversationDecision.expressionMode;
        final act = _classifyAct(mode: mode, text: text, turnIndex: i);
        turns.add(
          _TurnRow(
            user: user,
            nocta: text,
            mode: mode.name,
            act: act,
            tf: tf == null
                ? 'null'
                : '${tf.kind.name}@${tf.confidence.toStringAsFixed(2)}',
          ),
        );
      }

      final hard = _hardFails(turns, night);
      final quality = _qualityScores(turns, night, hard);
      scored.add(
        _ScoredNight(night: night, turns: turns, hard: hard, quality: quality),
      );

      raw
        ..writeln('## ${night.id} (${night.lang})')
        ..writeln('HARD: ${jsonEncode(hard.toJson())}')
        ..writeln('QUALITY: ${jsonEncode(quality)}');
      for (var i = 0; i < turns.length; i++) {
        final t = turns[i];
        raw
          ..writeln('T${i + 1}_USER: ${t.user}')
          ..writeln('T${i + 1}_TF: ${t.tf}')
          ..writeln('T${i + 1}_MODE: ${t.mode}')
          ..writeln('T${i + 1}_ACT: ${t.act}')
          ..writeln('T${i + 1}_NOCTA: ${t.nocta}')
          ..writeln('');
      }
      raw.writeln('---\n');
    }

    final summary = _buildSummary(scored);
    File('/tmp/nocta_phase12_gold_blind_lock_raw.txt')
        .writeAsStringSync(raw.toString());
    File('/tmp/nocta_phase12_gold_blind_lock_summary.json')
        .writeAsStringSync(const JsonEncoder.withIndent('  ').convert(summary));
    // ignore: avoid_print
    print(const JsonEncoder.withIndent('  ').convert(summary));
    // ignore: avoid_print
    print('WROTE /tmp/nocta_phase12_gold_blind_lock_raw.txt');
    // ignore: avoid_print
    print('WROTE /tmp/nocta_phase12_gold_blind_lock_summary.json');
  }, timeout: const Timeout(Duration(minutes: 25)));
}

class _Night {
  const _Night(this.id, this.lang, this.users);
  final String id;
  final String lang;
  final List<String> users;
}

class _TurnRow {
  const _TurnRow({
    required this.user,
    required this.nocta,
    required this.mode,
    required this.act,
    required this.tf,
  });
  final String user;
  final String nocta;
  final String mode;
  final String act;
  final String tf;
}

class _HardFails {
  _HardFails();
  int silence = 0;
  int bareAck = 0;
  int repeatedTerminal = 0;
  int contradictedMechanism = 0;
  int topicContamination = 0;
  int hardDiagnosis = 0;
  int unsupportedProtection = 0;
  int unsupportedCertainty = 0;
  int prematurePermission = 0;
  int fabricatedFact = 0;

  Map<String, int> toJson() => {
        'silence': silence,
        'bare_ack': bareAck,
        'repeated_terminal': repeatedTerminal,
        'contradicted_mechanism': contradictedMechanism,
        'topic_contamination': topicContamination,
        'hard_diagnosis': hardDiagnosis,
        'unsupported_protection': unsupportedProtection,
        'unsupported_certainty': unsupportedCertainty,
        'premature_permission': prematurePermission,
        'fabricated_fact': fabricatedFact,
      };

  int get total =>
      silence +
      bareAck +
      repeatedTerminal +
      contradictedMechanism +
      topicContamination +
      hardDiagnosis +
      unsupportedProtection +
      unsupportedCertainty +
      prematurePermission +
      fabricatedFact;
}

class _ScoredNight {
  _ScoredNight({
    required this.night,
    required this.turns,
    required this.hard,
    required this.quality,
  });
  final _Night night;
  final List<_TurnRow> turns;
  final _HardFails hard;
  final Map<String, double> quality;
}

String _classifyAct({
  required ConversationExpressionMode mode,
  required String text,
  required int turnIndex,
}) {
  final n = text.toLowerCase();
  if (text == '<SILENCE>') return 'FALLBACK';
  if (mode == ConversationExpressionMode.narrow) return 'NARROW';
  if (mode == ConversationExpressionMode.reframe) return 'REFRAME';
  if (mode == ConversationExpressionMode.integrate) return 'INTEGRATE';
  if (mode == ConversationExpressionMode.closure) return 'SLEEP_TRANSITION';
  if (_isPermission(n)) return 'PERMISSION';
  if (_isRelease(n)) return 'RELEASE';
  if (turnIndex == 0 || mode == ConversationExpressionMode.observePurity) {
    return 'RECEIVE';
  }
  if (_looksRecognize(n)) return 'RECOGNIZE';
  if (n.contains('i hear you') || n.contains('hâlâ orada') || n.contains('still there')) {
    return 'FALLBACK';
  }
  return 'RECOGNIZE';
}

bool _isPermission(String n) {
  return RegExp(
    r"don'?t (need|have) to|you can (stop|let|leave)|"
    r'zorunda degilsin|zorunda değilsin|gerekmiyor|'
    r'you do not have to|tonight you don',
  ).hasMatch(n);
}

bool _isRelease(String n) {
  return RegExp(
    r'\b(let (it|this) (rest|go)|leave it here|birakabilirsin|bırakabilirsin|'
    r'geceye birak|put (it|this) down)\b',
  ).hasMatch(n);
}

bool _looksRecognize(String n) {
  return RegExp(
    r'\b(rehears|prepar|scenario|senaryo|ihtimal|could go wrong|'
    r'imagining|invent|mind (is|may|might)|zihn|perhaps|belki|'
    r'exhausting|carrying|certainty)\b',
  ).hasMatch(n);
}

_HardFails _hardFails(List<_TurnRow> turns, _Night night) {
  final h = _HardFails();
  final seenHardTonight = <String>{};
  var sawRecognize = false;

  for (var i = 0; i < turns.length; i++) {
    final t = turns[i];
    final n = t.nocta.toLowerCase();
    if (t.nocta == '<SILENCE>') h.silence++;

    final bare = n.replaceAll(RegExp(r'[.!?…]+$'), '').trim();
    if (bare == 'okay' || bare == 'ok' || bare == 'tamam') {
      if (t.user.trim().length >= 12) h.bareAck++;
    }

    if (n.trim() == 'that sounds hard tonight.' ||
        n.trim() == 'bu gece söylediğin zor geliyor gibi.') {
      final key = n.trim();
      if (seenHardTonight.contains(key)) h.repeatedTerminal++;
      seenHardTonight.add(key);
    }

    if (RegExp(
      r'\b(protect(ing|s)? you|keep(ing)? you safe|seni koru|'
      r'trying to keep you safe|mind is protecting)\b',
    ).hasMatch(n)) {
      h.unsupportedProtection++;
    }

    if (RegExp(
      r'\b(you are (definitely|clearly)|kesinlikle|'
      r'this means you|tanı|diagnos)\b',
    ).hasMatch(n)) {
      h.hardDiagnosis++;
    }

    if (RegExp(
      r"\b(i'?m sure you|kesin olarak|you will definitely|"
      r'definitely going to)\b',
    ).hasMatch(n)) {
      h.unsupportedCertainty++;
    }

    if (_isPermission(n) || _isRelease(n)) {
      // Premature if before any recognition/reframe and still early arc.
      if (!sawRecognize && (i <= 1 || t.mode == 'standard' || t.mode == 'observePurity')) {
        // Count once per night max for permission-before-recognition.
        if (h.prematurePermission == 0) h.prematurePermission = 1;
      }
    }

    if (t.act == 'RECOGNIZE' || t.act == 'REFRAME') sawRecognize = true;

    // Correction nights: mechanism must not persist after denial.
    if (night.id.contains('correction') && i == turns.length - 1) {
      if (t.tf.startsWith('worstCase') &&
          RegExp(r'excited|heyecan|not imagining|düşünmüyorum|dusunmuyorum')
              .hasMatch(t.user.toLowerCase())) {
        h.contradictedMechanism++;
      }
    }

    // Topic shift: work TF must not color ex turn as work rehearsal.
    if (night.id.contains('topic_shift') && i == turns.length - 1) {
      if (RegExp(r'\b(meeting|review|toplant[iı]|iş değerlendirme)\b')
              .hasMatch(n) &&
          RegExp(r'\b(ex|eski|texted|yazd[iı])\b').hasMatch(t.user.toLowerCase())) {
        h.topicContamination++;
      }
    }

    // Crude fabricated-fact: invent named third parties not in user text.
    if (RegExp(r'\b(your (boss|manager|doctor|mother) said)\b').hasMatch(n) &&
        !t.user.toLowerCase().contains('said')) {
      // only if night never mentioned that role speaking
      final blob = turns.map((e) => e.user).join(' ').toLowerCase();
      if (!blob.contains('said') && !blob.contains('dedi')) {
        h.fabricatedFact++;
      }
    }
  }

  // Early permission: Permission/Release act on turn index 0/1 without prior recognize.
  for (var i = 0; i < turns.length && i < 2; i++) {
    if (turns[i].act == 'PERMISSION' || turns[i].act == 'RELEASE') {
      // already counted above when text matches; ensure act-based catch
      if (!_isPermission(turns[i].nocta.toLowerCase()) &&
          !_isRelease(turns[i].nocta.toLowerCase())) {
        continue;
      }
    }
  }

  // Special: permission language on T2 immediately after receive-only T1.
  if (turns.length >= 2) {
    final t1 = turns[0];
    final t2 = turns[1];
    if ((t1.act == 'RECEIVE' || t1.act == 'FALLBACK') &&
        (_isPermission(t2.nocta.toLowerCase()) ||
            _isRelease(t2.nocta.toLowerCase()))) {
      h.prematurePermission = 1;
    }
  }

  return h;
}

Map<String, double> _qualityScores(
  List<_TurnRow> turns,
  _Night night,
  _HardFails hard,
) {
  final nocta = turns.map((t) => t.nocta.toLowerCase()).toList();
  final acts = turns.map((t) => t.act).toList();
  final tfs = turns.map((t) => t.tf).toList();

  double clamp(double v) => v < 1 ? 1 : (v > 10 ? 10 : v);

  final hasMechanismTf =
      tfs.any((t) => t != 'null' && !t.startsWith('null'));
  final hasRecognize = acts.contains('RECOGNIZE') || acts.contains('REFRAME');
  final progressed = acts.toSet().length >= 2 &&
      !(turns.length >= 2 &&
          turns.first.nocta.trim().toLowerCase() ==
              turns.last.nocta.trim().toLowerCase());
  final paraphraseOnly = nocta.every(
    (n) =>
        n.contains('i hear you') ||
        n.contains('still there') ||
        n.contains('söylüyorsun') ||
        (!_looksRecognize(n) && !n.contains('?')),
  );

  var understanding = hasMechanismTf ? 7.0 : 5.0;
  var mechanism = hasRecognize && hasMechanismTf
      ? 8.0
      : (hasRecognize ? 6.0 : 3.0);
  var grounding = 7.0;
  var progression = progressed ? 7.5 : 4.0;
  var naturalness = nocta.any((n) => n.contains('i hear you')) ? 5.5 : 7.0;
  var insight = hasRecognize && !paraphraseOnly ? 7.0 : 3.5;
  var releaseTiming = acts.any((a) => a == 'PERMISSION' || a == 'RELEASE')
      ? (hard.prematurePermission > 0 ? 3.0 : 7.0)
      : 5.0;
  var sleepward = acts.contains('SLEEP_TRANSITION') ? 8.0 : 4.5;
  var returnIntent = (insight >= 6 && hard.total == 0) ? 7.0 : 5.0;

  if (hard.unsupportedProtection > 0) {
    insight -= 2;
    mechanism -= 1.5;
  }
  if (hard.prematurePermission > 0) {
    progression -= 1.5;
    releaseTiming = 2.5;
  }
  if (hard.silence > 0 || hard.bareAck > 0) naturalness -= 2;

  return {
    'understanding': clamp(understanding),
    'mechanism': clamp(mechanism),
    'grounding': clamp(grounding),
    'progression': clamp(progression),
    'naturalness': clamp(naturalness),
    'insight': clamp(insight),
    'release_timing': clamp(releaseTiming),
    'sleepward': clamp(sleepward),
    'return_intent': clamp(returnIntent),
    'paraphrase_only': paraphraseOnly ? 1.0 : 0.0,
    'mechanism_tf': hasMechanismTf ? 1.0 : 0.0,
    'earned_recognize': hasRecognize && hasMechanismTf && !paraphraseOnly
        ? 1.0
        : 0.0,
  };
}

Map<String, dynamic> _buildSummary(List<_ScoredNight> scored) {
  final en = scored.where((s) => s.night.lang == 'en').toList();
  final tr = scored.where((s) => s.night.lang == 'tr').toList();
  final totalTurns =
      scored.fold<int>(0, (a, s) => a + s.turns.length);

  Map<String, int> sumHard() {
    final out = <String, int>{
      'silence': 0,
      'bare_ack': 0,
      'repeated_terminal': 0,
      'contradicted_mechanism': 0,
      'topic_contamination': 0,
      'hard_diagnosis': 0,
      'unsupported_protection': 0,
      'unsupported_certainty': 0,
      'premature_permission': 0,
      'fabricated_fact': 0,
    };
    for (final s in scored) {
      final j = s.hard.toJson();
      for (final e in j.entries) {
        out[e.key] = (out[e.key] ?? 0) + e.value;
      }
    }
    return out;
  }

  Map<String, double> avgQuality(List<_ScoredNight> list) {
    const keys = [
      'understanding',
      'mechanism',
      'grounding',
      'progression',
      'naturalness',
      'insight',
      'release_timing',
      'sleepward',
      'return_intent',
    ];
    final out = <String, double>{};
    for (final k in keys) {
      final v =
          list.map((s) => s.quality[k] ?? 0).fold<double>(0, (a, b) => a + b) /
              (list.isEmpty ? 1 : list.length);
      out[k] = double.parse(v.toStringAsFixed(2));
    }
    return out;
  }

  final ranked = [...scored]
    ..sort((a, b) {
      final ao = a.quality.values
              .where((v) => v <= 10)
              .fold<double>(0, (x, y) => x + y) -
          a.hard.total * 5;
      final bo = b.quality.values
              .where((v) => v <= 10)
              .fold<double>(0, (x, y) => x + y) -
          b.hard.total * 5;
      return ao.compareTo(bo);
    });

  String transcript(_ScoredNight s) {
    final b = StringBuffer()..writeln(s.night.id);
    for (var i = 0; i < s.turns.length; i++) {
      final t = s.turns[i];
      b
        ..writeln('U: ${t.user}')
        ..writeln('N[${t.act}/${t.mode}/TF=${t.tf}]: ${t.nocta}');
    }
    return b.toString();
  }

  final paraphraseRate = scored
          .where((s) => (s.quality['paraphrase_only'] ?? 0) > 0)
          .length /
      scored.length;
  final mechanismRate = scored
          .where((s) => (s.quality['mechanism_tf'] ?? 0) > 0)
          .length /
      scored.length;
  final earnedRate = scored
          .where((s) => (s.quality['earned_recognize'] ?? 0) > 0)
          .length /
      scored.length;

  return {
    'nights_en': en.length,
    'nights_tr': tr.length,
    'total_nights': scored.length,
    'total_turns': totalTurns,
    'hard_fails': sumHard(),
    'avg_all': avgQuality(scored),
    'avg_en': avgQuality(en),
    'avg_tr': avgQuality(tr),
    'paraphrase_only_rate': double.parse(paraphraseRate.toStringAsFixed(3)),
    'mechanism_recognition_rate':
        double.parse(mechanismRate.toStringAsFixed(3)),
    'earned_recognition_rate': double.parse(earnedRate.toStringAsFixed(3)),
    'worst5_ids': ranked.take(5).map((s) => s.night.id).toList(),
    'best5_ids': ranked.reversed.take(5).map((s) => s.night.id).toList(),
    'worst5_transcripts': ranked.take(5).map(transcript).toList(),
    'best5_transcripts': ranked.reversed.take(5).map(transcript).toList(),
    'nights_with_hard_fails': scored
        .where((s) => s.hard.total > 0)
        .map((s) => {
              'id': s.night.id,
              'hard': s.hard.toJson(),
            })
        .toList(),
  };
}

class _RealHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback = (_, __, ___) => false;
  }
}
