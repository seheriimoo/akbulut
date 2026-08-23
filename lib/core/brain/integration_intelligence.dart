import 'conversation_blueprint_binding.dart';
import 'conversation_grounding_buffer.dart';

/// Integration Intelligence V1 (Slice 3)
///
/// After reframe confirm: connect confirmed insight to tonight's loop.
/// Not a new reframe. No question. No advice.
class IntegrationIntelligence {
  const IntegrationIntelligence();

  static const String version = '1.0';

  IntegrationCompileSlice compile({
    required BlueprintStageBinding stage,
    ConversationGroundingBuffer? conversationGrounding,
    String? confirmedReframeText,
  }) {
    assert(stage.stage == BlueprintStage.receipt);

    final currentTurn = _currentTurnGrounding(conversationGrounding);
    final forbidden = <String>[
      ...stage.forbiddenMoves,
      ..._integrateForbidden,
    ];

    return IntegrationCompileSlice(
      aim: _aim,
      sealedWhatSignature: _sealedWhatSignature,
      forbiddenMoves: forbidden,
      responseLength: _responseLength,
      integrateDirective: _integrateDirective,
      realizationDirective: _realizationDirective,
      userContent: _userContent(
        currentTurn: currentTurn,
        confirmedReframe: confirmedReframeText,
      ),
      systemAppendix: _systemAppendix,
    );
  }

  static String? _currentTurnGrounding(ConversationGroundingBuffer? buffer) {
    if (buffer == null || buffer.isEmpty) return null;
    return buffer.currentUserUtterance;
  }

  static const String _aim =
      'Connect the confirmed reframe to what their mind is doing tonight — '
      'one coherent model from their evidence. Not a new diagnosis.';

  static const String _sealedWhatSignature =
      'validation / Receipt — Integrate after reframe confirm only. '
      'Link confirmed insight to tonight loop. No question. No Release.';

  static const String _responseLength =
      'One or two short sentences, maximum 32 words. No question mark.';

  static const String _integrateDirective =
      'Integrate (Slice 3): the user confirmed your reframe. Now show what '
      'that insight means for the loop keeping them awake tonight. '
      'Use their confirmed angle — do NOT introduce a new hypothesis. '
      'Good: “O zaman zihnin yarınki konuşmayı çözmekten çok, onun gözünde '
      'nasıl görüneceğini şimdiden güvenceye almaya çalışıyor.” '
      'Good: “Bu yüzden zihnin yorulduğu halde düşünmeyi bırakmayı risk gibi görüyor.” '
      'Bad: “Anlıyorum.”, “Belki zihnin bir şeyleri çözmeye çalışıyor.”, '
      '“Bunu bırakabilirsin.”, any new reframe, any question, any advice. '
      'Derive only from confirmed reframe + their prior evidence.';

  static const String _realizationDirective =
      'Realize one integrate line only — bridge confirmed insight to tonight. '
      'Then stop. No question.';

  static const List<String> _integrateForbidden = [
    '“Anlıyorum.” / empathy filler',
    '“Bu çok zor olmalı.”',
    '“Belki zihnin bir şeyleri çözmeye çalışıyor.” without specific evidence',
    'New reframe or new diagnosis',
    'Questions',
    'Advice or plans',
    'Permission / Release / sleep coaching',
    'Generic put-down',
  ];

  String _userContent({
    required String? currentTurn,
    required String? confirmedReframe,
  }) {
    final reframeBlock = confirmedReframe == null || confirmedReframe.isEmpty
        ? ''
        : '\n\nConfirmed reframe they accepted:\n"""$confirmedReframe"""';
    final turn = currentTurn == null
        ? ''
        : '\n\nCurrent turn context (shaping only):\n"""$currentTurn"""';
    return '$_realizationDirective\n\n$_integrateDirective$reframeBlock$turn';
  }

  static const String _systemAppendix = '''
Integration Intelligence v$version:
$_integrateDirective
Confirmed insight only. No new theory. No question this turn.
''';
}

class IntegrationCompileSlice {
  final String aim;
  final String sealedWhatSignature;
  final List<String> forbiddenMoves;
  final String responseLength;
  final String integrateDirective;
  final String realizationDirective;
  final String userContent;
  final String systemAppendix;

  const IntegrationCompileSlice({
    required this.aim,
    required this.sealedWhatSignature,
    required this.forbiddenMoves,
    required this.responseLength,
    required this.integrateDirective,
    required this.realizationDirective,
    required this.userContent,
    required this.systemAppendix,
  });
}
