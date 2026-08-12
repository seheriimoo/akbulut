import 'conversation_blueprint_binding.dart';
import 'conversation_grounding_buffer.dart';
import 'permission_realization_contract.dart';
import 'prior_admitted_expression.dart';
import 'thinking_function_hypothesis.dart';
import 'thinking_function_intelligence_shaping.dart';

/// Permission Intelligence V1.2
///
/// Deterministic Permission-only compilation aid inside Conversation Compiler.
/// Authorizes non-resolution / eases obligation toward rest.
///
/// Steers realization into the shared [PermissionRealizationContract] so live
/// LLM variation stays inside Guard-admissible Permission speech acts
/// (obligation-ease — never Release put-down).
///
/// Optional [ThinkingFunctionHypothesis] (supported+) shapes HOW to reduce the
/// obligation created by the mind-job. Never chooses WHAT, readiness, exit,
/// or memory. Null/tentative preserves baseline Permission.
///
/// Current-turn grounding source: admitted [ConversationGroundingBuffer] only.
/// Grounding may shape wording texture; never decision authority.
class PermissionIntelligence {
  const PermissionIntelligence();

  static const String version = '1.2';

  /// Soft upper bound for current-turn grounding text in compile output.
  static const int maxCurrentGroundingChars = 480;

  /// Compile Permission-specific instruction material for the sealed stage.
  PermissionCompileSlice compile({
    required BlueprintStageBinding stage,
    ConversationGroundingBuffer? conversationGrounding,
    ThinkingFunctionHypothesis? thinkingFunctionHypothesis,
    PriorAdmittedExpression? priorAdmittedExpression,
  }) {
    assert(stage.stage == BlueprintStage.permission);

    final currentTurn = _currentTurnGrounding(conversationGrounding);
    final supportedFunctional =
        ThinkingFunctionIntelligenceShaping.isSupportedOrStrong(
      thinkingFunctionHypothesis,
    );
    final forbidden = <String>[
      ...stage.forbiddenMoves,
      ..._permissionIntelligenceForbidden,
      ...PermissionRealizationContract.intelligenceForbiddenMoves(),
      if (supportedFunctional) ..._supportedFunctionalForbidden,
    ];

    return PermissionCompileSlice(
      aim: supportedFunctional ? _aimSupportedFunctional : _aim,
      sealedWhatSignature: _sealedWhatSignature,
      forbiddenMoves: forbidden,
      responseLength: _responseLength,
      easeDirective: _easeDirective,
      realizationDirective: _realizationDirective,
      userContent: _userContent(
        currentTurn: currentTurn,
        hypothesis: thinkingFunctionHypothesis,
        supportedFunctional: supportedFunctional,
        priorAdmittedExpression: priorAdmittedExpression,
      ),
      systemAppendix: _systemAppendix(
        currentTurn: currentTurn,
        hypothesis: thinkingFunctionHypothesis,
        supportedFunctional: supportedFunctional,
        priorAdmittedExpression: priorAdmittedExpression,
      ),
    );
  }

  static const String _aim =
      'Authorize rest as legitimate. Make non-resolution emotionally allowed. '
      'Ease obligation—nothing more.';

  static const String _aimSupportedFunctional =
      'Authorize rest by reducing the specific obligation created by the '
      'authorized night mind-job—without solving, diagnosing, or enacting '
      'Release put-down.';

  static const String _responseLength =
      'One or two short sentences, maximum 24 words. '
      'Enough breath to ease obligation—not a clipped stamp.';

  static const String _sealedWhatSignature =
      'permission / Permission — ease pressure toward rest: non-resolution is '
      'allowed tonight. Natural wording may vary only inside the Permission '
      'Realization Contract. Do not require '
      '“solve / figure / sort this tonight.” Do not validate, name the load, '
      'invite release, or close. On quiet/low-load turns, authorize pause '
      'without inventing a problem to solve.';

  static const String _easeDirective =
      'Permission only: remove the obligation to solve, perform, or finish '
      'tonight. Keep the sealed WHAT. '
      'Speech-act: “you are not required to keep doing X tonight.” '
      'Not Release: “now stop / put down / let go of X.” '
      'Never write “you can let go…” — that fails Guard under Permission. '
      'Prefer: don’t need to keep thinking/rehearsing/preparing; '
      'it’s okay not to prepare for the worst tonight; pause the rehearsal. '
      'Mirror the person’s language (English or Turkish). '
      'Vary naturally only inside the Permission realization contract.';

  static const String _realizationDirective =
      'Realize only the sealed WHAT (permission / permission) as exactly one '
      'short utterance. Authorize non-resolution toward rest. '
      'Do not drift into Receipt, Naming, Release, Enough, or another WHAT. '
      'Do not choose release, protocol, exit, or silence.';

  static const String _speechActBarrier =
      'Speech-act barrier: PERMISSION reduces obligation '
      '(don’t/do not have to; don’t/do not need to; no need to; can pause; '
      'can leave unresolved). RELEASE enacts put-down '
      '(let go / set down / put down / let it rest / loosen grip). '
      'Do not paraphrase obligation-ease into Release enactment.';

  static const List<String> _permissionIntelligenceForbidden = [
    'Stock Permission stamps as the only form: “you don’t have to figure this '
        'out tonight”, “you don’t have to sort this out tonight”, or near-'
        'identical solve/figure/sort-tonight templates',
    'Forcing solve / figure / sort language when their words name no problem '
        'to resolve',
    'Release paraphrase under Permission: “you can let go…”, “set it down”, '
        '“leave it here”, “the night can hold”',
    'Inventing a task, conflict, or puzzle they did not bring',
    'Unsupported verbatim parroting of the user’s wording as padding',
    'Emitting internal cognition labels or camelCase kind ids in speech',
    'Canned Gold dialogue lines or reply-bank copy',
  ];

