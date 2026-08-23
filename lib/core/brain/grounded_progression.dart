import 'conversation_expression_mode.dart';
import 'conversation_grounding_buffer.dart';
import 'conversation_utterance.dart';
import 'night_session.dart';

/// B4 — grounded progression helpers: narrow grounding, mirror saturation,
/// narrow exhaustion, vent stack detection.
class GroundedNarrowContract {
  const GroundedNarrowContract._();

  static final RegExp _partConfirmPattern = RegExp(
    r'^(.{2,40}?)\s+k[ıi]sm[ıi]\s+dogru\s+gibi',
    caseSensitive: false,
  );

  /// Builds `{X} kısmı doğru gibi. Peki eksik kalan taraf ne?` only when [X]
  /// is semantically supported in user evidence. Otherwise abstains.
  static String? refinementQuestion({
    required String userUtterance,
    String? priorUserUtterance,
    String? groundingBlob,
  }) {
    final affirmed = _extractAffirmedFragment(userUtterance);
    if (affirmed != null &&
        _isSemanticallyGrounded(affirmed, userUtterance, priorUserUtterance, groundingBlob)) {
      final label = _displayFragment(affirmed);
      return '$label kısmı doğru gibi. Peki eksik kalan taraf ne?';
    }

    final n = _normalize(userUtterance);
    if (_containsAny(n, const [
      'anlamiyor',
      'anlamıyor',
      'kimse',
    ])) {
      return 'Anlaşılmadığını hissetmek mi daha ağır, yoksa yalnız kalmak mı?';
    }
    if (_containsAny(n, const [
      'evet ama',
      'dogru ama',
      'doğru ama',
      'hala',
      'hâlâ',
      'tam degil',
      'tam değil',
      'biraz ama',
    ])) {
      return 'Tamam. Peki tam oturmayan taraf ne?';
    }
    return 'Tam oturmayan taraf ne?';
  }

  /// Guard check: reject narrow confirmations naming objects absent from evidence.
  static bool admitsNarrowText({
    required String noctaText,
    required String? userUtterance,
    String? groundingBlob,
  }) {
    final lower = _normalize(noctaText);
    if (!lower.contains('kismi dogru gibi') && !lower.contains('kısmı doğru gibi')) {
      return true;
    }
    final match = _partConfirmPattern.firstMatch(lower);
    if (match == null) return true;
    final fragment = match.group(1)?.trim() ?? '';
    if (fragment.isEmpty) return false;
    return _isSemanticallyGrounded(
      fragment,
      userUtterance ?? '',
      null,
      groundingBlob,
    );
  }

  static String? _extractAffirmedFragment(String user) {
    final n = _normalize(user);
    final match = _partConfirmPattern.firstMatch(n);
    if (match != null) return match.group(1)?.trim();
    for (final marker in const [
      'baski',
      'baskı',
      'kaygi',
      'kaygı',
      'endise',
      'endişe',
      'kirgin',
      'kırgın',
      'yalniz',
      'yalnız',
      'ozlem',
      'özlem',
      'guven',
      'güven',
      'is ',
      'iş ',
    ]) {
      if (n.contains(marker)) return marker;
    }
    return null;
  }

  static bool _isSemanticallyGrounded(
    String fragment,
    String userUtterance,
    String? priorUserUtterance,
    String? groundingBlob,
  ) {
    final corpus = _normalize(
      '${groundingBlob ?? ''} ${priorUserUtterance ?? ''} $userUtterance',
    );
    final f = _normalize(fragment);
    if (f.length < 3) return false;
    if (corpus.contains(f)) return true;
    final stem = f.length > 5 ? f.substring(0, f.length - 1) : f;
    if (stem.length >= 4 && corpus.contains(stem)) return true;
    final tokens = f.split(RegExp(r'\s+')).where((t) => t.length >= 4);
    for (final token in tokens) {
      if (corpus.contains(token)) return true;
    }
    return false;
  }

  static String _displayFragment(String fragment) {
    final f = fragment.trim();
    if (f.isEmpty) return f;
    return '${f[0].toUpperCase()}${f.substring(1)}';
  }

  static String _normalize(String s) {
    return s
        .toLowerCase()
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

  static bool _containsAny(String n, List<String> markers) {
    for (final marker in markers) {
      if (n.contains(_normalize(marker))) return true;
    }
    return false;
  }
}

class ProgressionStateReader {
  const ProgressionStateReader._();

