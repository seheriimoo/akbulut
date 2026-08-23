import 'conversation_arc_reader.dart';
import 'conversation_grounding_buffer.dart';
import 'night_session.dart';
import 'validated_understanding.dart';

/// Deterministic evidence gate before Reframe compile (Slice 2).
///
/// Does not choose WHAT or expression mode. Answers only: is there enough
/// conversation evidence to offer one soft reframe?
class ReframeReadinessGate {
  const ReframeReadinessGate();

  bool isReady({
    required NightSession? session,
    required String? message,
    required ValidatedUnderstanding? understanding,
    ConversationGroundingBuffer? conversationGrounding,
    required ConversationArcReader arc,
  }) {
    // T1 / first Receipt: never reframe-ready.
    if (!arc.hadObservePurity) return false;

    if (message != null && _explicitCausalOrMotiveInfo(message)) {
      return true;
    }

    if (arc.hadNarrow && message != null && _substantiveAfterNarrow(message)) {
      return true;
    }

    if (_repeatedConcern(conversationGrounding)) {
      return true;
    }

    if (arc.loadTurnCount >= 3 && _stableLoadNight(understanding)) {
      return true;
    }

    return false;
  }

  bool _explicitCausalOrMotiveInfo(String message) {
    final n = _normalize(message);
    return _containsAny(n, const [
      'korkuyorum',
      'korkuyorum cunku',
      'korkuyorum çünkü',
      'cunku',
      'çünkü',
      'yuzunden',
      'yüzünden',
      'tepkisi',
      'tepkisinden',
      'yetersiz',
      'yargilan',
      'yargılan',
      'gorunecegim',
      'görüneceğim',
      'hazirlanmadigim',
      'hazırlanmadığım',
      'because',
      'afraid that',
      'scared that',
      'worried that',
      'his reaction',
      'her reaction',
      'judged',
      'inadequate',
    ]);
  }

  bool _substantiveAfterNarrow(String message) {
    final n = _normalize(message);
    if (n.length < 10) return false;
    if (_isBareAcknowledgment(n)) return false;
    if (_isVagueThinGuess(n)) return false;

    if (_explicitCausalOrMotiveInfo(message)) return true;
    if (_forkBranchPreference(n)) return true;
    if (_emotionalRelationEvidence(n)) return true;

    return _containsAny(n, const [
      'tepki',
      'konuşma',
      'konusma',
      'sunum',
      'toplanti',
      'toplantı',
      'is ',
      'iş ',
      'ozlem',
      'özlem',
      'yalniz',
      'yalnız',
      'kork',
      'endis',
      'endiş',
      'yetersiz',
      'hazirlan',
      'hazırlan',
      'dusunmezsem',
      'düşünmezsem',
      'guven',
      'güven',
      'hissed',
      'kirgin',
      'kırgın',
      'rahat',
      'baski',
      'baskı',
    ]);
  }

  /// User picked one side of a narrow fork or named the missing branch.
  bool _forkBranchPreference(String n) {
    return _containsAny(n, const [
      'onunlayken',
      'onunla ',
      'yanindayken',
      'yanındayken',
      'yaninda ',
      'yanında ',
      'sunumdan cok',
      'sunumdan çok',
      'sahneden cok',
      'sahneden çok',
      'tepkisinden',
      'baski kismi',
      'baskı kısmı',
      'yazmak istiyorum',
      'yazmasam',
      'pişman',
      'pisman',
      'aslında sunumdan',
      'aslinda sunumdan',
    ]);
  }

  /// Emotional/causal relation after narrow — not generic vague worry.
  bool _emotionalRelationEvidence(String n) {
    final hasFeeling = _containsAny(n, const [
      'hissed',
      'hisset',
      'guven',
      'güven',
      'ozled',
      'özled',
      'ozluy',
      'özüy',
      'kirgin',
      'kırgın',
      'uzgun',
      'üzgün',
      'rahat',
      'mutlu',
      'guvenli',
      'güvenli',
    ]);
    if (!hasFeeling) return false;
    return n.length >= 18 ||
        _containsAny(n, const [
          'onunla',
          'onunlayken',
          'yaninda',
          'yanında',
          'kendimi',
          'icimde',
          'içimde',
        ]);
  }

  /// Thin ambiguous guess — do not force reframe.
  bool _isVagueThinGuess(String n) {
    if (n.length > 16) return false;
    return RegExp(r'^(belki|galiba|sanirim|sanırım)\b').hasMatch(n.trim()) &&
        !_containsAny(n, const [
          'cunku',
          'çünkü',
          'hissed',
          'guven',
          'güven',
          'onunla',
        ]);
  }

  bool _isBareAcknowledgment(String n) {
    return RegExp(
      r'^(evet|aynen|tamam|ok|okay|hm+|hmm+|mm+|he+|ha+|yes|yeah|yep)\.?$',
    ).hasMatch(n.trim());
  }

  bool _repeatedConcern(ConversationGroundingBuffer? buffer) {
    if (buffer == null || buffer.userUtterances.length < 2) return false;
    final utterances = buffer.userUtterances.map(_normalize).toList();
    for (var i = 0; i < utterances.length; i++) {
      for (var j = i + 1; j < utterances.length; j++) {
        if (_sameConcernCluster(utterances[i], utterances[j])) return true;
      }
    }
    return false;
  }

  bool _sameConcernCluster(String a, String b) {
    if (a.isEmpty || b.isEmpty) return false;
    const clusters = [
      ['yarin', 'yarın', 'tomorrow', 'toplanti', 'toplantı', 'sunum', 'mudur', 'müdür'],
      ['ozle', 'özle', 'miss', 'onu', 'sevgili', 'partner'],
      ['is ', 'iş ', 'work', 'deadline', 'yetis', 'yetiş'],
      ['kafam', 'aklim', 'aklım', 'durmuyor', 'dusun', 'düşün'],
      ['gergin', 'garip', 'belirsiz', 'karisik', 'karışık', 'icime', 'içime'],
    ];
    for (final cluster in clusters) {
      final aHit = cluster.any((m) => a.contains(m));
      final bHit = cluster.any((m) => b.contains(m));
      if (aHit && bHit) return true;
    }
    return false;
  }

  bool _stableLoadNight(ValidatedUnderstanding? understanding) {
    if (understanding == null) return false;
    return understanding.mentalPatterns.isNotEmpty ||
        understanding.emotionalPatterns.isNotEmpty;
  }

  static String _normalize(String message) {
    return message.trim().toLowerCase().replaceAll('’', "'");
  }

  static bool _containsAny(String n, List<String> markers) {
    for (final marker in markers) {
      if (n.contains(marker.toLowerCase())) return true;
    }
    return false;
  }
}
