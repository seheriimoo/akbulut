/// Deterministic detector for an explicit desire to calm / settle tonight.
///
/// Policy input only. Does not own readiness, speech, exit, or memory.
/// Full-message / clear-intent match — never hijacks ordinary load talk.
class ExplicitCalmIntent {
  const ExplicitCalmIntent();

  /// True when the person clearly asks to calm, settle, or rest — not to
  /// keep exploring what is wrong.
  bool matches(String message) {
    final n = _normalize(message);
    if (n.isEmpty) return false;
    if (_isFalsePositive(n)) return false;
    return _hasExplicitCalmDesire(n);
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

  static bool _isFalsePositive(String n) {
    // "I can't calm down" / "sakinleşemiyorum" is load, not a calm request.
    if (n.contains('cant calm')) return true;
    if (n.contains("can't calm")) return true;
    if (n.contains('cannot calm')) return true;
    if (n.contains('sakinlesemiyorum')) return true;
    if (n.contains('sakinlesemiyom')) return true;
    if (n.contains('rahatlayamiyorum')) return true;
    return false;
  }

  static bool _hasExplicitCalmDesire(String n) {
    // English desire forms.
    if (n.contains('want to calm')) return true;
    if (n.contains('wanna calm')) return true;
    if (n.contains('need to calm')) return true;
    if (n.contains('just want to relax')) return true;
    if (n.contains('want to relax')) return true;
    if (n.contains('need to relax')) return true;
    if (n.contains('want to settle')) return true;
    if (n.contains('just want to rest')) return true;
    if (n.contains('want to rest')) return true;
    if (n.contains('help me calm')) return true;
    if (n.contains('help me settle')) return true;
    if (n.contains('help me relax')) return true;

    // Turkish desire forms (ASCII-folded).
    if (n.contains('sakinlesmek istiyorum')) return true;
    if (n.contains('sakinlesmek isterim')) return true;
    if (n.contains('sakinlesmek istiyom')) return true;
    if (n.contains('rahatlamak istiyorum')) return true;
    if (n.contains('rahatlamak isterim')) return true;
    if (n.contains('rahatlamak istiyom')) return true;
    if (n.contains('biraz sakinlesmek')) return true;
    if (n.contains('sadece sakinlesmek')) return true;
    if (n.contains('sadece rahatlamak')) return true;
    if (n.contains('sakinlesmeme yardim')) return true;
    if (n.contains('rahatlamama yardim')) return true;
    if (n.contains('dinlenmek istiyorum')) return true;
    if (n.contains('dinlenmek isterim')) return true;

    return false;
  }
}
