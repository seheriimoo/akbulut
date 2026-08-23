import 'conversation_blueprint_binding.dart';
import 'conversation_grounding_buffer.dart';
import 'light_conversation_detector.dart';
import 'prior_admitted_expression.dart';
import 'receipt_realization_contract.dart';
import 'thinking_function_hypothesis.dart';
import 'thinking_function_intelligence_shaping.dart';

/// Receipt Intelligence V1.6 (Golden Conversations V2 Voice)
///
/// Deterministic Receipt-only compilation aid inside Conversation Compiler.
/// Optimizes for a First Stop Moment: the person feels
/// "Yes. That's exactly it."
///
/// Steers toward Golden Conversations V2 short-line cadence + soft reframe
/// TYPE — never pastes canned Gold library lines.
///
/// Optional [ThinkingFunctionHypothesis] (supported+) MUST realize exactly ONE
/// soft functional recognition hinge — HOW only. Never chooses WHAT, phase,
/// readiness, exit, or memory. Null/tentative preserves texture-first Receipt.
///
/// Current-turn grounding source: admitted [ConversationGroundingBuffer] only.
/// Standalone livedExpression is not used.
class ReceiptIntelligence {
  const ReceiptIntelligence({
    this.lightConversation = const LightConversationDetector(),
  });

  final LightConversationDetector lightConversation;

  static const String version = '1.6';

  /// Soft upper bound for current-turn grounding text in compile output.
  static const int maxCurrentGroundingChars = 480;

  static const String _responseLengthShort =
      'Two short sentences, maximum 45 words. '
      'Golden Conversations V2 cadence: one specific observe, one hinge. '
      'Not a telegram. Not one dense clinical paragraph.';

  static const String _responseLengthSupportedFunctional =
      'Three to five short sentences, maximum 60 words. '
      'Golden Conversations V2 cadence with exactly one soft functional hinge '
      'and one soft reframe. Do not pad with essay explanation.';

  /// Compile Receipt-specific instruction material for the sealed Receipt stage.
  ///
  /// [conversationGrounding] is optional admitted same-night grounding.
  /// [thinkingFunctionHypothesis] is optional cognition/shaping evidence only.
  ReceiptCompileSlice compile({
    required BlueprintStageBinding stage,
    ConversationGroundingBuffer? conversationGrounding,
    ThinkingFunctionHypothesis? thinkingFunctionHypothesis,
    PriorAdmittedExpression? priorAdmittedExpression,
  }) {
    assert(stage.stage == BlueprintStage.receipt);

    final currentTurn = _currentTurnGrounding(conversationGrounding);
    final isLightTurn = currentTurn != null &&
        lightConversation.isLightConversation(currentTurn);
    final supportedFunctional = !isLightTurn &&
        ThinkingFunctionIntelligenceShaping.isSupportedOrStrong(
      thinkingFunctionHypothesis,
    );
    final forbidden = <String>[
      ...stage.forbiddenMoves,
      ..._receiptIntelligenceForbidden,
      ...ReceiptRealizationContract.intelligenceForbiddenMoves(),
      if (isLightTurn) ..._lightConversationForbidden,
      if (supportedFunctional) ..._supportedFunctionalForbidden,
    ];

    return ReceiptCompileSlice(
      aim: isLightTurn
          ? _aimLight
          : (supportedFunctional ? _aimSupportedFunctional : _aim),
      sealedWhatSignature: isLightTurn
          ? _sealedWhatSignatureLight
          : (supportedFunctional
              ? _sealedWhatSignatureSupportedFunctional
              : _sealedWhatSignature),
      forbiddenMoves: forbidden,
      responseLength: isLightTurn
          ? _responseLengthLight
          : (supportedFunctional
              ? _responseLengthSupportedFunctional
              : _responseLengthShort),
      fsmDirective: isLightTurn ? _lightReceiptDirective : _fsmDirective,
      realizationDirective: _realizationDirective,
      userContent: _userContent(
        currentTurn: currentTurn,
        hypothesis: thinkingFunctionHypothesis,
        supportedFunctional: supportedFunctional,
        priorAdmittedExpression: priorAdmittedExpression,
        isLightTurn: isLightTurn,
      ),
      systemAppendix: _systemAppendix(
        currentTurn: currentTurn,
        hypothesis: thinkingFunctionHypothesis,
        supportedFunctional: supportedFunctional,
        priorAdmittedExpression: priorAdmittedExpression,
        isLightTurn: isLightTurn,
      ),
    );
  }

