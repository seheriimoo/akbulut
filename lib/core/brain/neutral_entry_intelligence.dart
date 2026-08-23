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
    bool lightChatMode = false,
  }) {
    assert(stage.stage == BlueprintStage.neutralEntry);

    final currentTurn = _currentTurnGrounding(conversationGrounding);
    final isLightTurn = lightChatMode ||
        (currentTurn != null &&
            lightConversation.isLightConversation(currentTurn));

    final forbidden = <String>[
      ...stage.forbiddenMoves,
      ..._neutralEntryForbidden.where(
        (rule) => !lightChatMode || !rule.startsWith('Questions'),
      ),
      if (isLightTurn && !lightChatMode) ..._lightConversationForbidden,
      if (lightChatMode) ..._lightChatForbidden,
    ];

    return NeutralEntryCompileSlice(
      aim: lightChatMode ? _aimLightChat : (isLightTurn ? _aimLight : _aim),
      sealedWhatSignature: lightChatMode
          ? _sealedWhatSignatureLightChat
          : (isLightTurn ? _sealedWhatSignatureLight : _sealedWhatSignature),
      forbiddenMoves: forbidden,
      responseLength:
          lightChatMode ? _responseLengthLightChat : (isLightTurn ? _responseLengthLight : _responseLength),
      welcomeDirective: lightChatMode
          ? _lightChatDirective
          : (isLightTurn ? _lightWelcomeDirective : _welcomeDirective),
      realizationDirective: _realizationDirective,
      userContent: _userContent(
        isLightTurn: isLightTurn,
        lightChatMode: lightChatMode,
      ),
      systemAppendix: _systemAppendix(
        isLightTurn: isLightTurn,
        lightChatMode: lightChatMode,
      ),
    );
  }

  static const String _aimLightChat =
      'Respond like a warm human in light conversation. Mirror their moment '
      'briefly. You may ask exactly one natural follow-up question.';

  static const String _sealedWhatSignatureLightChat =
      'neutralEntry / Light chat — warm everyday acknowledgment. One natural '
      'follow-up question allowed. No mental load, reframe, Permission, '
      'Release, or sleep pressure.';

  static const String _responseLengthLightChat =
      'One or two short sentences, maximum 22 words. At most one question mark.';

  static const String _lightChatDirective =
      'Light chat only: respond like a normal friend — warm, brief, curious. '
      'Mirror what they shared (coffee, laughter, a good day). You may ask '
      'exactly one natural follow-up question (e.g. what made them laugh). '
      'Never invent distress, burden, mental load, Permission, Release, or '
      'sleep pressure. Stay in their light loop.';

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

  static const List<String> _lightChatForbidden = [
    'Inverting positive or mundane content into distress: “hard”, “heavy”, '
        '“difficult”, “zor geliyor”, “ağır geliyor”, “yük”, “burden”',
    'Permission / obligation-ease: “don’t have to think”, “gerekmiyor”, '
        '“düşünmene gerek yok”',
    'Release / put-down: “bırak”, “let go”, “leave it here”, “geceye bırak”',
    'Belki/Sanki difficulty reframes on clearly positive turns',
    'Inventing worry about tomorrow when they named a mundane plan only',
    'Mental load / sleep pressure / insomnia framing',
    'More than one question',
  ];

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

  String _userContent({
    required bool isLightTurn,
    required bool lightChatMode,
  }) {
    if (lightChatMode) {
      return '$_realizationDirective\n\n'
          '$_lightChatDirective\n\n'
          'One or two short sentences. At most one natural follow-up question. '
          'No invented distress, load, Permission, Release, or sleep pressure.';
    }
    return '$_realizationDirective\n\n'
        '${isLightTurn ? _lightWelcomeDirective : _welcomeDirective}\n\n'
        'Exactly one short sentence. Natural. Quiet. '
        'No question. No invented emotion, presence, stillness, or problem.';
  }

  String _systemAppendix({
    required bool isLightTurn,
    required bool lightChatMode,
  }) {
    if (lightChatMode) {
      return '''
Neutral Entry Intelligence v$version (Light chat):
$_lightChatDirective
Question rule: exactly one natural follow-up question is allowed.
No-invention rule: do not invent distress, mental load, Permission, Release, or sleep pressure.
Drift rule: do not Receipt, Name, grant Permission, invite Release, or close.
''';
    }
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
