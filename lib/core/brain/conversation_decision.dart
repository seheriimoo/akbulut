import 'conversation_phase.dart';

class ConversationDecision {
  final ConversationPhase phase;

  final bool shouldSpeak;

  const ConversationDecision({required this.phase, required this.shouldSpeak});
}
