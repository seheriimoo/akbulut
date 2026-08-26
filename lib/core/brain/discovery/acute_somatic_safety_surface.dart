import '../surface_text_fuzzy.dart';

/// User-facing safety surface for acute somatic caution.
///
/// Discovery must not continue as sleep-pattern Mirror. This text redirects
/// toward urgent medical help without diagnosing.
class AcuteSomaticSafetySurface {
  const AcuteSomaticSafetySurface._();

  static const en =
      "That sounds like your body is in real distress right now — a racing "
      "heart and short breath. I'm not a medical service, and I shouldn't "
      "keep going as if this were only a nighttime thought pattern. If this "
      "feels sudden, severe, or frightening, please seek urgent medical help "
      "or contact local emergency services. If someone is nearby, tell them "
      "you're not okay.";

  static const tr =
      'Bu, bedeninin gerçek bir sıkıntıda olduğunu düşündürüyor — hızlı kalp '
      've nefes darlığı. Ben tıbbi bir hizmet değilim ve bunu yalnızca bir '
      'uyku düşüncesi gibi sürdürmemeliyim. Ani, şiddetli veya korkutucu '
      'geliyorsa lütfen acil tıbbi yardım al veya yerel acil servise ulaş. '
      'Yanında biri varsa, kendini iyi hissetmediğini söyle.';

  static String forContext({
    required String message,
    String? groundingBlob,
  }) {
    final turkish = SurfaceTextFuzzy.prefersTurkish(message, groundingBlob);
    return turkish ? tr : en;
  }
}
