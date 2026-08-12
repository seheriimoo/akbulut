import 'evidence.dart';

class PerceptionEngine {
  const PerceptionEngine();

  List<Evidence> perceive(String message) {
    final text = _normalize(message);

    final evidence = <Evidence>[];

    if (_hasRepetitiveThinking(text)) {
      evidence.add(
        const Evidence(
          type: 'thinking',
          value: 'repetitive_thinking',
          confidence: 0.80,
        ),
      );
    }

    if (_hasFutureUncertainty(text)) {
      evidence.add(
        const Evidence(
          type: 'uncertainty',
          value: 'future_uncertainty',
          confidence: 0.85,
        ),
      );
    }

    if (_hasMentalOverload(text)) {
      evidence.add(
        const Evidence(
          type: 'cognition',
          value: 'mental_overload',
          confidence: 0.90,
        ),
      );
    }

    if (_hasEmotionalActivation(text)) {
      evidence.add(
        const Evidence(
          type: 'emotion',
          value: 'emotional_activation',
          confidence: 0.85,
        ),
      );
    }

    if (_hasLonelinessActivation(text)) {
      evidence.add(
        const Evidence(
          type: 'emotion',
          value: 'loneliness_activation',
          confidence: 0.88,
        ),
      );
    }

    if (_hasHoldingAgainstEase(text)) {
      evidence.add(
        const Evidence(
          type: 'stance',
          value: 'holding_against_ease',
          confidence: 0.88,
        ),
      );
    }

    if (_hasSofteningAcceptance(text)) {
      evidence.add(
        const Evidence(
          type: 'stance',
          value: 'softening_acceptance',
          confidence: 0.80,
        ),
      );
    }

    return evidence;
  }

  /// Normalize case and apostrophe/quote variants so ASCII and curly forms
  /// of contractions ("can't" / "can’t") match the same marker families.
  String _normalize(String message) {
    return message
        .toLowerCase()
        .replaceAll('’', "'")
        .replaceAll('‘', "'")
        .replaceAll('“', '"')
        .replaceAll('”', '"')
        .replaceAll('…', '...');
  }

  bool _hasRepetitiveThinking(String text) {
    return _containsAny(text, const [
      'düşünüyorum',
      'dusunuyorum',
      'thinking',
      'replaying',
      'replay',
      'looping',
      'loops',
      'same loops',
      'over and over',
      'keep going over',
      "can't stop thinking",
      'cannot stop thinking',
      'can not stop thinking',
      'overthinking',
      'overthink',
      "mind won't stop",
      'mind wont stop',
      'mind will not stop',
      "won't stop",
      'wont stop',
    ]);
  }

  bool _hasFutureUncertainty(String text) {
    return _containsAny(text, const [
      'ya şöyle olursa',
      'what if',
      'what-if',
      'tomorrow',
      'worst case',
      'worst versions',
      'falls apart',
    ]);
  }

  bool _hasMentalOverload(String text) {
    return _containsAny(text, const [
      'kafam durmuyor',
      "mind won't stop",
      'mind will not stop',
      'mind will not settle',
      "mind won't settle",
      "won't settle",
      'will not settle',
      'spiral',
      'spiraling',
      'spiralling',
      'racing',
      'racing thoughts',
      "can't let go",
      'cannot let go',
      'can not let go',
      "can't stop",
      'cannot stop',
      'can not stop',
      "won't stop",
      'will not stop',
      'too much in my head',
      'in my head',
      'overthinking',
      'overwhelmed',
      'overwhelm',
      'swirl',
      'swirling',
    ]);
  }

  bool _hasEmotionalActivation(String text) {
    return _containsAny(text, const [
      'stress',
      'stressed',
      'anxious',
      'anxiety',
      'scared',
      'afraid',
      'worried',
      'panic',
      'hurts',
      'hurt',
      'hurting',
      'lonely',
      'alone',
      'yalnız',
      'yalnizlik',
      'yalnızlık',
      'yalniz',
      'miss ',
      'missing',
      'raw',
      'heavy',
      'dread',
      'upset',
      'nervous',
      'tense',
      'on edge',
      'kaygı',
      'kaygi',
      'endişe',
      'endise',
    ]);
  }

  bool _hasLonelinessActivation(String text) {
    return _containsAny(text, const [
      'lonely',
      'loneliness',
      'alone',
      'yalnız',
      'yalnizlik',
      'yalnızlık',
      'yalniz',
      'by myself',
      'kendimi yalnız',
      'kendimi yalniz',
    ]);
  }

  /// Semantic family: user is gripping / unable to accept ease.
  /// Not an exact-message Policy patch — perception evidence only.
  bool _hasHoldingAgainstEase(String text) {
    return _containsAny(text, const [
      "can't let go",
      'cannot let go',
      'can not let go',
      "won't let go",
      'will not let go',
      "can't set it down",
      "can't set that down",
      'cannot set it down',
      'cannot set that down',
      "can't release",
      'cannot release',
      'still holding',
      'holding on',
      'holding onto',
      'still stuck',
      'still gripping',
      'clinging',
      "still can't",
      'still cannot',
      "won't settle",
      'will not settle',
    ]);
  }

  /// Semantic family: softening / quiet acceptance of prior ease.
  /// Stance detector still requires a prior ease-offer phase.
  bool _hasSofteningAcceptance(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return false;

    // Short acknowledgment forms (whole-message).
    if (_wholeSoftAck.hasMatch(trimmed)) {
      return true;
    }

    return _containsAny(text, const [
      'quieter',
      'softer',
      'softening',
      'lighter',
      'settling',
      'settled',
      'calmer',
      'ready to rest',
      'can rest',
      'letting go',
      'let it go',
      'feels better',
      'a bit better',
      'enough for tonight',
      "that's enough",
      'that is enough',
    ]);
  }

  static final RegExp _wholeSoftAck = RegExp(
    r'^(?:'
    r'ok(?:ay)?'
    r'|alright'
    r'|all right'
    r'|yeah'
    r'|yep'
    r'|yes'
    r'|mm+'
    r'|mhm'
    r'|mm-?hmm'
    r'|uh-?huh'
    r')'
    r'[.!?…]*'
    r'$',
  );

  bool _containsAny(String text, List<String> markers) {
    for (final marker in markers) {
      if (text.contains(marker)) return true;
    }
    return false;
  }
}
