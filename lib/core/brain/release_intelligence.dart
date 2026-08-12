import 'conversation_blueprint_binding.dart';
import 'conversation_grounding_buffer.dart';
import 'prior_admitted_expression.dart';
import 'thinking_function_hypothesis.dart';
import 'thinking_function_intelligence_shaping.dart';

/// Release Intelligence V1.3
///
/// Deterministic Release-only compilation aid inside Conversation Compiler.
/// Invites a gentle putting-down toward rest.
///
/// Optional [ThinkingFunctionHypothesis] (supported+) shapes HOW to put down
/// the mind-job (not a generic let-go). Never chooses WHAT, readiness, exit,
/// or memory. Null/tentative preserves baseline Release.
///
/// Current-turn grounding source: admitted [ConversationGroundingBuffer] only
/// (user utterances). Optional [PriorAdmittedExpression] for anti-repeat only.
class ReleaseIntelligence {
  const ReleaseIntelligence();

  static const String version = '1.3';

  /// Soft upper bound for current-turn grounding text in compile output.
  static const int maxCurrentGroundingChars = 480;

  /// Compile Release-specific instruction material for the sealed stage.
  ReleaseCompileSlice compile({
    required BlueprintStageBinding stage,
    ConversationGroundingBuffer? conversationGrounding,
    ThinkingFunctionHypothesis? thinkingFunctionHypothesis,
    PriorAdmittedExpression? priorAdmittedExpression,
  }) {
    assert(stage.stage == BlueprintStage.release);

    final currentTurn = _currentTurnGrounding(conversationGrounding);
    final lean = _deterministicLean(conversationGrounding);
    final turkish = _looksTurkish(conversationGrounding);
    final supportedFunctional =
        ThinkingFunctionIntelligenceShaping.isSupportedOrStrong(
      thinkingFunctionHypothesis,
    );
    final forbidden = <String>[
      ...stage.forbiddenMoves,
      ..._releaseIntelligenceForbidden,
      if (supportedFunctional) ..._supportedFunctionalForbidden,
    ];

    return ReleaseCompileSlice(
      aim: supportedFunctional ? _aimSupportedFunctional : _aim,
      sealedWhatSignature: _sealedWhatSignature,
      forbiddenMoves: forbidden,
      responseLength: _responseLength,
      putDownDirective: _putDownDirective(turkish),
      realizationDirective: _realizationDirective,
      userContent: _userContent(
        currentTurn: currentTurn,
        grounding: conversationGrounding,
        lean: lean,
        turkish: turkish,
        hypothesis: thinkingFunctionHypothesis,
        supportedFunctional: supportedFunctional,
        priorAdmittedExpression: priorAdmittedExpression,
      ),
      systemAppendix: _systemAppendix(
        currentTurn: currentTurn,
        grounding: conversationGrounding,
        lean: lean,
        turkish: turkish,
        hypothesis: thinkingFunctionHypothesis,
        supportedFunctional: supportedFunctional,
        priorAdmittedExpression: priorAdmittedExpression,
      ),
    );
  }

  static const String _aim =
      'A gentle putting-down: the night may hold what the person no longer '
      'needs to grip.';

  static const String _aimSupportedFunctional =
      'A gentle putting-down of the authorized mind-job toward rest—not a '
      'generic let-go stamp.';

  static const String _responseLength =
      'One or two short sentences, maximum 28 words total. '
      'Quiet putting-down with enough breath—not a clipped protocol stamp. '
      'Stay in one language (do not mix Turkish and English in one reply).';

  static const String _sealedWhatSignature =
      'release / Release — invite setting the load down toward rest. '
      'Natural wording may vary (set down / leave here / loosen grip / '
      'night can hold). Do not require “Let it rest for now.” '
      'Do not validate, name, grant permission, or close.';

