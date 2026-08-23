import 'conversation_blueprint_binding.dart';
import 'conversation_grounding_buffer.dart';

/// Repair Intelligence V1 (Slice 1)
///
/// Compile aid when the user protests a misread or repetition.
/// Realizes as validation WHAT with repair steering — not Permission ease.
class RepairIntelligence {
  const RepairIntelligence();

  static const String version = '1.0';

  RepairCompileSlice compile({
    required BlueprintStageBinding stage,
    ConversationGroundingBuffer? conversationGrounding,
    required bool repetitionProtest,
  }) {
    assert(stage.stage == BlueprintStage.receipt);

    final currentTurn = _currentTurnGrounding(conversationGrounding);
    final forbidden = <String>[
      ...stage.forbiddenMoves,
      ..._repairForbidden,
    ];

    return RepairCompileSlice(
      aim: repetitionProtest ? _aimRepetition : _aimCorrection,
      sealedWhatSignature: _sealedWhatSignature,
      forbiddenMoves: forbidden,
      responseLength: _responseLength,
      repairDirective:
          repetitionProtest ? _repetitionDirective : _correctionDirective,
      realizationDirective: _realizationDirective,
      userContent: _userContent(
        repetitionProtest: repetitionProtest,
        currentTurn: currentTurn,
      ),
      systemAppendix: _systemAppendix(repetitionProtest: repetitionProtest),
    );
  }

  static String? _currentTurnGrounding(ConversationGroundingBuffer? buffer) {
    if (buffer == null || buffer.isEmpty) return null;
    return buffer.currentUserUtterance;
  }

  static const String _aimCorrection =
      'Acknowledge the misread briefly, drop the prior hypothesis, and ask '
      'one short clarifying question about what is actually keeping them awake.';

  static const String _aimRepetition =
      'Acknowledge repetition fairly, stop restating the same frame, and '
      'invite a fresh angle in one short line plus optional one question.';

  static const String _sealedWhatSignature =
      'validation / Receipt — repair after protest. Drop prior reframe. '
      'Do not ease obligation (Permission). Do not put down (Release).';

  static const String _responseLength =
      'One or two short sentences, maximum 22 words. Plain, human, direct.';

  static const String _correctionDirective =
      'Correction repair: start by conceding the misread (“Tamam, orayı yanlış '
      'okudum” / “Okay, I read that wrong”). Name what they corrected if plain '
      'in their words. End with one specific question about what IS true for '
      'them tonight — not a generic “how do you feel”.';

  static const String _repetitionDirective =
      'Repetition repair: concede fairly (“Haklısın, aynı yere döndüm” / '
      '“You’re right, I kept saying the same thing”). Do not repeat Permission '
      'or Release stems. Offer to look from another angle; one question max.';

  static const String _realizationDirective =
      'Realize repair only. Do not Permission-ease. Do not Release. '
      'Do not reframe with Belki/Sanki/aslında on this turn.';

  static const List<String> _repairForbidden = [
    'Permission obligation-ease: gerekmiyor, zorunda değilsin, solve tonight',
    'Release put-down: bırak, geceye bırak, let go, let it rest',
    'Enough/closing: bu kadar yeter, nothing more needed',
    'Belki/Sanki/aslında reframe on this repair turn',
    'Repeating the same Permission stem they protested',
    'Inventing psychology they did not say',
    'More than one question',
  ];

  String _userContent({
    required bool repetitionProtest,
    required String? currentTurn,
  }) {
    final base = repetitionProtest ? _repetitionDirective : _correctionDirective;
    final turn = currentTurn == null
        ? ''
        : '\n\nCurrent turn (shaping only):\n"""$currentTurn"""';
    return '$_realizationDirective\n\n$base$turn';
  }

  String _systemAppendix({required bool repetitionProtest}) {
    return '''
Repair Intelligence v$version:
${repetitionProtest ? _repetitionDirective : _correctionDirective}
Drop prior hypothesis. No Permission. No Release. One question max.
''';
  }
}

class RepairCompileSlice {
  final String aim;
  final String sealedWhatSignature;
  final List<String> forbiddenMoves;
  final String responseLength;
  final String repairDirective;
  final String realizationDirective;
  final String userContent;
  final String systemAppendix;

  const RepairCompileSlice({
    required this.aim,
    required this.sealedWhatSignature,
    required this.forbiddenMoves,
    required this.responseLength,
    required this.repairDirective,
    required this.realizationDirective,
    required this.userContent,
    required this.systemAppendix,
  });
}