  static const String _aimLight =
      'Receive positive, mundane, playful, or chat-only warmth with one brief '
      'natural line. Do not invert their tone into distress or night-load.';

  static const String _sealedWhatSignatureLight =
      'validation / Receipt — brief warm acknowledgment only. Do not receive '
      'positive or everyday content as burden, worry, or something heavy.';

  static const String _responseLengthLight =
      'Exactly one short sentence, maximum 16 words. Warm, plain, unforced.';

  static const String _lightReceiptDirective =
      'Light-turn Receipt: mirror their warmth or everyday detail briefly. '
      'Never use Belki/Sanki difficulty frames, “zor geliyor”, “ağır geliyor”, '
      '“yük”, permission-ease, or put-down language on clearly positive or '
      'mundane content.';

  static const List<String> _lightConversationForbidden = [
    'Inverting positive or mundane content into distress or night-load',
    '“zor geliyor”, “ağır geliyor”, “yük”, “burden”, “heavy”, “hard”',
    'Permission-ease: “gerekmiyor”, “düşünmene gerek yok”, “don’t have to think”',
    'Release / put-down: “bırak”, “let go”, “leave it here”',
    'Belki/Sanki difficulty reframes on clearly positive turns',
    'Inventing worry about tomorrow when they named a mundane plan only',
  ];

  static const String _aim =
      'Create a First Stop Moment: accurate felt receipt of the lived '
      'emotional texture so the person could think “Yes. That’s exactly it.” '
      'Receive only—nothing more.';

  static const String _aimSupportedFunctional =
      'Create a First Stop Moment that MUST realize exactly one soft '
      'functional recognition hinge: notice the function of continued '
      'thinking beneath the surface words—without essay, Naming, Permission, '
      'or Release drift.';

  static const String _sealedWhatSignature =
      'validation / Receipt — concrete felt receipt of this turn’s lived '
      'texture without naming it as a holdable load, granting permission, '
      'inviting release, or closing. Prefer texture-first natural receipt; '
      'do not depend on a “That sounds…” template. Mirror emotional texture; '
      'do not parrot. Do not invent stillness, presence, or motives. '
      'Bare fillers alone are forbidden.';

  static const String _sealedWhatSignatureSupportedFunctional =
      'validation / Receipt — felt receipt that MUST include exactly one soft '
      'functional recognition hinge about the authorized night mind-job. Stay '
      'epistemically soft. Do not collapse into Naming, Permission, or Release. '
      'Do not diagnose. Do not invent hard motives or story. Prefer function '
      'recognition over surface paraphrase. Activation description is texture, '
      'not recognition.';

  static const String _fsmDirective =
      'First Stop Moment (Receipt only): the utterance must make the person '
      'feel precisely met—not generically acknowledged. '
      'Reflect the feeling under their words in fresh, plain wording. '
      'Stay specific enough to be personal, light enough to stay holdable. '
      'Prefer V2 soft reframe TYPE: soft observe → soft difficulty → '
      '“Perhaps… / It may be…” (or Turkish “Belki… / Sanki…”). '
      'Vary openers; do not restamp “Part of your mind…” every turn. '
      'CRITICAL — never write Naming stems inside Receipt: '
      '“on your mind”, “holding on”, “weighing”, “still there”, “lingering”. '
      'Say “swirling / racing / heavy / looping / overthinking” instead. '
      'CRITICAL — never open with “It sounds like” / “It seems like”. '
      'Start from their night-object (tomorrow / the list / the person). '
      'Two sentences: one specific observe + one hinge. Then stop. '
      'Never invent stillness, presence, mindfulness, or inner peace. '
      'Never mention sleep commands or “uykuya / go to sleep / fall asleep”. '
      'Prefer racing / looping / heavy / exhausting / overthinking / yalnız '
      'textures with soft frames. '
      'For Turkish, prefer classic soft stems when natural: '
      '“ağır geliyor” / “zor geliyor” / “anlıyorum…” + texture / '
      '“Sanki… / Belki…”. '
      'Mirror their language (English or Turkish).';

