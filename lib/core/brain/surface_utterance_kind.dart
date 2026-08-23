import 'surface_text_fuzzy.dart';

/// B2.2.1 — Topic-independent surface utterance classification for natural mirror.
///
/// Uses grammatical / functional signals only (volition, loss predicates,
/// uncertainty markers, progressive settling). Not topic keyword routing.
enum SurfaceUtteranceKind {
  /// Closing / social exit — mirror should abstain.
  abstain,

  /// Narrative event or ongoing situation.
  event,

  /// Explicit positive receipt (achievement, celebration, good news).
  positiveEvent,

  /// Named feeling state the user stated about themselves.
  statedFeeling,

  /// Uncertainty retained as uncertainty.
  uncertainty,

  /// Stated want / don't-want.
  desire,

  /// Loss or absence the user named.
  loss,

  /// Wind-down / settling progress.
  settling,

  /// Plain factual report without dominant emotion arc.
  neutralFact,
}

/// Structural reader for [SurfaceUtteranceKind].
class SurfaceUtteranceReader {
  const SurfaceUtteranceReader._();

  static SurfaceUtteranceKind classify(String text) {
    final n = SurfaceTextFuzzy.forClassification(text);
    if (n.trim().length < 3) return SurfaceUtteranceKind.abstain;
    if (isClosingIntent(text)) return SurfaceUtteranceKind.abstain;
    if (isClosingAck(text)) return SurfaceUtteranceKind.abstain;
    if (_hasSettlingProgress(n)) return SurfaceUtteranceKind.settling;
    if (_hasLossStatement(n)) return SurfaceUtteranceKind.loss;
    if (_hasPositiveEventSurface(n)) return SurfaceUtteranceKind.positiveEvent;
    if (_hasUncertaintyDominant(n)) return SurfaceUtteranceKind.uncertainty;
    if (_hasDesireVolition(n)) return SurfaceUtteranceKind.desire;
    if (_hasStatedFeeling(n)) return SurfaceUtteranceKind.statedFeeling;
    if (_hasExperientialSurface(n)) return SurfaceUtteranceKind.statedFeeling;
    if (_isNeutralFactSurface(n)) return SurfaceUtteranceKind.neutralFact;
    return SurfaceUtteranceKind.event;
  }

  /// User reports felt/experiential surface (how something lands), not a topic label.
  static bool _hasExperientialSurface(String n) {
    return RegExp(r'\b(geliyor|hissed\w*|oluyor|duruyor|oturuyor)\b').hasMatch(n);
  }

  /// Social closing — no substantive mirror needed.
  static bool isClosingIntent(String text) {
    final n = _normalize(text).replaceAll(RegExp(r'[.!?…]+$'), '').trim();
    if (RegExp(r'^(iyi geceler|gorusuruz|görüşürüz|hosca|hoşça|bb|bye)\b').hasMatch(n)) {
      return true;
    }
    if (RegExp(r'^iyi geceler dene$').hasMatch(n)) return true;
    return false;
  }

  /// Short ack that affirms a prior substantive turn (mirror via grounding).
  static bool isAffirmationAck(String text) {
    final n = _normalize(text).replaceAll(RegExp(r'[.!?…]+$'), '').trim();
    if (RegExp(r'\b(tam olarak bu|aynen|haklisin|dogru)\b').hasMatch(n)) {
      return true;
    }
    if (n == 'evet') return true;
    return RegExp(
      r'^evet[\s,.-]+(tam|aynen|oyle|boyle|olarak bu|tam olarak bu)',
    ).hasMatch(n);
  }

  /// Short ack that closes or settles — prefer landing, not mirror.
  static bool isClosingAck(String text) {
    final n = _normalize(text).replaceAll(RegExp(r'[.!?…]+$'), '').trim();
    return RegExp(r'^(tamam|peki|ok|okay|tesekkur|teşekkür)$').hasMatch(n);
  }

  /// Minimal surface ack — mirror abstains unless grounding supplies substance.
  static bool isMinimalAck(String text) {
    final n = _normalize(text).replaceAll(RegExp(r'[.!?…]+$'), '').trim();
    if (n.length <= 2) return true;
    const acks = {
      'evet',
      'hayir',
      'tamam',
      'ok',
      'okay',
      'peki',
      'bilmiyorum',
      'bilemiyorum',
      'kesin degil',
      'dogru',
      'aynen',
      'haklisin',
      'yes',
      'no',
      'tam olarak bu',
      'evet tam olarak bu',
    };
    if (acks.contains(n)) return true;
    if (RegExp(
      r'^(evet|tamam|peki|hayir|dogru|aynen|haklisin)([\s,.-]+(tam|aynen|oyle|boyle|olarak bu|tam olarak bu))*$',
    ).hasMatch(n)) {
      return true;
    }
    return false;
  }