  static bool isSurfaceMirror(String text) {
    final lower = text.toLowerCase();
    if (lower.contains('söylüyorsun') || lower.contains('soyluyorsun')) {
      return true;
    }
    if (RegExp(r'\bgibi\.?\s*$').hasMatch(lower.trim())) return true;
    if (lower.contains('hâlâ net olmayan') ||
        lower.contains('hala net olmayan')) {
      return true;
    }
    return false;
  }

  static bool isMirrorSaturated(NightSession? session) {
    if (session == null || session.turns.isEmpty) return false;
    final recent = <String>[];
    for (var i = session.turns.length - 1; i >= 0 && recent.length < 3; i--) {
      final text = session.turns[i].admittedExpression?.text;
      if (text == null || text.trim().isEmpty) continue;
      recent.add(text.trim().toLowerCase());
    }
    if (recent.length >= 2 &&
        isSurfaceMirror(recent[0]) &&
        isSurfaceMirror(recent[1])) {
      return true;
    }
    var mirrorInWindow = 0;
    for (final line in recent) {
      if (isSurfaceMirror(line)) mirrorInWindow++;
    }
    if (mirrorInWindow >= 2) return true;
    if (recent.length >= 2 && recent[0] == recent[1]) return true;
    return _hasDuplicateMirror(session);
  }

  static bool _hasDuplicateMirror(NightSession session) {
    final seen = <String>{};
    for (final turn in session.turns) {
      final text = turn.admittedExpression?.text.trim().toLowerCase();
      if (text == null || text.isEmpty) continue;
      if (!isSurfaceMirror(text)) continue;
      if (seen.contains(text)) return true;
      seen.add(text);
    }
    return false;
  }

  static int substantiveNarrowCount(NightSession? session) {
    return NarrowConcernBudget.countForCurrentConcern(session: session);
  }

  static bool sessionHasNegativeVent({
    required NightSession? session,
    required String? currentMessage,
    ConversationGroundingBuffer? grounding,
  }) {
    return SessionVentMemory.hasUnresolvedVent(
      session: session,
      grounding: grounding,
      currentMessage: currentMessage,
    );
  }

  static String? _groundingBlob(
    NightSession? session,
    ConversationGroundingBuffer? grounding,
  ) {
    if (grounding != null && !grounding.isEmpty) {
      return grounding.userUtterances.join(' ');
    }
    return null;
  }
}

class VentStackDetector {
  const VentStackDetector._();

  static bool hasFrustrationMarkers(String text) {
    final n = _normalize(text);
    return _containsAny(n, const [
      'sinir',
      'kizgin',
      'kızgın',
      'kirgin',
      'kırgın',
      'ust uste',
      'üst üste',
      'yoruldum',
      'yorgunum',
      'bunaldim',
      'bunaldım',
      'cok kotu',
      'çok kötü',
      'kotu gec',
      'kötü gece',
      'frustrated',
      'annoyed',
      'angry',
      'pissed',
    ]);
  }

  static bool isMultiStressorStack(String text) {
    final n = _normalize(text);
    var events = 0;
    for (final hint in const [
      'is ',
      'iş ',
      'patron',
      'komşu',
      'komsu',
      'kavga',
      'fatura',
      'deadline',
      'vet',
      'arkadas',
      'arkadaş',
      'kopuk',
      'veteriner',
      'gurultu',
      'gürültü',
    ]) {
      if (n.contains(hint)) events++;
    }
    return events >= 2;
  }

  static String? ventAcknowledgement({
    required String? userUtterance,
    String? groundingBlob,
  }) {
    final blob = '${groundingBlob ?? ''} ${userUtterance ?? ''}'.trim();
    if (blob.isEmpty) return null;
    if (isMultiStressorStack(blob) || hasFrustrationMarkers(blob)) {
      return 'Bugün gerçekten üst üste gelmiş.';
    }
    if (hasFrustrationMarkers(blob)) {
      return 'Sinir bozucu olmuş.';
    }
    return null;
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

  static bool _containsAny(String n, List<String> markers) {
    for (final marker in markers) {
      if (n.contains(_normalize(marker))) return true;
    }
    return false;
  }
}

class NarrowConcernBudget {
  const NarrowConcernBudget._();

  static const int maxSubstantivePerConcern = 2;

  static int countForCurrentConcern({
    required NightSession? session,
    ConversationGroundingBuffer? grounding,
    String? currentMessage,
  }) {
    if (session == null) return 0;

    if (currentMessage != null &&
        ConcernShiftDetector.isShift(
          currentMessage: currentMessage,
          grounding: grounding,
          session: session,
        )) {
      return 0;
    }

    final epochStart = _concernEpochStartIndex(
      grounding: grounding,
      session: session,
    );

    var count = 0;
    for (var i = session.turns.length - 1; i >= 0; i--) {
      if (i < epochStart) break;
      final mode = session.turns[i].expressionMode;
      if (mode == ConversationExpressionMode.reframe ||
          mode == ConversationExpressionMode.integrate ||
          mode == ConversationExpressionMode.closure) {
        break;
      }
      if (mode == ConversationExpressionMode.narrow) count++;
    }
    return count;
  }

