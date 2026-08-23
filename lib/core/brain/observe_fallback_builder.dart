import 'conversation_utterance.dart';
import 'session_locale.dart';

/// User-object aware Observe fallback when Guard rejects LLM output (Slice 2).
///
/// Mirror-only. No reframe, diagnosis, or invented psychology.
class ObserveFallbackBuilder {
  const ObserveFallbackBuilder._();

  static ConversationUtterance? forValidation({
    required String? userUtterance,
    String? groundingBlob,
  }) {
    if (userUtterance == null || userUtterance.trim().isEmpty) {
      return null;
    }
    final turkish =
        SessionLocale.prefersTurkish(userUtterance, groundingBlob);
    final text = turkish
        ? _turkishMirror(userUtterance)
        : _englishMirror(userUtterance);
    if (text == null || text.isEmpty) return null;
    return ConversationUtterance(text: text);
  }

  static String? _turkishMirror(String user) {
    final n = _normalize(user);
    if (_containsAny(n, ['bilmiyorum', 'net degil', 'net değil']) &&
        _containsAny(n, ['hala', 'hâlâ', 'net'])) {
      return 'Hâlâ net değil, biliyorsun.';
    }
    if (_containsAny(n, ['dusunmezsem', 'düşünmezsem', 'hazirliksiz', 'hazırlıksız', 'yakalanacak'])) {
      return 'Hazırlıksız yakalanma hissi hâlâ orada.';
    }
    if (_containsAny(n, ['anlamiyor', 'anlamıyor', 'kimse'])) {
      return 'Anlaşılmadığını hissetmek hâlâ orada.';
    }
    if (n.contains('belki') && _containsAny(n, ['isten', 'işten'])) {
      return 'Belki işten geldiği aklında.';
    }
    if (_containsAny(n, ['yarin', 'yarın']) &&
        _containsAny(n, ['mudur', 'müdür', 'konuş', 'konus', 'toplanti', 'toplantı', 'sunum'])) {
      return 'Yarınki konuşma hâlâ kafanda.';
    }
    if (_containsAny(n, ['yarin', 'yarın']) &&
        _containsAny(n, ['karisik', 'karışık', 'belirsiz', 'bilmiyorum'])) {
      return 'Yarınla ilgili belirsizlik hâlâ kafanda.';
    }
    if (_containsAny(n, ['uyuyamiyorum', 'uyuyamıyorum', 'uyuyam'])) {
      if (_containsAny(n, ['yarin', 'yarın'])) {
        return 'Yarınki konuşma hâlâ kafanda.';
      }
      return 'Bu gece uyku gelmiyor gibi.';
    }
    if (_containsAny(n, ['ozledim', 'ozluyorum']) ||
        (n.contains('onu') && _containsAny(n, ['ozle', 'ozluyorum', 'cok']))) {
      return 'Özlem bu gece daha yakın gibi.';
    }
    if (_containsAny(n, ['yalniz', 'yalnız', 'yalnizim', 'yalnızım'])) {
      return 'Yalnızlık bu gece daha yakın gibi.';
    }
    if (_containsAny(n, ['kavga', 'mesaj', 'sevgili', 'partner'])) {
      return 'Az önceki konuşma hâlâ orada.';
    }
    if (_containsAny(n, ['yazsam', 'yazmasam', 'mesajini', 'mesajını'])) {
      return 'Mesaj hâlâ aklında dönüyor.';
    }
    if (_containsAny(n, ['is ', 'iş ', 'deadline', 'yetis', 'yetiş', 'beynim', 'baski', 'baskı'])) {
      return 'İş kafanda hâlâ açık.';
    }
    if (_containsAny(n, ['kafam', 'aklim', 'aklım', 'durmuyor', 'donup', 'dönüp', 'kapanmiyor', 'kapanmıyor'])) {
      return 'Kafanda hâlâ dönüp duruyor.';
    }
    if (_containsAny(n, ['gergin', 'garip']) &&
        _containsAny(n, ['icimde', 'içimde', 'var'])) {
      return 'O gerginlik hâlâ içinde.';
    }
    if (_containsAny(n, ['beden', 'agir', 'ağır']) && n.contains('gibi')) {
      return 'Bedende ağır bir his var gibi.';
    }
    if (n.contains('gibi') && _containsAny(n, ['garip', 'agir', 'ağır', 'beden'])) {
      return 'Adını koyamadığın bir his var gibi.';
    }
    if (_containsAny(n, ['icime oturdu', 'içime oturdu', 'oturdu']) &&
        _containsAny(n, ['bilmiyorum', 'ne oldugunu', 'ne olduğunu'])) {
      return 'Bir şey hâlâ içinde duruyor.';
    }
    if (_containsAny(n, ['belirsiz', 'karisik', 'karışık', 'bilmiyorum']) &&
        _containsAny(n, ['icimde', 'içimde', 'garip', 'gergin'])) {
      return 'Bir şey hâlâ içinde duruyor.';
    }
    if (_containsAny(n, ['toplanti', 'toplantı', 'sunum'])) {
      return 'Yarınki konuşma hâlâ kafanda.';
    }
    if (_containsAny(n, ['keske', 'keşke', 'pisman', 'pişman'])) {
      return 'Az önceki konuşma hâlâ orada.';
    }
    return null;
  }

  static String? _englishMirror(String user) {
    final n = user.toLowerCase();
    if (n.contains('tomorrow') &&
        _containsAny(n, ['meeting', 'boss', 'talk', 'presentation', 'confused', 'unclear'])) {
      if (_containsAny(n, ['confused', 'unclear', 'mixed'])) {
        return 'Tomorrow still feels unclear in your head.';
      }
      return 'Tomorrow’s conversation is still in your head.';
    }
    if (_containsAny(n, ["can't sleep", 'cannot sleep', 'sleep'])) {
      return 'Sleep is not coming easily tonight.';
    }
    if (_containsAny(n, ['miss', 'lonely', 'alone'])) {
      return 'That missing feels close tonight.';
    }
    if (_containsAny(n, ['something', 'inside', "don't know"])) {
      return 'Something is still sitting inside.';
    }
    return null;
  }

  static bool _looksTurkish(String text) {
    final raw = text.toLowerCase();
    if (RegExp(r'[ğüşıöçâîû]').hasMatch(raw)) return true;
    final lower = _normalize(text);
    return _containsAny(lower, const [
      'yarin',
      'uyuyam',
      'kafam',
      'aklim',
      'ozled',
      'guluyor',
      'onu',
      'sevgili',
      'icime',
      'oturdu',
      'bilmiyorum',
      'dusunmezsem',
      'hazirliksiz',
      'anlamiyor',
    ]);
  }

  static bool _containsAny(String n, List<String> markers) {
    for (final marker in markers) {
      if (n.contains(_normalize(marker))) return true;
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
