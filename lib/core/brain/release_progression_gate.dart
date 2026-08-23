import 'conversation_arc_reader.dart';
import 'light_conversation_detector.dart';
import 'night_session.dart';
import 'validated_understanding.dart';

/// Deterministic gating for Release readiness climb vs ongoing conversation.
///
/// Expression/release input only. Does not choose WHAT, exit, or speech.
class ReleaseProgressionGate {
  const ReleaseProgressionGate({
    this.lightConversation = const LightConversationDetector(),
  });

  final LightConversationDetector lightConversation;

  /// True when the night is still actively unfolding — readiness must not climb.
  bool conversationStillActive({
    required ValidatedUnderstanding understanding,
    required NightSession session,
    String? message,
  }) {
    if (message != null && hasWindDownEvidence(message)) {
      return false;
    }

    if (message != null && hasWindDownEvidence(message)) {
      return false;
    }

    final arc = ConversationArcReader.fromSession(session);
    if (arc.problemFocusedArcIncomplete) {
      if (message != null && hasWindDownEvidence(message) && arc.hadClosure) {
        return false;
      }
      return true;
    }

    if (message != null && lightConversation.isLightConversation(message)) {
      return true;
    }

    if (understanding.mentalPatterns.isNotEmpty ||
        understanding.emotionalPatterns.isNotEmpty) {
      return true;
    }

    if (message != null && _messageSignalsOngoingConversation(message)) {
      return true;
    }

    if (_sessionRecentLoad(session)) {
      return true;
    }

    return false;
  }

  /// True when the user signals genuine settling / wind-down this turn.
  bool hasWindDownEvidence(String message) {
    final n = _normalize(message);
    if (n.isEmpty) return false;

    if (_containsAny(n, const [
      'biraz daha sakin',
      'daha sakinim',
      'calmer',
      'quieter',
      'a little quieter',
      'softening',
      'settling',
      'settled',
      'lighter',
      'feels better',
      'a bit better',
      'yumusuyor',
      'yumusadi',
      'yumusadim',
      'rahatladim',
      'rahatladım',
      'daha hafif',
      'biraz daha sessiz',
      'daha sessiz',
    ])) {
      return true;
    }

    if (_containsAny(n, const [
      'sabaha birak',
      'sabaha bırak',
      'leave it for tomorrow',
      'leave this for tomorrow',
      'for tomorrow morning',
      'tomorrow morning',
      'sabah birak',
    ])) {
      return true;
    }

    if (_containsAny(n, const [
      'uyumaya calis',
      'uyumaya çalış',
      'try to sleep',
      'trying to sleep',
      'going to sleep',
      'going to bed',
      'can sleep now',
      'uyuyabilirim',
      'uyuyabilir',
      'sanirim artik uyuyabilirim',
      'sanırım artık uyuyabilirim',
    ])) {
      return true;
    }

    if (_containsAny(n, const [
      'enough for tonight',
      "that's enough for tonight",
      'that is enough for tonight',
      'bu gece icin yeter',
      'bu gece için yeter',
      'can let this rest',
      'let this rest for now',
      'let it rest for now',
      'birakabilirim',
      'bırakabilirim',
      'birakabilir',
      'ready to rest',
      'can rest now',
    ])) {
      return true;
    }

    if (_containsAny(n, const [
      'sese gec',
      'sese geç',
      'move to audio',
      'ready for the audio',
    ])) {
      return true;
    }

    return false;
  }

  /// Short ack only — not wind-down by itself.
  bool isBareAcknowledgement(String? message) {
    if (message == null) return false;
    final stripped = _stripTrailingPunct(_normalize(message));
    if (stripped.isEmpty) return false;
    return RegExp(
      r'^(?:'
      r'tamam|tmm|ok|okay|okey|peki|evet|yes|yeah|yep|mm+|mhm|mm-?hmm|uh-?huh|hmm+'
      r')'
      r'(?: peki| tamam| o zaman| then| artik| artık)*'
      r'$',
    ).hasMatch(stripped);
  }

  bool _sessionRecentLoad(NightSession session, {int lookback = 2}) {
    final turns = session.turns;
    if (turns.isEmpty) return false;
    final start = turns.length > lookback ? turns.length - lookback : 0;
    for (var i = turns.length - 1; i >= start; i--) {
      final turn = turns[i];
      if (turn.mentalPatterns.isNotEmpty ||
          turn.emotionalPatterns.isNotEmpty) {
        return true;
      }
    }
    return false;
  }

  bool _messageSignalsOngoingConversation(String message) {
    final n = _normalize(message);
    if (n.isEmpty) return false;

    if (_containsAny(n, const [
      'konusabilir miyiz',
      'konuşabilir miyiz',
      'talk a bit more',
      'talk more',
      'keep talking',
      'stay with me',
      'biraz daha konus',
      'biraz daha konuş',
    ])) {
      return true;
    }

    if (RegExp(r'\?').hasMatch(message)) return true;
    if (RegExp(r'\b(neden|niye|why|how come)\b').hasMatch(n)) return true;

    if (_containsAny(n, const [
      'aslinda',
      'aslında',
      'actually',
      'bir de',
      'one more thing',
      'bir sey daha',
      'bir şey daha',
      'also',
      'plus',
    ])) {
      return true;
    }

    if (_containsAny(n, const [
      'korkuyorum',
      'korkmaktan',
      'scared',
      'afraid',
      'olmuyor',
      'durmuyor',
      'durduram',
      'kapanmiyor',
      'kapanmıyor',
      'uyuyamiyorum',
      'uyuyamıyorum',
      'cant sleep',
      "can't sleep",
      'cannot sleep',
      'hala dusun',
      'hâlâ düşün',
      'still thinking',
      "won't stop",
      'wont stop',
      'will not stop',
      "can't stop",
      'cannot stop',
      'aklim',
      'aklım',
      'kafam',
      'kafamda',
      'slack',
      'toplant',
      'patron',
      'sevgilim',
      'relationship',
      'unutursam',
      'unuturum',
      'geliyor akl',
      'aklima gel',
      'aklıma gel',
      'yuz ifades',
      'yüz ifades',
    ])) {
      return true;
    }

    final words =
        _stripTrailingPunct(n).split(RegExp(r'\s+')).where((w) => w.isNotEmpty);
    if (words.length >= 5 && _hasLoadOrCheckInStem(n)) return true;

    return false;
  }

  bool _hasLoadOrCheckInStem(String n) {
    const stems = [
      'dusun',
      'think',
      'worr',
      'stress',
      'anx',
      'kork',
      'scared',
      'heavy',
      'agir',
      'ağır',
      'mind',
      'head',
      'sleep',
      'uyku',
      'uyu',
      'yarın',
      'yarin',
      'tomorrow',
      'meeting',
      'work',
      'is ',
      'job',
    ];
    for (final stem in stems) {
      if (n.contains(stem)) return true;
    }
    return false;
  }

  static String _normalize(String message) {
    var s = message.trim().toLowerCase();
    s = s.replaceAll('\u2019', "'");
    s = s.replaceAll(RegExp(r'\s+'), ' ');
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

  static String _stripTrailingPunct(String n) {
    return n.replaceAll(RegExp(r'[.!?…,;:]+$'), '').trim();
  }

  static bool _containsAny(String n, List<String> markers) {
    for (final marker in markers) {
      if (n.contains(_normalize(marker))) return true;
    }
    return false;
  }
}
