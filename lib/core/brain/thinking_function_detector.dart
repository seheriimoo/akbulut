import 'conversation_grounding_buffer.dart';
import 'evidence.dart';
import 'thinking_function_hypothesis.dart';
import 'thinking_function_kind.dart';

/// Infers at most one primary [ThinkingFunctionHypothesis], or null.
///
/// Fail-closed: bare overthinking / generic anxiety does not invent a
/// mechanism. Reads authorized user grounding only; never owns or mutates it.
/// Does not choose phase, readiness, exit, memory, or expression.
class ThinkingFunctionDetector {
  const ThinkingFunctionDetector();

  /// Minimum confidence to emit a hypothesis (tentative floor).
  static const double minEmitConfidence = 0.45;

  /// Supported band floor.
  static const double supportedFloor = 0.65;

  /// Strong band floor.
  static const double strongFloor = 0.80;

  /// If top two kinds are within this margin and both emit-worthy → null.
  static const double ambiguityEpsilon = 0.05;

  ThinkingFunctionHypothesis? detect({
    required String currentMessage,
    ConversationGroundingBuffer? conversationGrounding,
    List<Evidence> perceptionEvidence = const [],
  }) {
    final current = _normalize(currentMessage);
    if (current.isEmpty) {
      return null;
    }

    final priors = <String>[
      for (final prior in conversationGrounding?.priorUserUtterances ??
          const <String>[])
        _normalize(prior),
    ].where((p) => p.isNotEmpty).toList(growable: false);

    final scores = <ThinkingFunctionKind, _KindScore>{};

    void consider(ThinkingFunctionKind kind, _KindScore? score) {
      if (score == null) return;
      if (score.confidence < minEmitConfidence) return;
      scores[kind] = score;
    }

    consider(
      ThinkingFunctionKind.certaintyChase,
      _scoreCertaintyChase(current: current, priors: priors),
    );
    consider(
      ThinkingFunctionKind.preparationRehearsal,
      _scorePreparation(current: current, priors: priors),
    );
    consider(
      ThinkingFunctionKind.worstCaseRehearsal,
      _scoreWorstCase(current: current, priors: priors),
    );
    consider(
      ThinkingFunctionKind.earlyTomorrowCarry,
      _scoreEarlyTomorrow(
        current: current,
        priors: priors,
        perceptionEvidence: perceptionEvidence,
      ),
    );
    consider(
      ThinkingFunctionKind.protectiveHolding,
      _scoreProtectiveHolding(
        current: current,
        priors: priors,
        perceptionEvidence: perceptionEvidence,
      ),
    );

    if (scores.isEmpty) {
      return null;
    }

    final ranked = scores.entries.toList()
      ..sort((a, b) {
        final byConfidence =
            b.value.confidence.compareTo(a.value.confidence);
        if (byConfidence != 0) return byConfidence;
        // Specificity tie-break among equal confidence.
        return _specificityRank(b.key).compareTo(_specificityRank(a.key));
      });

    final top = ranked.first;
    if (ranked.length >= 2) {
      final second = ranked[1];
      final gap = top.value.confidence - second.value.confidence;
      if (gap < ambiguityEpsilon &&
          _specificityRank(top.key) == _specificityRank(second.key)) {
        return null;
      }
      // Near-tie: only keep if top is clearly more specific.
      if (gap < ambiguityEpsilon &&
          _specificityRank(top.key) <= _specificityRank(second.key)) {
        return null;
      }
    }

    return ThinkingFunctionHypothesis(
      kind: top.key,
      confidence: _clamp01(top.value.confidence),
      evidenceIds: top.value.evidenceIds,
      supportTurnCount: top.value.supportTurnCount,
    );
  }

  /// Higher = more specific cue family (wins near-ties).
  ///
  /// Explicit worst-case evidence outranks generic readiness/preparation
  /// near-ties; readiness threat still wins on confidence when stronger.
  static int _specificityRank(ThinkingFunctionKind kind) {
    switch (kind) {
      case ThinkingFunctionKind.certaintyChase:
        return 5;
      case ThinkingFunctionKind.worstCaseRehearsal:
        return 4;
      case ThinkingFunctionKind.preparationRehearsal:
        return 3;
      case ThinkingFunctionKind.earlyTomorrowCarry:
        return 2;
      case ThinkingFunctionKind.protectiveHolding:
        return 1;
    }
  }

