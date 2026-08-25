import 'conversation_utterance.dart';
import 'grounded_progression.dart';
import 'thinking_function_hypothesis.dart';
import 'thinking_function_intelligence_shaping.dart';
import 'thinking_function_kind.dart';

/// Deterministic Narrow fork fallback when Guard rejects LLM output (Slice 2).
///
/// Phase 2+/final: when a supported ThinkingFunction is present, emit a soft
/// mechanism fork (mind-job A vs B) instead of collapsing to thin still-here.
class NarrowFallbackBuilder {
  const NarrowFallbackBuilder._();

  static ConversationUtterance? forValidation({
    required String? userUtterance,
    String? priorUserUtterance,
    bool refinementAfterPartial = false,
    String? groundingBlob,
    ThinkingFunctionHypothesis? thinkingFunctionHypothesis,
  }) {
    if (userUtterance == null || userUtterance.trim().isEmpty) {
      return null;
    }
    if (refinementAfterPartial) {
      final text = GroundedNarrowContract.refinementQuestion(
        userUtterance: userUtterance,
        priorUserUtterance: priorUserUtterance,
        groundingBlob: groundingBlob,
      );
      if (text != null) return ConversationUtterance(text: text);
    }

    final turkish = _looksTurkish(userUtterance) ||
        _looksTurkish(groundingBlob ?? '') ||
        _looksTurkish(priorUserUtterance ?? '');

    if (ThinkingFunctionIntelligenceShaping.isSupportedOrStrong(
          thinkingFunctionHypothesis,
        ) &&
        !refinementAfterPartial) {
      final mechanism = _mechanismFork(
        hypothesis: thinkingFunctionHypothesis!,
        turkish: turkish,
        user: userUtterance,
        groundingBlob: groundingBlob,
      );
      if (mechanism != null) return ConversationUtterance(text: mechanism);
    }

    final text = turkish
        ? _turkishFork(userUtterance, priorUserUtterance, groundingBlob)
        : _englishFork(userUtterance, priorUserUtterance);
    if (text == null || text.isEmpty) return null;
    return ConversationUtterance(text: text);
  }

  /// Soft mind-job forks — original TYPE templates, not GOLD dialogue paste.
  static String? _mechanismFork({
    required ThinkingFunctionHypothesis hypothesis,
    required bool turkish,
    required String user,
    String? groundingBlob,
  }) {
    final ctx = _normalize('$user ${groundingBlob ?? ''}');
    switch (hypothesis.kind) {
      case ThinkingFunctionKind.worstCaseRehearsal:
        if (turkish) {
          if (_containsAny(ctx, ['utanc', 'prova', 'rezil'])) {
            return 'Aklın utancı prova mı ediyor, yoksa belirsizlikte bir netlik mi arıyor?';
          }
          return 'Aklın kötü sonuçları tekrar mı kuruyor, yoksa belirsizlikte kesin bir cevap mı arıyor?';
        }
        if (_containsAny(ctx, ['embarrass', 'humiliat', 'social'])) {
          return 'Is your mind rehearsing embarrassment, or hunting for certainty in the unknown?';
        }
        return 'Is your mind rehearsing bad endings, or hunting for certainty in the unknown?';
      case ThinkingFunctionKind.earlyTomorrowCarry:
        return turkish
            ? 'Yarını bu geceye mi taşıyorsun, yoksa genel bir gece huzursuzluğu mu?'
            : 'Is tomorrow already landing in tonight, or is it more general night activation?';
      case ThinkingFunctionKind.preparationRehearsal:
        return turkish
            ? 'Hazırlıklı kalma baskısı mı daha ağır, yoksa açık bir belirsizlik mi?'
            : 'Is it readiness pressure, or open uncertainty without a prep job?';
      case ThinkingFunctionKind.certaintyChase:
        return turkish
            ? 'Bir düşünce daha ile netleşeceğini mi umuyorsun, yoksa oturmuş bir endişe mi duruyor?'
            : 'Is it chasing one more thought for certainty, or a settled worry without more figuring?';
      case ThinkingFunctionKind.protectiveHolding:
        return turkish
            ? 'Tutmaya devam etmek mi daha güvenli geliyor, yoksa düşünceler kendi kendine mi sürüyor?'
            : 'Does keeping hold feel safer than stopping, or are the thoughts just continuing on their own?';
    }
  }

