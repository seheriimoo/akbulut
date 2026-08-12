/// HCOS Conversation Protocol
///
/// The protocol defines the sequence of cognitive
/// interventions during a nighttime conversation.
///
/// Not every phase is required.
/// Phases may be skipped by ConversationPolicy
/// when doing so reduces cognitive load.
enum ConversationPhase {
  validation,
  naming,
  permission,
  release,
  continuity,

  /// Content-free greeting acknowledgment (Neutral Entry V1).
  /// Not Receipt. Not Enough/continuity. Not Arrival-as-assistant-silent.
  neutralEntry,

  audio,
  silence,
}
