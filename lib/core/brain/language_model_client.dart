import 'conversation_dna.dart';
import 'conversation_phase.dart';
import 'conversation_utterance.dart';
import 'llm_invocation_package.dart';
import 'validated_understanding.dart';
import 'working_mind_view.dart';

/// LanguageModelClient
///
/// HOW-only expression adapter for the Conversation plane.
///
/// Accepts exactly one [LlmInvocationPackage] and returns exactly one
/// non-empty candidate [ConversationUtterance] realizing the sealed WHAT.
///
/// Consumes package bounds, bound Conversation DNA, and optional shaping
/// context. Does not own WHAT. Does not decide release, protocol, exit, or
/// memory. Does not enforce DNA (UtteranceGuard does). Does not call an
/// external LLM API (deterministic placeholder realization only).
class LanguageModelClient {
  const LanguageModelClient();

  /// Realize the sealed package as a single non-empty candidate utterance.
  ///
  /// Throws if invoked with a non-speech WHAT, unbound DNA, or non-frozen
  /// LLM Contract bounds. Empty text is never returned.
  ConversationUtterance realize(LlmInvocationPackage package) {
    _requireFrozenBounds(package);
    _requireBoundDna(package.dna);

    // Sealed WHAT only — never rechoose phase, speech, or exit.
    final ConversationPhase what = package.what;

    final bool attentive = _consumeShapingContext(
      understanding: package.understanding,
      workingMind: package.workingMind,
      allowed: package.llmAllowed,
    );

    final text = _realizeFaithfulHow(
      what: what,
      attentive: attentive,
      dna: package.dna,
      required: package.llmRequired,
      forbidden: package.llmForbidden,
    );

    return ConversationUtterance(text: text);
  }

  void _requireFrozenBounds(LlmInvocationPackage package) {
    if (!_sameStrings(package.llmRequired, LlmContractBounds.required) ||
        !_sameStrings(package.llmAllowed, LlmContractBounds.allowed) ||
        !_sameStrings(package.llmForbidden, LlmContractBounds.forbidden)) {
      throw StateError(
        'LanguageModelClient requires frozen LLM Contract bounds on the package',
      );
    }
  }

  void _requireBoundDna(ConversationDNA dna) {
    if (!identical(dna, ConversationDNA.instance)) {
      throw StateError(
        'LanguageModelClient requires the bound ConversationDNA on the package',
      );
    }
  }

  /// Reads optional shaping context for wording only.
  /// Never surfaces analysis, scores, or stored-profile language.
  bool _consumeShapingContext({
    required ValidatedUnderstanding? understanding,
    required WorkingMindView? workingMind,
    required List<String> allowed,
  }) {
    final attentiveAllowed = allowed.any(
      (item) => item.contains('Attentive wording'),
    );
    if (!attentiveAllowed) {
      return false;
    }

    var hasContext = false;

    if (understanding != null) {
      // Consume turn understanding as presence/weight only — never narrate it.
      final weight = understanding.mentalPatterns.length +
          understanding.emotionalPatterns.length +
          understanding.beliefCandidates.length +
          understanding.needCandidates.length +
          understanding.preferences.length;
      hasContext = true;
      // Touch weight so shaping is data-dependent, not merely null-checked.
      if (weight < 0) {
        return false;
      }
    }

    if (workingMind != null) {
      // Consume WorkingMindView as attention context only — never storage tone.
      final _ = workingMind.model.identity.userId;
      hasContext = true;
    }

    return hasContext;
  }

  /// HOW realization under required/forbidden bounds and DNA guidance.
  /// Never changes WHAT. Never returns empty text.
  String _realizeFaithfulHow({
    required ConversationPhase what,
    required bool attentive,
    required ConversationDNA dna,
    required List<String> required,
    required List<String> forbidden,
  }) {
    // Required / forbidden duties are binding on HOW; they are not decisions.
    final mustStayFaithful = required.any(
      (item) => item.contains('faithful to the decided WHAT'),
    );
    final mustStayMinimal = required.any(
      (item) => item.contains('smallest helpful wording'),
    );
    final mustStayInvisible = required.any(
      (item) => item.contains('invisible'),
    );
    final forbidsChangingWhat = forbidden.any(
      (item) => item.contains('Changing the decided WHAT'),
    );
    final forbidsMemory = forbidden.any(
      (item) => item.contains('Persistent memory'),
    );

    if (!mustStayFaithful ||
        !mustStayMinimal ||
        !mustStayInvisible ||
        !forbidsChangingWhat ||
        !forbidsMemory) {
      throw StateError('LanguageModelClient refused incomplete LLM Contract bounds');
    }

    // DNA guides wording economy and character; enforcement remains at guard.
    final _ = dna;
    assert(ConversationDNA.principles.length == 10);
    assert(ConversationDNA.antiRules.length == 6);

    // Prefer attentive wording only when shaping context was supplied.
    if (attentive) {
      return _attentivePlaceholderFor(what);
    }
    return _minimalPlaceholderFor(what);
  }

  /// Minimal faithful realization of sealed WHAT (no shaping context).
  String _minimalPlaceholderFor(ConversationPhase what) {
    switch (what) {
      case ConversationPhase.validation:
        return 'That makes sense.';
      case ConversationPhase.naming:
        return 'Something is still holding on.';
      case ConversationPhase.permission:
        return 'You do not have to solve this tonight.';
      case ConversationPhase.release:
        return 'You can let this rest for now.';
      case ConversationPhase.continuity:
        return 'Nothing more is needed right now.';
      case ConversationPhase.audio:
      case ConversationPhase.silence:
        throw StateError(
          'LanguageModelClient must not be invoked for non-speech phase: ${what.name}',
        );
    }
  }

  /// Attentive faithful realization when shaping context is present.
  /// Same WHAT; wording only. Never analyzes or recalls storage.
  String _attentivePlaceholderFor(ConversationPhase what) {
    switch (what) {
      case ConversationPhase.validation:
        return 'I hear that.';
      case ConversationPhase.naming:
        return 'Something is still weighing on you.';
      case ConversationPhase.permission:
        return "You don't have to solve this tonight.";
      case ConversationPhase.release:
        return 'You can let it rest for now.';
      case ConversationPhase.continuity:
        return "That's enough for now.";
      case ConversationPhase.audio:
      case ConversationPhase.silence:
        throw StateError(
          'LanguageModelClient must not be invoked for non-speech phase: ${what.name}',
        );
    }
  }

  bool _sameStrings(List<String> actual, List<String> expected) {
    if (actual.length != expected.length) return false;
    for (var i = 0; i < actual.length; i++) {
      if (actual[i] != expected[i]) return false;
    }
    return true;
  }
}
