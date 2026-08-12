import 'thinking_function_kind.dart';

/// Soft, evidence-gated hypothesis about the function of continued thinking.
///
/// Cognition / shaping evidence only. Must not choose phase, readiness, exit,
/// memory, grounding ownership, Guard, or live wording by itself.
class ThinkingFunctionHypothesis {
  final ThinkingFunctionKind kind;

  /// Deterministic V1 confidence in `0.0..1.0`.
  final double confidence;

  /// Stable evidence markers that justified this hypothesis.
  final List<String> evidenceIds;

  /// How many authorized user turns (current + priors) contributed evidence.
  final int supportTurnCount;

  ThinkingFunctionHypothesis({
    required this.kind,
    required this.confidence,
    required List<String> evidenceIds,
    required this.supportTurnCount,
  })  : evidenceIds = List<String>.unmodifiable(evidenceIds),
        assert(confidence >= 0.0 && confidence <= 1.0),
        assert(evidenceIds.isNotEmpty),
        assert(supportTurnCount >= 1);
}