  static String? _turkishFork(
    String user,
    String? prior,
    String? groundingBlob,
  ) {
    final n = user.toLowerCase();
    final ctx = _normalize('${groundingBlob ?? ''} ${prior ?? ''} $user');
    if (_containsAny(ctx, ['yalniz', 'yalnız', 'yalnizim', 'sessiz', 'ev cok'])) {
      return 'Birinin burada olmasını mı özlüyorsun, yoksa bu sessizlikte kendi düşüncelerinle kalmak mı zor geliyor?';
    }
    if (_containsAny(ctx, ['icime oturdu', 'içime oturdu', 'bilmiyorum', 'belirsiz'])) {
      return 'Daha çok olacak bir şeyle mi ilgili geliyor, yoksa olmuş bir şey hâlâ sende kalmış gibi mi?';
    }
    if (_containsAny(ctx, ['yarin', 'yarın', 'mudur', 'müdür', 'toplanti', 'toplantı', 'sunum'])) {
      return 'Konuşmanın kendisi mi geriyor seni, yoksa onun vereceği tepki mi?';
    }
    if (_containsAny(ctx, ['ozle', 'özle', 'onu', 'sevgili', 'partner'])) {
      return 'Onu mu özlüyorsun, yoksa onunlayken nasıl hissettiğini mi?';
    }
    if (_containsAny(ctx, ['is ', 'iş ', 'deadline', 'yetis', 'yetiş', 'beynim', 'kafam'])) {
      return 'Yetiştiremeyeceğin bir şey mi var, yoksa yarın yine aynı baskının içine dönecek olmak mı?';
    }
    if (_containsAny(n, ['evet', 'aynen', 'tamam'])) {
      if (_containsAny(ctx, ['uyuyam', 'gece', 'kafa', 'aklim', 'aklım'])) {
        return 'Bu gece seni daha çok olayın kendisi mi tutuyor, yoksa sonucu mu?';
      }
    }
    if (_containsAny(ctx, ['kavga', 'mesaj', 'yazsam'])) {
      return 'Ona yazmak mı aklında, yoksa o mesajın içeriği mi?';
    }
    return 'Bu gece seni daha çok ne tarafı tutuyor — olayın kendisi mi, yoksa sonucu mu?';
  }

  static String? _englishFork(String user, String? prior) {
    final ctx = '${prior ?? ''} $user'.toLowerCase();
    if (ctx.contains('tomorrow') &&
        _containsAny(ctx, ['meeting', 'boss', 'presentation'])) {
      return 'Is it the conversation itself, or how they might react?';
    }
    if (_containsAny(ctx, ['miss', 'lonely', 'partner'])) {
      return 'Do you miss them, or how you felt when you were together?';
    }
    return 'Is it the situation itself, or what might happen next?';
  }

  static String _normalize(String s) {
    return s
        .toLowerCase()
        .replaceAll('ö', 'o')
        .replaceAll('ü', 'u')
        .replaceAll('ı', 'i')
        .replaceAll('ğ', 'g')
        .replaceAll('ş', 's')
        .replaceAll('ç', 'c');
  }

  static bool _looksTurkish(String text) {
    final lower = text.toLowerCase();
    if (lower.trim().isEmpty) return false;
    if (RegExp(r'[ğüşıöçâîû]').hasMatch(lower)) return true;
    return _containsAny(lower, [
      'yarin',
      'yarın',
      'uyuyam',
      'kafam',
      'evet',
      'mudur',
      'müdür',
      'yalniz',
      'belki',
      'aklim',
      'aklım',
    ]);
  }

  static bool _containsAny(String n, List<String> markers) {
    for (final marker in markers) {
      if (n.contains(marker)) return true;
    }
    return false;
  }
}
