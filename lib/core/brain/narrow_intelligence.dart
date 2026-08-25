import 'conversation_blueprint_binding.dart';
import 'conversation_grounding_buffer.dart';
import 'thinking_function_hypothesis.dart';
import 'thinking_function_intelligence_shaping.dart';

/// Narrow Intelligence V1.1 (Phase 2 — mechanism-aware when TF supported)
///
/// Compile aid for one conversation-specific fork question that splits two
/// plausible hypotheses — not generic follow-up bait.
///
/// When a supported ThinkingFunction exists, prefer a mechanism fork
/// (two jobs the mind may be doing) over a pure surface-topic fork.
/// Never pastes canned GOLD lines.
class NarrowIntelligence {
  const NarrowIntelligence();

  static const String version = '1.1';

  NarrowCompileSlice compile({
    required BlueprintStageBinding stage,
    ConversationGroundingBuffer? conversationGrounding,
    bool refinementAfterPartial = false,
    ThinkingFunctionHypothesis? thinkingFunctionHypothesis,
  }) {
    assert(stage.stage == BlueprintStage.receipt);

    final currentTurn = _currentTurnGrounding(conversationGrounding);
    final mechanismAware = !refinementAfterPartial &&
        ThinkingFunctionIntelligenceShaping.isSupportedOrStrong(
          thinkingFunctionHypothesis,
        );
    final forbidden = <String>[
      ...stage.forbiddenMoves,
      ..._narrowForbidden,
      if (mechanismAware) ..._mechanismForbidden,
    ];

    return NarrowCompileSlice(
      aim: refinementAfterPartial
          ? _aimRefinement
          : (mechanismAware ? _aimMechanism : _aim),
      sealedWhatSignature: refinementAfterPartial
          ? _sealedWhatSignatureRefinement
          : (mechanismAware
              ? _sealedWhatSignatureMechanism
              : _sealedWhatSignature),
      forbiddenMoves: forbidden,
      responseLength: _responseLength,
      narrowDirective: refinementAfterPartial
          ? _narrowRefinementDirective
          : (mechanismAware ? _narrowMechanismDirective : _narrowDirective),
      realizationDirective: refinementAfterPartial
          ? _realizationRefinementDirective
          : (mechanismAware
              ? _realizationMechanismDirective
              : _realizationDirective),
      userContent: _userContent(
        currentTurn: currentTurn,
        refinementAfterPartial: refinementAfterPartial,
        hypothesis: mechanismAware ? thinkingFunctionHypothesis : null,
      ),
      systemAppendix: refinementAfterPartial
          ? _systemAppendixRefinement
          : (mechanismAware
              ? _systemAppendixMechanism(
                  thinkingFunctionHypothesis!,
                )
              : _systemAppendix),
    );
  }

  static String? _currentTurnGrounding(ConversationGroundingBuffer? buffer) {
    if (buffer == null || buffer.isEmpty) return null;
    return buffer.currentUserUtterance;
  }

  static const String _aim =
      'Ask exactly one conversation-specific fork question that splits two '
      'different plausible causes — not generic therapy follow-up.';

  static const String _aimMechanism =
      'Ask exactly one mechanism fork: split two plausible jobs the mind may '
      'be doing tonight — grounded in their words + the soft function '
      'hypothesis — not a surface-topic A-vs-B only.';

  static const String _aimRefinement =
      'After a partial reframe confirm: briefly acknowledge the part they '
      'affirmed, then ask exactly one refinement question about what is missing.';

  static const String _sealedWhatSignature =
      'validation / Receipt — Narrow only. One fork question from their '
      'actual words. Do not reframe, interpret, or ease obligation.';

  static const String _sealedWhatSignatureMechanism =
      'validation / Receipt — Narrow mechanism fork only. One question '
      'splitting two soft mind-jobs from evidence. No reframe. No Permission.';

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

  static const String _narrowMechanismDirective =
      'Narrow mechanism (Phase 2): when a supported soft thinking-function '
      'exists, ask one fork that splits TWO plausible mind-jobs — not only '
      'surface topics (event vs uncertainty). '
      'Ground both sides in THEIR words + the authorized function TYPE. '
      'Stay epistemically soft. Never assert protection/safety motives unless '
      'their words already earned that. Prefer rehearsal/certainty forks for '
      'worst-case evidence; leave preparation as optional soft side only when '
      'prep language is present. No Belki-reframe. No Permission. '
      'One “or / yoksa” question only. Invent original wording — never paste '
      'GOLD library lines.';

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

  static const String _realizationMechanismDirective =
      'Realize one mechanism fork question only. Split two soft mind-jobs. '
      'Do not reframe. Do not ease obligation. Do not diagnose.';

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

  static const List<String> _mechanismForbidden = [
    'Hard diagnosis of motives (protection, safety) without user evidence',
    'Surface-only forks when mechanism evidence is available '
        '(prefer mind-job A vs mind-job B)',
    'Pasting GOLD dialogue lines or fixed response banks',
  ];

  String _userContent({
    required String? currentTurn,
    bool refinementAfterPartial = false,
    ThinkingFunctionHypothesis? hypothesis,
  }) {
    final turn = currentTurn == null
        ? ''
        : '\n\nCurrent turn (shaping only):\n"""$currentTurn"""';
    final directive = refinementAfterPartial
        ? _narrowRefinementDirective
        : (hypothesis != null
            ? _narrowMechanismDirective
            : _narrowDirective);
    final realization = refinementAfterPartial
        ? _realizationRefinementDirective
        : (hypothesis != null
            ? _realizationMechanismDirective
            : _realizationDirective);
    final mechanism = hypothesis == null
        ? ''
        : '\n\n${ThinkingFunctionIntelligenceShaping.narrowMechanismDirective(hypothesis)}';
    return '$realization\n\n$directive$mechanism$turn';
  }

  static const String _systemAppendix = '''
Narrow Intelligence v$version:
$_narrowDirective
One fork question only. Split two hypotheses from their message.
''';

  static String _systemAppendixMechanism(ThinkingFunctionHypothesis hypothesis) {
    return '''
Narrow Intelligence v$version (mechanism-aware):
$_narrowMechanismDirective
${ThinkingFunctionIntelligenceShaping.narrowMechanismDirective(hypothesis)}
One mechanism fork only. Soft mind-jobs — not diagnosis.
''';
  }

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
