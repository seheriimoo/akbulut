/// Expression compile/guard mode for a single turn (Slice 1).
///
/// Does not choose WHAT, exit, or protocol. Shapes HOW only.
enum ConversationExpressionMode {
  standard,

  /// First Receipt on a load night: mirror only, no reframe.
  observePurity,

  /// Protest / correction: drop prior hypothesis, repair + optional question.
  repair,

  /// Light/no-load turn: warm chat, one natural follow-up question allowed.
  lightChat,

  /// Slice 2: one fork question splitting two hypotheses from their words.
  narrow,

  /// Slice 2: evidence-gated soft reframe — confirmable, not advice.
  reframe,

  /// Slice 2: after reframe — brief listen only, no new interpretation.
  postReframeListen,

  /// Slice 3: connect confirmed reframe to tonight's mental loop.
  integrate,

  /// Slice 3: tonight boundary + personalized put-down from confirmed insight.
  closure,

  /// B4: honest synthesis / hold after narrow exhaustion — no new psychology.
  groundedHold,
}
