/// B2.2.1 — Safe surface acknowledgement contract for source-grounded mirrors.
///
/// Admits natural paraphrase mirrors that stay tied to the user's stated
/// surface without therapy/reframe inference. Not a template bank.
class SurfaceMirrorContract {
  const SurfaceMirrorContract._();

  static const String version = '1.1';

  static const List<String> _ackFrames = [
    'söylüyorsun',
    'soyluyorsun',
    'istiyorsun',
    'istemiyorsun',
    'istediğini',
    'istedigini',
    'başlamışsın',
    'baslamissin',
    'basliyorsun',
    'başlıyorsun',
    'geliyor',
    'oturuyorsun',
    'kaynatmışsın',
    'kaynatmissin',
    'paylaştın',
    'paylastin',
    'anlaşılır',
    'geliyorsun',
    'geliyor',
    'anlasilir',
    'emin degilsin',
    'emin değilsin',
    'hissediyorsun',
    'duymak istiyorsun',
    'hear you',
    'you want',
    'you said',
    'you seem',
    'still with you',
    'still there tonight',
    'what you named',
  ];

  static const List<String> _inferenceDrift = [
    'belki',
    'sanki',
    'aslında',
    'aslinda',
    'perhaps',
    'maybe',
    'therapy',
    'therapist',
    'clinical',
    'diagnos',
    'root cause',
    'deep down',
    'this means',
    'that means you',
    'because you',
    'unconscious',
    'attachment style',
  ];

  static const List<String> _distressStems = [
    'zor geliyor',
    'agir geliyor',
    'ağır geliyor',
    'distress',
    'panik',
    'felaket',
  ];

  /// Returns true when [candidate] is a grounded surface acknowledgement of
  /// [userUtterance] with no semantic invention.
  ///
  /// When the user's turn is a minimal affirmation, [groundingUtterance] may
  /// supply the substantive source line for overlap checks.
  static bool matches(
    String candidate,
    String userUtterance, {
    String? groundingUtterance,
  }) {
    final lower = _normalize(candidate);
    final user = _normalize(userUtterance);
    if (lower.trim().length < 8) return false;
    if (user.trim().isEmpty) return false;
    if (_containsAny(lower, _inferenceDrift)) return false;
    if (!hasAcknowledgmentFrame(lower)) return false;
    if (hasSourceGrounding(lower, user)) {
      if (!preservesValence(lower, user)) return false;
      return true;
    }
    if (groundingUtterance != null &&
        groundingUtterance.trim().isNotEmpty &&
        hasSourceGrounding(lower, _normalize(groundingUtterance))) {
      if (!preservesValence(lower, '$user $groundingUtterance')) return false;
      return true;
    }
    return false;
  }

  static bool hasAcknowledgmentFrame(String lower) {
    if (lower.endsWith(' gibi.') ||
        lower.endsWith(' gibi') ||
        lower.contains(' gibi.')) {
      return true;
    }
    return _containsAny(lower, _ackFrames);
  }

  static bool hasSourceGrounding(String candidate, String user) {
    final userTokens = _contentTokens(user);
    if (userTokens.isEmpty) return false;
    final candidateTokens = _contentTokens(candidate);
    for (final token in userTokens) {
      for (final other in candidateTokens) {
        if (_tokensOverlap(token, other)) return true;
      }
    }
    return false;
  }

  static bool preservesValence(String candidate, String user) {
    if (!_hasPositiveSurface(user)) return true;
    if (_hasDistress(user)) return true;
    return !_containsAny(candidate, _distressStems);
  }

  static bool _hasPositiveSurface(String user) {
    return RegExp(
      r'\b(guzel|güzel|harika|heyecan|mutlu|kutlad|terfi|aldim|aldım|kazand|sevind)\b',
    ).hasMatch(user);
  }

  static bool _hasDistress(String user) {
    return RegExp(
      r'\b(kirgin|kırgın|korku|uzgun|üzgün|panik|berbat|zor|agir|ağır)\b',
    ).hasMatch(user);
  }

  static List<String> _contentTokens(String text) {
    final tokens = <String>[];
    for (final raw in text.split(RegExp(r'\s+'))) {
      final n = _normalize(raw.replaceAll(RegExp(r'[^\w\s]'), ''));
      if (n.length < 4) continue;
      if (_stopwords.contains(n)) continue;
      tokens.add(n);
    }
    return tokens;
  }

  static bool _tokensOverlap(String a, String b) {
    if (a == b) return true;
    if (a.length >= 4 && b.length >= 4) {
      final len = a.length < b.length ? a.length : b.length;
      final prefix = len >= 6 ? 6 : 4;
      return a.substring(0, prefix) == b.substring(0, prefix);
    }
    return false;
  }

  static bool _containsAny(String haystack, List<String> needles) {
    for (final needle in needles) {
      if (haystack.contains(_normalize(needle))) return true;
    }
    return false;
  }

  static String _normalize(String s) {
    return s
        .toLowerCase()
        .replaceAll('’', "'")
        .replaceAll('ö', 'o')
        .replaceAll('ü', 'u')
        .replaceAll('ı', 'i')
        .replaceAll('ğ', 'g')
        .replaceAll('ş', 's')
        .replaceAll('ç', 'c')
        .replaceAll('â', 'a')
        .replaceAll('î', 'i')
        .replaceAll('û', 'u');
  }

  static const Set<String> _stopwords = {
    'bir',
    'bu',
    've',
    'de',
    'da',
    'ki',
    'mi',
    'mu',
    'mü',
    'mı',
    'the',
    'and',
    'ben',
    'sen',
    'cok',
    'icin',
    'ile',
    'ya',
    'hala',
    'hâlâ',
    'gibi',
    'ama',
    'olan',
    'olarak',
    'tam',
    'evet',
  };
}

/// B2.2 — Brief conversational landings when mirror abstains.
///
/// Closed list only — not a general Guard loosen.
/// Bare okay/tamam landings are additionally gated by [UtteranceGuard] against
/// substantive user turns.
class ConversationalLandingContract {
  const ConversationalLandingContract._();

  static const List<String> _allowed = [
    'tamam.',
    'tamam',
    'iyi geceler.',
    'iyi geceler',
    'good night.',
    'good night',
    'okay.',
    'okay',
  ];

  static bool matches(String lower) {
    final trimmed = lower.trim();
    return _allowed.contains(trimmed);
  }
}
