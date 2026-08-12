import 'conversation_blueprint_binding.dart';
import 'conversation_grounding_buffer.dart';

/// Neutral Entry Intelligence V1
///
/// Deterministic Neutral Entry compilation aid inside Conversation Compiler.
/// Emits a short greeting acknowledgment when there is nothing emotional
/// to receive yet.
///
/// Does not choose WHAT, psychology, release, exit, or protocol.
/// Does not generate the final utterance.
/// Does not apply to Receipt, Naming, Permission, Release, or Enough.
class NeutralEntryIntelligence {
  const NeutralEntryIntelligence();

  static const String version = '1.0';

  NeutralEntryCompileSlice compile({
    required BlueprintStageBinding stage,
    ConversationGroundingBuffer? conversationGrounding,
  }) {
    assert(stage.stage == BlueprintStage.neutralEntry);

    final forbidden = <String>[
      ...stage.forbiddenMoves,
      ..._neutralEntryForbidden,
    ];

    return NeutralEntryCompileSlice(
      aim: _aim,
      sealedWhatSignature: _sealedWhatSignature,
      forbiddenMoves: forbidden,
      responseLength: _responseLength,
      welcomeDirective: _welcomeDirective,
      realizationDirective: _realizationDirective,
      userContent: _userContent(),
      systemAppendix: _systemAppendix(),
    );
  }

  static const String _aim =
      'Acknowledge a content-free greeting with one short, natural line. '
      'Open the night without inventing emotion or a problem.';

  static const String _responseLength =
      'Exactly one short sentence, maximum 12 words. '
      'Prefer the fewest helpful words.';

  static const String _sealedWhatSignature =
      'neutralEntry / Neutral Entry — brief greeting acknowledgment only. '
      'Do not receive emotional texture, name a load, grant permission, '
      'invite release, or close. Do not invent distress, stillness, presence, '
      'or a sleep problem.';

  static const String _welcomeDirective =
      'Neutral Entry only: greet back briefly. Keep the sealed WHAT. '
      'No emotional receipt. No questions. No coaching.';

  static const String _realizationDirective =
      'Realize only the sealed WHAT (neutralEntry / neutral entry) as exactly '
      'one short utterance. Acknowledge the greeting. '
      'Do not drift into Receipt, Naming, Permission, Release, Enough, '
      'or another WHAT. Do not choose release, protocol, exit, or silence.';

  static const List<String> _neutralEntryForbidden = [
    'Questions of any kind',
    'Invented emotion, distress, ache, heaviness, or loneliness',
    'Invented stillness, presence, mindfulness, or inner peace',
    'Invented sleep problem or insomnia framing',
    'Receipt / First Stop Moment language',
    'Naming the load',
    'Permission / obligation-ease language',
    'Release / put-down language',
    'Enough/closing language',
    'Advice, plans, techniques, or engagement hooks',
    'How-are-you or feeling check-ins',
  ];

  String _userContent() {
    return '$_realizationDirective\n\n'
        '$_welcomeDirective\n\n'
        'Exactly one short sentence (max 12 words). Natural. Quiet. '
        'No question. No invented emotion, presence, stillness, or problem.';
  }

  String _systemAppendix() {
    return '''
Neutral Entry Intelligence v$version:
$_welcomeDirective
No-invention rule: do not invent emotion, distress, psychology, stillness, presence, or a sleep problem.
No-question rule: questions are forbidden.
Drift rule: do not Receipt, Name, grant Permission, invite Release, or close.
''';
  }
}

/// Neutral Entry compile material produced by [NeutralEntryIntelligence].
class NeutralEntryCompileSlice {
  final String aim;
  final String sealedWhatSignature;
  final List<String> forbiddenMoves;
  final String responseLength;
  final String welcomeDirective;
  final String realizationDirective;
  final String userContent;
  final String systemAppendix;

  const NeutralEntryCompileSlice({
    required this.aim,
    required this.sealedWhatSignature,
    required this.forbiddenMoves,
    required this.responseLength,
    required this.welcomeDirective,
    required this.realizationDirective,
    required this.userContent,
    required this.systemAppendix,
  });
}
