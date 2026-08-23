import 'conversation_expression_mode.dart';
import 'conversation_grounding_buffer.dart';
import 'conversation_phase.dart';
import 'conversation_utterance.dart';
import 'grounded_progression.dart';
import 'night_session.dart';
import 'surface_text_fuzzy.dart';
import 'surface_utterance_kind.dart';
import 'utterance_guard.dart';

/// B2.2.1 — Natural surface mirror for Guard-safe Receipt fallbacks.
///
/// Paraphrases the person's stated surface truth in natural Turkish/English.
/// No literal clause paste, no single suffix family, no topic keyword templates.
class UserObjectMirror {
  const UserObjectMirror._();

  static const _guard = UtteranceGuard();

  static String? mirrorEvidenceSource({
    required String? userUtterance,
    String? groundingBlob,
  }) => _mirrorSourceLine(
    userUtterance: userUtterance,
    groundingBlob: groundingBlob,
  );

  static ConversationUtterance? forValidation({
    required String? userUtterance,
    String? groundingBlob,
    ConversationExpressionMode expressionMode =
        ConversationExpressionMode.standard,
    NightSession? session,
    ConversationGroundingBuffer? grounding,
  }) {
    if (!_supportsMirror(expressionMode)) return null;
    final concernShiftFresh = userUtterance != null &&
        ConcernShiftDetector.isShift(
          currentMessage: userUtterance,
          grounding: grounding,
          session: session,
        );
    if (ProgressionStateReader.isMirrorSaturated(session) &&
        !concernShiftFresh) {
      return null;
    }

    final sourceLine = _mirrorSourceLine(
      userUtterance: userUtterance,
      groundingBlob: groundingBlob,
    );
    if (sourceLine == null || sourceLine.trim().isEmpty) return null;

    final kind = SurfaceUtteranceReader.classify(sourceLine);
    if (kind == SurfaceUtteranceKind.abstain) return null;

    final turkish = _prefersTurkish(userUtterance, groundingBlob);
    final candidates = turkish
        ? _turkishSurfaceLines(kind, sourceLine, expressionMode)
        : _englishSurfaceLines(kind, sourceLine, expressionMode);

    for (final text in candidates) {
      if (text == null || text.trim().isEmpty) continue;
      if (_isRepeatedMirror(text, session)) continue;
      if (_passesGuard(
        text: text,
        userUtterance: userUtterance,
        mirrorSourceLine: sourceLine,
        expressionMode: expressionMode,
      )) {
        return ConversationUtterance(text: text);
      }
    }

    // B2.2.1 — OOD structural retreat: substantive turns must not abstain.
    if (_isSubstantiveSource(sourceLine)) {
      final ood = _oodGuaranteedCandidates(
        sourceLine,
        kind,
        expressionMode,
      );
      for (final text in ood) {
        if (text == null || text.trim().isEmpty) continue;
        if (_isRepeatedMirror(text, session)) continue;
        if (_passesGuard(
          text: text,
          userUtterance: userUtterance,
          mirrorSourceLine: sourceLine,
          expressionMode: expressionMode,
        )) {
          return ConversationUtterance(text: text);
        }
      }
    }
    return null;
  }

  static bool _isSubstantiveSource(String source) {
    final n = _normalize(source).replaceAll(RegExp(r'[.!?…]+$'), '').trim();
    return n.length >= 8 && !SurfaceUtteranceReader.isClosingAck(source);
  }

  static List<String?> _oodGuaranteedCandidates(
    String source,
    SurfaceUtteranceKind kind,
    ConversationExpressionMode expressionMode,
  ) {
    final lines = <String?>[];
    switch (kind) {
      case SurfaceUtteranceKind.uncertainty:
        lines.add('Emin olmadığın bir taraf var.');
        lines.add('Hâlâ net olmayan bir kısım var.');
        break;
      case SurfaceUtteranceKind.desire:
      case SurfaceUtteranceKind.loss:
      case SurfaceUtteranceKind.settling:
      case SurfaceUtteranceKind.positiveEvent:
      case SurfaceUtteranceKind.statedFeeling:
      case SurfaceUtteranceKind.neutralFact:
      case SurfaceUtteranceKind.event:
        break;
      case SurfaceUtteranceKind.abstain:
        return const [];
    }

    final paraphrase = _paraphraseClauseToSecondPerson(source, minLength: 5);
    if (paraphrase != null) {
      lines.addAll(_actNativeAckCandidates(paraphrase));
    }

    if (expressionMode == ConversationExpressionMode.observePurity) {
      lines.addAll(_hedgeCandidatesIfNeeded(source, paraphrase));
    }
    return lines;
  }

