import '../thinking_function_hypothesis.dart';
import '../thinking_function_kind.dart';
import '../thinking_function_intelligence_shaping.dart';
import 'negation_correction_contract.dart';
import 'night_mind_map.dart';
import 'night_pattern_id.dart';

/// Ranked soft hypotheses for tonight. Never user-facing probabilities.
///
/// State-evolution contract: low-signal follow-ups must not wipe a leading
/// pattern already earned from prior resolved evidence.
class HypothesisBoard {
  const HypothesisBoard();

  /// Merge TF continuity with lexical cues + prior map stickiness.
  List<DiscoveryHypothesis> rank({
    required NightMindMap map,
    ThinkingFunctionHypothesis? thinkingFunction,
    required String currentMessage,
  }) {
    final text = _norm(currentMessage);
    final scores = <NightPatternId, double>{
      for (final id in NightPatternId.values)
        if (id != NightPatternId.unknown) id: 0.05,
    };

    void bump(NightPatternId id, double delta) {
      scores[id] = (scores[id] ?? 0) + delta;
    }

    // TF continuity is strong prior.
    if (thinkingFunction != null &&
        ThinkingFunctionIntelligenceShaping.isSupportedOrStrong(
          thinkingFunction,
        )) {
      final mapped = _patternForFunction(thinkingFunction.kind);
      bump(mapped, thinkingFunction.confidence * 0.7);
    }

    // Prior map fields — state must survive short/ambiguous follow-ups.
    _bumpFromResolvedMap(map, bump);

    if (_has(text, [
      r'\bscenario\w*',
      r'\bends? badly\b',
      r'\bcould go wrong\b',
      r'\bworst\b',
      r'\bsenaryo\w*',
      r'\bkotu ihtimal\b',
      r'\bher ihtimal\b',
      r'\bwhat if\b',
    ])) {
      bump(NightPatternId.worstCaseRehearsal, 0.35);
    }
    if (_has(text, [
      r'\bprepared\b',
      r'\bpreparation\b',
      r'\bready\b',
      r'\bhazir\w*',
      r'\boff guard\b',
      r'\bcaught\b',
      r'\brehears\w*',
      r'\bprova\w*',
    ]) &&
        !const NegationCorrectionContract().blocksPreparednessExtraction(text)) {
      bump(NightPatternId.preparationRehearsal, 0.35);
      bump(NightPatternId.worstCaseRehearsal, 0.15);
    }
    if (_has(text, [
      r'\bone more\b',
      r'\balmost\b',
      r'\bfigure\b',
      r'\bcertainty\b',
      r'\bemin\b',
      r'\bbir daha\b',
    ])) {
      bump(NightPatternId.certaintyChase, 0.35);
    }
    if (_has(text, [
      r'\btomorrow\b',
      r'\byarin\b',
      r'\bnext day\b',
      r'\bmorning\b',
    ])) {
      bump(NightPatternId.earlyTomorrowCarry, 0.25);
    }
    if (_has(text, [
      r"can'?t let (it )?go",
      r'\bholding\b',
      r'\bkeep(ing)? watch\b',
      r'\bstop watching\b',
      r'\bsomething will slip\b',
      r'\bwill slip\b',
      r'\bbirakamiyorum\b',
      r'\bnobet\w*',
    ])) {
      bump(NightPatternId.protectiveHolding, 0.45);
    }
    if (_has(text, [
      r'\bunfinished\b',
      r'\bnot done\b',
      r'\bopen thread\b',
      r'\bbitmedi\b',
      r'\byarim\b',
    ])) {
      bump(NightPatternId.unfinishedLoop, 0.35);
    }
    if (_has(text, [
      r'\breplay\b',
      r'\bsaid to\b',
      r'\bconversation\b',
      r'\bmesaj\w*',
      r'\bkonusma\b',
      r'\bkavga\b',
      r'\bkeske\b',
      r'\bsoylemeseydim\b',
    ])) {
      bump(NightPatternId.relationalReplay, 0.35);
    }
    if (_has(text, [
      r'\blonely\b',
      r'\balone\b',
      r'\byalniz\w*',
      r'\bmiss (him|her|them)\b',
      r'\bi miss\b',
      r'\bmiss having\b',
      r'\bmissing someone\b',
      r'\bsomeone here\b',
      r'\bozledim\b',
      r'\bozluyorum\b',
      r'\bozlem\w*',
    ])) {
      bump(NightPatternId.lonelinessPresence, 0.75);
      scores[NightPatternId.worstCaseRehearsal] =
          (scores[NightPatternId.worstCaseRehearsal] ?? 0) * 0.35;
      scores[NightPatternId.preparationRehearsal] =
          (scores[NightPatternId.preparationRehearsal] ?? 0) * 0.35;
    }
    if (_has(text, [
      r'\bheart\b',
      r'\bchest\b',
      r'\bpanic\b',
      r'\bnefes\w*',
      r'\bkalp\w*',
      r'\btitriyor\b',
      r'\bbody\b',
    ])) {
      bump(NightPatternId.bodyAlarm, 0.7);
      scores[NightPatternId.worstCaseRehearsal] =
          (scores[NightPatternId.worstCaseRehearsal] ?? 0) * 0.4;
    }
    if (_has(text, [
      r'\bshould i\b',
      r'\beither\b',
      r'\bor not\b',
      r'\bkarar\b',
      r'\bsecemiyorum\b',
      r'\bflipping\b',
    ])) {
      bump(NightPatternId.decisionPendulum, 0.3);
    }

    if (map.thoughtForm != null &&
        (map.thoughtForm!.contains('scenario') ||
            map.thoughtForm!.contains('rehearsal')) &&
        map.emotionalDriver != 'loneliness_absence' &&
        map.arousalType != 'somatic' &&
        map.arousalType != 'somatic_acute') {
      bump(NightPatternId.worstCaseRehearsal, 0.15);
      bump(NightPatternId.preparationRehearsal, 0.2);
    }

    // Stickiness: low-signal replies keep prior leading alive — never when
    // an explicit correction reopened the hypothesis.
    if (!map.hypothesisReopenRequired) {
      if (_isLowSignal(text) &&
          map.leadingPattern != NightPatternId.unknown &&
          map.mapConfidence >= 0.4) {
        bump(map.leadingPattern, 0.55 + map.mapConfidence * 0.3);
      } else if (map.leadingPattern != NightPatternId.unknown &&
          map.mapConfidence >= 0.5) {
        bump(map.leadingPattern, map.mapConfidence * 0.35);
      }
    } else {
      // Correction: dampen prep/rehearsal family until rediscriminated.
      scores[NightPatternId.preparationRehearsal] =
          (scores[NightPatternId.preparationRehearsal] ?? 0) * 0.2;
    }

    final ranked = scores.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final top = ranked.take(3).where((e) => e.value >= 0.2).toList();
    if (top.isEmpty) {
      // Preserve prior lead when current turn adds nothing usable.
      if (map.leadingPattern != NightPatternId.unknown &&
          map.mapConfidence >= 0.4) {
        return [
          DiscoveryHypothesis(
            pattern: map.leadingPattern,
            confidence: map.mapConfidence,
            function: thinkingFunction?.kind ?? map.thinkingFunction,
            evidenceIds: const ['sticky:prior_lead'],
          ),
        ];
      }
      return const [
        DiscoveryHypothesis(
          pattern: NightPatternId.unknown,
          confidence: 0.1,
        ),
      ];
    }

    final max = top.first.value;
    return [
      for (final e in top)
        DiscoveryHypothesis(
          pattern: e.key,
          confidence: (e.value / (max + 0.01)).clamp(0.0, 1.0) *
              (0.45 + 0.4 * (e.value.clamp(0.0, 1.0))),
          function: thinkingFunction?.kind,
          evidenceIds: [
            if (thinkingFunction != null) 'tf:continuity',
            'lex:${e.key.name}',
          ],
        ),
    ];
  }

