/// Permission Realization Contract V1
///
/// Single source of truth for V1 Permission expression shaping and Guard
/// obligation-ease admission. Shared by [PermissionIntelligence] and
/// [UtteranceGuard].
///
/// Closed structural contract — not a reply library, not open NLP.
/// Speech-act identity:
///   PERMISSION = reduce obligation / authorize non-resolution
///   NOT RELEASE = put down / let go / set down / rest the load
///
/// Fail-closed: off-contract or Release-enactment candidates must not invent
/// admission. Guard remains structural — not psychological scoring.
class PermissionRealizationContract {
  const PermissionRealizationContract._();

  static const String version = '1.0';

  /// Classic obligation-ease stems (FaithfulTestVendor + store path).
  static const List<String> classicObligationEase = [
    'do not have to',
    "don't have to",
    'dont have to',
    'does not have to',
    "doesn't have to",
    'doesnt have to',
    'no need to solve',
    'not something to solve',
    'solve this tonight',
  ];

  /// Bounded natural obligation-ease / non-resolution cues.
  /// Not a bare “need” wildcard. Not Release put-down language.
  static const List<String> naturalObligationEase = [
    'no need to',
    "don't need to",
    'dont need to',
    'do not need to',
    "doesn't need to",
    'doesnt need to',
    'does not need to',
    'need not',
    'nothing needs',
    'no pressure to',
    'without fixing',
    'without solving',
    'without figuring',
    'without sorting',
    'can wait',
    'allowed to pause',
    'allowed to stop',
    'can pause',
    'do not have to do more',
    "don't have to do more",
    'dont have to do more',
    'no more to push',
    'leave this unfinished',
    'leave it unfinished',
    'unfinished is',
    'not yours to finish',
    'no answer needed',
    'no puzzle',
    'tonight asks nothing',
    'does not ask for an answer',
    "doesn't ask for an answer",
    // Soft obligation / non-resolution modals (Permission speech-act only)
    "it's okay not to",
    'its okay not to',
    'it is okay not to',
    'okay not to',
    'can leave this unresolved',
    'can leave it unresolved',
    'leave this unresolved',
    'leave it unresolved',
    'can stop trying',
    'stop trying to solve',
    'stop trying to rehearse',
    'stop trying to prepare',
    'stop trying to figure',
    'stop trying to sort',
    'pause the rehearsal',
    'pause rehearsing',
    // Turkish Permission (same speech-act: reduce obligation)
    'zorunda değilsin',
    'zorunda değil',
    'zorunluluğun yok',
    'zorunlulugun yok',
    'zorunluluğu yok',
    'zorunlulugu yok',
    'zorunluluk yok',
    'gerekmiyor',
    'gerek yok',
    'çözmen gerekmiyor',
    'çözmek zorunda değilsin',
    'düşünmek zorunda değilsin',
    'düşünmeye devam',
    'hazırlanmak zorunda değilsin',
    'bu gece çözmen',
    'bu gece düşünmen',
    'çalışmana gerek yok',
    'bir şey yapmana gerek yok',
    'sadece durabilirsin',
    'durabilirsin',
  ];

  /// Okay/ok softeners for the leave-be family (not bare okay).
  static const List<String> leaveBeOkaySofteners = [
    "it's okay",
    'its okay',
    'it is okay',
    "it's ok ",
    'its ok ',
    'it is ok ',
    "it's ok to",
    'its ok to',
    'it is ok to',
  ];

  /// Leave-be / non-resolution tails — only with an okay softener.
  ///
  /// Bounded “let this/things be|go” under okay softener remains Permission
  /// non-resolution (not bare “let go” Release enactment).
  static const List<String> leaveBeTails = [
    'let this go',
    'let things be',
    'let this be',
    'let it be',
    'let things go',
    'as they are',
    'as it is',
  ];

  /// Release enactment markers — illegal under Permission WHAT.
  ///
  /// Structural put-down speech acts. Not admitted even with soft modals
  /// like “you can …”. Distinct from leave-be “let this go” under okay.
  static const List<String> illegalReleaseEnactment = [
    'let go',
    'set down',
    'set this down',
    'set it down',
    'set that down',
    'put down',
    'put this down',
    'put it down',
    'put that down',
    'let it rest',
    'let this rest',
    'let that rest',
    'loosen your grip',
    'loosen the grip',
    'release this',
    'release it',
    'leave it here',
    'leave this here',
    'drop it',
    'drop the grip',
    'lay this down',
    'lay it down',
    'stop holding',
    'stop gripping',
    // Turkish Release enactment under Permission
    'bırakabilirsin',
    'bir kenara bırak',
    'burada bırak',
    'şimdilik bırak',
    'gece tutabilir',
    'gece taşıyabilir',
    // English Release put-down that must not count as Permission ease
    'night can hold',
    'the night can hold',
    'leave some of',
    'let go of that tonight',
    'let go of this tonight',
    'don’t need to carry',
    "don't need to carry",
    'do not need to carry',
    'no longer need to carry',
  ];

