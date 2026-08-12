import 'conversation_blueprint_binding.dart';
import 'conversation_grounding_buffer.dart';
import 'prior_admitted_expression.dart';

/// Enough Intelligence V1.3
///
/// Deterministic Enough / continuity compilation aid inside Conversation
/// Compiler. Closes spoken night with a plain human line; may softly hand off
/// toward rest audio only when Exit already authorized transition.
///
/// Does not choose WHAT, psychology, release, exit, or protocol.
/// Does not generate the final utterance.
/// Anti-catchphrase: do not default to “That’s enough for now.”
class EnoughIntelligence {
  const EnoughIntelligence();

  static const String version = '1.3';

  EnoughCompileSlice compile({
    required BlueprintStageBinding stage,
    ConversationGroundingBuffer? conversationGrounding,
    PriorAdmittedExpression? priorAdmittedExpression,
    bool authorizeRestAudioHandoff = false,
  }) {
    assert(stage.stage == BlueprintStage.enough);

    final forbidden = <String>[
      ...stage.forbiddenMoves,
      ..._enoughForbidden,
      if (!authorizeRestAudioHandoff) ..._audioPromiseForbidden,
    ];

    final close = authorizeRestAudioHandoff
        ? _closeDirectiveWithHandoff
        : _closeDirectivePlain;
    final realization = authorizeRestAudioHandoff
        ? _realizationWithHandoff
        : _realizationPlain;
    final aim =
        authorizeRestAudioHandoff ? _aimWithHandoff : _aimPlain;
    final signature = authorizeRestAudioHandoff
        ? _signatureWithHandoff
        : _signaturePlain;

    return EnoughCompileSlice(
      aim: aim,
      sealedWhatSignature: signature,
      forbiddenMoves: forbidden,
      responseLength: _responseLength,
      closeDirective: close,
      realizationDirective: realization,
      userContent: _userContent(
        priorAdmittedExpression: priorAdmittedExpression,
        authorizeRestAudioHandoff: authorizeRestAudioHandoff,
        realization: realization,
        close: close,
      ),
      systemAppendix: _systemAppendix(
        priorAdmittedExpression: priorAdmittedExpression,
        authorizeRestAudioHandoff: authorizeRestAudioHandoff,
        close: close,
      ),
    );
  }

  static const String _aimWithHandoff =
      'Close the spoken night once with one plain, kind line that softly '
      'hands the person toward quiet rest audio — without drama or a '
      'protocol stamp.';

  static const String _aimPlain =
      'Close the spoken night once with one plain, kind line — without '
      'promising or preparing rest audio, and without a protocol stamp.';

  static const String _responseLength =
      'Prefer one short sentence, maximum 16 words. '
      'A second short close line is allowed only if needed. '
      'Not a telegram stamp.';

  static const String _signatureWithHandoff =
      'continuity / Enough — one gentle close that may include a soft rest-'
      'audio handoff (Golden Conversations V2 TYPE). Natural wording may vary. '
      'Do not default to “That’s enough for now.” Do not validate, name, '
      'grant permission, or invite release.';

  static const String _signaturePlain =
      'continuity / Enough — one gentle plain close. Do not promise that '
      'quiet/session/audio is being prepared. Do not default to “That’s enough '
      'for now.” Do not validate, name, grant permission, or invite release.';

  static const String _closeDirectiveWithHandoff =
      'Enough only: end speech cleanly and point softly toward rest audio. '
      'Sound like a tired kind human ending a quiet exchange. '
      'CRITICAL: reply in the SAME language as the current-turn user line. '
      'If they wrote English, use English only. If Turkish, Turkish only. '
      'Never mix. Never switch languages mid-night without them switching. '
      'Prefer a single soft handoff TYPE line such as '
      'English: “I’m preparing a little quiet for you now” / '
      '“I’ll leave you with a little rest now” / '
      '“I’m preparing a session for you now.” '
      'Turkish only when they wrote Turkish: '
      '“Şimdi sana biraz sessizlik hazırlıyorum” / '
      '“Seni şimdi biraz dinlenmeyle bırakıyorum.” '
      'A plain close alone (nothing more is needed / words can rest here) '
      'is still legal when a handoff would feel forced. '
      'Vary naturally; never force a signature catchphrase. '
      'Do not open with Release-ish lines (“it’s time to let… settle / set down”). '
      'Do not add Release put-down after the handoff '
      '(no “night can hold” / “set this down” / “let the night hold”). '
      'Do not add Neutral Entry fillers (“take your time”, “whenever you’re ready”). '
      'Do not drift into Release put-down (set down / night can hold / let rest). '
      'Do not Receipt, Name, or grant Permission.';

