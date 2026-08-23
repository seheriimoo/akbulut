import 'conversation_blueprint_binding.dart';
import 'conversation_grounding_buffer.dart';

/// Narrow Intelligence V1 (Slice 2)
///
/// Compile aid for one conversation-specific fork question that splits two
/// plausible hypotheses — not generic follow-up bait.
class NarrowIntelligence {
  const NarrowIntelligence();

  static const String version = '1.0';

  NarrowCompileSlice compile({
    required BlueprintStageBinding stage,
    ConversationGroundingBuffer? conversationGrounding,
    bool refinementAfterPartial = false,
  }) {
    assert(stage.stage == BlueprintStage.receipt);

    final currentTurn = _currentTurnGrounding(conversationGrounding);
    final forbidden = <String>[
      ...stage.forbiddenMoves,
      ..._narrowForbidden,
    ];

    return NarrowCompileSlice(
      aim: refinementAfterPartial ? _aimRefinement : _aim,
      sealedWhatSignature: refinementAfterPartial
          ? _sealedWhatSignatureRefinement
          : _sealedWhatSignature,
      forbiddenMoves: forbidden,
      responseLength: _responseLength,
      narrowDirective: refinementAfterPartial
          ? _narrowRefinementDirective
          : _narrowDirective,
      realizationDirective: refinementAfterPartial
          ? _realizationRefinementDirective
          : _realizationDirective,
      userContent: _userContent(
        currentTurn: currentTurn,
        refinementAfterPartial: refinementAfterPartial,
      ),
      systemAppendix: refinementAfterPartial
          ? _systemAppendixRefinement
          : _systemAppendix,
    );
  }

  static String? _currentTurnGrounding(ConversationGroundingBuffer? buffer) {
    if (buffer == null || buffer.isEmpty) return null;
    return buffer.currentUserUtterance;
  }

  static const String _aim =
      'Ask exactly one conversation-specific fork question that splits two '
      'different plausible causes — not generic therapy follow-up.';

  static const String _aimRefinement =
      'After a partial reframe confirm: briefly acknowledge the part they '
      'affirmed, then ask exactly one refinement question about what is missing.';

  static const String _sealedWhatSignature =
      'validation / Receipt — Narrow only. One fork question from their '
      'actual words. Do not reframe, interpret, or ease obligation.';

  static const String _sealedWhatSignatureRefinement =
      'validation / Receipt — Narrow refinement only. Acknowledge affirmed '
      'part + one question about the missing piece. No new reframe.';

  static const String _responseLength =
      'Exactly one short question, maximum 22 words. Plain Turkish or English.';

  static const String _narrowDirective =
      'Narrow (Slice 2): pick the unresolved variable in THEIR last message '
      'and ask one fork question with two concrete alternatives connected by '
      '“mi … yoksa … mi?” / “or … or …?”. '
      'Good: “Konuşmanın kendisi mi geriyor seni, yoksa onun vereceği tepki mi?” '
      'Bad: “Bu seni nasıl hissettiriyor?”, “Biraz daha anlatır mısın?”, '
      '“Ne düşünüyorsun?”. '
      'Never answer for them. No jargon. No Belki/Sanki/aslında. '
      'No Permission/Release. Not an interrogation stack.';

  static const String _narrowRefinementDirective =
      'Narrow refinement (Slice 2.1): they partially confirmed a reframe. '
      'Briefly name ONLY a fragment they actually said (“Yalnızlık kısmı doğru gibi.”), '
      'then ask ONE question about the missing piece (“Peki eksik kalan taraf ne?”). '
      'Never inject semantic objects they did not say (no default “baskı”, “endişe”, etc.). '
      'If you cannot ground the affirmed part, ask “Tam oturmayan taraf ne?” only. '
      'No new reframe. No Belki/Sanki. No advice. One question only.';

  static const String _realizationDirective =
      'Realize Narrow only as exactly one fork question. '
      'Do not Receipt-reframe. Do not Name. Do not Permission or Release.';

  static const String _realizationRefinementDirective =
      'Realize one refinement question only — acknowledge affirmed part, '
      'then ask what is missing. No reframe on this turn.';

  static const List<String> _narrowForbidden = [
    'Generic therapy questions: how does that make you feel, tell me more',
    'Belki/Sanki/aslında interpretation on this turn',
    'Permission obligation-ease',
    'Release put-down',
    'More than one question',
    'Answering the fork for them',
    'Psychology jargon',
    'Invented motives not in their words',
  ];

  String _userContent({
    required String? currentTurn,
    bool refinementAfterPartial = false,
  }) {
    final turn = currentTurn == null
        ? ''
        : '\n\nCurrent turn (shaping only):\n"""$currentTurn"""';
    final directive =
        refinementAfterPartial ? _narrowRefinementDirective : _narrowDirective;
    final realization = refinementAfterPartial
        ? _realizationRefinementDirective
        : _realizationDirective;
    return '$realization\n\n$directive$turn';
  }

  static const String _systemAppendix = '''
Narrow Intelligence v$version:
$_narrowDirective
One fork question only. Split two hypotheses from their message.
''';

  static const String _systemAppendixRefinement = '''
Narrow Intelligence v$version (refinement):
$_narrowRefinementDirective
Partial confirm only — refine, do not reframe.
''';
}

class NarrowCompileSlice {
  final String aim;
  final String sealedWhatSignature;
  final List<String> forbiddenMoves;
  final String responseLength;
  final String narrowDirective;
  final String realizationDirective;
  final String userContent;
  final String systemAppendix;

  const NarrowCompileSlice({
    required this.aim,
    required this.sealedWhatSignature,
    required this.forbiddenMoves,
    required this.responseLength,
    required this.narrowDirective,
    required this.realizationDirective,
    required this.userContent,
    required this.systemAppendix,
  });
}
