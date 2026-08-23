/// B2.2.1 — Fuzzy surface normalization for OOD slang / typo / short text.
///
/// Structural stem repair only — not topic keyword routing.
class SurfaceTextFuzzy {
  const SurfaceTextFuzzy._();

  /// Normalize user text before [SurfaceUtteranceReader] classification.
  static String forClassification(String text) {
    var n = _baseNormalize(text);
    n = _repairUncertaintyStems(n);
    n = _repairCommonVerbTypos(n);
    return n;
  }

  static String _repairUncertaintyStems(String n) {
    var out = n;
    out = out.replaceAllMapped(
      RegExp(r'\bbilmiy\w*\b'),
      (_) => 'bilmiyorum',
    );
    out = out.replaceAllMapped(
      RegExp(r'\bbilemiy\w*\b'),
      (_) => 'bilemiyorum',
    );
    out = out.replaceAllMapped(
      RegExp(r'\bbilmiyom\b'),
      (_) => 'bilmiyorum',
    );
    return out;
  }

  static String _repairCommonVerbTypos(String n) {
    return n
        .replaceAll(RegExp(r'\bolcak\b'), 'olacak')
        .replaceAll(RegExp(r'\bbişi\b'), 'bişi')
        .replaceAll(RegExp(r'\bbisi\b'), 'bişi');
  }

  /// Structural TR locale signal for typo/slang OOD — not topic routing.
  static bool prefersTurkish(String? userUtterance, [String? groundingBlob]) {
    final blob = '${userUtterance ?? ''} ${groundingBlob ?? ''}'.trim();
    if (blob.isEmpty) return false;

    final lower = blob.toLowerCase();
    if (RegExp(r'[ğüşıöçâîû]').hasMatch(lower)) return true;

    final n = forClassification(blob);
    if (RegExp(r'\bbilmiyorum\b|\bbilemiyorum\b').hasMatch(n)) return true;

    if (RegExp(r'\b(miyim|mıyım|musun|misin|iyor|uyor|degil|değil)\b')
        .hasMatch(lower)) {
      return true;
    }

    if (RegExp(r'\bbilmiy\w*\b|\bbilemiy\w*\b').hasMatch(lower)) return true;

    if (RegExp(
      r'\b(dim|dım|dum|düm|tim|tım|tum|tüm|iyor|uyor|erek|'
      r'edecek|misin|mısın|musun|miyim|mıyım)\b',
    ).hasMatch(lower)) {
      return true;
    }

    const markers = [
      'belki',
      'yorgun',
      'uyuyam',
      'kafam',
      'aklim',
      'aklım',
      'durmuyor',
      'gece',
      'yarin',
      'yarın',
      'evet',
      'tamam',
      'degil',
      'değil',
      'yalniz',
      'yalnız',
      'miyim',
      'mıyım',
      'yok',
      'bilmem',
      'işte',
      'iste',
      'beklemek',
      'sadece',
      'zor',
      'endişe',
      'endise',
      'istemiyorum',
      'yine',
      'ertele',
      'lazim',
      'lazım',
      'kelime',
      'kork',
      'yazm',
      'garip',
      'hissed',
      'acikla',
      'uzgun',
      'sinir',
      'beden',
      'agir',
      'ağır',
      'boyle',
      'böyle',
      'bisi',
      'bişi',
    ];
    for (final marker in markers) {
      if (lower.contains(marker)) return true;
    }
    return false;
  }

  static String _baseNormalize(String s) {
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
}
