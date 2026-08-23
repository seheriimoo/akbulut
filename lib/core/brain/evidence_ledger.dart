import 'reframe_hypothesis_kind.dart';

/// B3 — Deterministic evidence record for one reframe hypothesis.
class EvidenceHypothesis {
  const EvidenceHypothesis({
    required this.kind,
    required this.subject,
    required this.userStatedState,
    required this.candidateRelation,
    required this.supportingTurnIds,
    required this.strength,
    this.contradictingTurnIds = const [],
    required this.confidence,
    required this.invalidated,
  });

  final ReframeHypothesisKind kind;
  final String subject;
  final String userStatedState;
  final String candidateRelation;
  final List<String> supportingTurnIds;
  final EvidenceStrength strength;
  final List<String> contradictingTurnIds;
  final double confidence;
  final bool invalidated;

  EvidenceHypothesis copyWith({bool? invalidated}) {
    return EvidenceHypothesis(
      kind: kind,
      subject: subject,
      userStatedState: userStatedState,
      candidateRelation: candidateRelation,
      supportingTurnIds: supportingTurnIds,
      strength: strength,
      contradictingTurnIds: contradictingTurnIds,
      confidence: confidence,
      invalidated: invalidated ?? this.invalidated,
    );
  }
}

enum EvidenceStrength {
  /// User gave one explicit causal / motive line (e.g. çünkü + fear).
  explicitCausal,

  /// Two or more independent supporting user signals in the window.
  composite,

  /// Single substantive signal — not enough alone for reframe.
  singleSignal,
}

/// B3 — Session-scoped evidence ledger (user turns only; LLM cannot append).
class EvidenceLedger {
  const EvidenceLedger({
    required this.turns,
    required this.hypotheses,
    required this.invalidatedTopics,
  });

  /// Chronological user lines in the evidence window (T1..Tn labels align).
  final List<LedgerTurn> turns;

  /// Candidate hypotheses with supporting / contradicting turn ids.
  final List<EvidenceHypothesis> hypotheses;

  /// Topics user explicitly rejected — block for rest of night.
  final Set<InvalidatedTopic> invalidatedTopics;

  EvidenceHypothesis? strongestEarned({ReframeHypothesisKind? kind}) {
    EvidenceHypothesis? best;
    for (final h in hypotheses) {
      if (h.invalidated) continue;
      if (kind != null && h.kind != kind) continue;
      if (!_isEarnedStrength(h.strength)) continue;
      if (h.contradictingTurnIds.isNotEmpty) continue;
      if (best == null || h.confidence > best.confidence) best = h;
    }
    return best;
  }

  EvidenceHypothesis? strongestPlausible() {
    EvidenceHypothesis? best;
    for (final h in hypotheses) {
      if (h.invalidated) continue;
      if (h.contradictingTurnIds.isNotEmpty) continue;
      if (best == null || h.confidence > best.confidence) best = h;
    }
    return best;
  }

  bool isTopicInvalidated(InvalidatedTopic topic) =>
      invalidatedTopics.contains(topic);

  static bool _isEarnedStrength(EvidenceStrength s) =>
      s == EvidenceStrength.explicitCausal ||
      s == EvidenceStrength.composite;
}

class LedgerTurn {
  const LedgerTurn({required this.id, required this.text});

  final String id;
  final String text;
}

/// User-correction invalidation scopes (night-long).
enum InvalidatedTopic {
  motherTrauma,
  motherConflictReframe,
  jobLossFear,
  bossTrustAbsence,
  appearanceFear,
  tomorrowPressure,
  lonelinessAlone,
}
