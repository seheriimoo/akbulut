import 'conversation_blueprint_binding.dart';
import 'conversation_grounding_buffer.dart';

/// Reframe Intelligence V1 (Slice 2)
///
/// Evidence-gated soft reframe — one new relational angle the user could
/// confirm or correct. Not advice. Not generic Belki fatigue.
class ReframeIntelligence {
  const ReframeIntelligence();

  static const String version = '1.0';

  ReframeCompileSlice compile({
    required BlueprintStageBinding stage,
    ConversationGroundingBuffer? conversationGrounding,
  }) {
    assert(stage.stage == BlueprintStage.receipt);

    final currentTurn = _currentTurnGrounding(conversationGrounding);
    final forbidden = <String>[
      ...stage.forbiddenMoves,
      ..._reframeForbidden,
    ];

    return ReframeCompileSlice(
      aim: _aim,
      sealedWhatSignature: _sealedWhatSignature,
      forbiddenMoves: forbidden,
      responseLength: _responseLength,
      reframeDirective: _reframeDirective,
      realizationDirective: _realizationDirective,
      userContent: _userContent(currentTurn: currentTurn),
      systemAppendix: _systemAppendix,
    );
  }

  static String? _currentTurnGrounding(ConversationGroundingBuffer? buffer) {
    if (buffer == null || buffer.isEmpty) return null;
    return buffer.currentUserUtterance;
  }

  static const String _aim =
      'Offer one short, evidence-based reframe the user could say “evet” to — '
      'a new relationship between facts they already gave. Not advice.';

  static const String _sealedWhatSignature =
      'validation / Receipt — Reframe only when evidence-ready. One soft new '
      'angle from their words. Confirmable. No Release/Permission.';

  static const String _responseLength =
      'One or two short sentences, maximum 28 words. Soft epistemic tail allowed.';

  static const String _reframeDirective =
      'Reframe (Slice 2): connect what they already said into one new angle '
      'they could recognize. Use soft tails like “olabilir”, “gibi”, '
      '“sanırım”, “galiba” — vary syntax; never use Belki/Sanki on this turn. '
      'Good: “O zaman konuşmanın kendisinden çok, onun gözünde nasıl görüneceğin '
      'geceyi açık tutuyor olabilir.” '
      'Bad: “Belki bunu bırakmakta zorlanıyorsun.”, “Sanki bu sana ağır geliyor.” '
      'Must derive from THEIR evidence (narrow answer, repeated concern, causal line). '
      'Never declare hard truth. No question on this turn — let them confirm next turn. '
      'No Permission/Release/sleep coaching.';

  static const String _realizationDirective =
      'Realize one evidence-based reframe only. Then stop. No second reframe. '
      'No follow-up question on this turn.';

  static const List<String> _reframeForbidden = [
    'Generic Belki/Sanki templates without user-specific evidence',
    '“Belki bunu bırakmakta zorlanıyorsun” / “Sanki bu sana ağır geliyor”',
    '“Belki zihnin bir şeyleri çözmeye çalışıyor” without specific evidence',
    'Permission obligation-ease',
    'Release put-down',
    'Questions on this turn',
    'Hard certainty / diagnosis',
    'Invented psychology they did not say',
    'Advice or plans',
  ];

  String _userContent({required String? currentTurn}) {
    final turn = currentTurn == null
        ? ''
        : '\n\nCurrent turn + prior grounding context (shaping only):\n"""$currentTurn"""';
    return '$_realizationDirective\n\n$_reframeDirective$turn';
  }

  static const String _systemAppendix = '''
Reframe Intelligence v$version:
$_reframeDirective
Evidence-only. Confirmable. No question this turn.
''';
}

class ReframeCompileSlice {
  final String aim;
  final String sealedWhatSignature;
  final List<String> forbiddenMoves;
  final String responseLength;
  final String reframeDirective;
  final String realizationDirective;
  final String userContent;
  final String systemAppendix;

  const ReframeCompileSlice({
    required this.aim,
    required this.sealedWhatSignature,
    required this.forbiddenMoves,
    required this.responseLength,
    required this.reframeDirective,
    required this.realizationDirective,
    required this.userContent,
    required this.systemAppendix,
  });
}
