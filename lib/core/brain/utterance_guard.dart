import 'conversation_dna.dart';
import 'conversation_phase.dart';
import 'conversation_utterance.dart';

/// UtteranceGuard
///
/// Enforces Conversation Output Contract and Conversation DNA on emission.
///
/// Expression-plane only. Does not decide release, protocol, or exit.
/// Does not generate language. Does not write memory.
/// Admit/reject only — never rewrites or repairs wording.
class UtteranceGuard {
  const UtteranceGuard();

  static const List<ConversationPhase> _speakablePhases = [
    ConversationPhase.validation,
    ConversationPhase.naming,
    ConversationPhase.permission,
    ConversationPhase.release,
    ConversationPhase.continuity,
  ];

  /// Soft upper bound for DNA principle 2 (fewest helpful words).
  /// Placeholders remain well under this; essays are rejected.
  static const int _maxHelpfulWords = 20;

  /// Returns [utterance] if it may leave the Conversation layer; otherwise
  /// `null` (no conversational language).
  ///
  /// [dna] is the bound Conversation DNA from the invocation package.
  /// Defaults to [ConversationDNA.instance], the sole frozen binding today.
  ConversationUtterance? allow({
    required ConversationUtterance utterance,
    required ConversationPhase what,
    ConversationDNA dna = ConversationDNA.instance,
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

    // Bound Conversation DNA: every anti-rule and principle must hold.
    if (!_satisfiesDna(text: text, what: what, dna: dna)) {
      return null;
    }

    // Emit the validated single utterance (normalized trim). No rewrite.
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

  /// Contract-level WHAT faithfulness.
  ///
  /// Allows natural wording variation inside the sealed WHAT.
  /// Rejects non-speech emission and semantic drift into another agenda/phase.
  bool _faithfulToWhat(String text, ConversationPhase what) {
    switch (what) {
      case ConversationPhase.audio:
      case ConversationPhase.silence:
        return false;
      case ConversationPhase.validation:
      case ConversationPhase.naming:
      case ConversationPhase.permission:
      case ConversationPhase.release:
      case ConversationPhase.continuity:
        break;
    }

    final lower = text.toLowerCase();

    if (!_matchesPhase(lower, what)) {
      return false;
    }

    for (final other in _speakablePhases) {
      if (other == what) continue;
      if (_matchesPhase(lower, other)) {
        return false;
      }
    }

    return true;
  }

  /// Semantic signature of a speakable protocol phase.
  bool _matchesPhase(String lower, ConversationPhase phase) {
    switch (phase) {
      case ConversationPhase.validation:
        return _containsAny(lower, const [
          'makes sense',
          'understand',
          'hear you',
          'hear that',
          'that sounds',
          "that's hard",
          'thats hard',
        ]);
      case ConversationPhase.naming:
        return _containsAny(lower, const [
          'holding on',
          'weighing',
          'still there',
          'lingering',
          'on your mind',
        ]);
      case ConversationPhase.permission:
        return _containsAny(lower, const [
          'do not have to',
          "don't have to",
          'dont have to',
          'no need to solve',
          'not something to solve',
          'solve this tonight',
        ]);
      case ConversationPhase.release:
        return _containsAny(lower, const [
          'let this rest',
          'let it rest',
          'set this down',
          'set it down',
          'put this down',
          'put it down',
          'release this',
          'let go for now',
        ]);
      case ConversationPhase.continuity:
        return _containsAny(lower, const [
          'nothing more',
          'no more is needed',
          'nothing else needed',
          "that's enough",
          'thats enough',
          'enough for now',
        ]);
      case ConversationPhase.audio:
      case ConversationPhase.silence:
        return false;
    }
  }

  bool _containsAny(String lower, List<String> markers) {
    for (final marker in markers) {
      if (lower.contains(marker)) return true;
    }
    return false;
  }

  /// Enforces the bound [dna]: all anti-rules and all principles.
  /// Admit/reject only.
  bool _satisfiesDna({
    required String text,
    required ConversationPhase what,
    required ConversationDNA dna,
  }) {
    // Only the bound canonical DNA may authorize emission.
    if (!identical(dna, ConversationDNA.instance)) {
      return false;
    }

    final lower = text.toLowerCase();

    for (final antiRule in ConversationDNA.antiRules) {
      if (!_antiRuleClear(lower: lower, what: what, antiRule: antiRule)) {
        return false;
      }
    }

    for (final principle in ConversationDNA.principles) {
      if (!_principleClear(lower: lower, text: text, principle: principle)) {
        return false;
      }
    }

    return true;
  }

  bool _antiRuleClear({
    required String lower,
    required ConversationPhase what,
    required ConversationDNAAntiRule antiRule,
  }) {
    switch (antiRule.name) {
      case 'Multiple insights in one turn':
        return !_containsAny(lower, const [
          ' also ',
          ' additionally ',
          ' another ',
          '1.',
          '2.',
          ' first ',
          ' second ',
          'tip:',
          'try this',
        ]);
      case 'Analysis, scores, or pattern narration as content':
        return !_containsAny(lower, const [
          'score',
          'diagnos',
          'pattern shows',
          'i detected',
          'analysis',
          'your anxiety level',
          'your pattern',
          'i classified',
          'based on your data',
        ]);
      case 'Engagement hooks or follow-up bait':
        return !_containsAny(lower, const [
          '?',
          'tell me more',
          'what else',
          'let’s keep talking',
          "let's keep talking",
          'keep going',
          'want to talk',
          'share more',
        ]);
      case 'Sleep commands or performance coaching':
        return !_containsAny(lower, const [
          'go to sleep',
          'you should sleep',
          'fall asleep',
          'make yourself sleep',
          'force yourself to sleep',
          'sleep better tonight',
          'improve your sleep',
        ]);
      case 'Clinical / diagnostic / therapeutic framing':
        return !_containsAny(lower, const [
          'therapist',
          'therapy',
          'clinical',
          'disorder',
          'crisis',
          'medication',
          'diagnos',
          'psycholog',
          'treatment plan',
        ]);
      case 'Rewriting the decided conversational move':
        // Enforced by the WHAT faithfulness gate before DNA checks.
        // Re-assert against the same sealed WHAT; never rewrite text.
        return _faithfulToWhat(lower, what);
      default:
        // Unknown anti-rule on a non-canonical DNA binding cannot pass.
        return false;
    }
  }

  bool _principleClear({
    required String lower,
    required String text,
    required ConversationDNAPrinciple principle,
  }) {
    switch (principle.id) {
      case 1: // Subtract, do not add
        return !_containsAny(lower, const [
          'have you tried',
          "let's work on",
          'lets work on',
          'action plan',
          'homework',
          'new problem',
          'another issue',
          'we should examine',
          'think about why',
        ]);
      case 2: // Fewest helpful words
        final words = text
            .split(RegExp(r'\s+'))
            .where((w) => w.isNotEmpty)
            .length;
        return words <= _maxHelpfulWords;
      case 3: // One help, not many
        return !_containsAny(lower, const [
          ' also ',
          ' additionally ',
          ' another ',
          'as well as',
          'not only',
        ]);
      case 4: // Understood, not analyzed
        return !_containsAny(lower, const [
          'score',
          'diagnos',
          'pattern shows',
          'i detected',
          'analysis',
          'i labeled',
          'system shows',
          'your anxiety level',
        ]);
      case 5: // Attention, not storage
        return !_containsAny(lower, const [
          'i stored',
          'database',
          'in my memory',
          'your profile says',
          'according to your record',
          'from your data',
        ]);
      case 6: // Relief over engagement
        return !_containsAny(lower, const [
          '?',
          'tell me more',
          'what else',
          'let’s keep talking',
          "let's keep talking",
          'keep talking',
          'continue this',
        ]);
      case 7: // Silence can be success — reject presence-filling
        return !_containsAny(lower, const [
          'just checking in',
          "i'm still here",
          'im still here',
          'i am here if',
          "don't go quiet",
          'dont go quiet',
          'say something',
        ]);
      case 8: // Sleep is never forced
        return !_containsAny(lower, const [
          'go to sleep',
          'you should sleep',
          'fall asleep',
          'make yourself sleep',
          'force yourself to sleep',
          'sleep now',
        ]);
      case 9: // Stay inside the decided help
        // Enforced by WHAT faithfulness before DNA; nothing further here.
        return true;
      case 10: // Remain human and non-clinical
        return !_containsAny(lower, const [
          'therapist',
          'therapy',
          'clinical',
          'disorder',
          'crisis',
          'medication',
          'as an ai',
          'as a chatbot',
          'doctor',
          'productivity',
          'optimize your',
        ]);
      default:
        return false;
    }
  }
}