  static bool _hasSettlingProgress(String n) {
    return RegExp(
      r'\b(sakinles\w*|rahatlad\w*|iyiles\w*|daha iyi his\w*)\b',
    ).hasMatch(n);
  }

  static bool _hasLossStatement(String n) {
    return RegExp(
      r'\b(kaybettim|kaybettik|kayip|kayıp|kayboldu|vefat|oldu|gitmis|gitmiş|yok artik|yok artık)\b',
    ).hasMatch(n);
  }

  static bool _hasPositiveEventSurface(String n) {
    final hasExclaim = n.contains('!');
    final hasAchievementVerb = RegExp(
      r'\b\w*(aldim|aldım|kazandim|kazandım|kutlad\w*|terfi|promosyon)\b',
    ).hasMatch(n);
    final hasPositiveEval = RegExp(
      r'\b(guzel|güzel|harika|heyecan verici|mutlu|kutlad\w*|sevindim)\b',
    ).hasMatch(n);
    final distressHeavy = RegExp(
      r'\b(korkuyorum|panik|felaket|berbat|dayanam|intihar|olurum)\b',
    ).hasMatch(n);
    if (distressHeavy) return false;
    return (hasExclaim && hasAchievementVerb) ||
        (hasPositiveEval && !RegExp(r'\b(kirgin|kırgın|korku|uzgun|üzgün)\b').hasMatch(n));
  }

  static bool _hasUncertaintyDominant(String n) {
    if (_hasBelkiMinimalUncertainty(n)) return true;

    final uncertainty = RegExp(
      r'\b(bilmiyorum|bilemiyorum|emin degil|emin değil|net degil|net değil|kararsiz|kararsız|kesin degil|kesin değil)\b',
    ).hasMatch(n);
    if (!uncertainty) {
      if (RegExp(r'\bbilmiy\w*\b|\bbilemiy\w*\b').hasMatch(n)) return true;
      return false;
    }
    return !RegExp(r'\b(kirgin|kırgın|korkuyorum|panik)\b').hasMatch(n) ||
        RegExp(r'\bhakli miyim|doğru mu|dogru mu').hasMatch(n);
  }

  /// Belki-led minimal / absence surface — retain as uncertainty, not event mirror.
  static bool _hasBelkiMinimalUncertainty(String n) {
    if (!RegExp(r'\bbelki\b').hasMatch(n)) return false;
    if (RegExp(r'\b(hicbir|hic\b|bir sey|birsey)\b').hasMatch(n)) return true;
    final withoutBelki = n.replaceFirst(RegExp(r'\bbelki\b\s*'), '').trim();
    return withoutBelki.length <= 12;
  }

  static bool _hasDesireVolition(String n) {
    return RegExp(r'\b(istiyorum|istemiyorum|isterdim|istiyor|istemiyor)\b')
            .hasMatch(n) ||
        RegExp(r'\bgecelim\b|\bgeçelim\b').hasMatch(n);
  }

  static bool _hasStatedFeeling(String n) {
    return RegExp(
      r'\b(kirgin\w*(im|ım|um|üm|yim|yım)|kırgın\w*(im|ım|um|üm|yim|yım)|'
      r'yorgun\w*(im|ım|um|üm)|gergin\w*(im|ım|um|üm)|'
      r'uzgun\w*(im|ım|um|üm)|üzgün\w*(im|ım|um|üm)|'
      r'mutsuz\w*(im|ım|um|üm)|huzursuz\w*(im|ım|um|üm)|'
      r'yalniz\w*(im|ım|um|üm)|yalnız\w*(im|ım|um|üm)|'
      r'korkuyor\w*(um|üm))\b',
    ).hasMatch(n);
  }

  static bool _isNeutralFactSurface(String n) {
    if (RegExp(r'\beskiden\b').hasMatch(n) &&
        RegExp(r'\b(severdi|seviyordu)\b').hasMatch(n)) {
      return true;
    }
    if (RegExp(r'\bkaynattim\b|\bkaynat\w*').hasMatch(n)) return true;
    if (n.length <= 22 && RegExp(r'\bsoguk\b|\bsoğuk\b').hasMatch(n)) {
      return true;
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
}