  String _putDownDirective(bool turkish) {
    final languageBlock = turkish
        ? 'Reply in Turkish only. Guard-legal TR put-down families include: '
            '“bir kenara bırak / koy” / “burada bırak” / “şimdilik bırak” / '
            '“geceye bırak” / “gece tutabilir / taşıyabilir” / '
            '“tutuşunu gevşet” / “yumuşakça bırak” / “bu yükü bırak”. '
            'FORBIDDEN stamp pair (never default to it): '
            '“Bunu burada bırak. Gece bunu taşıyabilir.” or near-identical '
            '“Bunu burada bırak. Gece tutabilir.” '
            'Pick ONE lean family below; do not concatenate the same two-line stamp.'
        : 'Reply in English only. Guard-legal put-down stems include: '
            '“set this down” / “leave it here” / “leave some of that here” / '
            '“let go for now” / “let go of that tonight” / “the night can hold” / '
            '“loosen your grip.” '
            'Prefer plain natural wording over “Let it rest for now.”';

    return 'Release only: invite a quiet putting-down. Keep the sealed WHAT. '
        'Every reply MUST include at least one Guard-legal put-down stem. '
        'Do not narrate softening without a put-down stem. '
        '$languageBlock '
        'Stay in one language only. '
        'Do not open with Receipt (“you’re feeling… quieter” / “yumuşuyor…”). '
        'Lead with a put-down stem in the first sentence.';
  }

  static const String _realizationDirective =
      'Realize only the sealed WHAT (release / release) as one or two '
      'short utterances. Invite setting the load down toward rest. '
      'Do not drift into Receipt, Naming, Permission, Enough, or another WHAT. '
      'Do not choose exit, silence, or a different WHAT.';

  static const List<String> _releaseIntelligenceForbidden = [
    'Stock Release catchphrase as the only form: “Let it rest for now” or '
        'near-identical let-it-rest stamps across the night',
    'Turkish stamp pair “Bunu burada bırak. Gece bunu taşıyabilir.” / '
        '“Bunu burada bırak. Gece tutabilir.” as the default Release',
    'Exact or near-exact same-night Release repetition when natural legal '
        'variation is available',
    'Receipt / First Stop Moment language',
    'Permission / obligation-ease language (“you don’t have to”, '
        '“solve this tonight”, “zorunda değilsin” as the whole Release)',
    'Naming the load as a holdable object',
    'Enough/closing language (“nothing more”, “that’s enough”)',
    'Advice, techniques, instructions, or reassurance pep',
    'Sleep commands (“go to sleep”, “fall asleep”, “uykuya”)',
    'Questions of any kind',
    'Unsupported verbatim parroting of the user’s wording as padding',
    'Inventing new emotional material or facts not in grounding',
    'Emitting internal cognition labels or camelCase kind ids in speech',
    'Canned Gold dialogue lines or reply-bank copy',
    'Bare “let go” without a temporal/place stem (use “let go for now” / '
        '“let go of that tonight” / “leave it here” / “night can hold”)',
    'Softening narration without a legal put-down stem',
  ];

  static const List<String> _supportedFunctionalForbidden = [
    'Diagnosing motives while inviting put-down',
    'Solving the daytime problem as Release',
  ];

  String _userContent({
    required String? currentTurn,
    required ConversationGroundingBuffer? grounding,
    required int lean,
    required bool turkish,
    required ThinkingFunctionHypothesis? hypothesis,
    required bool supportedFunctional,
    PriorAdmittedExpression? priorAdmittedExpression,
  }) {
    final buffer = StringBuffer()
      ..writeln(_realizationDirective)
      ..writeln()
      ..writeln(_putDownDirective(turkish))
      ..writeln()
      ..writeln(
        _shapeDirective(currentTurn: currentTurn, lean: lean, turkish: turkish),
      )
      ..writeln()
      ..writeln(_antiRepeatDirective(
        grounding: grounding,
        priorAdmittedExpression: priorAdmittedExpression,
      ));

    if (supportedFunctional && hypothesis != null) {
      buffer
        ..writeln()
        ..writeln(
          ThinkingFunctionIntelligenceShaping.releaseJobDirective(hypothesis),
        );
    }

    if (currentTurn != null) {
      buffer
        ..writeln()
        ..writeln(
          'Current-turn conversation grounding (shaping texture only; '
          'never authority; do not parrot; do not analyze; do not infer; '
          'do not summarize; do not change WHAT):',
        )
        ..writeln('"""')
        ..writeln(currentTurn)
        ..writeln('"""');
    } else {
      buffer
        ..writeln()
        ..writeln(
          'No current-turn conversation grounding was supplied. Still invite '
          'a quiet putting-down without inventing grounding or a problem.',
        );
    }

    return buffer.toString().trimRight();
  }