  static const String _closeDirectivePlain =
      'Enough only: end speech cleanly with a plain close. '
      'Sound like a tired kind human ending a quiet exchange. '
      'CRITICAL: reply in the SAME language as the current-turn user line. '
      'If they wrote English, use English only. If Turkish, Turkish only. '
      'Never mix. Never switch languages mid-night without them switching. '
      'Do NOT promise or imply that quiet, a session, or audio is being prepared. '
      'Forbidden examples: “I’m preparing a little quiet…”, '
      '“Şimdi sana biraz sessizlik hazırlıyorum”, '
      '“I’m preparing a session for you now.” '
      'Prefer a plain close (nothing more is needed / words can rest here). '
      'Vary naturally; never force a signature catchphrase. '
      'Do not open with Release-ish lines (“it’s time to let… settle / set down”). '
      'Do not add Release put-down '
      '(no “night can hold” / “set this down” / “let the night hold”). '
      'Do not add Neutral Entry fillers (“take your time”, “whenever you’re ready”). '
      'Do not Receipt, Name, or grant Permission.';

  static const String _realizationWithHandoff =
      'Realize only the sealed WHAT (continuity / enough) as one or two short '
      'utterances. Close gently once, preferably with a soft rest-audio handoff. '
      'Do not drift into Receipt, Naming, Permission, Release, or another WHAT. '
      'Do not choose release, protocol, exit, or silence.';

  static const String _realizationPlain =
      'Realize only the sealed WHAT (continuity / enough) as one or two short '
      'utterances. Close gently once with a plain close. '
      'Do not promise rest audio, a session, or preparing quiet. '
      'Do not drift into Receipt, Naming, Permission, Release, or another WHAT. '
      'Do not choose release, protocol, exit, or silence.';

  static const List<String> _enoughForbidden = [
    'Stock Enough catchphrases as the only form: “That’s enough for now”, '
        '“That’s enough”, or near-identical checklist closes used by default',
    'Repeating the same close line as if restamping the night',
    'Recaps, lessons, or takeaways',
    'Questions of any kind',
    'Receipt / First Stop Moment language',
    'Naming the load',
    'Permission / obligation-ease language',
    'Release / put-down language',
    'Advice, plans, techniques, or engagement hooks',
    'Clinical coldness or brand-sounding confirmation',
    'Cheerful promo tone about the audio session',
    'Release put-down drift (“night can hold”, “set this down”, “let go”)',
  ];

  static const List<String> _audioPromiseForbidden = [
    'Promising that quiet / a session / audio is being prepared',
    'Soft rest-audio handoff TYPE lines while Exit is not transitionToAudio',
    'Turkish audio-prep lines such as “sessizlik hazırlıyorum”',
    'English audio-prep lines such as “preparing a little quiet”',
  ];

  String _userContent({
    required PriorAdmittedExpression? priorAdmittedExpression,
    required bool authorizeRestAudioHandoff,
    required String realization,
    required String close,
  }) {
    final anti = priorAdmittedExpression == null
        ? ''
        : '\n\n${priorAdmittedExpression.antiRepeatDirective()}';
    final lead = authorizeRestAudioHandoff
        ? 'Prefer one soft handoff sentence (max 16 words). Plain. Quiet. Human. '
            'Lead with the handoff; do not open with “it’s time to let…”. '
        : 'Prefer one plain close sentence (max 16 words). Quiet. Human. '
            'Do not prepare or promise audio. ';
    return '$realization\n\n'
        '$close\n\n'
        '${lead}No question. No catchphrase stamp. No second agenda.$anti';
  }

  String _systemAppendix({
    required PriorAdmittedExpression? priorAdmittedExpression,
    required bool authorizeRestAudioHandoff,
    required String close,
  }) {
    final anti = priorAdmittedExpression == null
        ? 'Anti-repeat rule: one Enough close is enough — do not restate the same stamp.'
        : priorAdmittedExpression.antiRepeatDirective();
    final handoffRule = authorizeRestAudioHandoff
        ? 'Audio-handoff rule (Golden Conversations V2 TYPE): when closing the night, prefer one soft directing line toward quiet rest audio — not a product pitch.'
        : 'Audio-handoff rule: Exit did not authorize transition — do not promise preparing quiet/session/audio.';
    return '''
Enough Intelligence v$version:
$close
Anti-catchphrase rule: do not default to “That’s enough for now.” Prefer a plain close${authorizeRestAudioHandoff ? ', ideally with soft rest-audio handoff' : ' without audio preparation promises'}.
$handoffRule
$anti
Warmth rule: sound nearby and tired-kind, not clinical or protocol-confirming.
Drift rule: do not Receipt, Name, grant Permission, or invite Release.
''';
  }
}

/// Enough-only compile material produced by [EnoughIntelligence].
class EnoughCompileSlice {
  final String aim;
  final String sealedWhatSignature;
  final List<String> forbiddenMoves;
  final String responseLength;
  final String closeDirective;
  final String realizationDirective;
  final String userContent;
  final String systemAppendix;

  const EnoughCompileSlice({
    required this.aim,
    required this.sealedWhatSignature,
    required this.forbiddenMoves,
    required this.responseLength,
    required this.closeDirective,
    required this.realizationDirective,
    required this.userContent,
    required this.systemAppendix,
  });
}