  _KindScore? _scoreCertaintyChase({
    required String current,
    required List<String> priors,
  }) {
    final ids = <String>[];
    var turns = 0;
    var confidence = 0.0;

    void absorb(String text, {required bool isCurrent}) {
      final local = <String>[];
      if (_hasOneMoreThought(text)) {
        local.add('one_more_thought');
      }
      if (_hasAlmostFigured(text)) {
        local.add('almost_figured');
      }
      if (_hasKeepReviewing(text)) {
        local.add('keep_reviewing');
      }
      if (local.isEmpty) return;
      ids.addAll(local.map((e) => isCurrent ? 'current:$e' : 'prior:$e'));
      turns += 1;
      confidence = isCurrent
          ? (confidence < strongFloor ? strongFloor : confidence)
          : (confidence < supportedFloor ? supportedFloor : confidence);
      if (isCurrent && local.length >= 2) {
        confidence = 0.88;
      }
    }

    absorb(current, isCurrent: true);
    for (final prior in priors) {
      absorb(prior, isCurrent: false);
    }

    if (ids.isEmpty || confidence < minEmitConfidence) return null;
    // Prior-only certainty without current cue is too weak for V1.
    if (!ids.any((e) => e.startsWith('current:'))) return null;

    return _KindScore(
      confidence: confidence,
      evidenceIds: ids,
      supportTurnCount: turns < 1 ? 1 : turns,
    );
  }

  _KindScore? _scorePreparation({
    required String current,
    required List<String> priors,
  }) {
    final ids = <String>[];
    var turns = 0;
    var confidence = 0.0;

    void absorb(String text, {required bool isCurrent}) {
      final local = <String>[];
      if (_hasStrongPreparationThreat(text)) {
        local.add('preparation_threat');
      } else if (_hasPreparationLanguage(text) &&
          _hasContinuationPressure(text)) {
        local.add('preparation_continuation');
      }
      if (local.isEmpty) return;
      ids.addAll(local.map((e) => isCurrent ? 'current:$e' : 'prior:$e'));
      turns += 1;
      if (local.contains('preparation_threat') && isCurrent) {
        confidence = 0.88;
      } else if (local.contains('preparation_threat')) {
        confidence = confidence < supportedFloor ? supportedFloor : confidence;
      } else if (isCurrent) {
        confidence = confidence < supportedFloor ? 0.72 : confidence;
      } else {
        confidence = confidence < 0.55 ? 0.55 : confidence;
      }
    }

    absorb(current, isCurrent: true);
    for (final prior in priors) {
      absorb(prior, isCurrent: false);
    }

    if (ids.isEmpty || confidence < minEmitConfidence) return null;
    if (!ids.any((e) => e.startsWith('current:'))) return null;

    return _KindScore(
      confidence: confidence,
      evidenceIds: ids,
      supportTurnCount: turns < 1 ? 1 : turns,
    );
  }

  _KindScore? _scoreWorstCase({
    required String current,
    required List<String> priors,
  }) {
    // Excited anticipation alone is not worst-case rehearsal.
    if (_isExcitedAnticipationOnly(current)) return null;

    final ids = <String>[];
    var turns = 0;
    var confidence = 0.0;

    void absorb(String text, {required bool isCurrent}) {
      if (_isExcitedAnticipationOnly(text)) return;
      if (_isDeniedWorstCaseClaim(text)) return;
      final local = <String>[];
      if (_hasWhatIf(text)) {
        local.add('what_if');
      }
      if (_hasWorstCase(text)) {
        local.add('worst_case');
      }
      if (_hasNegativeScenarioLoop(text)) {
        local.add('negative_scenario_loop');
      }
      if (local.isEmpty) return;
      ids.addAll(local.map((e) => isCurrent ? 'current:$e' : 'prior:$e'));
      turns += 1;
      if (isCurrent) {
        confidence = local.length >= 2 ||
                _hasWorstCase(text) ||
                _hasNegativeScenarioLoop(text)
            ? 0.82
            : 0.72;
      } else {
        confidence = confidence < 0.55 ? 0.55 : confidence;
      }
    }

    absorb(current, isCurrent: true);
    for (final prior in priors) {
      absorb(prior, isCurrent: false);
    }

    if (ids.isEmpty || confidence < minEmitConfidence) return null;
    if (!ids.any((e) => e.startsWith('current:'))) return null;
    // Generic anxiety words alone never reach here (_hasWhatIf/_hasWorstCase).

    return _KindScore(
      confidence: confidence,
      evidenceIds: ids,
      supportTurnCount: turns < 1 ? 1 : turns,
    );
  }

