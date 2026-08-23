import 'conversation_decision.dart';
import 'conversation_dna.dart';
import 'conversation_grounding_buffer.dart';
import 'conversation_phase.dart';
import 'exit_decision.dart';
import 'llm_invocation_package.dart';
import 'prior_admitted_expression.dart';
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
  /// Optional inputs: [understanding], [workingMind], [livedExpression],
  /// [conversationGrounding], [priorAdmittedExpression] (shaping only).
  ///
  /// [conversationGrounding]: admit when present; omit when null.
  /// Never invent or modify grounding. Never decision authority.
  ///
  /// Forbidden inputs are excluded by omission: no release decision,
  /// no direct Living Mind Model, no transcript-as-authority, no memory-write
  /// authority, no deprecated reasoning decisions.
  LlmInvocationPackage? package({
    required ConversationDecision conversationDecision,
    required ExitDecision exitDecision,
    ValidatedUnderstanding? understanding,
    WorkingMindView? workingMind,
    String? livedExpression,
    ConversationGroundingBuffer? conversationGrounding,
    PriorAdmittedExpression? priorAdmittedExpression,
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
    // conversationGrounding: admit if provided, omit if null. Never invent.
    return LlmInvocationPackage(
      what: what,
      understanding: understanding,
      workingMind: workingMind,
      livedExpression: livedExpression,
      conversationGrounding: conversationGrounding,
      priorAdmittedExpression: priorAdmittedExpression,
      exitDecision: exitDecision,
      expressionMode: conversationDecision.expressionMode,
      repairRepetitionProtest: conversationDecision.repairRepetitionProtest,
      dna: ConversationDNA.instance,
    );
  }

  /// Gate: protocol speak intent must authorize invoke.
  ///
  /// Allows speech when Exit is [ExitDecision.continueConversation], or when
  /// Exit is [ExitDecision.transitionToAudio] with shouldSpeak (Enough soft
  /// rest-audio handoff on the same turn before player navigation).
  bool _invocationEligible({
    required ConversationDecision conversationDecision,
    required ExitDecision exitDecision,
  }) {
    if (!conversationDecision.shouldSpeak) {
      return false;
    }

    switch (exitDecision) {
      case ExitDecision.continueConversation:
        break;
      case ExitDecision.transitionToAudio:
        // Spoken handoff, then audio.
        break;
      case ExitDecision.silence:
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
      case ConversationPhase.neutralEntry:
        return true;
    }
  }
}
