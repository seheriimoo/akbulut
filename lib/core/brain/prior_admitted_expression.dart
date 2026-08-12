import 'conversation_phase.dart';

/// Last Guard-admitted assistant line from the same night.
///
/// Expression-plane anti-repeat only. Not decision authority.
/// Not durable memory. Not stored in ConversationGroundingBuffer
/// (that buffer remains user-only).
class PriorAdmittedExpression {
  /// Phase under which the line was admitted.
  final ConversationPhase phase;

  /// Admitted utterance text (trimmed).
  final String text;

  const PriorAdmittedExpression({
    required this.phase,
    required this.text,
  });

  /// Soft upper bound for prompt materialization.
  static const int maxDirectiveChars = 160;

  /// Deterministic anti-repeat steering for compile overlays.
  String antiRepeatDirective() {
    final clipped = _clip(text);
    return 'Anti-repeat (same-night prior admitted ${phase.name} line): '
        'do not near-repeat or restamp “$clipped”. '
        'Vary naturally inside the sealed WHAT only.';
  }

  static String _clip(String raw) {
    final trimmed = raw.trim();
    if (trimmed.length <= maxDirectiveChars) return trimmed;
    return '${trimmed.substring(0, maxDirectiveChars).trimRight()}…';
  }
}
