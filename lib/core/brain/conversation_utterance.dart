/// Immutable output produced by ConversationEngine.
///
/// Contains the text that HCOS chooses to deliver
/// during the current turn.
class ConversationUtterance {
  final String text;

  const ConversationUtterance({required this.text});
}
