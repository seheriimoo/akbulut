import 'conversation_grounding_buffer.dart';
import 'evidence_ledger.dart';
import 'reframe_hypothesis_kind.dart';

/// B3 — Builds [EvidenceLedger] from user turns only (deterministic).
class ReframeEvidenceReader {
  const ReframeEvidenceReader._();

  static EvidenceLedger fromGrounding(ConversationGroundingBuffer? grounding) {
    if (grounding == null || grounding.isEmpty) {
      return const EvidenceLedger(
        turns: [],
        hypotheses: [],
        invalidatedTopics: {},
      );
    }

    final utterances = grounding.userUtterances.toList();
    final turns = <LedgerTurn>[];
    for (var i = 0; i < utterances.length; i++) {
      turns.add(LedgerTurn(id: 'T${i + 1}', text: utterances[i]));
    }

    final invalidated = _detectInvalidations(turns);
    final hypotheses = _buildHypotheses(turns, invalidated);

    return EvidenceLedger(
      turns: turns,
      hypotheses: hypotheses,
      invalidatedTopics: invalidated,
    );
  }

  static Set<InvalidatedTopic> _detectInvalidations(List<LedgerTurn> turns) {
    final out = <InvalidatedTopic>{};
    for (final turn in turns) {
      final n = _normalize(turn.text);
      if (!_isDenial(n)) continue;

      if (_containsAny(n, ['travma', 'annemle', 'annem']) &&
          _containsAny(n, ['yok', 'falan yok', 'degil', 'değil'])) {
        out.add(InvalidatedTopic.motherTrauma);
        out.add(InvalidatedTopic.motherConflictReframe);
      }
      if (_containsAny(n, ['kovul', 'isten', 'işten']) &&
          _containsAny(n, ['korkmuyorum', 'korkmuyor', 'degil', 'değil'])) {
        out.add(InvalidatedTopic.jobLossFear);
      }
    }
    return out;
  }

  static bool _isDenial(String n) {
    return RegExp(r'^(hayir|hayır|yok|degil|değil)\b').hasMatch(n.trim()) ||
        _containsAny(n, [' falan yok', ' yok.', ' korkmuyorum', ' korkmuyor']);
  }

