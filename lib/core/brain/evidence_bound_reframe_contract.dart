import 'evidence_ledger.dart';
import 'reframe_hypothesis_kind.dart';

/// B3 — Semantic support check: reframe claims must not exceed evidence ceiling.
class EvidenceBoundReframeContract {
  const EvidenceBoundReframeContract._();

  static bool admits({
    required String reframeText,
    required EvidenceLedger ledger,
    EvidenceHypothesis? hypothesis,
  }) {
    final lower = _normalize(reframeText);
    if (lower.contains('?')) return false;

    if (_violatesInvalidations(lower, ledger)) return false;
    if (!_hasSoftTail(lower)) return false;

    final h = hypothesis ?? ledger.strongestEarned();
    if (h == null || h.invalidated) return false;
    if (h.contradictingTurnIds.isNotEmpty) return false;

    return _claimMatchesHypothesis(lower, h, ledger);
  }

  static bool _violatesInvalidations(String lower, EvidenceLedger ledger) {
    if (ledger.isTopicInvalidated(InvalidatedTopic.motherTrauma) ||
        ledger.isTopicInvalidated(InvalidatedTopic.motherConflictReframe)) {
      if (_containsAny(lower, [
        'annen',
        'annem',
        'travma',
        'yasadin',
        'yaşadın',
        'tekrar etmes',
      ])) {
        return true;
      }
    }
    if (ledger.isTopicInvalidated(InvalidatedTopic.jobLossFear)) {
      if (_containsAny(lower, ['kovul', 'isini kaybet', 'işini kaybet'])) {
        return true;
      }
    }

    // Specificity ceiling: tomorrow pressure without evidence.
    if (_containsAny(lower, [
      'yarinki baskinin',
      'yarınki baskının',
      'yapacaklarin degil',
      'yapacakların değil',
    ])) {
      final hasPressureEvidence = ledger.hypotheses.any(
        (h) =>
            h.kind == ReframeHypothesisKind.tomorrowPressureReturn &&
            !h.invalidated &&
            h.supportingTurnIds.isNotEmpty,
      );
      if (!hasPressureEvidence) return true;
    }

    // Invented kırgınlık when user only named özlem.
    if (_containsAny(lower, ['kirgin', 'kırgın']) &&
        !_ledgerHasResentment(ledger)) {
      return true;
    }

    // Invented past trust when user named boss distrust not together-memory.
    if (_containsAny(lower, ['yanindayken', 'yanındayken', 'hissettigin guven']) &&
        !ledger.hypotheses.any(
          (h) =>
              h.kind == ReframeHypothesisKind.trustWhenTogether &&
              !h.invalidated,
        )) {
      if (ledger.hypotheses.any(
        (h) => h.kind == ReframeHypothesisKind.bossTrustAbsence && !h.invalidated,
      )) {
        return true;
      }
    }

    // Control-loss / generic psychology without evidence.
    if (_containsAny(lower, [
      'kontrol',
      'kaybetmekten kork',
      'zihnin bir seyleri cozmeye',
    ])) {
      return !_ledgerHasExplicitFear(ledger);
    }

    return false;
  }

  static bool _claimMatchesHypothesis(
    String lower,
    EvidenceHypothesis h,
    EvidenceLedger ledger,
  ) {
    switch (h.kind) {
      case ReframeHypothesisKind.appearanceInTheirEyes:
        return _containsAny(lower, [
          'gozunde',
          'gözünde',
          'goruneceg',
          'görüneceğ',
          'tepkis',
          'konusmanin kendisinden',
          'konuşmanın kendisinden',
          'how you might look',
          'in their eyes',
        ]);
      case ReframeHypothesisKind.tomorrowPressureReturn:
        return _containsAny(lower, [
          'baskinin',
          'baskının',
          'yapacaklarin',
          'yapacakların',
          'yarinki',
          'yarınki',
        ]);
      case ReframeHypothesisKind.trustWhenTogether:
        return _containsAny(lower, ['guven', 'güven', 'yanindayken', 'yanındayken']);
      case ReframeHypothesisKind.bossTrustAbsence:
        return _containsAny(lower, ['guven', 'güven', 'patron', 'eksik']);
      case ReframeHypothesisKind.mixedLongingResentment:
        return _containsAny(lower, ['ozlem', 'özlem', 'kirgin', 'kırgın', 'ikisi']);
      case ReframeHypothesisKind.lonelinessPresence:
      case ReframeHypothesisKind.presenceInSilence:
        return _containsAny(lower, [
          'yaninda',
          'yanında',
          'hisset',
          'presence',
          'burada olmas',
        ]);
    }
  }

  static bool _ledgerHasResentment(EvidenceLedger ledger) {
    return ledger.hypotheses.any(
      (h) =>
          h.kind == ReframeHypothesisKind.mixedLongingResentment &&
          !h.invalidated &&
          h.strength == EvidenceStrength.composite,
    );
  }

  static bool _ledgerHasExplicitFear(EvidenceLedger ledger) {
    return ledger.hypotheses.any(
      (h) =>
          !h.invalidated &&
          h.strength == EvidenceStrength.explicitCausal,
    );
  }

  static bool _hasSoftTail(String lower) {
    return _containsAny(lower, [
      'olabilir',
      'gibi',
      'sanirim',
      'sanırım',
      'might',
      'could',
    ]);
  }

  static bool _containsAny(String n, List<String> markers) {
    for (final m in markers) {
      if (n.contains(m.toLowerCase())) return true;
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
