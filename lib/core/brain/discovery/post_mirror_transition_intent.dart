/// Post–Sleep Mind Mirror conversational intent (state-machine input).
///
/// Classifies user moves after a grounded Mirror has been surfaced.
/// Not a Discovery redesign and not a single-phrase bug patch.
enum PostMirrorTransitionIntent {
  /// Accept / continue / action → [TRANSITION_READY] → Nocta Transition.
  advanceTransition,

  /// Reject Mirror, correct it, or introduce materially new topic → reopen.
  reopenDiscovery,

  /// No clear advance or reopen — soft hold; never Narrow refine.
  softHold,
}

/// Deterministic post-Mirror intent classifier.
class PostMirrorTransitionIntentClassifier {
  const PostMirrorTransitionIntentClassifier();

  PostMirrorTransitionIntent classify(
    String message, {
    bool materialNewTopic = false,
  }) {
    final n = _normalize(message);
    if (n.isEmpty) return PostMirrorTransitionIntent.softHold;

    if (materialNewTopic) {
      return PostMirrorTransitionIntent.reopenDiscovery;
    }
    if (_isMirrorRejectOrCorrection(n)) {
      return PostMirrorTransitionIntent.reopenDiscovery;
    }
    if (_isAdvanceTransition(n)) {
      return PostMirrorTransitionIntent.advanceTransition;
    }
    return PostMirrorTransitionIntent.softHold;
  }

  /// Continuation / action / readiness after Mirror.
  ///
  /// Category-based (what-now, continue, ready, sleep/audio handoff, soft accept)
  /// — not a one-off regex for a single device phrase.
  bool _isAdvanceTransition(String n) {
    final stripped = _stripTrailingPunct(n);

    // Soft accept / proceed.
    if (stripped == 'tamam' ||
        stripped == 'ok' ||
        stripped == 'okay' ||
        stripped == 'peki' ||
        stripped == 'evet' ||
        stripped == 'aynen') {
      return true;
    }

    // What-now / next-step (TR + EN).
    if (n.contains('simdi ne yapacag') ||
        n.contains('simdi ne olacak') ||
        n.contains('ne yapacagim') ||
        n.contains('ne yapalim') ||
        n.contains('what now') ||
        n.contains('what do i do') ||
        n.contains('what should i do') ||
        n.contains('what happens now') ||
        n.contains('what next')) {
      return true;
    }

    // Continue / ready.
    if (n.contains('devam edelim') ||
        n.contains('devam et') ||
        n.contains('hazirim') ||
        n.contains('haziriz') ||
        n.contains("i'm ready") ||
        n.contains('i am ready') ||
        n.contains('lets continue') ||
        n.contains("let's continue") ||
        n.contains('continue')) {
      return true;
    }

    // Sleep / audio handoff (also covered by ExplicitExitIntent for "sese geç").
    if (n.contains('beni uyut') ||
        n.contains('sese gec') ||
        n.contains('sese geç') ||
        n.contains('move to audio') ||
        n.contains('ready for the audio') ||
        n.contains('take me to the audio') ||
        n.contains('put me to sleep')) {
      return true;
    }

    return false;
  }

  bool _isMirrorRejectOrCorrection(String n) {
    if (n.contains('yanlis anlad') ||
        n.contains('yanlis bu') ||
        n.contains('bu degil') ||
        n.contains('      oyle degil') ||
        n.contains('alakasi yok') ||
        n.contains('demedim') ||
        n.contains('beni anlam') ||
        n.contains('ayna yanlis') ||
        n.contains('dogru degil') ||
        n.contains('not what i') ||
        n.contains('you misunderstood') ||
        n.contains("that's not") ||
        n.contains('thats not') ||
        n.contains('wrong mirror') ||
        n.contains('not it')) {
      return true;
    }
    return false;
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
}