  /// Advice / invented-problem markers beyond cross-phase WHAT checks.
  static const List<String> unsafeAdviceMarkers = [
    'have you tried',
    'you should',
    'you need to figure',
    'you need to solve',
    'work on this',
    'action plan',
    'try this',
    'tip:',
    'because you',
    'deep down',
    'diagnos',
    'therapist',
    'therapy',
  ];

  static bool containsAny(String lower, List<String> markers) {
    for (final marker in markers) {
      if (lower.contains(marker)) return true;
    }
    return false;
  }

  static bool hasUnsafeAdvice(String lower) =>
      containsAny(lower, unsafeAdviceMarkers);

  static bool hasIllegalReleaseEnactment(String lower) =>
      containsAny(lower, illegalReleaseEnactment);

  static bool hasClassicObligationEase(String lower) =>
      containsAny(lower, classicObligationEase);

  static bool hasNaturalObligationEase(String lower) =>
      containsAny(lower, naturalObligationEase);

  /// Bounded leave-be: okay softener + leave-be tail. Bare okay is not enough.
  static bool matchesLeaveBeFamily(String lower) {
    if (!containsAny(lower, leaveBeOkaySofteners)) return false;
    return containsAny(lower, leaveBeTails);
  }

  /// Texture-free structural Permission under this contract.
  ///
  /// Order: unsafe → Release enactment → classic / leave-be / natural ease.
  static bool matchesObligationEase(String lower) {
    if (hasUnsafeAdvice(lower)) return false;
    if (hasIllegalReleaseEnactment(lower)) return false;
    if (hasClassicObligationEase(lower)) return true;
    if (matchesLeaveBeFamily(lower)) return true;
    return hasNaturalObligationEase(lower);
  }

  /// Positive steering for Permission Intelligence (not a reply library).
  static String intelligenceSteeringDirective() {
    return 'Permission Realization Contract v$version — realize inside this '
        'closed grammar only:\n'
        '- Speech-act: PERMISSION = reduce obligation / authorize '
        'non-resolution (“you are not required to keep doing X tonight”).\n'
        '- Speech-act: NOT RELEASE = put down / let go / set down / rest the '
        'load (“now stop / put down / let go of X”).\n'
        '- Prefer one short sentence (~20 words).\n'
        '- Legal obligation-ease families include: don’t/do not have to; '
        'don’t/do not need to; no need to; it’s okay not to; can pause; '
        'can leave unresolved; can stop trying to solve/rehearse/prepare '
        'tonight.\n'
        '- Soft modals such as “you can pause…” / “you can leave this '
        'unresolved…” are legal only when they ease obligation—not when they '
        'enact putting-down.\n'
        '- Illegal Release enactment: let go / set down / put down / let it '
        'rest / loosen your grip / release this / leave it here / drop it / '
        'stop holding.\n'
        '- Never say “you can let go…” under Permission — that is Release.\n'
        '- Prefer: “You don’t need to keep rehearsing / preparing tonight.”\n'
        '- Do not drift into Receipt, Naming, or Enough.\n'
        '- Mirror the person’s language (English or Turkish) inside this '
        'contract only.\n'
        '- Vary naturally only inside this Permission realization contract. '
        'Do not paraphrase into Release speech acts.\n'
        '- Do not emit a canned reply library line.';
  }

  /// Forbidden-move lines merged into Permission Intelligence compile output.
  static List<String> intelligenceForbiddenMoves() {
    return [
      'Release enactment under Permission: let go / set down / put down / '
          'let it rest / loosen grip / release this / leave it here / drop it / '
          'stop holding',
      'Receipt / First Stop Moment language (“that sounds”, “I hear”, felt '
          'receipt of texture)',
      'Naming the load as a holdable object (Naming stage drift)',
      'Enough/closing language (“nothing more”, “that’s enough”)',
      'Advice, plans, techniques, or instructions',
      'Questions of any kind',
      'Paraphrasing obligation-ease into put-down / let-go speech acts',
    ];
  }
}