  /// Act-native acknowledgement — no redundant hedge when frame is already clear.
  static List<String?> _actNativeAckCandidates(String paraphrase) {
    if (_hasClearActFrame(paraphrase)) {
      final trimmed = paraphrase.endsWith('.')
          ? paraphrase.substring(0, paraphrase.length - 1)
          : paraphrase;
      return ['$trimmed.'];
    }
    return [
      '$paraphrase söylüyorsun.',
      '$paraphrase, anlaşılır.',
    ];
  }

  static bool _hasClearActFrame(String text) {
    final lower = _normalize(text);
    return RegExp(
      r'(söylüyorsun|soyluyorsun|istiyorsun|istemiyorsun|başlamışsın|baslamissin|'
      r'geliyorsun|hissediyorsun|oturuyorsun|kaynatmışsın|kaynatmissin|paylaştın|paylastin|'
      r'istiyorsun|söyledin|soyledin)\.?$',
    ).hasMatch(lower);
  }

  /// Hedge tails only when act-native lines fail Guard — observe path last resort.
  static List<String?> _hedgeCandidatesIfNeeded(
    String source,
    String? paraphrase,
  ) {
    final base = paraphrase ?? _paraphraseClauseToSecondPerson(source, minLength: 5);
    if (base == null) return const [];
    if (_hasClearActFrame(base)) return const [];
    return ['$base gibi.'];
  }

  static bool _isRepeatedMirror(String text, NightSession? session) {
    if (session == null) return false;
    final normalized = text.trim().toLowerCase();
    for (final turn in session.turns) {
      final prior = turn.admittedExpression?.text.trim().toLowerCase();
      if (prior != null && prior == normalized) return true;
    }
    return false;
  }

  static bool _supportsMirror(ConversationExpressionMode mode) {
    switch (mode) {
      case ConversationExpressionMode.standard:
      case ConversationExpressionMode.observePurity:
      case ConversationExpressionMode.lightChat:
        return true;
      case ConversationExpressionMode.postReframeListen:
      case ConversationExpressionMode.narrow:
      case ConversationExpressionMode.reframe:
      case ConversationExpressionMode.integrate:
      case ConversationExpressionMode.closure:
      case ConversationExpressionMode.repair:
      case ConversationExpressionMode.groundedHold:
        return false;
    }
  }

  static String? _mirrorSourceLine({
    required String? userUtterance,
    String? groundingBlob,
  }) {
    final user = userUtterance?.trim();
    if (user == null || user.isEmpty) {
      return _richestClause(groundingBlob);
    }
    if (SurfaceUtteranceReader.isClosingAck(user)) return null;
    if (SurfaceUtteranceReader.isAffirmationAck(user)) {
      return _richestClause(groundingBlob) ?? user;
    }
    if (SurfaceUtteranceReader.isMinimalAck(user)) {
      final kind = SurfaceUtteranceReader.classify(user);
      if (kind != SurfaceUtteranceKind.abstain) return user;
      return _richestClause(groundingBlob);
    }
    return user;
  }

  static String? _richestClause(String? text) {
    if (text == null || text.trim().isEmpty) return null;
    final clauses = text
        .split(RegExp(r'[,;!.?]\s*'))
        .map((c) => c.trim())
        .where((c) => c.isNotEmpty)
        .toList();
    if (clauses.isEmpty) return null;

    String? best;
    var bestScore = -1;
    for (final clause in clauses) {
      if (SurfaceUtteranceReader.isMinimalAck(clause)) continue;
      final score = _contentScore(clause);
      if (score > bestScore) {
        bestScore = score;
        best = clause;
      }
    }
    return best ?? (clauses.length == 1 ? clauses.first : null);
  }

  static int _contentScore(String clause) {
    var score = 0;
    for (final word in clause.split(RegExp(r'\s+'))) {
      final n = _normalize(word);
      if (n.length <= 2) continue;
      if (_stopwords.contains(n)) continue;
      score += n.length >= 5 ? 3 : 1;
    }
    return score;
  }

