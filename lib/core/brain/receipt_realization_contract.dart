/// Receipt Realization Contract V1.6
///
/// Single source of truth for V1 Receipt expression shaping and Guard
/// texture-first / soft-functional admission. Shared by [ReceiptIntelligence]
/// and [UtteranceGuard].
///
/// Closed structural contract — not a reply library, not open NLP.
/// Fail-closed: off-contract candidates must not invent admission.
/// Guard remains mechanism-agnostic: soft-functional forms are structural,
/// not psychological scoring.
class ReceiptRealizationContract {
  const ReceiptRealizationContract._();

  static const String version = '1.6';

  /// Classic soft stems — still legal Receipt admission paths.
  static const List<String> classicStems = [
    'makes sense',
    'understand',
    'hear you',
    'hear that',
    'that sounds',
    'it sounds',
    "that's hard",
    'thats hard',
    // Turkish classic soft receipt
    'anlıyorum',
    'anliyorum',
    'duyuyorum',
    'zor geliyor',
    'ağır geliyor',
    'gibi geliyor',
    'anlaşılır',
    'anlasilir',
  ];

  /// Soft receipt frames for texture-first realization.
  /// Narrow structural frames only — never a bare "mind" wildcard.
  static const List<String> softFrames = [
    'feels ',
    'feel ',
    'feeling ',
    'sitting ',
    'sits ',
    'already ',
    'with you',
    'right there',
    "it's ",
    'it is ',
    "there's ",
    'theres ',
    'there is ',
    'yeah ',
    'mm ',
    'your thoughts',
    'your mind',
    'making it hard',
    // Soft epistemic frames (supported soft-functional Receipt)
    'part of your mind',
    'perhaps ',
    'perhaps,',
    'perhaps',
    'maybe ',
    'maybe,',
    'maybe',
    'it may ',
    'almost as if',
    'almost like',
    // Turkish soft frames
    'belki ',
    'belki,',
    'belki',
    'sanki ',
    'sanki,',
    'sanki',
    'zihninin',
    'zihnin ',
    'zihnim',
    'ağır ',
    'ağırlık',
    'gibi ',
    'gibi.',
    'gibi,',
    'gibi',
    'hissediyor',
    'hissediyorum',
    'hissediyorsun',
    'hissetmek',
    'taşıyor',
    'taşiyor',
    'çoktan ',
    'çoktan',
  ];

  /// Activation / felt-texture families for texture-first Receipt.
  /// Closed families justified by night-load Receipt — not incident patches.
  static const List<String> activationAndFeltTexture = [
    // Felt pressure
    'heavy',
    'heaviness',
    'dread',
    'weight',
    'ache',
    'aching',
    'raw',
    'alone',
    'lonely',
    'loneliness',
    'yalnız',
    'yalnizlik',
    'yalnızlık',
    'yalniz',
    'miss ',
    'missing',
    'longing',
    'unsettled',
    'overwhelm',
    'overwhelming',
    'stress',
    'stressed',
    'exhaust',
    'exhausted',
    'exhausting',
    'tired',
    'loud',
    'quiet',
    'pressure',
    'tight',
    'hurt',
    'hurts',
    'hurting',
    'pain',
    'empty',
    'hard to find',
    'hard to settle',
    'what if',
    'what-ifs',
    'what ifs',
    // Turkish felt texture
    'ağır',
    'ağırlık',
    'yük',
    'yuku',
    'zor ',
    'zorlayıcı',
    'zorlayici',
    'yorgun',
    'yorgunluk',
    'gergin',
    'endişe',
    'kaygı',
    'yarın',
    'düşün',
    'dusun',
    'düşünce',
    'düşünceler',
    'dönüp',
    'donup',
    'durmuyor',
    'belirsizlik',
    'karmaşa',
    'karmasa',
    'yalnız',
    'yalnizlik',
    'yalnızlık',
    // Activation / motion
    'spiral',
    'spiraling',
    'spiralling',
    'loop',
    'loops',
    'looping',
    'replay',
    'replaying',
    'racing',
    'swirl',
    'swirling',
    'busy',
    'spinning',
    'churning',
    'overthink',
    'overthinking',
    "won't stop",
    'wont stop',
    // Soft-functional night-load textures (structural — not diagnosis)
    'carrying',
    'carry ',
    'tomorrow',
    'prepared',
    'preparing',
    'preparation',
    'unprepared',
    'rehears',
    'keeping watch',
    'keep watch',
    'search',
    'certainty',
    'one more',
    'going wrong',
    'worst',
    'less safe',
    'unsafe',
  ];

  /// Naming stems illegal inside Receipt (phase boundary).
  static const List<String> forbiddenNamingStems = [
    'weighing',
    'holding on',
    'lingering',
    'still there',
    'on your mind',
  ];

  /// Permission drift markers (Intelligence forbid surface).
  static const List<String> forbiddenPermissionMarkers = [
    "you don't have to",
    'you do not have to',
    'solve this tonight',
    'figure it out tonight',
  ];

  /// Release drift markers (Intelligence forbid surface).
  static const List<String> forbiddenReleaseMarkers = [
    'let this rest',
    'let it rest',
    'set this down',
    'set it down',
    'set that down',
    'let go',
  ];

  /// Enough / continuity drift markers (Intelligence forbid surface).
  static const List<String> forbiddenEnoughMarkers = [
    'nothing more',
    "that's enough",
    'thats enough',
    'enough for now',
  ];

  /// Compound second-move tails that stack a second help after a comma.
  static const List<String> forbiddenCompoundSecondMoves = [
    ", and that's",
    ', and thats',
    ', and that is',
    ", and that is",
  ];