  void _bumpFromResolvedMap(
    NightMindMap map,
    void Function(NightPatternId id, double delta) bump,
  ) {
    if (map.emotionalDriver == 'loneliness_absence' ||
        map.unresolvedNeed == 'companionship_presence') {
      bump(NightPatternId.lonelinessPresence, 0.55);
    }
    if (map.emotionalDriver == 'relational_regret_replay' ||
        map.thoughtForm == 'relational_or_event_replay') {
      bump(NightPatternId.relationalReplay, 0.45);
    }
    if (map.perceivedUtility == 'protective_watch') {
      bump(NightPatternId.protectiveHolding, 0.5);
    }
    if (map.perceivedUtility == 'thinking_as_preparation' &&
        !map.hypothesisReopenRequired) {
      bump(NightPatternId.preparationRehearsal, 0.4);
      bump(NightPatternId.worstCaseRehearsal, 0.2);
    }
    if (map.perceivedUtility == 'seeking_certainty') {
      bump(NightPatternId.certaintyChase, 0.4);
    }
    if (map.thoughtForm == 'decision_oscillation') {
      bump(NightPatternId.decisionPendulum, 0.4);
    }
    if (map.thoughtForm == 'unfinished_open_thread' ||
        map.unresolvedNeed == 'park_unfinished_thread') {
      bump(NightPatternId.unfinishedLoop, 0.4);
    }
    if (map.temporalOrientation == 'future' &&
        (map.topicDomain == 'tomorrow' ||
            map.thoughtForm == 'repetitive_forward_load')) {
      bump(NightPatternId.earlyTomorrowCarry, 0.35);
    }
    if (map.arousalType == 'somatic' || map.arousalType == 'somatic_acute') {
      bump(NightPatternId.bodyAlarm, 0.55);
    }
    if (map.actualEffect == 'perpetuates_new_scenarios') {
      bump(NightPatternId.worstCaseRehearsal, 0.25);
      bump(NightPatternId.preparationRehearsal, 0.2);
    }
  }

