/// Turn-local stance of the user's response relative to the prior sealed WHAT.
///
/// Night-scoped understanding only. Not durable memory.
/// Fail-closed default: [unclear] — never invent acceptance.
enum TurnResponseStance {
  /// No reliable response stance detected.
  unclear,

  /// Active night load continues (mental/emotional activation).
  continuedLoad,

  /// User is holding against an ease/release invitation.
  holdingAgainstEase,

  /// User is softening / accepting a prior ease invitation.
  softeningAcceptance,
}