  /// Excitement / wired energy without negative rehearsal/simulation.
  bool _isExcitedAnticipationOnly(String text) {
    final excited = RegExp(
      r'\b(excited|excitement|wired|heyecan|heyecanli|heyecanliyim|'
      r'cant wait|cannot wait|looking forward)\b',
    ).hasMatch(text);
    if (!excited) return false;
    if (_hasWorstCase(text) || _hasNegativeScenarioLoop(text)) return false;
    if (_hasWhatIf(text) && _hasNegativeLanding(text)) return false;
    return true;
  }

  /// Denial of worst-case imagination must not count as positive evidence.
  bool _isDeniedWorstCaseClaim(String text) {
    return RegExp(
      r"\b(not imagining|not inventing|i'?m just excited|just excited|"
      r'hayir[,.]?.{0,48}kotu|'
      r'kotu .{0,24}(degil|dusunmuyorum|dusunmuyorum)|'
      r'kotu sonuc .{0,12}(degil|dusunmuyorum)|'
      r'sadece heyecan)\b',
    ).hasMatch(text);
  }

  bool _hasNegativeLanding(String text) => _negativeLanding.hasMatch(text);

  _KindScore? _scoreEarlyTomorrow({
    required String current,
    required List<String> priors,
    required List<Evidence> perceptionEvidence,
  }) {
    final currentTomorrow = _hasTomorrowCue(current);
    final priorTomorrow = priors.any(_hasTomorrowCue);
    final currentCarry = _hasCarryOrContinuation(current);
    final priorCarry = priors.any(_hasCarryOrContinuation);
    final futureEvidence = perceptionEvidence.any(
      (e) => e.value == 'future_uncertainty',
    );
    final thinkingEvidence = perceptionEvidence.any(
      (e) => e.value == 'repetitive_thinking',
    );

    final ids = <String>[];
    var turns = 0;
    var confidence = 0.0;

    // Bare "tomorrow" / future cue alone → fail closed.
    if (currentTomorrow && currentCarry) {
      ids.add('current:tomorrow');
      ids.add('current:continuation_or_carry');
      turns = 1;
      confidence = 0.72;
      if (futureEvidence) {
        ids.add('perception:future_uncertainty');
      }
      if (thinkingEvidence) {
        ids.add('perception:repetitive_thinking');
      }
    } else if (currentCarry && priorTomorrow) {
      // Current continuation holding prior tomorrow load.
      ids.add('prior:tomorrow');
      ids.add('current:continuation_or_carry');
      turns = 2;
      confidence = 0.68;
    } else if (currentTomorrow && priorCarry) {
      ids.add('current:tomorrow');
      ids.add('prior:continuation_or_carry');
      turns = 2;
      confidence = 0.68;
    } else {
      return null;
    }

    // Do not promote to preparation merely because tomorrow exists.
    return _KindScore(
      confidence: confidence,
      evidenceIds: ids,
      supportTurnCount: turns,
    );
  }

  _KindScore? _scoreProtectiveHolding({
    required String current,
    required List<String> priors,
    required List<Evidence> perceptionEvidence,
  }) {
    final ids = <String>[];
    var turns = 0;
    var confidence = 0.0;

    final strongProtective = _hasStrongProtectiveLanguage(current);
    final bareHolding = _hasBareHolding(current);
    final holdingEvidence = perceptionEvidence.any(
      (e) => e.value == 'holding_against_ease',
    );

    if (strongProtective) {
      ids.add('current:protective_stopping_cost');
      turns = 1;
      confidence = 0.82;
      if (holdingEvidence) {
        ids.add('perception:holding_against_ease');
      }
    } else if (bareHolding) {
      // Alone: fail closed (null). History may raise to tentative/supported.
      final priorLoad = priors.any(
        (p) =>
            _hasTomorrowCue(p) ||
            _hasCarryOrContinuation(p) ||
            _hasStrongProtectiveLanguage(p) ||
            _hasPreparationLanguage(p) ||
            _hasWhatIf(p) ||
            _hasOneMoreThought(p),
      );
      if (!priorLoad) {
        return null;
      }
      ids.add('current:bare_holding');
      turns = 1;
      if (priors.any(_hasTomorrowCue)) {
        ids.add('prior:tomorrow');
        turns = 2;
        confidence = 0.70; // supported: holding onto known tomorrow load
      } else if (priors.any(_hasStrongProtectiveLanguage)) {
        ids.add('prior:protective_stopping_cost');
        turns = 2;
        confidence = 0.72;
      } else {
        // Prior load exists but weak → tentative only.
        ids.add('prior:related_load');
        turns = 2;
        confidence = 0.55;
      }
      if (holdingEvidence) {
        ids.add('perception:holding_against_ease');
      }
    } else {
      return null;
    }

    if (confidence < minEmitConfidence) return null;

    return _KindScore(
      confidence: confidence,
      evidenceIds: ids,
      supportTurnCount: turns,
    );
  }

