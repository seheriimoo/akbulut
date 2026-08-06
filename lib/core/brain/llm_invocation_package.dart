import 'dart:collection';

import 'conversation_dna.dart';
import 'conversation_phase.dart';
import 'validated_understanding.dart';
import 'working_mind_view.dart';

/// Immutable LLM invocation package.
///
/// Carries a fixed speakable WHAT, optional shaping context, and bound
/// expression constraints. Does not contain prompt wording. Does not invoke
/// a model. Does not generate language.
///
/// Construction is rejected for non-speakable WHAT (`audio`, `silence`).
/// Those turns must abstain before packaging.
class LlmInvocationPackage {
  /// Sealed expression intent for this turn (protocol phase to realize).
  /// Always a speakable [ConversationPhase].
  final ConversationPhase what;

  /// Optional turn understanding for wording shaping only.
  final ValidatedUnderstanding? understanding;

  /// Optional WorkingMindView for wording shaping only.
  final WorkingMindView? workingMind;

  /// Bound Conversation DNA constraints (not enforced by this package).
  final ConversationDNA dna;

  /// Bound LLM Contract required responsibilities.
  /// Always [LlmContractBounds.required]; not caller-overridable or mutable.
  UnmodifiableListView<String> get llmRequired => LlmContractBounds.required;

  /// Bound LLM Contract allowed responsibilities.
  /// Always [LlmContractBounds.allowed]; not caller-overridable or mutable.
  UnmodifiableListView<String> get llmAllowed => LlmContractBounds.allowed;

  /// Bound LLM Contract forbidden responsibilities.
  /// Always [LlmContractBounds.forbidden]; not caller-overridable or mutable.
  UnmodifiableListView<String> get llmForbidden => LlmContractBounds.forbidden;

  /// Creates a package for a speakable WHAT only.
  ///
  /// Throws [ArgumentError] if [what] is `audio` or `silence`.
  LlmInvocationPackage({
    required this.what,
    this.understanding,
    this.workingMind,
    this.dna = ConversationDNA.instance,
  }) {
    if (!_isSpeakableWhat(what)) {
      throw ArgumentError.value(
        what,
        'what',
        'LlmInvocationPackage WHAT must be speakable '
        '(validation, naming, permission, release, or continuity)',
      );
    }
  }

  static bool _isSpeakableWhat(ConversationPhase what) {
    switch (what) {
      case ConversationPhase.validation:
      case ConversationPhase.naming:
      case ConversationPhase.permission:
      case ConversationPhase.release:
      case ConversationPhase.continuity:
        return true;
      case ConversationPhase.audio:
      case ConversationPhase.silence:
        return false;
    }
  }
}

/// Frozen LLM Contract bounds attached to every invocation package.
///
/// Declarative only. No generation. No validation. No model calls.
/// Exported collections are unmodifiable.
class LlmContractBounds {
  const LlmContractBounds._();

  static const List<String> _required = [
    'Realize the already-decided WHAT as natural language',
    'Emit exactly one utterance for the turn',
    'Use the smallest helpful wording for that WHAT',
    'Keep intelligence invisible in the wording',
    'Remain faithful to the decided WHAT',
  ];

  static const List<String> _allowed = [
    'Lexical and syntactic choice of phrasing',
    'Attentive wording from already-supplied expression context',
    'Natural nighttime relief tone',
  ];

  static const List<String> _forbidden = [
    'Release, protocol/phase, or exit judgment',
    'Changing the decided WHAT',
    'Choosing silence or speech contrary to authorization',
    'Multiple utterances or multi-insight bundles',
    'Surfacing analysis, scores, or system reasoning',
    'Persistent memory / Living Mind Model / durable learning writes',
    'Upstream revision in the same turn',
    'Clinical, diagnostic, therapeutic, crisis, or chatbot engagement roles',
  ];

  static final UnmodifiableListView<String> required =
      UnmodifiableListView<String>(_required);

  static final UnmodifiableListView<String> allowed =
      UnmodifiableListView<String>(_allowed);

  static final UnmodifiableListView<String> forbidden =
      UnmodifiableListView<String>(_forbidden);
}
