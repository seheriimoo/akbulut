import 'conversation_utterance.dart';

/// Evidence-shaped Reframe fallback when Guard rejects LLM output (Slice 2).
class ReframeFallbackBuilder {
  const ReframeFallbackBuilder._();

  static ConversationUtterance? forValidation({
    required String? userUtterance,
  }) {
    if (userUtterance == null || userUtterance.trim().isEmpty) {
      return null;
    }
    final turkish = _looksTurkish(userUtterance);
    final text = turkish
        ? _turkishReframe(userUtterance)
        : _englishReframe(userUtterance);
    if (text == null || text.isEmpty) return null;
    return ConversationUtterance(text: text);
  }

  static String? _turkishReframe(String user) {
    final n = _normalize(user);
    if (_containsAny(n, ['tepki', 'yetersiz', 'gorun', 'görün', 'judg'])) {
      return 'O zaman konuşmanın kendisinden çok, onun gözünde nasıl görüneceğin geceyi açık tutuyor olabilir.';
    }
    if (_containsAny(n, ['rezil', 'sahne', 'sunum', 'presentation'])) {
      return 'O zaman sunumdan çok, sahnede nasıl görüneceğin geceyi açık tutuyor olabilir.';
    }
    if (_containsAny(n, ['baski', 'baskı', 'stres', 'endis', 'endiş', 'kayg']) &&
        _containsAny(n, ['yarin', 'yarın', 'sunum', 'toplanti', 'toplantı'])) {
      return 'O zaman yapacakların değil, yarınki baskının tekrar geleceği hissi geceyi açık tutuyor olabilir.';
    }
    if (_containsAny(n, ['guven', 'onunlayken', 'hissed']) &&
        _containsAny(n, ['ozle', 'ozluy', 'onu'])) {
      return 'O zaman onun yanındayken hissettiğin güven, şimdi eksik kalmış gibi duruyor olabilir.';
    }
    if (_containsAny(n, ['yanimda', 'hissetmeyi', 'birinin yan']) &&
        _containsAny(n, ['yalniz', 'sessiz', 'ozle', 'ozl'])) {
      return 'O zaman bu gece eksik gelen şey sadece birinin fiziksel olarak burada olması değil; yanında biri varmış hissi olabilir.';
    }
    if (_containsAny(n, ['anlamiyor', 'anlamıyor', 'kimse'])) {
      return 'O zaman bu gece eksik gelen şey belki de anlaşılmak; yalnız kalmaktan ayrı duruyor olabilir.';
    }
    if (_containsAny(n, ['kirgin', 'ozle', 'ozlem'])) {
      return 'O zaman ikisi ayrı duygular gibi duruyor; özlem bir yanda, kırgınlık bir yanda duruyor olabilir.';
    }
    return null;
  }

  static String? _englishReframe(String user) {
    final n = user.toLowerCase();
    if (_containsAny(n, ['reaction', 'inadequate', 'judged'])) {
      return 'It could be less the talk itself and more how you might look in their eyes tonight.';
    }
    return null;
  }

  static bool _looksTurkish(String text) {
    final lower = text.toLowerCase();
    if (RegExp(r'[ğüşıöçâîû]').hasMatch(lower)) return true;
    return _containsAny(lower, [
      'tepki',
      'yetersiz',
      'korkuyorum',
      'yarin',
      'yarın',
    ]);
  }

  static bool _containsAny(String n, List<String> markers) {
    for (final marker in markers) {
      if (n.contains(marker)) return true;
    }
    return false;
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
}