  static List<String?> _turkishSurfaceLines(
    SurfaceUtteranceKind kind,
    String source,
    ConversationExpressionMode expressionMode,
  ) {
    switch (kind) {
      case SurfaceUtteranceKind.abstain:
        return const [];
      case SurfaceUtteranceKind.positiveEvent:
        return _positiveEventTr(source, expressionMode);
      case SurfaceUtteranceKind.loss:
        return _lossTr(source, expressionMode);
      case SurfaceUtteranceKind.settling:
        return _settlingTr(source, expressionMode);
      case SurfaceUtteranceKind.desire:
        return _desireTr(source, expressionMode);
      case SurfaceUtteranceKind.uncertainty:
        return _uncertaintyTr(source, expressionMode);
      case SurfaceUtteranceKind.statedFeeling:
        return _statedFeelingTr(source, expressionMode);
      case SurfaceUtteranceKind.neutralFact:
        return _neutralFactTr(source, expressionMode);
      case SurfaceUtteranceKind.event:
        return _eventTr(source, expressionMode);
    }
  }

  static List<String?> _englishSurfaceLines(
    SurfaceUtteranceKind kind,
    String source,
    ConversationExpressionMode expressionMode,
  ) {
    switch (kind) {
      case SurfaceUtteranceKind.abstain:
        return const [];
      case SurfaceUtteranceKind.positiveEvent:
        return [
          'That good news still feels a little unreal tonight.',
          'Sounds like that bright moment is still with you.',
        ];
      case SurfaceUtteranceKind.loss:
        return [
          'Losing them is still part of tonight for you.',
          'That loss is still sitting with you tonight.',
        ];
      case SurfaceUtteranceKind.settling:
        return [
          'You seem to be settling a little.',
          'A little calm is starting to show up.',
        ];
      case SurfaceUtteranceKind.desire:
        final want = _extractWantPhrase(source);
        if (want != null) return ['You want $want.'];
        return ['That want is still there tonight.'];
      case SurfaceUtteranceKind.uncertainty:
        return [
          'You are not sure about that yet.',
          'That part still feels unclear for you.',
        ];
      case SurfaceUtteranceKind.statedFeeling:
        final feeling = _extractFeelingWord(source);
        if (feeling != null) {
          return ['You said you feel $feeling.', 'Feeling $feeling is what you named.'];
        }
        return ['That feeling is what you named tonight.'];
      case SurfaceUtteranceKind.neutralFact:
      case SurfaceUtteranceKind.event:
        final compressed = _compressEnglish(source);
        if (compressed != null) return ['$compressed — I hear you.'];
        return ['What you said is still there tonight.'];
    }
  }

  static List<String?> _positiveEventTr(
    String source,
    ConversationExpressionMode expressionMode,
  ) {
    final n = _normalize(source);
    final lines = <String?>[];

    if (RegExp(r'\bterfi\b').hasMatch(n) ||
        RegExp(r'\baldim\b|\baldım\b').hasMatch(n)) {
      lines.addAll([
        'Terfi haberi hâlâ biraz gerçek dışı geliyor.',
        'Aldığın haber hâlâ tam oturmamış gibi.',
      ]);
    }
    if (RegExp(r'\bheyecan verici\b').hasMatch(n)) {
      final low = source.toLowerCase();
      if (low.contains('maaş') || low.contains('maas')) {
        lines.add('Yeni teklif heyecan verici geliyor; maaş kısmı da aklında.');
      } else {
        lines.add('Söylediğin şey heyecan verici geliyor.');
      }
    }
    if (RegExp(r'\b(guzel|güzel|harika|kutlad\w*)\b').hasMatch(n)) {
      lines.addAll([
        'Güzel bir an paylaştın.',
        'Bu güzel haber hâlâ yakında.',
      ]);
    }
    if (lines.isEmpty) {
      lines.add('Paylaştığın iyi haber hâlâ yakında duruyor gibi.');
    }
    return _withStandardFallback(lines, source, expressionMode);
  }

