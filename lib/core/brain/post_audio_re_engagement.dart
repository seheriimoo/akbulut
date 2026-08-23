/// Deterministic detector for meaningful conversation re-engagement after audio.
///
/// Presentation/policy input only. Does not own readiness, speech, or exit.
/// Distinguishes new substantive turns from closing acknowledgements.
///
/// Priority: explicit re-engagement → explicit closing intent → conservative
/// substantive fallback. Bare "tamam" inside a message is not closing by itself.
class PostAudioReEngagement {
  const PostAudioReEngagement();

  /// True when the user starts a new meaningful turn after terminal audio.
  bool isMeaningful(String message) {
    final normalized = _normalize(message);
    if (normalized.isEmpty) return false;
    if (_isEmojiOnly(normalized)) return false;
    if (_matchesExplicitReEngagement(normalized)) return true;
    if (_isClosingAcknowledgement(normalized)) return false;
    if (_matchesClosingIntent(normalized)) return false;
    return _hasSubstantiveContent(normalized);
  }

  static String _normalize(String message) {
    var s = message.trim().toLowerCase();
    s = s.replaceAll('\u2019', "'");
    s = s.replaceAll(RegExp(r'\s+'), ' ');
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

  static String _stripTrailingPunct(String n) {
    return n.replaceAll(RegExp(r'[.!?…,;:]+$'), '').trim();
  }

  static bool _isEmojiOnly(String n) {
    final stripped = n.replaceAll(
      RegExp(
        r'[\u{1F300}-\u{1FAFF}\u{2600}-\u{27BF}\u{FE0F}\u{200D}\s]+',
        unicode: true,
      ),
      '',
    );
    return stripped.isEmpty;
  }

  /// Whole-utterance bare closes.
  static bool _isClosingAcknowledgement(String n) {
    final stripped = _stripTrailingPunct(n);
    if (stripped == 'tamam' ||
        stripped == 'tmm' ||
        stripped == 'ok' ||
        stripped == 'okey' ||
        stripped == 'peki' ||
        stripped == 'okay' ||
        stripped == 'thanks' ||
        stripped == 'thank you' ||
        stripped == 'tesekkurler' ||
        stripped == 'tesekkur ederim' ||
        stripped == 'sagol' ||
        stripped == 'iyi geceler' ||
        stripped == 'good night' ||
        stripped == 'gn' ||
        stripped == 'night') {
      return true;
    }
    if (RegExp(r'^👍+$').hasMatch(n.trim())) return true;
    return false;
  }

  static bool _matchesExplicitReEngagement(String n) {
    // Fear / activation
    if (n.contains('korkuyorum')) return true;
    if (n.contains('korkmaktan')) return true;
    if (RegExp(r'\bkorku\b').hasMatch(n)) return true;
    if (n.contains('scared') || n.contains('afraid')) return true;

    // Weight / heaviness
    if (n.contains('agir geliyor')) return true;
    if (n.contains('cok agir')) return true;
    if (n.contains('so heavy') || n.contains('feels heavy')) return true;

    // Continued thinking
    if (n.contains('hala dusunuyorum')) return true;
    if (n.contains('still thinking')) return true;
    if (n.contains('cant stop thinking')) return true;

    // Confusion / checking in after silence
    if (RegExp(r'\bnoldu\b').hasMatch(n)) return true;
    if (n.contains('noldu simdi')) return true;
    if (n.contains('ne oldu simdi')) return true;
    if (n.contains('ne oldu')) return true;
    if (n.contains('what happened')) return true;
    if (n.contains('are you there')) return true;
    if (n.contains('hala orada misin')) return true;
    if (n.contains('neden sessizsin')) return true;
    if (n.contains('neden suskun')) return true;
    if (n.contains('why are you silent')) return true;
    if (n.contains('why so quiet')) return true;

    // Why-feel check-ins (short but meaningful)
    if (RegExp(r'\bneden\b').hasMatch(n) &&
        (n.contains('hissed') ||
            n.contains('feel') ||
            n.contains('boyle') ||
            n.contains('böyle'))) {
      return true;
    }

    // New content / unfinished night
    if (n.contains('aslinda bir sey daha')) return true;
    if (n.contains('actually one more thing')) return true;
    if (n.contains('one more thing')) return true;
    if (n.contains('bir sey daha var')) return true;

    // Sleep failure — re-engage, not close
    if (n.contains('uyuyamadim')) return true;
    if (n.contains('uyuyamiyorum')) return true;
    if (n.contains("couldn't sleep") || n.contains('cant sleep')) return true;

    // Hold / wait — user wants talk, not audio
    if (_stripTrailingPunct(n) == 'bekle') return true;
    if (_stripTrailingPunct(n) == 'wait') return true;
    if (RegExp(r'^bekle\b').hasMatch(n)) return true;
    if (RegExp(r'^wait\b').hasMatch(n)) return true;

    return false;
  }

  /// Multi-word night-close / defer-talk intent (not bare tamam alone).
  static bool _matchesClosingIntent(String n) {
    final stripped = _stripTrailingPunct(n);

    // Good night family
    if (n.contains('iyi geceler')) return true;
    if (n.contains('good night')) return true;

    // Going to sleep / bed tonight (not failure-to-sleep — checked above)
    if (n.contains('yatiyorum')) return true;
    if (n.contains('uyumaya calis')) return true;
    if (n.contains('uyuyorum artik')) return true;
    if (n.contains('going to bed')) return true;
    if (n.contains('going to sleep')) return true;
    if (n.contains('try to sleep') || n.contains('trying to sleep')) return true;

    // Defer conversation to later
    if (n.contains('sonra konusuruz')) return true;
    if (n.contains('yarin konusuruz')) return true;
    if (n.contains('talk later')) return true;
    if (n.contains('talk tomorrow')) return true;
    if (n.contains('speak tomorrow')) return true;

    // Gratitude / wrap-up close
    if (n.contains('thanks for tonight')) return true;
    if (n.contains('thank you for tonight')) return true;
    if (RegExp(r'tesekkur').hasMatch(n)) return true;

    // Ack-only wrap chains (tamam alone inside is not enough elsewhere)
    if (RegExp(
      r'^(oh )?(hadi )?(peki|tamam|tamamdir|okey|ok)( (peki|tamam|tamamdir|okey|ok))*( (o zaman|then|artik|hadi))*$',
    ).hasMatch(stripped)) {
      return true;
    }
    if (stripped == 'tamam yeter artik') return true;

    // See-you closes
    if (n.contains('gorusuruz')) return true;
    if (n.contains('see you')) return true;

    return false;
  }

  /// Conservative fallback: substantive turn with load/check-in texture.
  static bool _hasSubstantiveContent(String n) {
    final stripped = _stripTrailingPunct(n);
    if (stripped.isEmpty) return false;
    final words = stripped.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
    if (words.length >= 4) return true;
    if (words.length == 3 && _hasLoadOrCheckInStem(stripped)) return true;
    return false;
  }

  static bool _hasLoadOrCheckInStem(String n) {
    const stems = [
      'kork',
      'dusun',
      'agir',
      'neden',
      'niye',
      'why',
      'how',
      'help',
      'yardim',
      'uzul',
      'sad',
      'anx',
      'worr',
      'scared',
      'afraid',
      'hala',
      'still',
      'wait',
      'bekle',
    ];
    for (final stem in stems) {
      if (n.contains(stem)) return true;
    }
    return false;
  }
}
