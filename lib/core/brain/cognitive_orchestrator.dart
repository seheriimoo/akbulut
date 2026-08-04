import 'conversation_engine.dart';
import 'conversation_policy.dart';
import 'exit_intelligence.dart';
import 'perception_engine.dart';
import 'release_engine.dart';

/// CognitiveOrchestrator
///
/// Central coordinator of the HCOS cognitive pipeline.
///
/// Owns no business logic.
///
/// Wires components together in a forward-only pipeline.
class CognitiveOrchestrator {
  final PerceptionEngine perceptionEngine;

  final ReleaseEngine releaseEngine;

  final ConversationPolicy conversationPolicy;

  final ConversationEngine conversationEngine;

  final ExitIntelligence exitIntelligence;

  const CognitiveOrchestrator({
    required this.perceptionEngine,
    required this.releaseEngine,
    required this.conversationPolicy,
    required this.conversationEngine,
    required this.exitIntelligence,
  });
}