  static const List<String> _supportedFunctionalForbidden = [
    'Diagnosing motives or clinicalizing the mind-job',
    'Solving tomorrow / the feared future in Permission',
    'Turning mind-job obligation reduction into put-down / let-go wording',
  ];

  String _userContent({
    required String? currentTurn,
    required ThinkingFunctionHypothesis? hypothesis,
    required bool supportedFunctional,
    PriorAdmittedExpression? priorAdmittedExpression,
  }) {
    final buffer = StringBuffer()
      ..writeln(_realizationDirective)
      ..writeln()
      ..writeln(_easeDirective)
      ..writeln()
      ..writeln(_speechActBarrier)
      ..writeln()
      ..writeln(_shapeDirective(currentTurn))
      ..writeln()
      ..writeln(PermissionRealizationContract.intelligenceSteeringDirective());

    if (supportedFunctional && hypothesis != null) {
      buffer
        ..writeln()
        ..writeln(
          ThinkingFunctionIntelligenceShaping.permissionObligationDirective(
            hypothesis,
          ),
        );
    }

    if (priorAdmittedExpression != null) {
      buffer
        ..writeln()
        ..writeln(priorAdmittedExpression.antiRepeatDirective());
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
          'No current-turn conversation grounding was supplied. Still ease '
          'obligation toward rest without inventing a problem or grounding.',
        );
    }

    return buffer.toString().trimRight();
  }

  String _shapeDirective(String? currentTurn) {
    final lowLoad = currentTurn != null && _looksLowLoad(currentTurn)
        ? ' Low-load note: their line is quiet/thin—authorize pause or '
            'non-pushing without inventing something to figure out.'
        : '';

    final active = currentTurn != null &&
            !_looksLowLoad(currentTurn) &&
            _looksActiveLoad(currentTurn)
        ? ' Active-load note: pressure/looping/anxiety/relational residue may '
            'be present—ease obligation with light wording texture from their '
            'words only; do not re-receive or name the load.'
        : '';

    return 'One short sentence (max 20 words). Restward. No advice. '
        'No solving. No question. Vary naturally only inside the Permission '
        'realization contract; do not stamp figure/sort/solve-tonight by '
        'default.$lowLoad$active';
  }

  String _systemAppendix({
    required String? currentTurn,
    required ThinkingFunctionHypothesis? hypothesis,
    required bool supportedFunctional,
    PriorAdmittedExpression? priorAdmittedExpression,
  }) {
    final stampRule =
        'Anti-stamp rule: do not default to “you don’t have to '
        'figure/sort/solve this out tonight.” Keep Permission meaning with '
        'natural variation only inside the Permission realization contract.';

    final lowLoadRule =
        'Low-load rule: if their words are sparse or already quiet, authorize '
        'pause without inventing a problem.';

    final groundingRule =
        'Grounding rule: admitted conversation grounding may tint wording '
        'only. It never changes WHAT, never becomes Receipt, and never adds '
        'facts.';

    final driftRule =
        'Drift rule: do not validate texture, name the load, invite release, '
        'enact put-down, or close the night.';

    final antiRepeatRule = priorAdmittedExpression == null
        ? 'Anti-repeat rule: no prior admitted assistant line for this compile.'
        : priorAdmittedExpression.antiRepeatDirective();

    final functionRule = supportedFunctional && hypothesis != null
        ? ThinkingFunctionIntelligenceShaping.permissionObligationDirective(
            hypothesis,
          )
        : 'Thinking-function rule: no supported mind-job obligation shaping '
            'for this compile—use baseline Permission ease.';

    final grounding = currentTurn == null
        ? 'Conversation grounding (current turn): not supplied for this compile.'
        : 'Conversation grounding (current turn): supplied below in the user '
            'instruction for shaping only.';

    final contractRule =
        PermissionRealizationContract.intelligenceSteeringDirective();

    return '''
Permission Intelligence v$version:
$_easeDirective
$_speechActBarrier
$stampRule
$lowLoadRule
$groundingRule
$driftRule
$antiRepeatRule
$functionRule
$contractRule
$grounding
''';
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

  bool _looksLowLoad(String text) {
    final words = text
        .trim()
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .length;
    if (words <= 4) return true;
    final lower = text.toLowerCase();
    return lower.contains('still here') ||
        lower.contains('softening') ||
        lower.contains('quieter') ||
        lower == 'here' ||
        lower == 'i am here.' ||
        lower == 'i am here';
  }

  bool _looksActiveLoad(String text) {
    final lower = text.toLowerCase();
    return lower.contains('think') ||
        lower.contains('loop') ||
        lower.contains('what if') ||
        lower.contains('miss') ||
        lower.contains('alone') ||
        lower.contains('heavy') ||
        lower.contains('work') ||
        lower.contains('deadline') ||
        lower.contains('bill') ||
        lower.contains('argu') ||
        lower.contains('fight');
  }
}

/// Permission-only compile material produced by [PermissionIntelligence].
class PermissionCompileSlice {
  final String aim;
  final String sealedWhatSignature;
  final List<String> forbiddenMoves;
  final String responseLength;
  final String easeDirective;
  final String realizationDirective;
  final String userContent;
  final String systemAppendix;

  const PermissionCompileSlice({
    required this.aim,
    required this.sealedWhatSignature,
    required this.forbiddenMoves,
    required this.responseLength,
    required this.easeDirective,
    required this.realizationDirective,
    required this.userContent,
    required this.systemAppendix,
  });
}