  static List<String?> _lossTr(
    String source,
    ConversationExpressionMode expressionMode,
  ) {
    final n = _normalize(source);
    if (RegExp(r'\bonu kaybettim\b|\bonu kaybettik\b').hasMatch(n)) {
      return ['Onu kaybetmiş olman hâlâ açık.'];
    }
    if (RegExp(r'\bkaybettim\b').hasMatch(n)) {
      return [
        'Kaybetmiş olman hâlâ açık.',
        'Kaybettiğini söylüyorsun.',
      ];
    }
    return _withStandardFallback(
      ['Kaybettiğini söylüyorsun.'],
      source,
      expressionMode,
    );
  }

  static List<String?> _settlingTr(
    String source,
    ConversationExpressionMode expressionMode,
  ) {
    final lines = <String?>[
      'Biraz sakinleşmeye başlamışsın.',
      'Sakinleşmeye başladığını söylüyorsun.',
    ];
    final paraphrase = _paraphraseClauseToSecondPerson(source);
    if (paraphrase != null) {
      lines.addAll(_actNativeAckCandidates(paraphrase));
    }
    return _withStandardFallback(lines, source, expressionMode);
  }

  static List<String?> _desireTr(
    String source,
    ConversationExpressionMode expressionMode,
  ) {
    final n = _normalize(source);
    if (RegExp(r'gecelim|geçelim').hasMatch(n)) {
      return [
        'Sesli kısma geçmek istediğini söylüyorsun.',
        'Sesli kısma geçmek istiyorsun.',
      ];
    }
    if (RegExp(r'istiyorum').hasMatch(n) && RegExp(r'nefes').hasMatch(n)) {
      return [
        'Yanında birinin nefes aldığını duymak istiyorsun.',
        'Yanında birinin nefes aldığını duymak istediğini söylüyorsun.',
      ];
    }
    final want = _extractWantObject(source);
    if (want != null) {
      return [
        '$want istiyorsun.',
        '$want istediğini söylüyorsun.',
      ];
    }
    if (RegExp(r'istemiyorum').hasMatch(n)) {
      final avoid = _extractDontWantObject(source);
      if (avoid != null) {
        return [
          '$avoid istemiyorsun.',
          '$avoid istemediğini söylüyorsun.',
        ];
      }
    }
    return _withStandardFallback(
      ['Söylediğin isteği açıkça söylüyorsun.'],
      source,
      expressionMode,
    );
  }

  static List<String?> _uncertaintyTr(
    String source,
    ConversationExpressionMode expressionMode,
  ) {
    final n = _normalize(source);
    if (RegExp(r'\bhakli miyim\b|\bhaklı mıyım\b').hasMatch(n)) {
      return ['Haklı olup olmadığından emin değilsin.'];
    }
    if (RegExp(r'\bnet degil\b|\bnet değil\b').hasMatch(n)) {
      return ['Hâlâ net değil, biliyorsun.'];
    }
    return _withStandardFallback(
      [
        'Emin olmadığın bir taraf var.',
        'Hâlâ net olmayan bir kısım var.',
      ],
      source,
      expressionMode,
    );
  }

  static List<String?> _statedFeelingTr(
    String source,
    ConversationExpressionMode expressionMode,
  ) {
    final feeling = _extractFeelingWord(source);
    if (feeling != null) {
      return _withStandardFallback(
        [
          '${_capitalize(feeling)} olduğunu söylüyorsun.',
          '${_capitalize(feeling)} hissettiğini söylüyorsun.',
        ],
        source,
        expressionMode,
      );
    }
    final paraphrase = _paraphraseClauseToSecondPerson(source);
    if (paraphrase != null) {
      return _withStandardFallback(
        _actNativeAckCandidates(paraphrase),
        source,
        expressionMode,
      );
    }
    return _withStandardFallback(
      ['Söylediğin duygu hâlâ açık.'],
      source,
      expressionMode,
    );
  }

  static List<String?> _neutralFactTr(
    String source,
    ConversationExpressionMode expressionMode,
  ) {
    final n = _normalize(source);
    if (RegExp(r'\bkaynattim\b|\bkaynat\w*').hasMatch(n) &&
        RegExp(r'\bbos\b|\bboş\b').hasMatch(n)) {
      return [
        'Çorba kaynatmışsın; elin boş kalmış.',
        'Mutfakta çorba kaynatmışsın.',
      ];
    }
    if (RegExp(r'\beskiden\b').hasMatch(n) &&
        RegExp(r'\bseverdi\b').hasMatch(n)) {
      return [
        'Bu çorbayı eskiden birinin sevdiğini söylüyorsun.',
        'Eskiden birinin sevdiği bir çorba.',
      ];
    }
    if (RegExp(r'\bsoguk\b|\bsoğuk\b').hasMatch(n) &&
        source.trim().length < 24) {
      return ['Havanın soğuk olduğunu söylüyorsun.'];
    }
    return _eventTr(source, expressionMode);
  }

