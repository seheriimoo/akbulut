import 'evidence_ledger.dart';
import 'reframe_admission_gate.dart';
import 'reframe_hypothesis_kind.dart';

/// B3 — Debug trace for admitted / rejected reframes (not shown to user).
class ReframeTrace {
  const ReframeTrace({
    required this.claim,
    required this.supportedBy,
    required this.contradictions,
    required this.confidence,
    required this.outcome,
    this.note,
  });

  final String? claim;
  final List<String> supportedBy;
  final List<String> contradictions;
  final double confidence;
  final ReframeAdmissionOutcome outcome;
  final String? note;

  factory ReframeTrace.fromHypothesis(
    EvidenceHypothesis h,
    ReframeAdmissionOutcome outcome,
  ) {
    return ReframeTrace(
      claim: h.candidateRelation,
      supportedBy: h.supportingTurnIds,
      contradictions: h.contradictingTurnIds,
      confidence: h.confidence,
      outcome: outcome,
      note: h.kind.name,
    );
  }

  @override
  String toString() {
    return 'REFRAME CLAIM: ${claim ?? "none"}\n'
        'SUPPORTED BY: ${supportedBy.isEmpty ? "none" : supportedBy.join(" + ")}\n'
        'CONTRADICTIONS: ${contradictions.isEmpty ? "none" : contradictions.join(", ")}\n'
        'CONFIDENCE: ${confidence.toStringAsFixed(2)}\n'
        'OUTCOME: ${outcome.name}${note != null ? " ($note)" : ""}';
  }
}