  String _shapeDirective({
    required String? currentTurn,
    required int lean,
    required bool turkish,
  }) {
    final leanLine = _leanInstruction(lean, turkish);
    final quiet = currentTurn != null && _looksQuieting(currentTurn)
        ? ' Quieting note: their words are softening—invite put-down lightly, '
            'without inventing new weight.'
        : '';

    return 'One or two short sentences (max 28 words). Quiet. Restward. '
        'No advice. No sleep command. No question. '
        '$leanLine$quiet';
  }

  String _antiRepeatDirective({
    required ConversationGroundingBuffer? grounding,
    PriorAdmittedExpression? priorAdmittedExpression,
  }) {
    if (priorAdmittedExpression != null) {
      return priorAdmittedExpression.antiRepeatDirective();
    }

    final priorCount = grounding == null
        ? 0
        : grounding.priorUserUtterances.length;

    if (priorCount == 0) {
      return 'Anti-repeat (HOW only): prefer a natural putting-down line; '
          'do not lock onto “Let it rest for now” or the Turkish stamp pair '
          'as the only Release form. Vary using this turn’s sealed WHAT only.';
    }

    return 'Anti-repeat (HOW only): this night already has prior user turns. '
        'If Release was invited earlier, do not reuse an identical or '
        'near-identical catchphrase. Choose a different legal putting-down '
        'wording for this sealed WHAT.';
  }

  String _systemAppendix({
    required String? currentTurn,
    required ConversationGroundingBuffer? grounding,
    required int lean,
    required bool turkish,
    required ThinkingFunctionHypothesis? hypothesis,
    required bool supportedFunctional,
    PriorAdmittedExpression? priorAdmittedExpression,
  }) {
    final stampRule = turkish
        ? 'Anti-stamp rule: never emit the default pair '
            '“Bunu burada bırak. Gece bunu taşıyabilir.” Follow the lean '
            'family instead. Keep Release meaning with natural TR variation.'
        : 'Anti-stamp rule: do not default to “Let it rest for now” or '
            '“You can set it down for now.” Prefer a quieter putting-down line '
            'inside Release meaning; avoid protocol catchphrases.';

    final antiRepeatRule = priorAdmittedExpression == null
        ? 'Anti-repeat rule: consecutive same-night Release must not collapse '
            'to one catchphrase when legal variation exists. Deterministic lean '
            'from admitted user grounding; prior assistant line not supplied.'
        : priorAdmittedExpression.antiRepeatDirective();

    final groundingRule =
        'Grounding rule: admitted user conversation grounding may tint '
        'wording only. Never infer, summarize, reinterpret, or add facts.';

    final driftRule =
        'Drift rule: do not validate, name, grant permission, close, advise, '
        'reassure, or command sleep.';

    final leanRule =
        'Deterministic lean index: $lean — ${_leanInstruction(lean, turkish)}';

    final functionRule = supportedFunctional && hypothesis != null
        ? ThinkingFunctionIntelligenceShaping.releaseJobDirective(hypothesis)
        : 'Thinking-function rule: no supported mind-job put-down shaping for '
            'this compile—use baseline Release putting-down.';

    final groundingStatus = currentTurn == null
        ? 'Conversation grounding (current turn): not supplied for this compile.'
        : 'Conversation grounding (current turn): supplied below in the user '
            'instruction for shaping only.';

    final priorNote = grounding == null || grounding.priorUserUtterances.isEmpty
        ? 'Prior user turns in window: none.'
        : 'Prior user turns in window: ${grounding.priorUserUtterances.length}.';

    return '''
Release Intelligence v$version:
${_putDownDirective(turkish)}
$stampRule
$antiRepeatRule
$groundingRule
$driftRule
$leanRule
$functionRule
$groundingStatus
$priorNote
''';
  }

