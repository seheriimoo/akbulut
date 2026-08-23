import 'conversation_expression_mode.dart';
import 'conversation_utterance.dart';
import 'night_session.dart';

/// Evidence-shaped Integrate fallback when Guard rejects LLM output (Slice 3).
class IntegrateFallbackBuilder {
  const IntegrateFallbackBuilder._();

  static ConversationUtterance? forValidation({
    required String? userUtterance,
    required NightSession? session,
  }) {
    final reframe = _lastReframeText(session);
    if (reframe != null) {
      final fromReframe = _integrateFromReframe(reframe);
      if (fromReframe != null) {
        return ConversationUtterance(text: fromReframe);
      }
    }
    if (userUtterance == null || userUtterance.trim().isEmpty) {
      return null;
    }
    final turkish = _looksTurkish(userUtterance);
    final text = turkish
        ? _turkishIntegrate(userUtterance)
        : _englishIntegrate(userUtterance);
    if (text == null || text.isEmpty) return null;
    return ConversationUtterance(text: text);
  }

  static String? _lastReframeText(NightSession? session) {
    if (session == null) return null;
    for (var i = session.turns.length - 1; i >= 0; i--) {
      final turn = session.turns[i];
      if (turn.admittedExpression != null &&
          turn.expressionMode == ConversationExpressionMode.reframe) {
        return turn.admittedExpression!.text;
      }
    }
    return null;
  }

  static String? _integrateFromReframe(String reframe) {
    final n = _normalize(reframe);
    if (_containsAny(n, ['gozunde', 'görün', 'gorun', 'yetersiz', 'tepki'])) {
      return 'O zaman zihnin yarınki konuşmayı çözmekten çok, onun gözünde nasıl görüneceğini şimdiden güvenceye almaya çalışıyor.';
    }
    if (_containsAny(n, ['guven', 'güven', 'ozle', 'ozl'])) {
      return 'O zaman zihnin onu geri getirmekten çok, onunlayken hissettiğin güveni şimdi tamamlamaya çalışıyor.';
    }
    if (_containsAny(n, ['hazirlik', 'hazırlık', 'dusun', 'düşün'])) {
      return 'Bu yüzden zihnin yorulduğu halde düşünmeyi bırakmayı risk gibi görüyor.';
    }
    if (_containsAny(n, ['baski', 'baskı', 'yarın', 'yarin'])) {
      return 'O zaman zihnin yarını çözmekten çok, baskının tekrar geleceğini şimdiden kontrol etmeye çalışıyor.';
    }
    return null;
  }

  static String? _turkishIntegrate(String user) {
    final n = _normalize(user);
    if (_containsAny(n, ['tepki', 'yetersiz', 'gorun', 'görün', 'mudur', 'müdür'])) {
      return 'O zaman zihnin yarınki konuşmayı çözmekten çok, onun gözünde nasıl görüneceğini şimdiden güvenceye almaya çalışıyor.';
    }
    if (_containsAny(n, ['dusun', 'düşün', 'hazir', 'hazır'])) {
      return 'Bu yüzden zihnin yorulduğu halde düşünmeyi bırakmayı risk gibi görüyor.';
    }
    return null;
  }

  static String? _englishIntegrate(String user) {
    final n = user.toLowerCase();
    if (_containsAny(n, ['reaction', 'inadequate', 'judged'])) {
      return 'So your mind may be trying to secure how you look in their eyes tonight, more than to solve tomorrow talk.';
    }
    return null;
  }

  static bool _looksTurkish(String text) {
    final lower = text.toLowerCase();
    if (RegExp(r'[ğüşıöçâîû]').hasMatch(lower)) return true;
    return _containsAny(lower, ['tepki', 'yetersiz', 'korkuyorum', 'yarin', 'yarın']);
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
