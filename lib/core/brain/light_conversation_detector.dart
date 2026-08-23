/// Deterministic detector for positive, mundane, playful, or chat-only turns.
///
/// Perception/policy input only. Does not choose WHAT, exit, or memory.
/// A turn is light when the user is not signaling night load, distress,
/// or sleep struggle.
class LightConversationDetector {
  const LightConversationDetector();

  /// True when [message] is positive, mundane, playful, or chat-intent only.
  bool isLightConversation(String message) {
    final n = _normalize(message);
    if (n.isEmpty) return false;
    if (hasRealLoadMarkers(n)) return false;
    if (_isPositiveContinuation(n)) return true;
    return _isPositiveTone(n) ||
        _isNeutralMundane(n) ||
        _isHopefulFuture(n) ||
        _isMundanePlan(n) ||
        _isPlayfulLight(n) ||
        _isChatIntent(n);
  }

  /// True when future/plan language carries explicit worry or night load.
  bool hasRealLoadMarkers(String text) {
    final n = _normalize(text);
    if (n.isEmpty) return false;

    if (_containsAny(n, const [
      'kaygili',
      'kaygılı',
      'kaygiliyim',
      'kaygılıyım',
      'endise',
      'endişe',
      'endiseli',
      'endişeli',
      'korkuyorum',
      'korku',
      'stress',
      'stressed',
      'anxious',
      'anxiety',
      'worried',
      'scared',
      'afraid',
      'uyuyamiyorum',
      'uyuyamıyorum',
      'cant sleep',
      "can't sleep",
      'cannot sleep',
      'kafam susmuyor',
      'kafam durmuyor',
      'aklim durmuyor',
      'aklım durmuyor',
      'ozluyorum',
      'özliyorum',
      'ozledim',
      'özledim',
      'yalniz',
      'yalnız',
      'lonely',
      'heavy',
      'agir geliyor',
      'ağır geliyor',
      'what if',
      'worst case',
      'yetisemeyecegim',
      'yetişemeyeceğim',
      'kaciracagim',
      'kaçıracağım',
      'spiral',
      'overthinking',
      'stresli',
      'kotu gec',
      'kötü gece',
      'cok kotu',
      'çok kötü',
      'aci veriyor',
      'acı veriyor',
      'icimi acit',
      'içimi acıt',
      'ozlemek icimi',
      'özlemek içimi',
      'icimi acitiyor',
      'içimi acıtıyor',
      'kapanmiyor',
      'kapanmıyor',
      'bilmiyorum ve korkuyorum',
    ])) {
      return true;
    }

    if (_containsWord(n, const ['yarin', 'yarın', 'tomorrow'])) {
      return _containsAny(n, const [
        'toplant',
        'meeting',
        'presentation',
        'deadline',
        'sunum',
        'kayg',
        'endis',
        'endiş',
        'worri',
        'anx',
        'scared',
        'afraid',
        'kork',
        'stress',
        'yetisem',
        'yetişem',
        'kacir',
        'kaçır',
        'what if',
        'endiseli',
        'endişeli',
      ]);
    }

    if (_containsAny(n, const [
      'dusunuyorum',
      'düşünüyorum',
      'thinking',
      "can't stop",
      'cannot stop',
      'kafam',
      'aklim',
      'aklım',
    ])) {
      if (_containsAny(n, const [
        'durmuyor',
        'susmuyor',
        'calisiyor',
        'çalışıyor',
        'cikmiyor',
        'çıkmıyor',
      ])) {
        return true;
      }
    }

    return false;
  }

  bool _isNeutralMundane(String n) {
    return _containsAny(n, const [
      'normal bir gun',
      'normal bir gundu',
      'normal gec',
      'normal geç',
      'film izledim',
      'bugun film',
    ]);
  }

  bool _isHopefulFuture(String n) {
    if (!_containsWord(n, const ['yarin', 'yarın', 'tomorrow'])) {
      return false;
    }
    return _containsAny(n, const [
      'guzel gecer',
      'güzel geçer',
      'umarim',
      'umarm',
      'hope',
    ]);
  }

  bool _isPositiveTone(String n) {
    return _containsAny(n, const [
      'cok guzel bir gun',
      'çok güzel bir gün',
      'guzel bir gun',
      'güzel bir gün',
      'guzel gec',
      'güzel geç',
      'keyfim yerinde',
      'keyifli',
      'mutlu',
      'harikaydi',
      'harikaydı',
      'guldum',
      'güldüm',
      'guldum',
      'güldük',
      'guldik',
      'güldik',
      'kahve ic',
      'kahve iç',
      'good day',
      'great day',
      'nice day',
      'had fun',
      'laughed',
      'film izledim',
      'hava cok guzel',
      'hava çok güzel',
      'hava harika',
    ]);
  }

  bool _isMundanePlan(String n) {
    if (!_containsWord(n, const ['yarin', 'yarın', 'tomorrow'])) {
      return false;
    }
    return _containsAny(n, const [
      'market',
      'makarna',
      'alisveris',
      'alışveriş',
      'gidecegim',
      'gideceğim',
      'alacagim',
      'alacağım',
      'yapacagim',
      'yapacağım',
      'grocery',
      'pasta',
      'cook',
      'shopping',
    ]);
  }

  bool _isPlayfulLight(String n) {
    if (_containsAny(n, const [
      'komik',
      'gurultu',
      'gürültü',
      'funny',
      'daagit',
      'dağıt',
    ])) {
      return true;
    }
    if (n.contains('😅') || n.contains('😂') || n.contains('🙂')) {
      return !_containsAny(n, const ['kork', 'agir', 'ağır', 'uzgun', 'üzgün']);
    }
    return false;
  }

  bool _isChatIntent(String n) {
    return _containsAny(n, const [
      'konusmak istedim',
      'konuşmak istedim',
      'sohbet etmek',
      'sohbet etmek istedim',
      'biraz konus',
      'biraz konuş',
      'iki dakika konus',
      'iki dakika konuş',
      'talk a bit',
      'just wanted to talk',
      'wanted to chat',
      'before sleep i wanted to talk',
      'uyumadan once konus',
      'uyumadan önce konuş',
    ]);
  }

  bool _isPositiveContinuation(String n) {
    if (_containsAny(n, const [
      'hala guluyorum',
      'hâlâ gülüyorum',
      'hala guluyoruz',
      'hâlâ gülüyoruz',
      'still laughing',
      'still smiling',
      'still giggling',
    ])) {
      return true;
    }
    if (_containsAny(n, const ['eve geldim', 'just got home', 'got home'])) {
      return _containsAny(n, const [
        'gul',
        'gül',
        'laugh',
        'smil',
        'mutlu',
        'keyif',
        'guzel',
        'güzel',
      ]);
    }
    return false;
  }

  static String _normalize(String message) {
    var s = message.trim().toLowerCase();
    s = s.replaceAll('\u2019', "'");
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

  static bool _containsAny(String n, List<String> markers) {
    for (final marker in markers) {
      if (n.contains(_normalize(marker))) return true;
    }
    return false;
  }

  static bool _containsWord(String n, List<String> words) {
    for (final word in words) {
      if (RegExp('\\b${RegExp.escape(_normalize(word))}\\b').hasMatch(n)) {
        return true;
      }
    }
    return false;
  }
}
