/// Soft functional hypotheses about why continued thinking may be occurring.
///
/// Runtime cognition only — not editorial Gold labels, not phase authority,
/// not reply routing.
enum ThinkingFunctionKind {
  /// Stopping feels costly; thinking functions as protective holding.
  protectiveHolding,

  /// Thinking is equated with readiness / avoiding unpreparedness.
  preparationRehearsal,

  /// Tomorrow / near future is being carried into the present night.
  earlyTomorrowCarry,

  /// What-if / worst-case futures are being rehearsed.
  worstCaseRehearsal,

  /// Relief / certainty is promised after one more thought or review.
  certaintyChase,
}