  // --- lexical helpers -----------------------------------------------------

  static final RegExp _tomorrowCue = RegExp(
    r'\b(tomorrow|next day|coming day|in the morning)\b',
  );

  static final RegExp _continuation = RegExp(
    r"\b(can'?t stop|cannot stop|keep thinking|keeps? (thinking|going)|"
    r"won'?t (stop|switch off)|mind (won'?t|will not)|"
    r'already (in|at|with)|carrying|keep going back)\b',
  );

  static final RegExp _preparationThreat = RegExp(
    r"\b((won'?t|will not|not) be (ready|prepared)|unprepared|"
    r'need to keep thinking.{0,40}prepared|'
    r'keep thinking.{0,40}(ready|prepared)|'
    r"if i stop.{0,40}(won'?t|will not|not).{0,20}(ready|prepared)|"
    r"so i'?m prepared|so i am prepared)\b",
  );

  /// Readiness-oriented preparation language only.
  ///
  /// Bare "preparing" / "prepare" alone is NOT enough (fail-closed without
  /// night-load / readiness context). "Preparing for the worst" is owned by
  /// worst-case rehearsal, not preparation rehearsal.
  static final RegExp _preparationLanguage = RegExp(
    r'\b(prepared|preparation|unprepared|get ready|getting ready|rehearse|'
    r'rehearsing|'
    r"preparing (to be|so (i'?m|i am|i)|myself)|"
    r"prepare (to be|so (i'?m|i am|i)|myself))\b",
  );

  static final RegExp _whatIf = RegExp(r'\bwhat if\b');

  /// Worst-case / go-wrong / preparing-for-the-worst semantic family.
  /// Bounded natural variants — not exact-message patches.
  /// Phase 2+hardening: generative future simulation + negative landing.
  static final RegExp _worstCase = RegExp(
    r'\b('
    r'worst[- ]?case|'
    r'everything goes wrong|all goes wrong|things go wrong|'
    r'everything that could go wrong|what could go wrong|'
    r'could go wrong|goes wrong|going wrong|'
    r'preparing for the worst|prepare for the worst|'
    r'keeps? preparing for the worst|keep preparing for the worst|'
    r'bracing for the worst|brace for the worst|'
    r'for the worst|'
    r'catastroph|'
    r'invent\w* disasters?|inventing disasters?|'
    r'worst[- ]?case outcomes?|new worst[- ]?case|'
    r'ends? badly|ending badly|ends worse|end worse|'
    r'bad outcomes?|kotu senaryo|kotu ihtimal|kotu sonuc|'
    r'en kotu sonuc|baska kotu|'
    r'her ihtimali kotuye|kotuye bagli|kotu(ye)? bagliyor|'
    r'ihtimali kotuye|kotuye bagla|'
    r'fall(ing)? apart|falls apart|fell apart|'
    r'disaster (movies?|films?|scenes?)|'
    r'rehears\w* embarrassment|rehears\w* (failure|humiliation)|'
    r'imagined (social )?failure|social failure|'
    r'negative (future )?scenes?|tiny disaster|'
    // TR rehearsal / simulation family (normalized fold)
    r'utanc(i|ı)? prova|prova ediyor|prova etmek|'
    r'utanci prova|rezil(ligi)? prova|'
    r'kotu sonuclar?i? (kafada |akilda |zihninde )?(cevir|don|bul)|'
    r'kotu ihtimalleri? (tekrar|canlandir|uret)|'
    r'ters gidebilecek|ters gidecek'
    r')\w*\b',
  );

  /// Structural: mind generating multiple futures AND landing negative.
  static final RegExp _scenarioGeneration = RegExp(
    r'\b(scenario|scenarios|senaryo|senaryolar|'
    r'creating different|keeps? creating|keeps? inventing|'
    r'keeps? generating|invent\w*|imagining|imagine|'
    r'every path|paths? i imagine|ihtimal|ihtimaller|'
    r'uret\w*|uretiyor|uretiyorum|'
    r'disaster (movies?|films?|scenes?)|carousel of scenes|'
    r'rehears\w*|on loop|drafting disasters?|'
    r'building .{0,24}(disaster|scene|movie)|'
    r'running through what|new ways it could|'
    r'ugly one shows|another ugly|'
    // TR generative / rehearsal loop (normalized)
    r'prova|provalamak|canlandir|canlandiriyor|'
    r'hayal ediyorum|hayal ediyor|'
    r'hesapliyorum|hesapliyor|'
    r'yenisi geliyor|yenisini|baska .{0,20}(buluyor|geliyor|uretiyor)|'
    r'surekli .{0,24}(kotu|ihtimal|sonuc|senaryo)|'
    r'aklim .{0,32}(prova|uret|bagliyor|buluyor|cevir)|'
    r'zihn .{0,32}(prova|uret|bagliyor)|'
    r'her yol|her ihtimal)\b',
  );