  static const String _realizationDirective =
      'Realize only the sealed WHAT (validation / receipt) as exactly one '
      'short utterance. Create a First Stop Moment. '
      'Do not drift into Naming, Permission, Release, Enough, or another WHAT. '
      'Do not choose release, protocol, exit, or silence.';

  static const List<String> _receiptIntelligenceForbidden = [
    'Bare generic fillers alone: “I understand”, “I hear you”, “That makes sense”',
    'Using “I understand” / “I hear you” / “That makes sense” / “I hear that” '
        'unless immediately followed in the same sentence by concrete, '
        'user-specific lived texture',
    'Defaulting to a dense clinical paragraph (“making it hard to find rest… '
        'it’s a lot to hold onto”) instead of short V2 lines',
    'Category remapping: do not translate their words into a different emotion '
        'label (e.g. spiraling → “overwhelmed”, stressed → “anxious”). Stay '
        'inside their texture',
    'Therapist-cadence openers that diagnose feeling: '
        '“It sounds like you’re feeling…”, “You’re feeling… right now”, '
        '“That must be…”',
    'Opening with “It sounds like” / “It seems like”',
    'Emitting “I’m preparing a session for you now” inside Receipt speech',
    'Pasting canned Golden Conversations V2 / Gold Standard library lines '
        'verbatim as the only form',
    'Intensifiers the person did not use: really / so / deeply / incredibly / '
        'extremely',
    'Near-parroting: repeating their distinctive wording, clause, or phrase '
        'back as padding (especially place/alone/miss phrasing)',
    'Inventing stillness, presence, mindfulness, hard motives, diagnosis, or '
        'story they did not say',
    'Naming the load as a holdable object (Naming stage drift)',
    'Advice, positivity reframes, plans, or techniques',
    'Toxic-positivity or cheer-up reframes that erase the load',
    'Questions of any kind',
    'Unsupported verbatim parroting of the user’s wording as padding',
    'Emitting internal cognition labels or camelCase kind ids in speech',
    'Defaulting twice to the same opener (“Part of your mind…”) in one night',
    'Protective-explanation padding after the reframe already landed '
        '(“your thoughts are just trying to protect you”)',
    'Sleep / insomnia coaching drift (“uykuya dal”, “go to sleep”, '
        '“fall asleep”, “hard to sleep”) inside Receipt',
    'Inventing tomorrow / yarın / a future scene / “what’s to come” when '
        'those objects are absent from current-turn grounding',
    'Inventing racing / swirling / spinning thoughts when this turn does '
        'not name thought-motion',
    'Answering a Turkish night in English, or an English night in Turkish',
    'Anti-stack: restating the same felt load three ways (overwhelming + '
        'hard to rest + a lot to carry) after the observe already landed',
    'Generic remap of their night-objects into stock load (“on your plate”, '
        '“a lot to carry”, “overwhelming”) when they named tomorrow, a list, '
        'tasks, a person, or a place',
  ];

  static const List<String> _supportedFunctionalForbidden = [
    'Paraphrase-only / surface-motion-only Receipt when a functional hinge '
        'is required',
    'Stopping at activation paraphrase (swirling / racing / spinning / busy / '
        'looping) when an authorized function hypothesis exists',
    'Treating motion/activation description as sufficient recognition',
    'Satisfying the hinge with activation + topic alone '
        '(e.g. busy/swirl/race/spin + tomorrow) without the authorized '
        'functional recognition',
    'Merely describing mental motion around the user’s topic when a '
        'supported function hypothesis exists',
    'Mechanism essays or stacked interpretations in Receipt',
    'Collapsing Naming / Permission / Release into Receipt',
    'Hard certainty about why they think (diagnosis / motive fact)',
    'Canned Gold dialogue lines or reply-bank copy',
  ];