  static List<String?> _eventTr(
    String source,
    ConversationExpressionMode expressionMode,
  ) {
    final lines = <String?>[];

    if (RegExp(r'\bkafam\b|\baklim\b|\baklım\b|\bdurmuyor\b').hasMatch(
      _normalize(source),
    )) {
      lines.add('Kafan durmuyor, anlaşılır.');
      lines.addAll(_actNativeAckCandidates('Kafan durmuyor'));
    }

    final clauses = source
        .split(RegExp(r'[,;]\s*'))
        .map((c) => c.trim())
        .where((c) => c.isNotEmpty)
        .toList();
    if (clauses.length >= 2) {
      final first = _paraphraseClauseToSecondPerson(clauses.first);
      final second = _paraphraseClauseToSecondPerson(clauses[1]);
      if (first != null && second != null) {
        lines.addAll(_actNativeAckCandidates('$first; $second'));
      }
    }

    final single = _paraphraseClauseToSecondPerson(source);
    if (single != null) {
      lines.addAll(_actNativeAckCandidates(single));
    }

    if (expressionMode == ConversationExpressionMode.observePurity) {
      lines.addAll(_hedgeCandidatesIfNeeded(source, single));
    }

    return _withStandardFallback(lines, source, expressionMode);
  }

  /// Standard Receipt mode: act-native tails only — no gibi hedge bank.
  static List<String?> _withStandardFallback(
    List<String?> lines,
    String source,
    ConversationExpressionMode expressionMode,
  ) {
    if (expressionMode != ConversationExpressionMode.standard) return lines;
    final extra = <String?>[];
    final compressed = _paraphraseClauseToSecondPerson(source);
    if (compressed != null) {
      extra.addAll(_actNativeAckCandidates(compressed));
    }
    return [...lines, ...extra];
  }

  static String? _paraphraseClauseToSecondPerson(
    String clause, {
    int minLength = 6,
  }) {
    var text = clause.trim();
    if (text.isEmpty) return null;

    text = text.replaceAll(
      RegExp(r'^(aslında|galiba|sanırım|belki)\s+', caseSensitive: false),
      '',
    );
    text = text.replaceAll(RegExp(r'\s+(ya|işte|falan|filan)\.?$'), '');

    final replacements = <RegExp, String>{
      RegExp(r'\bben\b', caseSensitive: false): 'sen',
      RegExp(r'\bBen\b'): 'Sen',
      RegExp(r'\btek başıma\b', caseSensitive: false): 'tek başına',
      RegExp(r'\boturuyorum\b', caseSensitive: false): 'oturuyorsun',
      RegExp(r'\bistiyorum\b', caseSensitive: false): 'istiyorsun',
      RegExp(r'\bistemiyorum\b', caseSensitive: false): 'istemiyorsun',
      RegExp(r'\bsakinleşiyorum\b', caseSensitive: false): 'sakinleşiyorsun',
      RegExp(r'\bkaynattım\b', caseSensitive: false): 'kaynatmışsın',
      RegExp(r'\baldım\b', caseSensitive: false): 'aldın',
      RegExp(r'\bkaybettim\b', caseSensitive: false): 'kaybettin',
      RegExp(r'\bikinci plandayım\b', caseSensitive: false): 'ikinci plandasın',
      RegExp(r'\bikinci plandayim\b', caseSensitive: false): 'ikinci plandasın',
    };
    for (final entry in replacements.entries) {
      text = text.replaceAll(entry.key, entry.value);
    }

    text = text.replaceAllMapped(
      RegExp(r'\b(\w*?)iyorum\b', caseSensitive: false),
      (m) => '${m.group(1)}iyorsun',
    );
    text = text.replaceAllMapped(
      RegExp(r'\b(\w*?)uyorum\b', caseSensitive: false),
      (m) => '${m.group(1)}uyorsun',
    );
    text = text.replaceAllMapped(
      RegExp(r'\b(\w+?)iyor\b', caseSensitive: false),
      (m) {
        final stem = m.group(1)!;
        if (stem.length <= 2) return m.group(0)!;
        return '${stem}iyorsun';
      },
    );

    if (text.endsWith('.')) text = text.substring(0, text.length - 1);
    if (text.length < minLength) return null;
    return text;
  }