  static final RegExp _negativeLanding = RegExp(
    r'\b(badly|worse|worst|disaster|catastrop|kotu|'
    r'ends? bad|go wrong|alone|unsafe|rezil|'
    r'fall(ing)? apart|embarrassment|humiliat|'
    r'failure|ruin|messed it up|'
    r'utanc|utanci|yalniz bitiyor|uzaklik|'
    r'none .{0,24}safe|not .{0,12}safe|dont .{0,12}feel safe)\b',
  );

  static final RegExp _oneMoreThought = RegExp(
    r'\b(one more thought|one more time|just one more|'
    r'another thought|think (about it )?one more)\b',
  );

  static final RegExp _almostFigured = RegExp(
    r"\b(almost (figured|figuring)|figure it out|figuring it out|"
    r"close to (figuring|understanding))\b",
  );

  static final RegExp _keepReviewing = RegExp(
    r'\b(keep (reviewing|replaying|going over)|'
    r'if i keep (reviewing|thinking|going over))\b',
  );

  static final RegExp _bareHolding = RegExp(
    r"\b(can'?t let go|cannot let go|won'?t let go|will not let go|"
    r"can'?t release|cannot release)\b",
  );

  static final RegExp _strongProtective = RegExp(
    r'\b(stopping feels (unsafe|risky|dangerous)|'
    r'afraid to (stop|let go)|keep(ing)? watch|'
    r'if i (stop|let go).{0,40}(bad|worse|unsafe|happen)|'
    r'holding (on|onto) (it|this) (to stay )?safe|'
    r'thinking (is|as) (a form of )?protection)\b',
  );

  bool _hasTomorrowCue(String text) => _tomorrowCue.hasMatch(text);

  bool _hasCarryOrContinuation(String text) =>
      _continuation.hasMatch(text) ||
      text.contains('worrying about tomorrow') ||
      text.contains('worried about tomorrow') ||
      text.contains('thinking about tomorrow');

  bool _hasContinuationPressure(String text) =>
      _continuation.hasMatch(text) ||
      text.contains('keep thinking') ||
      text.contains('need to keep');

  bool _hasStrongPreparationThreat(String text) =>
      _preparationThreat.hasMatch(text);

  bool _hasPreparationLanguage(String text) =>
      _preparationLanguage.hasMatch(text);

  bool _hasWhatIf(String text) => _whatIf.hasMatch(text);

  bool _hasWorstCase(String text) => _worstCase.hasMatch(text);

  bool _hasNegativeScenarioLoop(String text) =>
      _scenarioGeneration.hasMatch(text) && _negativeLanding.hasMatch(text);

  bool _hasOneMoreThought(String text) => _oneMoreThought.hasMatch(text);

  bool _hasAlmostFigured(String text) => _almostFigured.hasMatch(text);

  bool _hasKeepReviewing(String text) => _keepReviewing.hasMatch(text);

  bool _hasBareHolding(String text) => _bareHolding.hasMatch(text);

  bool _hasStrongProtectiveLanguage(String text) =>
      _strongProtective.hasMatch(text);

  String _normalize(String message) {
    return message
        .toLowerCase()
        .replaceAll('’', "'")
        .replaceAll('‘', "'")
        .replaceAll('`', "'")
        .replaceAll('ö', 'o')
        .replaceAll('ü', 'u')
        .replaceAll('ı', 'i')
        .replaceAll('ğ', 'g')
        .replaceAll('ş', 's')
        .replaceAll('ç', 'c')
        .trim();
  }

  double _clamp01(double value) {
    if (value < 0) return 0;
    if (value > 1) return 1;
    return value;
  }
}

class _KindScore {
  final double confidence;
  final List<String> evidenceIds;
  final int supportTurnCount;

  const _KindScore({
    required this.confidence,
    required this.evidenceIds,
    required this.supportTurnCount,
  });
}