  /// Turn index of the latest concern shift; narrows before this do not count.
  static int _concernEpochStartIndex({
    ConversationGroundingBuffer? grounding,
    NightSession? session,
  }) {
    if (grounding == null || grounding.userUtterances.isEmpty) return 0;
    final users = grounding.userUtterances;
    var epochStart = 0;
    for (var i = 1; i < users.length; i++) {
      var partial = ConversationGroundingBuffer.empty();
      for (var j = 0; j < i; j++) {
        partial = partial.appendUserUtterance(users[j]);
      }
      if (ConcernShiftDetector.isShift(
        currentMessage: users[i],
        grounding: partial,
        session: session,
      )) {
        epochStart = i;
      }
    }
    return epochStart;
  }

  static bool isExhausted({
    required NightSession? session,
    ConversationGroundingBuffer? grounding,
    String? currentMessage,
  }) {
    return countForCurrentConcern(
          session: session,
          grounding: grounding,
          currentMessage: currentMessage,
        ) >=
        maxSubstantivePerConcern;
  }

  static bool isForbiddenGenericRefinement(String text) {
    final lower = text.toLowerCase();
    return lower.contains('eksik kalan taraf') ||
        lower.contains('tam oturmayan taraf') ||
        lower.contains('peki eksik kalan');
  }
}

class ConcernShiftDetector {
  const ConcernShiftDetector._();

  static const _stopTokens = {
    'ama', 've', 'bir', 'cok', 'çok', 'icin', 'için', 'gibi', 'ben', 'sen',
    'biz', 'bu', 'su', 'şu', 'the', 'that', 'with', 'have', 'sanirim',
    'sanırım', 'galiba', 'belki', 'az', 'once', 'önce', 'hala', 'hâlâ',
    'tamam', 'evet', 'degil', 'değil', 'olarak', 'fark', 'ettim',
  };

  static bool isShift({
    required String? currentMessage,
    ConversationGroundingBuffer? grounding,
    NightSession? session,
    bool blockDuringEarnedArc = false,
  }) {
    if (blockDuringEarnedArc) return false;
    if (currentMessage == null || currentMessage.trim().length < 10) {
      return false;
    }
    if (!_hasPivotMarker(currentMessage)) return false;

    final prior = _priorSubstantiveUserLine(grounding, session);
    if (prior == null || prior.trim().length < 8) return false;

    final currentSig = _signature(currentMessage);
    final priorSig = _signature(prior);
    if (currentSig.isEmpty || priorSig.isEmpty) return true;

    final overlap = _jaccard(currentSig, priorSig);
    return overlap < 0.35;
  }

  static String? _priorSubstantiveUserLine(
    ConversationGroundingBuffer? grounding,
    NightSession? session,
  ) {
    if (grounding != null && grounding.priorUserUtterances.isNotEmpty) {
      for (var i = grounding.priorUserUtterances.length - 1; i >= 0; i--) {
        final line = grounding.priorUserUtterances[i].trim();
        if (line.length >= 8) return line;
      }
    }
    return null;
  }

  static bool _hasPivotMarker(String message) {
    final n = _normalize(message);
    return RegExp(
      r'\b(aslinda|aslında|degil de|değil de|fark ettim|farkettim|'
      r'baska bir|başka bir|sanirim aslinda|sanırım aslında)\b',
    ).hasMatch(n);
  }

  static Set<String> _signature(String message) {
    final n = _normalize(message);
    final raw = n.split(RegExp(r'[^a-z0-9]+')).where((t) => t.length >= 4);
    return raw.where((t) => !_stopTokens.contains(t)).toSet();
  }