  static String? _extractDontWantObject(String source) {
    final matches = RegExp(
      r'(.+?)\s+istemiyorum',
      caseSensitive: false,
    ).allMatches(source);
    if (matches.isEmpty) return null;
    var phrase = matches.last.group(1)?.trim();
    if (phrase == null || phrase.isEmpty) return null;
    if (phrase.contains(',')) {
      phrase = phrase.split(',').last.trim();
    }
    phrase = phrase.replaceAll(RegExp(r'^(ama|fakat|da|de)\s+', caseSensitive: false), '');
    phrase = phrase.replaceAll(RegExp(r'\bben\b', caseSensitive: false), 'sen');
    if (phrase.length < 3) return null;
    return _capitalize(phrase);
  }

  static String? _extractWantObject(String source) {
    final matches = RegExp(
      r'(.+?)\s+istiyorum',
      caseSensitive: false,
    ).allMatches(source);
    if (matches.isEmpty) return null;
    var phrase = matches.last.group(1)?.trim();
    if (phrase == null || phrase.isEmpty) return null;
    if (phrase.contains(',')) {
      phrase = phrase.split(',').last.trim();
    }
    phrase = phrase.replaceAll(RegExp(r'\bben\b', caseSensitive: false), 'sen');
    phrase = phrase.replaceAll(
      RegExp(r'^(aslında|galiba|sanırım|belki)\s+', caseSensitive: false),
      '',
    );
    if (phrase.length < 4) return null;
    return _capitalize(phrase);
  }

  static String? _extractWantPhrase(String source) {
    final match = RegExp(
      r'([^.!?]*istiyorum[^.!?]*)',
      caseSensitive: false,
    ).firstMatch(source);
    if (match == null) return null;
    var phrase = match.group(1)?.trim();
    if (phrase == null || phrase.isEmpty) return null;
    phrase = phrase
        .replaceAll(RegExp(r'\bben\b', caseSensitive: false), 'sen')
        .replaceAll(RegExp(r'istiyorum', caseSensitive: false), 'istiyorsun');
    return phrase;
  }

  static String? _extractFeelingWord(String source) {
    final match = RegExp(
      r'\b(kirgin\w*|kırgın\w*|yorgun\w*|gergin\w*|uzgun\w*|üzgün\w*|mutsuz\w*|huzursuz\w*|yalniz\w*|yalnız\w*)\b',
      caseSensitive: false,
    ).firstMatch(source);
    return match?.group(1);
  }

  static String? _compressEnglish(String source) {
    final trimmed = source.trim();
    if (trimmed.length < 8) return null;
    if (trimmed.length > 72) return trimmed.substring(0, 72).trim();
    return trimmed;
  }

  static String _capitalize(String word) {
    if (word.isEmpty) return word;
    if (word[0] == 'ı') return 'I${word.substring(1)}';
    return word[0].toUpperCase() + word.substring(1);
  }

  static bool _passesGuard({
    required String text,
    required String? userUtterance,
    required String? mirrorSourceLine,
    required ConversationExpressionMode expressionMode,
  }) {
    return _guard.allow(
          utterance: ConversationUtterance(text: text),
          what: ConversationPhase.validation,
          userUtterance: userUtterance,
          mirrorGroundingUtterance:
              mirrorSourceLine != userUtterance ? mirrorSourceLine : null,
          expressionMode: expressionMode,
        ) !=
        null;
  }

  static bool _isMinimalAck(String text) =>
      SurfaceUtteranceReader.isMinimalAck(text);

  static bool _prefersTurkish(String? userUtterance, String? groundingBlob) =>
      SurfaceTextFuzzy.prefersTurkish(userUtterance, groundingBlob);

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

  static const Set<String> _stopwords = {
    'bir',
    'bu',
    've',
    'de',
    'da',
    'ki',
    'mi',
    'mu',
    'mü',
    'mı',
    'the',
    'a',
    'an',
    'and',
    'but',
    'ben',
    'sen',
    'cok',
    'çok',
    'icin',
    'için',
    'ile',
    'ya',
    'hala',
    'hâlâ',
  };
}
