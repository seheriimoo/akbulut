/// Deterministic detector for explicit conversation→audio exit intent.
///
/// Presentation/policy input only. Does not own readiness, speech, or beds.
class ExplicitExitIntent {
  const ExplicitExitIntent();

  /// True when the user clearly asks to end talk with Nocta and/or move to audio.
  /// Bare “yeter/enough” inside unrelated sentences must not match.
  bool matches(String message) {
    final normalized = _normalize(message);
    if (normalized.isEmpty) return false;
    if (_isReportedSpeech(normalized)) return false;
    if (_isFalsePositive(normalized)) return false;
    if (_matchesAudioMove(normalized)) return true;
    if (_matchesBareEnough(normalized)) return true;
    if (_matchesAffirmationEnough(normalized)) return true;
    if (_matchesNaturalTrClose(normalized)) return true;
    return false;
  }

  static String _normalize(String message) {
    var s = message.trim().toLowerCase();
    s = s.replaceAll('\u2019', "'");
    s = s.replaceAll(RegExp(r'\s+'), ' ');
    // ASCII fold so mobile TR without diacritics still closes
    // ("konusmak istemiyorum" == "konuşmak istemiyorum").
    s = s
        .replaceAll('ş', 's')
        .replaceAll('ğ', 'g')
        .replaceAll('ü', 'u')
        .replaceAll('ö', 'o')
        .replaceAll('ı', 'i')
        .replaceAll('ç', 'c')
        .replaceAll('â', 'a')
        .replaceAll('î', 'i')
        .replaceAll('û', 'u');
    return s;
  }

  /// Exit-only abbreviation fold. Does not rewrite general chat language.
  static String _normalizeExitAffirmations(String n) {
    var s = n;
    s = s.replaceAll(RegExp(r'\btmm\b'), 'tamam');
    s = s.replaceAll(RegExp(r'\bokey\b'), 'ok');
    return s;
  }

  /// Strip trailing sentence punctuation for whole-utterance checks.
  static String _stripTrailingPunct(String n) {
    return n.replaceAll(RegExp(r'[.!?…,;:]+$'), '').trim();
  }

  static bool _isReportedSpeech(String n) {
    // Someone else said an exit line — not the user's present intent.
    // `n` is already ASCII-folded.
    if (n.contains('demisti')) return true;
    if (n.contains('demis')) return true;
    if (RegExp(r'\bdedi\b').hasMatch(n)) return true;
    if (n.contains('diyor ki')) return true;
    if (n.contains('demis ki')) return true;
    if (RegExp(r'\bsoylemis\b').hasMatch(n)) return true;
    return false;
  }

  static bool _isFalsePositive(String n) {
    // Sleep / volume / time sufficiency — not night-exit intent.
    if (n.contains('yeter mi')) return true;
    if (n.contains('yeterince')) return true;
    if (RegExp(r'\byeterli\b').hasMatch(n)) return true;
    if (n.contains('enough sleep')) return true;
    if (n.contains('loud enough')) return true;
    if (n.contains('enough time')) return true;
    if (RegExp(r'\bget enough\b').hasMatch(n)) return true;
    if (RegExp(r'\bhave enough\b').hasMatch(n)) return true;
    if (RegExp(r'\bis .+ enough\b').hasMatch(n)) return true;
    // "bu kadar uyku yeter…" is sleep talk, not night close.
    if (n.contains('bu kadar uyku')) return true;
    return false;
  }

  static bool _matchesAudioMove(String n) {
    // Turkish direct audio handoff (covers geçelim / geçebiliriz / geçmek…).
    if (n.contains('sese geç')) return true;
    if (n.contains('sese gec')) return true; // ASCII fallback
    // English direct audio handoff.
    if (n.contains('move to audio')) return true;
    if (n.contains('ready for the audio')) return true;
    if (n.contains('take me to the audio')) return true;
    return false;
  }

  static bool _matchesBareEnough(String n) {
    // Whole-utterance close only (allow light trailing punctuation).
    final stripped = _stripTrailingPunct(n);
    if (stripped == 'yeter') return true;
    if (stripped == 'artık yeter') return true;
    if (stripped == 'artik yeter') return true;
    if (stripped == 'enough') return true;
    if (stripped == "that's enough") return true;
    if (stripped == 'thats enough') return true;
    return false;
  }

  /// Affirmation + bare yeter (tmm/ok/okey/peki/tamam [artık] yeter).
  /// Bare affirmation alone is never an exit.
  static bool _matchesAffirmationEnough(String n) {
    final folded = _normalizeExitAffirmations(n);
    final stripped = _stripTrailingPunct(folded);
    // Affirmation alone — not exit.
    if (stripped == 'tamam' ||
        stripped == 'ok' ||
        stripped == 'peki' ||
        stripped == 'tmm' ||
        stripped == 'okey') {
      return false;
    }
    if (stripped == 'tamam yeter') return true;
    if (stripped == 'tamam artık yeter') return true;
    if (stripped == 'tamam artik yeter') return true;
    if (stripped == 'ok yeter') return true;
    if (stripped == 'ok artık yeter') return true;
    if (stripped == 'ok artik yeter') return true;
    if (stripped == 'peki yeter') return true;
    if (stripped == 'peki artık yeter') return true;
    if (stripped == 'peki artik yeter') return true;
    return false;
  }

  /// Natural Turkish closes that end *this* Nocta conversation (not third-party talk).
  static bool _matchesNaturalTrClose(String n) {
    final stripped = _stripTrailingPunct(n);

    // "yeter bu kadar konuşmak" / "bu kadar konuşmak yeter" (ASCII-folded).
    if (n.contains('bu kadar konusmak')) {
      if (RegExp(r'\byeter\b').hasMatch(n)) return true;
    }

    // Whole close: "bu kadar yeter" (uyku case already excluded).
    if (stripped == 'bu kadar yeter') return true;

    // "yeter artık dinlemek istiyorum"
    if (RegExp(r'\byeter\b').hasMatch(n) &&
        n.contains('dinlemek istiyorum')) {
      return true;
    }

    // End-the-talk together (this night).
    if (n.contains('konusmayi bitirelim')) return true;
    if (stripped == 'burada bitirelim') return true;
    if (RegExp(r'^burada bitirelim\b').hasMatch(stripped)) return true;

    // First-person stop-talking to continue into rest — not relationship drama.
    // Bare "konusmak istemiyorum" closes unless a third-person / topic diversion.
    if (n.contains('konusmak istemiyorum')) {
      if (_isOtherPersonOrTopicDiversion(n)) return false;
      return true;
    }

    return false;
  }

  /// Reject relationship / topic-switch uses of "konuşmak istemiyorum".
  static bool _isOtherPersonOrTopicDiversion(String n) {
    // Talking about someone else, not ending Nocta.
    if (RegExp(r'\bonunla\b').hasMatch(n)) return true;
    if (RegExp(r'\bonlarla\b').hasMatch(n)) return true;
    if (n.contains('sevgilim')) return true;
    if (n.contains('esim')) return true;
    if (n.contains('arkadasim')) return true;
    if (n.contains('annem')) return true;
    if (n.contains('babam')) return true;
    // Topic refusal while continuing the chat.
    if (n.contains('hakkinda')) return true;
    if (n.contains('ama başka')) return true;
    if (n.contains('ama baska')) return true;
    return false;
  }
}
