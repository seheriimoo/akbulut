import 'conversation_blueprint_binding.dart';
import 'conversation_grounding_buffer.dart';

/// Naming Intelligence V1
///
/// Deterministic Naming-only compilation aid inside Conversation Compiler.
/// Optimizes for quiet recognition:
/// "Yes… that's exactly what's happening."
///
/// Continues from successful Receipt. Names only what is already evident.
/// Does not invent motives, diagnose, explain psychology, or drift into
/// Permission / Release.
///
/// Does not choose WHAT, psychology, release, exit, or protocol.
/// Does not generate the final utterance.
/// Does not apply to Receipt, Permission, Release, or Enough.
///
/// Current-turn grounding source: admitted [ConversationGroundingBuffer] only.
/// Standalone livedExpression is not used.
class NamingIntelligence {
  const NamingIntelligence();

  static const String version = '1.0';

  /// Soft upper bound for current-turn grounding text in compile output.
  static const int maxCurrentGroundingChars = 480;

  /// Compile Naming-specific instruction material for the sealed Naming stage.
  ///
  /// [conversationGrounding] is optional admitted same-night grounding.
  /// Naming uses only the current-turn user utterance from that buffer.
  /// It is never decision authority and must not be parroted or over-read.
  /// Never invents, infers, or summarizes grounding.
  NamingCompileSlice compile({
    required BlueprintStageBinding stage,
    ConversationGroundingBuffer? conversationGrounding,
  }) {
    assert(stage.stage == BlueprintStage.naming);

    final currentTurn = _currentTurnGrounding(conversationGrounding);
    final forbidden = <String>[
      ...stage.forbiddenMoves,
      ..._namingIntelligenceForbidden,
    ];

    return NamingCompileSlice(
      aim: _aim,
      sealedWhatSignature: _sealedWhatSignature,
      forbiddenMoves: forbidden,
      responseLength: _responseLength,
      recognitionDirective: _recognitionDirective,
      realizationDirective: _realizationDirective,
      userContent: _userContent(currentTurn),
      systemAppendix: _systemAppendix(currentTurn),
    );
  }

  static const String _aim =
      'Create quiet recognition: one soft name—or soft perspective—for what '
      'is already evident so the person could think “Yes… that’s exactly '
      'what’s happening.” Name only—never interpret, diagnose, or excavate.';

  static const String _responseLength =
      'Three to four short sentences, maximum 45 words. '
      'Golden Conversations V2 cadence: quiet name + soft perspective. '
      'Not a stamp. Not an essay.';

  static const String _sealedWhatSignature =
      'naming / Naming — one gentle, holdable name or soft perspective for '
      'what is already evident in their words (still holding on / weighing / '
      'lingering / on their mind / the hard part beneath it). Continue from '
      'Receipt; do not re-receive. '
      'Do not invent hidden motives. Do not grant permission, invite release, '
      'or close.';

  static const String _recognitionDirective =
      'Quiet recognition (Naming only): name only what is already visible in '
      'their words. Soft perspective (Golden Conversations V2 TYPE) is allowed: '
      'short lines, soft reframe (“Perhaps… / It may be…” / Turkish '
      '“Belki… / Sanki…”). Not positivity, not advice, not diagnosis. '
      'Soft enough to hold—never sharp enough to dig. '
      'CRITICAL: include at least one Guard-legal Naming stem such as '
      '“holding on” / “weighing” / “still there” / “lingering” / '
      '“on your mind” — or Turkish “aklında” / “zihninde” / “hâlâ orada” / '
      '“duruyor” / “tutunuyor.” '
      'Prefer their night-object inside the stem: '
      '“Tomorrow is still on your mind.” / “That list is still on your mind.” / '
      '“The going-over is still there.” '
      'Do not default to “Something is still weighing on your mind” plus a '
      'pasted clause. Do not add “a lot to carry” / “on your plate”. '
      'Do not invent new labels (do not add “worries/anxiety” they did not say). '
      'Do not open with Receipt “It sounds like…” if you can name directly. '
      'One short sentence preferred. No blank lines. No trailing empty lines. '
      'Never insert a newline mid-reply — write one continuous paragraph. '
      'Mirror the person’s language (English or Turkish). '
      'Stay in one language only.';

  static const String _realizationDirective =
      'Realize only the sealed WHAT (naming / naming) as three to four short '
      'lines totaling at most ~45 words. Create quiet recognition: '
      '“Yes… that’s exactly what’s happening.” Do not drift into Receipt, '
      'Permission, Release, Enough, or another WHAT. Do not choose release, '
      'protocol, exit, or silence.';

