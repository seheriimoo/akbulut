import 'conversation_arc_reader.dart';
import 'conversation_grounding_buffer.dart';
import 'evidence_ledger.dart';
import 'night_session.dart';
import 'reframe_evidence_reader.dart';
import 'reframe_readiness_gate.dart';
import 'reframe_trace.dart';
import 'validated_understanding.dart';

/// B3 — Three-way reframe admission (not binary reframe / no reframe).
enum ReframeAdmissionOutcome {
  earned,
  plausibleUnproven,
  noBasis,
}

class ReframeAdmissionDecision {
  const ReframeAdmissionDecision({
    required this.outcome,
    required this.ledger,
    required this.trace,
    this.primaryHypothesis,
  });

  final ReframeAdmissionOutcome outcome;
  final EvidenceLedger ledger;
  final ReframeTrace trace;
  final EvidenceHypothesis? primaryHypothesis;
}

/// B3 — Evidence-bound gate layered on arc + legacy readiness heuristics.
class ReframeAdmissionGate {
  const ReframeAdmissionGate({
    this.legacyGate = const ReframeReadinessGate(),
  });

  final ReframeReadinessGate legacyGate;

  ReframeAdmissionDecision evaluate({
    required NightSession? session,
    required String? message,
    required ValidatedUnderstanding? understanding,
    ConversationGroundingBuffer? conversationGrounding,
    required ConversationArcReader arc,
  }) {
    final ledger = ReframeEvidenceReader.fromGrounding(conversationGrounding);
    final legacyReady = legacyGate.isReady(
      session: session,
      message: message,
      understanding: understanding,
      conversationGrounding: conversationGrounding,
      arc: arc,
    );

    if (message != null && _isUserCorrection(message)) {
      return ReframeAdmissionDecision(
        outcome: ReframeAdmissionOutcome.noBasis,
        ledger: ledger,
        trace: ReframeTrace(
          claim: null,
          supportedBy: const [],
          contradictions: ledger.invalidatedTopics.map((t) => t.name).toList(),
          confidence: 0,
          outcome: ReframeAdmissionOutcome.noBasis,
          note: 'user correction — hold',
        ),
      );
    }

    if (!arc.hadObservePurity) {
      return _decision(
        ReframeAdmissionOutcome.noBasis,
        ledger,
        note: 'no observe yet',
      );
    }

    final earned = ledger.strongestEarned();
    if (earned != null && legacyReady) {
      return ReframeAdmissionDecision(
        outcome: ReframeAdmissionOutcome.earned,
        ledger: ledger,
        primaryHypothesis: earned,
        trace: ReframeTrace.fromHypothesis(
          earned,
          ReframeAdmissionOutcome.earned,
        ),
      );
    }

    if (earned != null &&
        earned.strength == EvidenceStrength.explicitCausal &&
        arc.hadNarrow) {
      return ReframeAdmissionDecision(
        outcome: ReframeAdmissionOutcome.earned,
        ledger: ledger,
        primaryHypothesis: earned,
        trace: ReframeTrace.fromHypothesis(
          earned,
          ReframeAdmissionOutcome.earned,
        ),
      );
    }

    final plausible = ledger.strongestPlausible();
    if (plausible != null &&
        plausible.strength == EvidenceStrength.singleSignal &&
        arc.hadNarrow) {
      return ReframeAdmissionDecision(
        outcome: ReframeAdmissionOutcome.plausibleUnproven,
        ledger: ledger,
        primaryHypothesis: plausible,
        trace: ReframeTrace.fromHypothesis(
          plausible,
          ReframeAdmissionOutcome.plausibleUnproven,
        ),
      );
    }

    if (legacyReady && earned == null) {
      return _decision(
        ReframeAdmissionOutcome.plausibleUnproven,
        ledger,
        note: 'legacy ready but ledger unsupported',
      );
    }

    return _decision(
      ReframeAdmissionOutcome.noBasis,
      ledger,
      note: 'no earned evidence',
    );
  }

  ReframeAdmissionDecision _decision(
    ReframeAdmissionOutcome outcome,
    EvidenceLedger ledger, {
    required String note,
  }) {
    return ReframeAdmissionDecision(
      outcome: outcome,
      ledger: ledger,
      trace: ReframeTrace(
        claim: null,
        supportedBy: const [],
        contradictions: const [],
        confidence: 0,
        outcome: outcome,
        note: note,
      ),
    );
  }

  bool _isUserCorrection(String message) {
    final n = message.toLowerCase().trim();
    if (RegExp(r'^(hayir|hayır)\b').hasMatch(n)) return true;
    if (n.contains('falan yok') || n.contains('korkmuyorum')) return true;
    return false;
  }
}
