import 'arc_evidence_context.dart';
import 'conversation_grounding_buffer.dart';
import 'conversation_utterance.dart';
import 'night_session.dart';

/// Evidence-shaped Closure fallback when Guard rejects LLM output (Slice 3.1).
///
/// Never invents new interpretation. Never returns null — silence is unacceptable.
class ClosureFallbackBuilder {
  const ClosureFallbackBuilder._();

  static ConversationUtterance forValidation({
    required String? userUtterance,
    NightSession? session,
    ConversationGroundingBuffer? grounding,
    ArcEvidenceContext? arcEvidence,
  }) {
    final arc = arcEvidence ??
        ArcEvidenceContext.fromNight(session: session, grounding: grounding);
    final turkish = arc.prefersTurkish || _looksTurkish(userUtterance ?? '');
    final text = turkish
        ? _turkishClosure(
            arc.lastReframeText,
            arc.lastIntegrateText,
            userUtterance,
            arc.userEvidenceBlob,
          )
        : _englishClosure(arc.lastReframeText, arc.lastIntegrateText);
    return ConversationUtterance(text: text);
  }

  static String _turkishClosure(
    String? reframe,
    String? integrate,
    String? user,
    String? userBlob,
  ) {
    final blob = _normalize(
      '${reframe ?? ''} ${integrate ?? ''} ${user ?? ''} ${userBlob ?? ''}',
    );
    if (_containsAny(blob, ['gozunde', 'gorun', 'görün', 'yetersiz', 'tepki', 'mudur'])) {
      return 'Ama onun seni nasıl göreceğini bu gece kesinleştiremezsin. Yarınki konuşma yarının işi. Bu gece kendini onun gözünde kanıtlamak zorunda değilsin.';
    }
    if (_containsAny(blob, ['ozlem', 'ozl', 'kirgin', 'ikisi'])) {
      return 'Bu özlemi bu gece çözmek zorunda değilsin.';
    }
    if (_containsAny(blob, ['guven', 'güven', 'ozle', 'ozl'])) {
      return 'O güven duygusunu bu gece geri getirmek zorunda değilsin. Özlemek, geri dönmen gerektiği anlamına gelmiyor.';
    }
    if (_containsAny(blob, ['yalniz', 'yalnız', 'yaninda biri', 'hissetmeyi', 'sessiz'])) {
      return 'Bu gece yanında biri varmış hissini geri getirmek zorunda değilsin.';
    }
    if (_containsAny(blob, ['anlamiyor', 'anlamıyor', 'kimse'])) {
      return 'Bu gece anlaşılmak zorunda hissetmek zorunda değilsin.';
    }
    if (_containsAny(blob, ['baski', 'baskı', 'yarın', 'yarin', 'is ', 'iş '])) {
      return 'Yarınki baskıyı bu gece çözemezsin. Yarın kendi zamanında gelecek. Bu gece zihnini ona hazırlamak zorunda değilsin.';
    }
    if (_containsAny(blob, ['dusun', 'düşün', 'hazir', 'hazır'])) {
      return 'Bu gece düşünerek daha hazır olamazsın. Hazırlık yarının işi. Bu gece zorunda değilsin.';
    }
    return 'Bu gece taşıdığın şeyi çözmek zorunda değilsin.';
  }

  static String _englishClosure(String? reframe, String? integrate) {
    final blob = _normalize('${reframe ?? ''} ${integrate ?? ''}');
    if (_containsAny(blob, ['eyes', 'look', 'judged', 'reaction'])) {
      return 'You cannot settle how they see you tonight. Tomorrow talk is tomorrow. You do not have to prove yourself in their eyes tonight.';
    }
    if (_containsAny(blob, ['miss', 'long'])) {
      return 'You do not have to resolve this missing tonight.';
    }
    return 'You do not have to carry this tonight.';
  }

  static bool _looksTurkish(String text) {
    if (text.trim().isEmpty) return false;
    final lower = text.toLowerCase();
    if (RegExp(r'[ğüşıöçâîû]').hasMatch(lower)) return true;
    return _containsAny(lower, [
      'tepki',
      'yetersiz',
      'korkuyorum',
      'yarin',
      'yarın',
      'bu gece',
      'dogru',
      'ozle',
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