  static double _jaccard(Set<String> a, Set<String> b) {
    if (a.isEmpty || b.isEmpty) return 0;
    final inter = a.intersection(b).length;
    final union = a.union(b).length;
    if (union == 0) return 0;
    return inter / union;
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

class SessionVentMemory {
  const SessionVentMemory._();

  static bool hasUnresolvedVent({
    required NightSession? session,
    ConversationGroundingBuffer? grounding,
    String? currentMessage,
    String? sessionVentCorpus,
  }) {
    final windowBlob = _userLines(grounding).join(' ');
    final ventBlob = [sessionVentCorpus, windowBlob]
        .where((s) => s != null && s.trim().isNotEmpty)
        .join(' ')
        .trim();
    final priorVent = ventBlob.isNotEmpty &&
        (VentStackDetector.hasFrustrationMarkers(ventBlob) ||
            VentStackDetector.isMultiStressorStack(ventBlob));
    if (!priorVent) return false;
    if (currentMessage != null && isVentResolved(currentMessage)) {
      return false;
    }
    return true;
  }

  static bool blocksPlayfulLight({
    required NightSession? session,
    ConversationGroundingBuffer? grounding,
    required String? currentMessage,
    String? sessionVentCorpus,
  }) {
    if (currentMessage != null && isPseudoPositiveContinuation(currentMessage)) {
      if (hasUnresolvedVent(
        session: session,
        grounding: grounding,
        currentMessage: null,
        sessionVentCorpus: sessionVentCorpus,
      )) {
        return true;
      }
    }
    if (!hasUnresolvedVent(
      session: session,
      grounding: grounding,
      currentMessage: currentMessage,
      sessionVentCorpus: sessionVentCorpus,
    )) {
      return false;
    }
    if (currentMessage != null && isVentResolved(currentMessage)) {
      return false;
    }
    if (currentMessage != null && isGenuinePositiveShift(currentMessage)) {
      return false;
    }
    return true;
  }

  static bool isVentResolved(String message) {
    final n = _normalize(message);
    return RegExp(
      r'\b(rahatladim|rahatladım|sakinlestim|sakinleştim|simdi iyiyim|'
      r'şimdi iyiyim|artik iyiyim|artık iyiyim|daha iyi|sakinim artik|'
      r'sakinim artık|iyi hissediyorum|mutlu|keyfim)\b',
    ).hasMatch(n);
  }

  static bool isGenuinePositiveShift(String message) {
    if (isPseudoPositiveContinuation(message)) return false;
    final n = _normalize(message);
    return RegExp(
      r'\b(terfi|kutlad|harika|mutlu|guzel gec|güzel geç|keyfim|guldum|güldüm)\b',
    ).hasMatch(n);
  }

  static bool isPseudoPositiveContinuation(String message) {
    final n = _normalize(message);
    return n.contains('tamam biraz konust') ||
        n.contains('biraz konust') ||
        n.contains('konustuk') ||
        n.contains('konusmam');
  }

  static bool ventEvidencePresent({
    ConversationGroundingBuffer? grounding,
    String? sessionVentCorpus,
  }) {
    final windowBlob = _userLines(grounding).join(' ');
    final ventBlob = [sessionVentCorpus, windowBlob]
        .where((s) => s != null && s.trim().isNotEmpty)
        .join(' ')
        .trim();
    if (ventBlob.isEmpty) return false;
    return VentStackDetector.hasFrustrationMarkers(ventBlob) ||
        VentStackDetector.isMultiStressorStack(ventBlob);
  }

  /// Session-level vent latch — survives the 3-turn grounding window.
  static String advanceVentCorpus({
    required String currentCorpus,
    required String message,
  }) {
    if (isVentResolved(message)) return '';
    if (VentStackDetector.hasFrustrationMarkers(message) ||
        VentStackDetector.isMultiStressorStack(message)) {
      return '$currentCorpus $message'.trim();
    }
    return currentCorpus;
  }

  static List<String> _userLines(ConversationGroundingBuffer? grounding) {
    if (grounding == null || grounding.isEmpty) return const [];
    return grounding.userUtterances.toList();
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

class GroundedHoldContract {
  const GroundedHoldContract._();

  static const _ventPhrases = [
    'ust uste gel',
    'üst üste gel',
    'sinir bozucu',
    'gercekten ust',
  ];

  static const _inventedObjects = [
    'baski',
    'baskı',
    'korku',
    'kirgin',
    'kırgın',
    'yuk',
    'yük',
    'endise',
    'endişe',
    'kaygi',
    'kaygı',
  ];

  static bool admits({
    required String noctaText,
    required String? userUtterance,
    String? groundingBlob,
  }) {
    final lower = noctaText.toLowerCase();
    if (lower.contains('?')) return false;

    final corpus = _normalize('${groundingBlob ?? ''} ${userUtterance ?? ''}');
    final ventAllowed = VentStackDetector.hasFrustrationMarkers(corpus) ||
        VentStackDetector.isMultiStressorStack(corpus);

    for (final phrase in _ventPhrases) {
      if (lower.contains(phrase) && !ventAllowed) return false;
    }

    for (final obj in _inventedObjects) {
      final nObj = _normalize(obj);
      if (lower.contains(nObj) && !corpus.contains(nObj)) return false;
    }

    if (_genericReframeDrift(lower)) return false;
    return _hasAllowedHoldShape(lower) || _hasCorpusOverlap(lower, corpus);
  }

  static bool _hasAllowedHoldShape(String lower) {
    return lower.contains('henuz') ||
        lower.contains('henüz') ||
        lower.contains('tam adini') ||
        lower.contains('tam adını') ||
        lower.contains('kaybetmedim') ||
        lower.contains('uyanik tut') ||
        lower.contains('uyanık tut') ||
        lower.contains('burada kalabilir') ||
        lower.contains('cozmek zorunda degilsin') ||
        lower.contains('çözmek zorunda değilsin') ||
        lower.contains('hala sende duruyor') ||
        lower.contains('hâlâ sende duruyor');
  }

  static bool _hasCorpusOverlap(String lower, String corpus) {
    if (corpus.trim().length < 8) return false;
    final tokens = corpus
        .split(RegExp(r'[^a-z0-9]+'))
        .where((t) => t.length >= 5)
        .toSet();
    for (final token in tokens) {
      if (lower.contains(token)) return true;
    }
    return false;
  }

  static bool _genericReframeDrift(String lower) {
    return lower.contains('olabilir') ||
        lower.contains('sanki') ||
        lower.contains('belki ') ||
        lower.contains(' aslında ') ||
        lower.contains(' aslinda ');
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

class NarrowExhaustionGate {
  const NarrowExhaustionGate._();

  static const int maxSubstantiveNarrowAttempts = 2;

  static bool isExhausted(
    NightSession? session, {
    ConversationGroundingBuffer? grounding,
    String? currentMessage,
  }) {
    return NarrowConcernBudget.isExhausted(
      session: session,
      grounding: grounding,
      currentMessage: currentMessage,
    );
  }

  static bool userStillUncertain(String? message) {
    if (message == null) return false;
    final n = message.toLowerCase();
    return RegExp(
      r'\b(bilmiyorum|bilmiyom|emin degilim|emin değilim|net degil|net değil|'
      r'kararsiz|kararsız|aciklayamam|açıklayamam|belki hic|belki hiç)\b',
    ).hasMatch(n);
  }

  static bool hasFreshEvidence(String? message) {
    if (message == null || message.trim().length < 12) return false;
    if (userStillUncertain(message)) return false;
    return true;
  }
}

/// Honest synthesis / hold — no invented psychology.
class HonestSynthesisBuilder {
  const HonestSynthesisBuilder._();

  static ConversationUtterance? forValidation({
    required String? userUtterance,
    String? groundingBlob,
    bool prefersTurkish = true,
  }) {
    if (!prefersTurkish) {
      return const ConversationUtterance(
        text: 'You do not have to name it perfectly tonight. What we know is it is still keeping you awake.',
      );
    }

    if (NarrowExhaustionGate.userStillUncertain(userUtterance)) {
      return const ConversationUtterance(
        text:
            'Tam adını koyamıyor olman da tamam. Şimdilik bildiğimiz şey, bunun seni hâlâ uyanık tuttuğu.',
      );
    }

    final corpus = '${groundingBlob ?? ''} ${userUtterance ?? ''}';
    final ventAllowed = VentStackDetector.hasFrustrationMarkers(corpus) ||
        VentStackDetector.isMultiStressorStack(corpus);
    if (ventAllowed) {
      final vent = VentStackDetector.ventAcknowledgement(
        userUtterance: userUtterance,
        groundingBlob: groundingBlob,
      );
      if (vent != null) return ConversationUtterance(text: vent);
    }

    final anchor = _surfaceAnchor(userUtterance, groundingBlob);
    if (anchor != null) {
      return ConversationUtterance(
        text: '$anchor hâlâ sende duruyor. Bu gece çözmek zorunda değilsin.',
      );
    }

    return const ConversationUtterance(
      text:
          'Henüz tam oturmadı ama seni kaybetmedim. Bu gece burada kalabilir.',
    );
  }

  static String? _surfaceAnchor(String? user, String? blob) {
    final source = (user ?? blob ?? '').trim();
    if (source.isEmpty) return null;
    final clauses = source
        .split(RegExp(r'[,;!.?]\s*'))
        .map((c) => c.trim())
        .where((c) => c.length >= 8)
        .toList();
    if (clauses.isEmpty) return null;
    clauses.sort((a, b) => b.length.compareTo(a.length));
    final best = clauses.first;
    if (best.length > 48) {
      return '${best.substring(0, 45).trim()}…';
    }
    return best;
  }
}