  static bool containsAny(String lower, List<String> markers) {
    for (final marker in markers) {
      if (lower.contains(marker)) return true;
    }
    return false;
  }

  static bool hasClassicStem(String lower) =>
      containsAny(lower, classicStems);

  static bool hasSoftFrame(String lower) => containsAny(lower, softFrames);

  static bool hasActivationOrFeltTexture(String lower) =>
      containsAny(lower, activationAndFeltTexture);

  static bool hasForbiddenNamingStem(String lower) =>
      containsAny(lower, forbiddenNamingStems);

  static bool hasCompoundSecondMove(String lower) =>
      containsAny(lower, forbiddenCompoundSecondMoves);

  /// Texture-first semantic Receipt under this contract.
  ///
  /// Requires soft frame + activation/felt texture, and rejects Naming-stem
  /// and compound second-move forms at the contract layer.
  /// Soft-functional epistemic frames are admitted the same way when paired
  /// with a contract texture (Guard stays mechanism-agnostic).
  static bool matchesTextureFirst(String lower) {
    if (hasForbiddenNamingStem(lower)) return false;
    if (hasCompoundSecondMove(lower)) return false;
    if (!hasActivationOrFeltTexture(lower)) return false;
    if (!hasSoftFrame(lower)) return false;
    return true;
  }

  /// Positive steering text for Receipt Intelligence (not a reply library).
  ///
  /// [supportedFunctional] strengthens functional-over-activation order when a
  /// supported/strong ThinkingFunctionHypothesis authorizes a hinge. Does not
  /// change Guard admission logic.
  static String intelligenceSteeringDirective({
    bool supportedFunctional = false,
  }) {
    if (supportedFunctional) {
      return 'Receipt Realization Contract v$version — realize inside this '
          'closed grammar only:\n'
          '- Prefer three to five short sentences. An authorized soft '
          'functional hinge is active: MUST realize exactly one soft functional '
          'recognition hinge inside Golden Conversations V2 short-line cadence '
          '(~60 words). Soft reframe TYPE welcome after the hinge.\n'
          '- Soft perspective (Golden Conversations V2): soft observe → hinge → '
          '“Perhaps… / It may be…” — never positivity advice or cheer-up.\n'
          '- Do not write one dense clinical paragraph.\n'
          '- Structural shape: soft epistemic frame + authorized FUNCTIONAL '
          'texture/hinge first; activation words are optional supporting '
          'texture only. Do not embed a stock response.\n'
          '- Prefer a Receipt-safe soft frame such as: part of your mind / '
          'already / perhaps / maybe / it may / your mind / your thoughts / '
          'feels / making it hard / it\'s.\n'
          '- Prioritize functional night-load texture such as: carrying / '
          'already / tomorrow / prepared / rehears / search / heavy—before '
          'generic activation.\n'
          '- Activation words (busy / racing / swirling / spinning / looping) '
          'remain legal texture only when they support the functional '
          'recognition. Activation + topic alone is insufficient and fails the '
          'functional recognition requirement.\n'
          '- Do not make generic activation the preferred completion when a '
          'supported function hypothesis exists.\n'
          '- Do not stack a second move after a comma (forbid forms like '
          '", and that\'s ...").\n'
          '- Forbidden Naming stems inside Receipt: weighing, holding on, '
          'lingering, still there, on your mind.\n'
          '- Do not drift into Permission, Release, or Enough language.\n'
          '- Do not emit hard motive claims, diagnosis, or invented story.\n'
          '- Keep natural First Stop Moment wording; do not emit a canned reply '
          'library line or Gold Standard reference line.';
    }

    return 'Receipt Realization Contract v$version — realize inside this '
        'closed grammar only:\n'
        '- Prefer three to four short sentences. Keep the felt Receipt budget '
        '(~45 words) when no authorized soft functional hinge is active.\n'
        '- Golden Conversations V2 cadence: short lines + soft reframe. '
        'Do not telegram. Do not write a clinical essay paragraph.\n'
        '- Do not stack a second move after a comma (forbid forms like '
        '", and that\'s ...").\n'
        '- Prefer a Receipt-safe soft frame such as: your mind / your thoughts / '
        'feels / already / making it hard / it\'s / part of your mind / '
        'perhaps / maybe / it may.\n'
        '- Pair the frame with a Receipt-safe activation, felt, or soft-'
        'functional night-load texture such as: racing / looping / swirling / '
        'busy / heavy / carrying / tomorrow / prepared / rehears / search.\n'
        '- Do not invent a mind-job or functional mechanism without '
        'authorization.\n'
        '- Forbidden Naming stems inside Receipt: weighing, holding on, '
        'lingering, still there, on your mind.\n'
        '- Do not drift into Permission, Release, or Enough language.\n'
        '- Do not emit hard motive claims, diagnosis, or invented story.\n'
        '- Keep natural First Stop Moment wording; do not emit a canned reply '
        'library line or Gold Standard reference line.';
  }

  /// Forbidden-move lines merged into Receipt Intelligence compile output.
  static List<String> intelligenceForbiddenMoves() {
    return [
      'Receipt Naming-stem drift: weighing / holding on / lingering / '
          'still there / on your mind',
      'Compound second move after a comma (e.g. ", and that\'s ...")',
      'Permission language (“you don’t have to”, “solve this tonight”)',
      'Release language (“let this rest”, “set this down”, “let go”)',
      'Enough/closing language (“nothing more”, “that’s enough”)',
    ];
  }
}
