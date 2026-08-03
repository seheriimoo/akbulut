/// Defines how the current conversation should end.
enum ExitDecision {
  /// Continue the conversation.
  continueConversation,

  /// Transition from conversation to audio.
  transitionToAudio,

  /// End the interaction completely.
  silence,
}
