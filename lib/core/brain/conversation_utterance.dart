/// Immutable speech result produced by ConversationEngine.
///
/// When Conversation emits conversational language, exactly one
/// [ConversationUtterance] is produced for the turn.
///
/// No conversational language is represented by the absence of this
/// value (`null` at the Conversation boundary), not by an empty utterance.
class ConversationUtterance {
  final String text;

  const ConversationUtterance({required this.text});
}
