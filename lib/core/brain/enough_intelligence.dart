import 'conversation_blueprint_binding.dart';
import 'conversation_grounding_buffer.dart';
import 'prior_admitted_expression.dart';

/// Enough Intelligence V1.2
///
/// Deterministic Enough / continuity compilation aid inside Conversation
/// Compiler. Closes spoken night with a plain human line that may softly
/// hand off toward rest audio (Golden Conversations V2 TYPE).
///
/// Does not choose WHAT, psychology, release, exit, or protocol.
/// Does not generate the final utterance.
/// Anti-catchphrase: do not default to “That’s enough for now.”
class EnoughIntelligence {
  const EnoughIntelligence();

  static const String version = '1.2';

  EnoughCompileSlice compile({
    required BlueprintStageBinding stage,
    ConversationGroundingBuffer? conversationGrounding,
    PriorAdmittedExpression? priorAdmittedExpression,
  }) {
    assert(stage.stage == BlueprintStage.enough);

    final forbidden = <String>[
      ...stage.forbiddenMoves,
      ..._enoughForbidden,
    ];

    return EnoughCompileSlice(
      aim: _aim,
      sealedWhatSignature: _sealedWhatSignature,
      forbiddenMoves: forbidden,
      responseLength: _responseLength,
      closeDirective: _closeDirective,
      realizationDirective: _realizationDirective,
      userContent: _userContent(priorAdmittedExpression),
      systemAppendix: _systemAppendix(priorAdmittedExpression),
    );
  }

  static const String _aim =
      'Close the spoken night once with one plain, kind line that softly '
      'hands the person toward quiet rest audio — without drama or a '
      'protocol stamp.';

  static const String _responseLength =
      'Prefer one short handoff sentence, maximum 16 words. '
      'A second short close line is allowed only if needed. '
      'Not a telegram stamp.';

  static const String _sealedWhatSignature =
      'continuity / Enough — one gentle close that may include a soft rest-'
      'audio handoff (Golden Conversations V2 TYPE). Natural wording may vary. '
      'Do not default to “That’s enough for now.” Do not validate, name, '
      'grant permission, or invite release.';

  static const String _closeDirective =
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

  static const String _realizationDirective =
      'Realize only the sealed WHAT (continuity / enough) as one or two short '
      'utterances. Close gently once, preferably with a soft rest-audio handoff. '
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

  String _userContent(PriorAdmittedExpression? priorAdmittedExpression) {
    final anti = priorAdmittedExpression == null
        ? ''
        : '\n\n${priorAdmittedExpression.antiRepeatDirective()}';
    return '$_realizationDirective\n\n'
        '$_closeDirective\n\n'
        'Prefer one soft handoff sentence (max 16 words). Plain. Quiet. Human. '
        'Lead with the handoff; do not open with “it’s time to let…”. '
        'No question. No catchphrase stamp. No second agenda.$anti';
  }

  String _systemAppendix(PriorAdmittedExpression? priorAdmittedExpression) {
    final anti = priorAdmittedExpression == null
        ? 'Anti-repeat rule: one Enough close is enough — do not restate the same stamp.'
        : priorAdmittedExpression.antiRepeatDirective();
    return '''
Enough Intelligence v$version:
$_closeDirective
Anti-catchphrase rule: do not default to “That’s enough for now.” Prefer a plain close, ideally with soft rest-audio handoff.
Audio-handoff rule (Golden Conversations V2 TYPE): when closing the night, prefer one soft directing line toward quiet rest audio — not a product pitch.
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