  static List<EvidenceHypothesis> _buildHypotheses(
    List<LedgerTurn> turns,
    Set<InvalidatedTopic> invalidated,
  ) {
    final blob = turns.map((t) => t.text).join(' ');
    final n = _normalize(blob);
    final current = turns.isEmpty ? '' : _normalize(turns.last.text);
    final out = <EvidenceHypothesis>[];

    void add(EvidenceHypothesis h) {
      var hypothesis = h;
      if (_hypothesisInvalidated(h.kind, invalidated)) {
        hypothesis = hypothesis.copyWith(invalidated: true);
      }
      out.add(hypothesis);
    }

    final appearanceIds = _turnIdsMatching(turns, [
      'tepki',
      'yetersiz',
      'gorun',
      'görün',
      'judg',
      'inadequate',
      'yargilan',
      'yargılan',
    ]);
    if (appearanceIds.isNotEmpty) {
      final explicit = _hasExplicitCausal(current);
      add(
        EvidenceHypothesis(
          kind: ReframeHypothesisKind.appearanceInTheirEyes,
          subject: 'their reaction / how you appear',
          userStatedState: 'fear of judgment or inadequacy',
          candidateRelation: 'talk vs being seen',
          supportingTurnIds: appearanceIds,
          strength: explicit
              ? EvidenceStrength.explicitCausal
              : appearanceIds.length >= 2
                  ? EvidenceStrength.composite
                  : EvidenceStrength.singleSignal,
          confidence: explicit ? 0.92 : appearanceIds.length >= 2 ? 0.78 : 0.45,
          invalidated: invalidated.contains(InvalidatedTopic.appearanceFear),
        ),
      );
    }

    final pressureIds = _turnIdsMatching(turns, [
      'yarin ',
      'yarın ',
      'sunum',
      'toplanti',
      'toplantı',
      'mudur',
      'müdür',
      'presentation',
      'tomorrow',
    ]);
    final hasPressureContext = pressureIds.isNotEmpty ||
        (_containsAny(n, ['baski', 'baskı']) &&
            _containsAny(n, ['yarin', 'yarın', 'sunum', 'toplanti']));
    if (hasPressureContext) {
      add(
        EvidenceHypothesis(
          kind: ReframeHypothesisKind.tomorrowPressureReturn,
          subject: 'tomorrow / meeting pressure',
          userStatedState: 'anticipatory work pressure',
          candidateRelation: 'return of tomorrow pressure vs tasks',
          supportingTurnIds: pressureIds.isEmpty ? [turns.last.id] : pressureIds,
          strength: pressureIds.length >= 2
              ? EvidenceStrength.composite
              : EvidenceStrength.singleSignal,
          confidence: pressureIds.length >= 2 ? 0.75 : 0.5,
          invalidated: invalidated.contains(InvalidatedTopic.tomorrowPressure),
        ),
      );
    }

    final bossIds = _turnIdsMatching(turns, [
      'patron',
      'mudur',
      'müdür',
      'boss',
      'guvenmedi',
      'güvenmedi',
      'trust',
    ]);
    if (bossIds.isNotEmpty &&
        _containsAny(n, ['guven', 'güven', 'trust', 'patron', 'mudur', 'müdür'])) {
      final explicitBelief = _containsAny(current, [
        'dusunuyorum',
        'düşünüyorum',
        'saniyorum',
        'guvenmedi',
        'güvenmedi',
      ]);
      add(
        EvidenceHypothesis(
          kind: ReframeHypothesisKind.bossTrustAbsence,
          subject: 'boss / patron trust',
          userStatedState: 'belief boss does not trust them',
          candidateRelation: 'missing trust now',
          supportingTurnIds: bossIds,
          strength: explicitBelief
              ? EvidenceStrength.explicitCausal
              : bossIds.length >= 2
                  ? EvidenceStrength.composite
                  : EvidenceStrength.singleSignal,
          confidence: explicitBelief ? 0.88 : 0.72,
          invalidated: invalidated.contains(InvalidatedTopic.bossTrustAbsence),
        ),
      );
    }

    final trustIds = _turnIdsMatching(turns, [
      'onunlayken',
      'yanindayken',
      'yanındayken',
      'guven',
      'güven',
    ]);
    final longingIds = _turnIdsMatching(turns, ['ozle', 'özle', 'ozluy', 'miss']);
    if (trustIds.isNotEmpty && longingIds.isNotEmpty) {
      add(
        EvidenceHypothesis(
          kind: ReframeHypothesisKind.trustWhenTogether,
          subject: 'person missed',
          userStatedState: 'longing + trust when together',
          candidateRelation: 'trust felt with them now absent',
          supportingTurnIds: {...trustIds, ...longingIds}.toList(),
          strength: EvidenceStrength.composite,
          confidence: 0.8,
          invalidated: false,
        ),
      );
    }

    final resentIds = _turnIdsMatching(turns, ['kirgin', 'kırgın', 'resent']);
    if (longingIds.isNotEmpty && resentIds.isNotEmpty) {
      add(
        EvidenceHypothesis(
          kind: ReframeHypothesisKind.mixedLongingResentment,
          subject: 'ex / person on Instagram',
          userStatedState: 'longing and resentment both named',
          candidateRelation: 'two feelings side by side',
          supportingTurnIds: {...longingIds, ...resentIds}.toList(),
          strength: EvidenceStrength.composite,
          confidence: 0.76,
          invalidated: false,
        ),
      );
    } else if (_containsAny(current, ['ozlem', 'özlem']) && turns.length >= 2) {
      add(
        EvidenceHypothesis(
          kind: ReframeHypothesisKind.mixedLongingResentment,
          subject: 'longing',
          userStatedState: 'longing only named',
          candidateRelation: 'unknown second feeling',
          supportingTurnIds: [turns.last.id],
          strength: EvidenceStrength.singleSignal,
          confidence: 0.35,
          invalidated: false,
        ),
      );
    }

    final lonelyIds = _turnIdsMatching(turns, [
      'yalniz',
      'yalnız',
      'yalnizim',
      'lonely',
      'alone',
    ]);
    final presenceIds = _turnIdsMatching(turns, [
      'nefes',
      'yanimda',
      'yanımda',
      'birinin yan',
      'hissetmeyi',
      'presence',
    ]);
    if (lonelyIds.isNotEmpty && presenceIds.isNotEmpty) {
      add(
        EvidenceHypothesis(
          kind: ReframeHypothesisKind.lonelinessPresence,
          subject: 'being alone tonight',
          userStatedState: 'loneliness + wanting presence',
          candidateRelation: 'missing felt presence not just body',
          supportingTurnIds: {...lonelyIds, ...presenceIds}.toList(),
          strength: EvidenceStrength.composite,
          confidence: 0.82,
          invalidated: invalidated.contains(InvalidatedTopic.lonelinessAlone),
        ),
      );
    }

    if (presenceIds.isNotEmpty && lonelyIds.isEmpty) {
      add(
        EvidenceHypothesis(
          kind: ReframeHypothesisKind.presenceInSilence,
          subject: 'silence tonight',
          userStatedState: 'wants to hear someone breathe',
          candidateRelation: 'presence in quiet',
          supportingTurnIds: presenceIds,
          strength: EvidenceStrength.singleSignal,
          confidence: 0.55,
          invalidated: false,
        ),
      );
    }

    return out;
  }

