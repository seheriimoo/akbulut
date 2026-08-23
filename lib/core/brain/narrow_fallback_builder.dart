import 'conversation_utterance.dart';

/// Deterministic Narrow fork fallback when Guard rejects LLM output (Slice 2).
class NarrowFallbackBuilder {
  const NarrowFallbackBuilder._();

  static ConversationUtterance? forValidation({
    required String? userUtterance,
    String? priorUserUtterance,
    bool refinementAfterPartial = false,
    String? groundingBlob,
  }) {
    if (userUtterance == null || userUtterance.trim().isEmpty) {
      return null;
    }
    if (refinementAfterPartial) {
      final text = _turkishRefinement(
        userUtterance,
        priorUserUtterance: priorUserUtterance,
        groundingBlob: groundingBlob,
      );
      if (text != null) return ConversationUtterance(text: text);
    }
    final turkish = _looksTurkish(userUtterance);
    final text = turkish
        ? _turkishFork(userUtterance, priorUserUtterance, groundingBlob)
        : _englishFork(userUtterance, priorUserUtterance);
    if (text == null || text.isEmpty) return null;
    return ConversationUtterance(text: text);
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

  static String? _turkishRefinement(
    String user, {
    String? priorUserUtterance,
    String? groundingBlob,
  }) {
    final n = _normalize(user);
    final ctx = _normalize('${groundingBlob ?? ''} ${priorUserUtterance ?? ''} $user');
    if (_containsAny(n, ['belki']) && _containsAny(n, ['isten', 'işten'])) {
      return 'İşin kendisi mi geliyor aklına, yoksa yarın tekrar o ortama dönecek olmak mı?';
    }
    if (_containsAny(ctx, ['icime oturdu', 'bilmiyorum', 'belirsiz']) &&
        _containsAny(n, ['belki', 'galiba', 'sanirim'])) {
      return 'İşin kendisi mi geliyor aklına, yoksa yarın tekrar o ortama dönecek olmak mı?';
    }
    if (_containsAny(n, ['belki']) && _containsAny(n, ['isten', 'işten'])) {
      return 'İşin kendisi mi geliyor aklına, yoksa yarın tekrar o ortama dönecek olmak mı?';
    }
    if (_containsAny(n, ['baski', 'baskı']) && !_containsAny(n, ['belki', 'isten', 'işten'])) {
      return 'Baskı kısmı doğru gibi. Peki eksik kalan taraf ne?';
    }
    if (_containsAny(n, ['biraz ama', 'tam degil', 'tam değil', 'sadece o'])) {
      return 'Anladım. Peki eksik kalan taraf ne?';
    }
    if (_containsAny(n, ['evet ama', 'dogru ama', 'doğru ama', 'hala', 'hâlâ'])) {
      return 'Tamam. Peki tam oturmayan taraf ne?';
    }
    if (_containsAny(n, ['anlamiyor', 'anlamıyor', 'kimse'])) {
      return 'Anlaşılmadığını hissetmek mi daha ağır, yoksa yalnız kalmak mı?';
    }
    return 'Anladım. Peki eksik kalan taraf ne?';
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
    ]);
  }

  static bool _containsAny(String n, List<String> markers) {
    for (final marker in markers) {
      if (n.contains(marker)) return true;
    }
    return false;
  }
}
