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
}