  static bool _hypothesisInvalidated(
    ReframeHypothesisKind kind,
    Set<InvalidatedTopic> invalidated,
  ) {
    switch (kind) {
      case ReframeHypothesisKind.appearanceInTheirEyes:
        return invalidated.contains(InvalidatedTopic.appearanceFear);
      case ReframeHypothesisKind.tomorrowPressureReturn:
        return invalidated.contains(InvalidatedTopic.tomorrowPressure);
      case ReframeHypothesisKind.bossTrustAbsence:
        return invalidated.contains(InvalidatedTopic.bossTrustAbsence);
      case ReframeHypothesisKind.lonelinessPresence:
        return invalidated.contains(InvalidatedTopic.lonelinessAlone);
      case ReframeHypothesisKind.trustWhenTogether:
      case ReframeHypothesisKind.mixedLongingResentment:
      case ReframeHypothesisKind.presenceInSilence:
        return false;
    }
  }

  static bool _hasExplicitCausal(String n) {
    return _containsAny(n, [
          'cunku',
          'çünkü',
          'korkuyorum',
          'korkuyor',
          'afraid',
          'because',
          'scared',
        ]) &&
        _containsAny(n, ['tepki', 'yetersiz', 'gorun', 'görün', 'judg']);
  }

  static List<String> _turnIdsMatching(
    List<LedgerTurn> turns,
    List<String> markers,
  ) {
    final ids = <String>[];
    for (final turn in turns) {
      final n = _normalize(turn.text);
      if (_containsAnyBounded(n, markers)) ids.add(turn.id);
    }
    return ids;
  }

  static bool _containsAnyBounded(String n, List<String> markers) {
    for (final marker in markers) {
      final m = marker.trim().toLowerCase();
      if (m.endsWith(' ')) {
        if (n.contains(m)) return true;
        continue;
      }
      // Prefix-friendly for TR morphology (patron → patronun, mudur → müdürümle).
      if (RegExp('(?:^|[\\s,.-])${RegExp.escape(m)}\\w*').hasMatch(n)) {
        return true;
      }
    }
    return false;
  }

  static bool _containsAny(String n, List<String> markers) {
    for (final m in markers) {
      if (n.contains(m)) return true;
    }
    return false;
  }

  static String _normalize(String s) {
    return s
        .toLowerCase()
        .replaceAll('ö', 'o')
        .replaceAll('ü', 'u')
        .replaceAll('ı', 'i')
        .replaceAll('ğ', 'g')
        .replaceAll('ş', 's')
        .replaceAll('ç', 'c');
  }
}
