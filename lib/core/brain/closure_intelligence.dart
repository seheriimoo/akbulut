import 'conversation_blueprint_binding.dart';
import 'conversation_grounding_buffer.dart';

/// Closure Intelligence V1 (Slice 3)
///
/// After integrate ack: tonight boundary + personalized put-down from insight.
class ClosureIntelligence {
  const ClosureIntelligence();

  static const String version = '1.0';

  ClosureCompileSlice compile({
    required BlueprintStageBinding stage,
    ConversationGroundingBuffer? conversationGrounding,
    String? confirmedReframeText,
    String? integrateText,
  }) {
    assert(stage.stage == BlueprintStage.receipt);

    final currentTurn = _currentTurnGrounding(conversationGrounding);
    final forbidden = <String>[
      ...stage.forbiddenMoves,
      ..._closureForbidden,
    ];

    return ClosureCompileSlice(
      aim: _aim,
      sealedWhatSignature: _sealedWhatSignature,
      forbiddenMoves: forbidden,
      responseLength: _responseLength,
      closureDirective: _closureDirective,
      realizationDirective: _realizationDirective,
      userContent: _userContent(
        currentTurn: currentTurn,
        confirmedReframe: confirmedReframeText,
        integrate: integrateText,
      ),
      systemAppendix: _systemAppendix,
    );
  }

  static String? _currentTurnGrounding(ConversationGroundingBuffer? buffer) {
    if (buffer == null || buffer.isEmpty) return null;
    return buffer.currentUserUtterance;
  }

  static const String _aim =
      'Draw a tonight-usable conclusion: what cannot be solved tonight, '
      'what can be put down — tied to their confirmed insight.';

  static const String _sealedWhatSignature =
      'validation / Receipt — Closure after integrate ack. '
      'Personalized boundary + put-down. No generic Release. No question.';

  static const String _responseLength =
      'Two or three short sentences, maximum 42 words total. No question mark.';

  static const String _closureDirective =
      'Closure (Slice 3): they accepted the integrate line. Now close the loop '
      'for tonight using THEIR insight — not a generic template. '
      'Structure (natural, not mechanical): what cannot be solved tonight → '
      'what can be put down tonight. '
      'Good: “Ama onun seni nasıl göreceğini bu gece kesinleştiremezsin. '
      'Yarınki konuşma yarının işi. Bu gece kendini onun gözünde kanıtlamak '
      'zorunda değilsin.” '
      'Good (relationship): “O güven duygusunu bu gece geri getirmek zorunda '
      'değilsin. Özlemek, geri dönmen gerektiği anlamına gelmiyor.” '
      'Bad: “Bu gece bunu çözmek zorunda değilsin.” (too generic), '
      '“Anlıyorum.”, questions, new hypotheses, sleep commands. '
      'Must echo specific objects from their evidence (manager, reaction, trust, etc.).';

  static const String _realizationDirective =
      'Realize personalized closure only — boundary + put-down from their arc. '
      'Then stop. No question.';

  static const List<String> _closureForbidden = [
    'Generic “Bu gece bunu çözmek zorunda değilsin.” without their insight',
    '“Anlıyorum.”',
    'New reframe or diagnosis',
    'Questions',
    'Advice or plans',
    'Sleep commands',
    'Invented outcomes user did not imply',
  ];

  String _userContent({
    required String? currentTurn,
    required String? confirmedReframe,
    required String? integrate,
  }) {
    final reframeBlock = confirmedReframe == null || confirmedReframe.isEmpty
        ? ''
        : '\n\nConfirmed reframe:\n"""$confirmedReframe"""';
    final integrateBlock = integrate == null || integrate.isEmpty
        ? ''
        : '\n\nIntegrate line they accepted:\n"""$integrate"""';
    final turn = currentTurn == null
        ? ''
        : '\n\nCurrent turn context (shaping only):\n"""$currentTurn"""';
    return '$_realizationDirective\n\n$_closureDirective$reframeBlock$integrateBlock$turn';
  }

  static const String _systemAppendix = '''
Closure Intelligence v$version:
$_closureDirective
Personalized to their arc. No generic Release. No question this turn.
''';
}

class ClosureCompileSlice {
  final String aim;
  final String sealedWhatSignature;
  final List<String> forbiddenMoves;
  final String responseLength;
  final String closureDirective;
  final String realizationDirective;
  final String userContent;
  final String systemAppendix;

  const ClosureCompileSlice({
    required this.aim,
    required this.sealedWhatSignature,
    required this.forbiddenMoves,
    required this.responseLength,
    required this.closureDirective,
    required this.realizationDirective,
    required this.userContent,
    required this.systemAppendix,
  });
}