  static const List<String> _namingIntelligenceForbidden = [
    'Inventing hidden motives or causes not evident in their words',
    'Diagnosis, clinical labels, or psychological explanation',
    'Multiple observations or stacked namings in one turn',
    'Receipt filler / re-acknowledgment as if nothing was heard',
    'Permission language (“you don’t have to”, “solve this tonight”)',
    'Release language (“let this rest”, “set this down”, “let go”)',
    'Enough/closing language (“nothing more”, “that’s enough”)',
    'Advice, positivity reframes, plans, or techniques',
    'Cheer-up or toxic-positivity reframes that erase the load',
    'Questions of any kind',
    'Unsupported verbatim parroting of the user’s wording as padding',
    'Pasting their full clause after a Naming stem (I→you copies of '
        '“keep going over everything I have to do”)',
    'A second restatement after the name already landed (hard to find peace / '
        'a lot to carry / on your plate)',
    'Generic remap of their night-objects into stock load when they named '
        'tomorrow, a list, or tasks',
  ];

  String _userContent(String? currentTurn) {
    final buffer = StringBuffer()
      ..writeln(_realizationDirective)
      ..writeln()
      ..writeln(_recognitionDirective)
      ..writeln()
      ..writeln(
        'Emit two short Naming lines (max 45 words). '
        'Quiet name with their night-object inside the stem, then at most one '
        'soft perspective. Then stop. '
        'No interpretation. No Permission. No Release. No questions.',
      );

    if (currentTurn != null) {
      buffer
        ..writeln()
        ..writeln(
          'Current-turn conversation grounding already admitted (shaping only; '
          'never authority; name only what is evident; do not parrot; '
          'do not analyze; do not infer; do not summarize):',
        )
        ..writeln('"""')
        ..writeln(currentTurn)
        ..writeln('"""');
    } else {
      buffer
        ..writeln()
        ..writeln(
          'No current-turn conversation grounding was supplied. Still name '
          'only one evident, holdable presence—never invent motives, '
          'psychology, or grounding.',
        );
    }

    return buffer.toString().trimRight();
  }

  String _systemAppendix(String? currentTurn) {
    final evidenceRule =
        'Evidence rule: name only what is already evident in the user’s words. '
        'If it was not said or clearly implied in ordinary language, do not name it.';

    final singleRecognitionRule =
        'Single recognition rule: prefer one precise recognition (with optional '
        'soft perspective) over multiple observations. Extra agendas are a '
        'Naming failure. After the Naming stem, at most one hinge — never a '
        'second “hard to find peace / a lot to carry / on your plate”.';

    final keepObjectRule =
        'Night-object rule: keep their named object (tomorrow / the list / '
        'the tasks / the person) as light texture inside the stem. Never paste '
        'their full clause or an I→you near-copy.';

    final continuityRule =
        'Continuity rule: continue naturally from a successful Receipt. '
        'Do not restart with generic acknowledgment. Do not pretend nothing '
        'was heard.';

    final softPerspectiveRule =
        'Soft perspective rule (golden reframe TYPE): when the load is '
        'evident, one gentle shift of how the night-mind is working may land—'
        'e.g. the hard part may be the cost of stopping, not the thought '
        'itself. Not positivity. Not advice. Not diagnosis.';

    final guardAnchor =
        'Naming anchor (HOW only): keep a soft naming frame such as still '
        'holding on / weighing / lingering / on your mind / still there—or a '
        'soft-perspective cue tied to their evident texture, never as a '
        'clinical label.';

    final grounding = currentTurn == null
        ? 'Conversation grounding (current turn): not supplied for this compile.'
        : 'Conversation grounding (current turn): supplied below in the user '
            'instruction for shaping only.';

    return '''
Naming Intelligence v$version:
$_recognitionDirective
$evidenceRule
$singleRecognitionRule
$keepObjectRule
$continuityRule
$softPerspectiveRule
$guardAnchor
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
}

/// Naming-only compile material produced by [NamingIntelligence].
class NamingCompileSlice {
  final String aim;
  final String sealedWhatSignature;
  final List<String> forbiddenMoves;
  final String responseLength;
  final String recognitionDirective;
  final String realizationDirective;
  final String userContent;
  final String systemAppendix;

  const NamingCompileSlice({
    required this.aim,
    required this.sealedWhatSignature,
    required this.forbiddenMoves,
    required this.responseLength,
    required this.recognitionDirective,
    required this.realizationDirective,
    required this.userContent,
    required this.systemAppendix,
  });
}