  String _userContent({
    required String? currentTurn,
    required ThinkingFunctionHypothesis? hypothesis,
    required bool supportedFunctional,
    PriorAdmittedExpression? priorAdmittedExpression,
    required bool isLightTurn,
  }) {
    final buffer = StringBuffer()
      ..writeln(_realizationDirective)
      ..writeln()
      ..writeln(isLightTurn ? _lightReceiptDirective : _fsmDirective);

    if (!isLightTurn) {
      buffer
        ..writeln()
        ..writeln(
          _shapeDirective(
            currentTurn: currentTurn,
            supportedFunctional: supportedFunctional,
          ),
        );
    }

    if (supportedFunctional && hypothesis != null) {
      buffer
        ..writeln()
        ..writeln(
          ThinkingFunctionIntelligenceShaping.receiptHingeDirective(
            hypothesis,
          ),
        );
    }

    if (priorAdmittedExpression != null) {
      buffer
        ..writeln()
        ..writeln(priorAdmittedExpression.antiRepeatDirective())
        ..writeln(
          'Same-night Receipt note: vary the opener; do not restamp the same '
          '“Part of your mind…” / identical soft-frame start.',
        );
    }

    buffer
      ..writeln()
      ..writeln(_languageDirective(currentTurn))
      ..writeln()
      ..writeln(_antiInventionDirective(currentTurn));

    if (currentTurn != null) {
      buffer
        ..writeln()
        ..writeln(
          'Current-turn conversation grounding to receive (shaping only; '
          'never authority; do not parrot; do not analyze; do not infer; '
          'do not summarize):',
        )
        ..writeln('"""')
        ..writeln(currentTurn)
        ..writeln('"""');
    } else {
      buffer
        ..writeln()
        ..writeln(
          'No current-turn conversation grounding was supplied. Still avoid '
          'bare generic filler; prefer concrete felt receipt if any shaping '
          'context exists. Do not invent grounding.',
        );
    }

    return buffer.toString().trimRight();
  }

