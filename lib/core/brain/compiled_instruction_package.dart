import 'dart:collection';

import 'conversation_blueprint_binding.dart';
import 'conversation_phase.dart';

/// Immutable vendor-ready instruction package produced by ConversationCompiler.
///
/// Contains deterministic language-instruction material derived solely from a
/// sealed [LlmInvocationPackage] and frozen conversation canon.
///
/// Does not choose WHAT, psychology, release, exit, or memory.
/// Does not call a vendor. Does not validate emission.
class CompiledInstructionPackage {
  /// Identity of the already-sealed speakable WHAT.
  final ConversationPhase sealedWhat;

  /// Blueprint stage binding for [sealedWhat].
  final BlueprintStageBinding stage;

  /// Frozen constitutional constraints bound for realization.
  final UnmodifiableListView<String> constitutionalConstraints;

  /// Frozen philosophical beliefs + stance bound for realization.
  final UnmodifiableListView<String> philosophicalStance;

  /// Bound Conversation DNA principles restated for realization only.
  final UnmodifiableListView<String> dnaPrinciples;

  /// Bound Conversation DNA anti-rules restated for realization only.
  final UnmodifiableListView<String> dnaAntiRules;

  /// Bound LLM Contract required duties (unchanged meaning).
  final UnmodifiableListView<String> llmRequired;

  /// Bound LLM Contract allowed duties (unchanged meaning).
  final UnmodifiableListView<String> llmAllowed;

  /// Bound LLM Contract forbidden duties (unchanged meaning).
  final UnmodifiableListView<String> llmForbidden;

  /// Deterministic realization directive for exactly one short utterance.
  final String realizationDirective;

  /// Shaping presence note only — never analysis narration.
  final String shapingNote;

  /// Canon versions bound at compile time.
  final String constitutionVersion;
  final String philosophyVersion;
  final String blueprintVersion;

  /// Deterministic system instruction material for transport serialization.
  final String systemContent;

  /// Deterministic user instruction material for transport serialization.
  final String userContent;

  CompiledInstructionPackage({
    required this.sealedWhat,
    required this.stage,
    required List<String> constitutionalConstraints,
    required List<String> philosophicalStance,
    required List<String> dnaPrinciples,
    required List<String> dnaAntiRules,
    required List<String> llmRequired,
    required List<String> llmAllowed,
    required List<String> llmForbidden,
    required this.realizationDirective,
    required this.shapingNote,
    required this.constitutionVersion,
    required this.philosophyVersion,
    required this.blueprintVersion,
    required this.systemContent,
    required this.userContent,
  })  : constitutionalConstraints =
            UnmodifiableListView<String>(constitutionalConstraints),
        philosophicalStance = UnmodifiableListView<String>(philosophicalStance),
        dnaPrinciples = UnmodifiableListView<String>(dnaPrinciples),
        dnaAntiRules = UnmodifiableListView<String>(dnaAntiRules),
        llmRequired = UnmodifiableListView<String>(llmRequired),
        llmAllowed = UnmodifiableListView<String>(llmAllowed),
        llmForbidden = UnmodifiableListView<String>(llmForbidden);
}
