import 'conversation_blueprint_binding.dart';
import 'conversation_grounding_buffer.dart';
import 'light_conversation_detector.dart';

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
  const NeutralEntryIntelligence({
    this.lightConversation = const LightConversationDetector(),
  });

  final LightConversationDetector lightConversation;

  static const String version = '1.0';

  NeutralEntryCompileSlice compile({
    required BlueprintStageBinding stage,
    ConversationGroundingBuffer? conversationGrounding,
  }) {
    assert(stage.stage == BlueprintStage.neutralEntry);

    final currentTurn = _currentTurnGrounding(conversationGrounding);
    final isLightTurn = currentTurn != null &&
        lightConversation.isLightConversation(currentTurn);

    final forbidden = <String>[
      ...stage.forbiddenMoves,
      ..._neutralEntryForbidden,
      if (isLightTurn) ..._lightConversationForbidden,
    ];

    return NeutralEntryCompileSlice(
      aim: isLightTurn ? _aimLight : _aim,
      sealedWhatSignature:
          isLightTurn ? _sealedWhatSignatureLight : _sealedWhatSignature,
      forbiddenMoves: forbidden,
      responseLength: isLightTurn ? _responseLengthLight : _responseLength,
      welcomeDirective: isLightTurn ? _lightWelcomeDirective : _welcomeDirective,
      realizationDirective: _realizationDirective,
      userContent: _userContent(isLightTurn: isLightTurn),
      systemAppendix: _systemAppendix(isLightTurn: isLightTurn),
    );
  }

  static String? _currentTurnGrounding(ConversationGroundingBuffer? buffer) {
    if (buffer == null || buffer.isEmpty) return null;
    return buffer.currentUserUtterance;
  }

  static const String _aimLight =
      'Acknowledge positive, mundane, playful, or chat-only warmth with one '
      'short natural line. Keep their tone — do not invert it into distress.';

  static const String _aim =
      'Acknowledge a content-free greeting with one short, natural line. '
      'Open the night without inventing emotion or a problem.';

  static const String _responseLengthLight =
      'Exactly one short sentence, maximum 16 words. Warm, plain, unforced.';

  static const String _responseLength =
      'Exactly one short sentence, maximum 12 words. '
      'Prefer the fewest helpful words.';

  static const String _sealedWhatSignatureLight =
      'neutralEntry / Neutral Entry — brief warm acknowledgment of positive, '
      'mundane, playful, or chat-only content. Do not receive it as distress, '
      'burden, worry, or night-load. Do not grant permission, invite release, '
      'or close.';

  static const String _sealedWhatSignature =
      'neutralEntry / Neutral Entry — brief greeting acknowledgment only. '
      'Do not receive emotional texture, name a load, grant permission, '
      'invite release, or close. Do not invent distress, stillness, presence, '
      'or a sleep problem.';

  static const String _welcomeDirective =
      'Neutral Entry only: greet back briefly. Keep the sealed WHAT. '
      'No emotional receipt. No questions. No coaching.';

  static const String _lightWelcomeDirective =
      'Light Neutral Entry: mirror their warmth or everyday detail briefly. '
      'Stay with what they offered — coffee, a good day, a cat, a plan, or '
      'wanting to talk. Never recast it as difficulty, burden, or something '
      'to put down tonight.';

  static const String _realizationDirective =
      'Realize only the sealed WHAT (neutralEntry / neutral entry) as exactly '
      'one short utterance. Acknowledge the greeting. '
      'Do not drift into Receipt, Naming, Permission, Release, Enough, '
      'or another WHAT. Do not choose release, protocol, exit, or silence.';

  static const List<String> _lightConversationForbidden = [
    'Inverting positive or mundane content into distress: “hard”, “heavy”, '
        '“difficult”, “zor geliyor”, “ağır geliyor”, “yük”, “burden”',
    'Permission / obligation-ease: “don’t have to think”, “gerekmiyor”, '
        '“düşünmene gerek yok”',
    'Release / put-down: “bırak”, “let go”, “leave it here”, “geceye bırak”',
    'Belki/Sanki difficulty reframes on clearly positive turns',
    'Inventing worry about tomorrow when they named a mundane plan only',
  ];

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

  String _userContent({required bool isLightTurn}) {
    return '$_realizationDirective\n\n'
        '${isLightTurn ? _lightWelcomeDirective : _welcomeDirective}\n\n'
        'Exactly one short sentence. Natural. Quiet. '
        'No question. No invented emotion, presence, stillness, or problem.';
  }

  String _systemAppendix({required bool isLightTurn}) {
    return '''
Neutral Entry Intelligence v$version:
${isLightTurn ? _lightWelcomeDirective : _welcomeDirective}
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