  String _shapeDirective({
    required String? currentTurn,
    required bool supportedFunctional,
  }) {
    final relational = currentTurn != null && _looksRelational(currentTurn)
        ? ' Relational note: longing / missing / absence texture is present—'
            'receive that bond-ache lightly without inventing who they are or '
            'why they left.'
        : '';

    final sparse = currentTurn != null && _looksSparse(currentTurn)
        ? ' Sparse-message restraint: their words are thin or filler '
            '(idk / bilmiyorum / hm / I don’t know). Receive only what is '
            'plainly there. Do not invent stillness, presence, calm, or '
            'inner peace. HARD: do not invent night-objects absent from THIS '
            'turn — tomorrow, yarın, a list, a meeting, a relationship, '
            'racing/swirling thoughts, or a future scene.'
        : '';

    final nightObject = currentTurn != null && _looksNightObject(currentTurn)
        ? ' Night-object rule: keep their named object (tomorrow / the list / '
            'the tasks / the person) in the observe. Do not replace it with '
            'generic overwhelm, plate, or carry padding.'
        : '';

    final lengthLine = supportedFunctional
        ? 'Three to five short sentences (max 60 words). '
            'Golden Conversations V2 cadence: short lines + one soft functional '
            'hinge + one soft reframe. Not one dense paragraph.'
        : 'Two short sentences (max 45 words). '
            'Golden Conversations V2 cadence: one specific observe, then one hinge. '
            'Not a telegram. Not a clinical essay.';

    final depthLine = supportedFunctional
        ? ' Depth rule: MUST realize exactly one soft functional recognition '
            'hinge for the authorized hypothesis. Activation description is '
            'optional supporting texture only—not recognition. The response '
            'fails the Intelligence quality target if it merely describes '
            'mental motion around the user’s topic '
            '(busy/swirl/race/spin + topic alone).'
        : '';

    return '$lengthLine$depthLine Anti-stack rule: two sentences — one specific '
        'observe + one hinge. Then stop. Never a third restatement '
        '(hard to rest / overwhelming / a lot to carry). '
        'Never open with “It sounds like” / “It seems like”. '
        'No advice. No solving. '
        'No question. Prefer texture-first receipt over “It/That sounds…” '
        'templates. Do not remap into a generic feeling label they did not '
        'use. Avoid intensifiers (really / so / deeply). Do not parrot their '
        'distinctive wording. Your only goal is a First Stop Moment.\n\n'
        '${ReceiptRealizationContract.intelligenceSteeringDirective(
          supportedFunctional: supportedFunctional,
        )}'
        '$relational$sparse$nightObject';
  }

  String _systemAppendix({
    required String? currentTurn,
    required ThinkingFunctionHypothesis? hypothesis,
    required bool supportedFunctional,
    PriorAdmittedExpression? priorAdmittedExpression,
    required bool isLightTurn,
  }) {
    if (isLightTurn) {
      return '''
Receipt Intelligence v$version (light turn):
$_lightReceiptDirective
No-invention rule: do not invent distress, burden, worry, or night-load on positive or mundane content.
No-question rule: questions are forbidden.
Drift rule: do not Name, grant Permission, invite Release, or close.
''';
    }

    final fillerRule =
        'Generic filler rule: never emit bare “I understand”, “I hear you”, '
        'or “That makes sense”. Those openers are allowed only when the same '
        'sentence continues with concrete, user-specific receipt of lived texture.';

    final mirrorRule =
        'Mirror rule: reflect emotional texture in fresh wording. '
        'Do not quote them back as padding. Do not escalate into Naming. '
        'If they name missing someone, receive the longing—not a generic '
        '“heavy feeling” alone. If they name loneliness, receive aloneness '
        'without echoing their exact room/alone clause.';

    final remapRule =
        'No-remap rule: never replace their lived texture with a stock emotion '
        'category. If they say spiraling, receive the spiral — not '
        '“overwhelmed”. If they say stressed, receive the stress — not a '
        'different clinical-adjacent label. If they name tomorrow or a list, '
        'keep that object — not “on your plate” / “a lot to carry”.';

    final antiStackRule =
        'Anti-stack rule: two sentences — one specific observe + one hinge. '
        'After the hinge lands, stop. Do not add a third restatement. '
        'Never open with “It sounds like” / “It seems like”.';

    final intensifierRule =
        'Intensifier rule: do not add really / so / deeply / incredibly / '
        'extremely unless the person used that intensity.';

    final restraintRule =
        'Restraint rule: on sparse or ambiguous lines, under-receive rather '
        'than invent psychology, stillness, or presence.';

    final antiInventionRule = _antiInventionDirective(currentTurn);
    final languageRule = _languageDirective(currentTurn);

    final functionRule = supportedFunctional && hypothesis != null
        ? ThinkingFunctionIntelligenceShaping.receiptHingeDirective(hypothesis)
        : 'Thinking-function rule: no supported soft functional hinge for '
            'this compile—stay texture-first; do not invent a mind-job.';

    final antiShallowRule = supportedFunctional
        ? 'Anti-shallow rule: Activation description is optional supporting '
            'texture only. Exactly one functional hinge is mandatory. Do not '
            'stop at describing motion when an authorized function hypothesis '
            'exists. Surface-only swirl / race / spin / busy / loop + topic '
            'paraphrases fail the Intelligence quality target.'
        : 'Anti-shallow rule: with no supported function hypothesis, stay '
            'texture-first; do not invent a mechanism.';

    final softPerspectiveRule = supportedFunctional
        ? 'Soft perspective rule (Golden Conversations V2 TYPE): short lines. '
            'Soft observe → one soft functional hinge → soft reframe '
            '(“Perhaps what feels heavy is not X. It may be Y.”). '
            'Not positivity. Not advice. Not diagnosis. Not an essay paragraph.'
        : 'Soft perspective rule (Golden Conversations V2 TYPE): short lines. '
            'Soft observe, then one soft reframe if already evident in their '
            'words. Do not invent a new angle. Do not write a clinical paragraph.';

    final templateRule =
        'Anti-essay rule: do not collapse into one long sentence with '
        '“making it hard / it’s a lot to hold” padding. '
        'Soft observe openers (“It sounds like…”, “Part of your mind…”) are '
        'legal when they open short V2 lines with concrete texture from THIS '
        'turn — not feeling-diagnosis templates.';

    final antiRepeat = priorAdmittedExpression == null
        ? 'Anti-repeat rule: vary Receipt openers across the night; do not '
            'default to the same “Part of your mind…” start.'
        : priorAdmittedExpression.antiRepeatDirective();

    final grounding = currentTurn == null
        ? 'Conversation grounding (current turn): not supplied for this compile.'
        : 'Conversation grounding (current turn): supplied below in the user '
            'instruction for shaping only.';

    final contractRule = ReceiptRealizationContract.intelligenceSteeringDirective(
      supportedFunctional: supportedFunctional,
    );

    return '''
Receipt Intelligence v$version:
$_fsmDirective
$fillerRule
$mirrorRule
$templateRule
$remapRule
$antiStackRule
$intensifierRule
$restraintRule
$antiInventionRule
$languageRule
$functionRule
$antiShallowRule
$softPerspectiveRule
$antiRepeat
$contractRule
$grounding
''';
  }

  /// Current-turn utterance from admitted grounding only. Never invents.
  String? _currentTurnGrounding(ConversationGroundingBuffer? grounding) {
    if (grounding == null || grounding.isEmpty) return null;
    return _normalizeCurrentTurn(grounding.currentUserUtterance);
  }

  String? _normalizeCurrentTurn(String? raw) {
    if (raw == null) return null;
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return null;
    if (trimmed.length <= maxCurrentGroundingChars) return trimmed;
    return trimmed.substring(0, maxCurrentGroundingChars).trimRight();
  }

  bool _looksRelational(String text) {
    final lower = text.toLowerCase();
    return lower.contains('miss') ||
        lower.contains('missing') ||
        lower.contains('lonely') ||
        lower.contains('alone') ||
        lower.contains('without them') ||
        lower.contains('without him') ||
        lower.contains('without her') ||
        lower.contains('ozledim') ||
        lower.contains('özledim') ||
        lower.contains('yalniz') ||
        lower.contains('yalnız');
  }

  bool _looksSparse(String text) {
    if (_looksFiller(text)) return true;
    final words = text
        .trim()
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .length;
    return words <= 4;
  }

  /// Thin honesty: don't-know / filler turns must not compile a night-story.
  bool _looksFiller(String text) {
    final lower = text.toLowerCase().trim().replaceAll(RegExp(r'[.!?…,]+$'), '');
    if (lower.isEmpty) return true;
    if (RegExp(
      r"^(idk|dunno|hm+|hmm+|bilmiyorum|bilmiyom|bilmem|ne bileyim|"
      r"i don'?t know|i do not know|not sure|no idea|whatever)$",
    ).hasMatch(lower)) {
      return true;
    }
    if (RegExp(
      r"^(idk|bilmiyorum|bilmiyom|hm+|i don'?t know)\b",
    ).hasMatch(lower)) {
      return true;
    }
    return false;
  }

  bool _looksNightObject(String text) {
    final lower = text.toLowerCase();
    return lower.contains('tomorrow') ||
        lower.contains('yarın') ||
        lower.contains('yarin') ||
        lower.contains('have to do') ||
        lower.contains('to-do') ||
        lower.contains('todo') ||
        lower.contains('task') ||
        lower.contains('list') ||
        lower.contains('meeting') ||
        lower.contains('deadline') ||
        lower.contains('toplantı') ||
        lower.contains('toplantida') ||
        lower.contains('sunum') ||
        lower.contains('yapılacak') ||
        lower.contains('yapilacak');
  }

  String _antiInventionDirective(String? currentTurn) {
    final lower = (currentTurn ?? '').toLowerCase();
    final hasTomorrow = lower.contains('tomorrow') ||
        RegExp(r'\byarın\b').hasMatch(lower) ||
        RegExp(r'\byarin\b').hasMatch(lower);
    final hasThoughtMotion = lower.contains('racing') ||
        lower.contains('swirl') ||
        lower.contains('spiral') ||
        lower.contains('loop') ||
        lower.contains('thinking') ||
        lower.contains('düşün') ||
        lower.contains('dusun') ||
        lower.contains('kafa') ||
        lower.contains('zihn') ||
        lower.contains('durmuyor') ||
        lower.contains('overthink');

    final bans = <String>[];
    if (!hasTomorrow) {
      bans.add(
        'tomorrow / yarın / a future scene / “what’s to come” / already '
        'living tomorrow',
      );
    }
    if (!hasThoughtMotion) {
      bans.add('racing / swirling / spinning thoughts');
    }
    if (bans.isEmpty) {
      return 'Anti-invention rule: keep objects that are already in this '
          'turn; do not import a different night-story.';
    }
    return 'Anti-invention rule: this turn does not name ${bans.join('; ')}. '
        'Do not introduce them. Stay inside their actual words. '
        'If the line is only insomnia / don’t-know / don’t-want-to-talk, '
        'receive that — do not import a tomorrow-carry scene they did not name.';
  }

  String _languageDirective(String? currentTurn) {
    final lang = _nightLanguage(currentTurn);
    if (lang == 'tr') {
      return 'Language lock: the person wrote Turkish. Reply in Turkish only. '
          'Do not answer in English.';
    }
    if (lang == 'en') {
      return 'Language lock: the person wrote English. Reply in English only. '
          'Do not answer in Turkish.';
    }
    return 'Language lock: stay in one language. Mirror theirs if it is clear.';
  }

  /// Compact night-language tag from current-turn grounding only.
  String? _nightLanguage(String? text) {
    if (text == null || text.trim().isEmpty) return null;
    final lower = text.toLowerCase();
    final hasTr = RegExp(r'[ğüşıöç]').hasMatch(lower) ||
        lower.contains('gece') ||
        lower.contains('yalniz') ||
        lower.contains('yalnız') ||
        lower.contains('uyuyamiyorum') ||
        lower.contains('uyuyamıyorum') ||
        lower.contains('dusun') ||
        lower.contains('düşün') ||
        lower.contains('konusmak') ||
        lower.contains('konuşmak') ||
        lower.contains('bilmiyorum') ||
        lower.contains('kafam') ||
        lower.contains('aklim') ||
        lower.contains('aklım') ||
        lower.contains('ozledim') ||
        lower.contains('özledim') ||
        lower.contains('durmuyor') ||
        lower.contains('kafayi');
    final hasEn = RegExp(
      r"\b(you|your|the|tonight|don't|need|perhaps|mind|thinking|"
      r"can't|cannot|about|tomorrow|feel|feeling|idk)\b",
    ).hasMatch(lower);
    if (hasTr && hasEn) return 'mixed';
    if (hasTr) return 'tr';
    if (hasEn) return 'en';
    return null;
  }
}

/// Receipt-only compile material produced by [ReceiptIntelligence].
class ReceiptCompileSlice {
  final String aim;
  final String sealedWhatSignature;
  final List<String> forbiddenMoves;
  final String responseLength;
  final String fsmDirective;
  final String realizationDirective;
  final String userContent;
  final String systemAppendix;

  const ReceiptCompileSlice({
    required this.aim,
    required this.sealedWhatSignature,
    required this.forbiddenMoves,
    required this.responseLength,
    required this.fsmDirective,
    required this.realizationDirective,
    required this.userContent,
    required this.systemAppendix,
  });
}
