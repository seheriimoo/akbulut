import 'conversation_decision.dart';
import 'conversation_dna.dart';
import 'conversation_phase.dart';
import 'exit_decision.dart';
import 'llm_invocation_package.dart';
import 'validated_understanding.dart';
import 'working_mind_view.dart';

/// Prompt Architecture
///
/// Expression-binding transformation inside the Conversation plane.
///
/// Transforms authorized Conversation inputs into exactly one immutable
/// [LlmInvocationPackage], or abstains with no invocation.
///
/// Does not decide release, protocol, or exit.
/// Does not generate language.
/// Does not invoke an LLM.
/// Does not enforce Conversation DNA.
/// Does not write memory.
class PromptArchitecture {
  const PromptArchitecture();

  /// Package a constrained LLM invocation, or return `null` to abstain.
  ///
  /// Required inputs: [conversationDecision], [exitDecision].
  /// Optional inputs: [understanding], [workingMind] (shaping only).
  ///
  /// Forbidden inputs are excluded by omission: no release decision,
  /// no direct Living Mind Model, no raw transcript, no memory-write
  /// authority, no deprecated reasoning decisions.
  LlmInvocationPackage? package({
    required ConversationDecision conversationDecision,
    required ExitDecision exitDecision,
    ValidatedUnderstanding? understanding,
    WorkingMindView? workingMind,
  }) {
    if (!_invocationEligible(
      conversationDecision: conversationDecision,
      exitDecision: exitDecision,
    )) {
      return null;
    }

    // Fix WHAT from the authorized protocol decision. Do not expand it.
    final ConversationPhase what = conversationDecision.phase;

    // Admit optional shaping context only; never reopen phase/exit/release.
    return LlmInvocationPackage(
      what: what,
      understanding: understanding,
      workingMind: workingMind,
      dna: ConversationDNA.instance,
    );
  }

  /// Gate: Exit permission and protocol speak intent must authorize invoke.
  bool _invocationEligible({
    required ConversationDecision conversationDecision,
    required ExitDecision exitDecision,
  }) {
    if (exitDecision != ExitDecision.continueConversation) {
      return false;
    }
    if (!conversationDecision.shouldSpeak) {
      return false;
    }
    switch (conversationDecision.phase) {
      case ConversationPhase.audio:
      case ConversationPhase.silence:
        return false;
      case ConversationPhase.validation:
      case ConversationPhase.naming:
      case ConversationPhase.permission:
      case ConversationPhase.release:
      case ConversationPhase.continuity:
        return true;
    }
  }
}