  /// Instructional lean only (not a reply library). Deterministic from
  /// admitted user grounding window.
  String _leanInstruction(int lean, bool turkish) {
    if (turkish) {
      switch (lean % 5) {
        case 0:
          return 'Lean TR: soft set-aside — “bir kenara bırak / koy”, '
              '“şimdi kenara koy”; optional short night-hold breath.';
        case 1:
          return 'Lean TR: loosen grip — “tutuşunu gevşet”, “yumuşakça bırak”; '
              'no Permission-only obligation line as the whole reply.';
        case 2:
          return 'Lean TR: night-hold first — lead with “gece tutabilir / '
              'taşıyabilir / geceye bırak”; do not open with “Bunu burada bırak.”';
        case 3:
          return 'Lean TR: leave-here — “burada bırak”, “şimdilik burada bırak”, '
              '“bu yükü burada bırak”; vary the second breath.';
        default:
          return 'Lean TR: load put-down — “bu yükü bırak”, “taşımayı bırak”, '
              '“geceye bırak”; keep one short night-hold if needed.';
      }
    }

    switch (lean % 5) {
      case 0:
        return 'Lean: soft set-down / lay-aside putting-down frame.';
      case 1:
        return 'Lean: loosen-grip / stop-holding putting-down frame.';
      case 2:
        return 'Lean: night-can-hold first; put-down may follow lightly.';
      case 3:
        return 'Lean: leave-it-here / leave-some-of-that putting-down frame.';
      default:
        return 'Lean: set-aside / rest-it-here putting-down frame.';
    }
  }

  /// Stable lean from user grounding only. Same grounding → same lean.
  int _deterministicLean(ConversationGroundingBuffer? grounding) {
    if (grounding == null || grounding.isEmpty) {
      return 0;
    }
    final material = grounding.userUtterances.join('\u0001');
    var hash = 0;
    for (final unit in material.codeUnits) {
      hash = (hash * 31 + unit) & 0x7fffffff;
    }
    return hash % 5;
  }

  bool _looksTurkish(ConversationGroundingBuffer? grounding) {
    if (grounding == null || grounding.isEmpty) return false;
    final lower = grounding.userUtterances.join(' ').toLowerCase();
    if (RegExp(r'[ğüşıöçâîû]').hasMatch(lower)) return true;
    return lower.contains('yalniz') ||
        lower.contains('yalnız') ||
        lower.contains('zihn') ||
        lower.contains('tamam') ||
        lower.contains('yumus') ||
        lower.contains('yumuş') ||
        lower.contains('sessiz') ||
        lower.contains('biraz');
  }

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

  bool _looksQuieting(String text) {
    final lower = text.toLowerCase();
    return lower.contains('quiet') ||
        lower.contains('softer') ||
        lower.contains('softening') ||
        lower.contains('ready to rest') ||
        lower.contains('let this rest') ||
        lower.contains('enough for') ||
        lower.contains('sessiz') ||
        lower.contains('yumuş') ||
        lower.contains('yumus') ||
        lower.contains('rahat');
  }
}

/// Release-only compile material produced by [ReleaseIntelligence].
class ReleaseCompileSlice {
  final String aim;
  final String sealedWhatSignature;
  final List<String> forbiddenMoves;
  final String responseLength;
  final String putDownDirective;
  final String realizationDirective;
  final String userContent;
  final String systemAppendix;

  const ReleaseCompileSlice({
    required this.aim,
    required this.sealedWhatSignature,
    required this.forbiddenMoves,
    required this.responseLength,
    required this.putDownDirective,
    required this.realizationDirective,
    required this.userContent,
    required this.systemAppendix,
  });
}