  /// Write ranked hypotheses onto the night map.
  NightMindMap applyToMap(NightMindMap map, List<DiscoveryHypothesis> hyps) {
    if (hyps.isEmpty) {
      return map.copyWith(
        hypotheses: const [],
        leadingPattern: NightPatternId.unknown,
        mapConfidence: 0,
      );
    }
    final lead = hyps.first;
    // Do not let a weaker unknown wipe a sticky prior.
    if (lead.pattern == NightPatternId.unknown &&
        map.leadingPattern != NightPatternId.unknown &&
        map.mapConfidence >= 0.4) {
      return map;
    }
    return map.copyWith(
      hypotheses: hyps,
      leadingPattern: lead.pattern,
      mapConfidence: lead.confidence,
      thinkingFunction: map.thinkingFunction ?? lead.function,
    );
  }

  NightPatternId _patternForFunction(ThinkingFunctionKind kind) {
    switch (kind) {
      case ThinkingFunctionKind.worstCaseRehearsal:
        return NightPatternId.worstCaseRehearsal;
      case ThinkingFunctionKind.preparationRehearsal:
        return NightPatternId.preparationRehearsal;
      case ThinkingFunctionKind.certaintyChase:
        return NightPatternId.certaintyChase;
      case ThinkingFunctionKind.earlyTomorrowCarry:
        return NightPatternId.earlyTomorrowCarry;
      case ThinkingFunctionKind.protectiveHolding:
        return NightPatternId.protectiveHolding;
    }
  }

  static bool _isLowSignal(String text) {
    if (text.trim().length < 12) return true;
    return _has(text, [
      r"i don'?t know",
      r"it won'?t stop",
      r'\bstill here\b',
      r'\bbilmiyorum\b',
      r'\bdurmuyor\b',
      r'\bhala ayni\b',
      r'\bayni yerdeyim\b',
    ]);
  }

  static bool _has(String text, List<String> patterns) {
    for (final p in patterns) {
      if (RegExp(p).hasMatch(text)) return true;
    }
    return false;
  }

  static String _norm(String message) {
    return message
        .toLowerCase()
        .replaceAll('’', "'")
        .replaceAll('‘', "'")
        .replaceAll('ö', 'o')
        .replaceAll('ü', 'u')
        .replaceAll('ı', 'i')
        .replaceAll('İ', 'i')
        .replaceAll('ğ', 'g')
        .replaceAll('ş', 's')
        .replaceAll('ç', 'c')
        .trim();
  }
}
