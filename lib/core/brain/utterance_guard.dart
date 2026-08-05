import 'conversation_dna.dart';
import 'conversation_phase.dart';
import 'conversation_utterance.dart';

/// UtteranceGuard
///
/// Enforces Conversation Output Contract and Conversation DNA on emission.
///
/// Expression-plane only. Does not decide release, protocol, or exit.
/// Does not generate language. Does not write memory.
/// Deterministic placeholder enforcement.
class UtteranceGuard {
  const UtteranceGuard();

  /// Returns [utterance] if it may leave the Conversation layer; otherwise
  /// `null` (no conversational language).
  ///
  /// Ensures exactly one speech outcome when allowed: a single non-empty
  /// utterance faithful to [what] and compliant with [ConversationDNA].
  ConversationUtterance? allow({
    required ConversationUtterance utterance,
    required ConversationPhase what,
  }) {
    final text = utterance.text.trim();

    // Output Contract: no conversational language is absence, not empty text.
    if (text.isEmpty) {
      return null;
    }

    // Output Contract: exactly one speech artifact (no multi-message bundles).
    if (!_singleSpeechOutcome(text)) {
      return null;
    }

    // Stay inside the decided WHAT (DNA principle 9 / anti-rule rewrite).
    if (!_faithfulToWhat(text, what)) {
      return null;
    }

    // Frozen Conversation DNA anti-rules.
    if (!_satisfiesDna(text)) {
      return null;
    }

    // Emit the validated single utterance (normalized trim).
    return ConversationUtterance(text: text);
  }

  bool _singleSpeechOutcome(String text) {
    if (text.contains('\n')) {
      return false;
    }
    // More than one terminal sentence marks stacked help.
    final sentenceEnds = RegExp(r'[.!?]+').allMatches(text).length;
    return sentenceEnds <= 1;
  }

  /// Placeholder faithfulness: utterance must match the canonical realization
  /// of the sealed WHAT. Non-speech phases must not emit language.
  bool _faithfulToWhat(String text, ConversationPhase what) {
    final expected = _canonicalRealization(what);
    if (expected.isEmpty) {
      return false;
    }
    return text == expected;
  }

  String _canonicalRealization(ConversationPhase what) {
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
        return '';
    }
  }

  bool _satisfiesDna(String text) {
    // Constraints are defined by frozen ConversationDNA anti-rules/principles.
    assert(ConversationDNA.principles.length == 10);
    assert(ConversationDNA.antiRules.length == 6);

    final lower = text.toLowerCase();

    // Multiple insights / stacked tips.
    if (lower.contains(' also ') ||
        lower.contains(' additionally ') ||
        lower.contains(' another ') ||
        lower.contains('1.') ||
        lower.contains('2.')) {
      return false;
    }

    // Analysis, scores, or pattern narration.
    if (lower.contains('score') ||
        lower.contains('diagnos') ||
        lower.contains('pattern shows') ||
        lower.contains('i detected') ||
        lower.contains('analysis') ||
        lower.contains('your anxiety level')) {
      return false;
    }

    // Engagement hooks or follow-up bait.
    if (lower.contains('?') ||
        lower.contains('tell me more') ||
        lower.contains('what else') ||
        lower.contains('let’s keep talking') ||
        lower.contains("let's keep talking")) {
      return false;
    }

    // Sleep commands or performance coaching.
    if (lower.contains('go to sleep') ||
        lower.contains('you should sleep') ||
        lower.contains('fall asleep') ||
        lower.contains('make yourself sleep')) {
      return false;
    }

    // Clinical / diagnostic / therapeutic framing.
    if (lower.contains('therapist') ||
        lower.contains('therapy') ||
        lower.contains('clinical') ||
        lower.contains('disorder') ||
        lower.contains('crisis') ||
        lower.contains('medication')) {
      return false;
    }

    // Attention-not-storage / system recall tone.
    if (lower.contains('i stored') ||
        lower.contains('database') ||
        lower.contains('in my memory') ||
        lower.contains('your profile says')) {
      return false;
    }

    return true;
  }
}
