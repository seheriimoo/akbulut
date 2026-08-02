import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../content/nocta_conversations.dart';

enum SleepState {
  overthinking,
  workStress,
  relationship,
  missSomeone,
  futureAnxiety,
  loneliness,
  emotional,
  physical,
  unknown,
}

class AIService {

  // removed (now SessionManager)
  static String get apiKey => dotenv.env['OPENAI_API_KEY'] ?? "";

  static final Set<String> _used = {};

  static String _pick(List<String> pool) {
    final available = pool.where((e) => !_used.contains(e)).toList();

    if (available.isEmpty) {
      _used.clear();
      return pool[Random().nextInt(pool.length)];
    }

    final choice = available[Random().nextInt(available.length)];
    _used.add(choice);
    return choice;
  }

  static SleepState detectState(String input) {
    final text = input.toLowerCase();

    if (text.contains("thinking") ||
        text.contains("overthinking") ||
        text.contains("can't stop thinking") ||
        text.contains("cannot stop thinking") ||
        text.contains("mind won't stop") ||
        text.contains("thoughts") ||
        text.contains("kafam") ||
        text.contains("düşünü") ||
        text.contains("aklım") ||
        text.contains("zihnim") ||
        text.contains("susturam") ||
        text.contains("takıldım")) {
      return SleepState.overthinking;
    }

    if (text.contains("work") ||
        text.contains("job") ||
        text.contains("meeting") ||
        text.contains("presentation") ||
        text.contains("deadline") ||
        text.contains("iş") ||
        text.contains("çalış") ||
        text.contains("hastane") ||
        text.contains("mesai") ||
        text.contains("nöbet") ||
        text.contains("yetiştir") ||
        text.contains("sorumluluk")) {
      return SleepState.workStress;
    }

    if (text.contains("future") ||
        text.contains("uncertain") ||
        text.contains("what if") ||
        text.contains("financial") ||
        text.contains("career") ||
        text.contains("gelecek") ||
        text.contains("belirsiz") ||
        text.contains("ya olmazsa") ||
        text.contains("ya olursa")) {
      return SleepState.futureAnxiety;
    }


    if (text.contains("stres") ||
        text.contains("stress") ||
        text.contains("anxious") ||
        text.contains("worried") ||
        text.contains("nervous") ||
        text.contains("gergin") ||
        text.contains("bunald") ||
        text.contains("baskı") ||
        text.contains("overwhelmed") ||
        text.contains("drained") ||
        text.contains("exhausted") ||
        text.contains("heavy") ||
        text.contains("too much") ||
        text.contains("emotionally tired")) {
      return SleepState.emotional;
    }

    if (text.contains("üzgün") ||
        text.contains("sad") ||
        text.contains("kötü") ||
        text.contains("moral")) {
      return SleepState.emotional;
    }

    if (text.contains("alone") ||
        text.contains("lonely") ||
        text.contains("loneliness") ||
        text.contains("miss someone") ||
        text.contains("feel alone") ||
        text.contains("by myself")) {
      return SleepState.loneliness;
    }

    if (text.contains("miss her") ||
        text.contains("miss him") ||
        text.contains("thinking about her") ||
        text.contains("thinking about him")) {
      return SleepState.missSomeone;
    }

    if (text.contains("relationship") ||
        text.contains("breakup") ||
        text.contains("ex") ||
        text.contains("partner") ||
        text.contains("girlfriend") ||
        text.contains("boyfriend") ||
        text.contains("husband") ||
        text.contains("wife") ||
        text.contains("miss my ex") ||
        text.contains("heartbroken")) {
      return SleepState.relationship;
    }

    if (text.contains("tired") ||
        text.contains("body") ||
        text.contains("yorgun") ||
        text.contains("beden")) {
      return SleepState.physical;
    }

    return SleepState.unknown;
  }

  
  
  
  static Future<String?> enhanceWithAI(String baseText) async {
    if (apiKey.isEmpty) return null;

    final uri = Uri.parse("https://api.openai.com/v1/chat/completions");

    try {
      final response = await http.post(
        uri,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $apiKey",
        },
        body: jsonEncode({
          "model": "gpt-4o-mini",
          "messages": [
            {
              "role": "system",
              "content": """
Rewrite the following text in a more natural, soft, human way.

Rules:
- Keep EXACT same meaning
- Keep same number of sentences
- Do not expand
- Do not explain
- Make it feel less repetitive and more human
"""
            },
            {"role": "user", "content": baseText}
          ],
          "temperature": 0.8,
          "max_tokens": 80,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        return data["choices"][0]["message"]["content"];
      }
    } catch (_) {}

    return null;
  }

  static Future<String> generateReply({
    required String userInput,
    required int aiMessageCount,
    required List<String> conversationHistory,
    required SleepState? conversationState,
  }) async {
    final state = conversationState ?? detectState(userInput);
    final historyText = conversationHistory.join(" ");

    print("HISTORY = $historyText");
    print("AI MESSAGE COUNT = $aiMessageCount");
    print("STATE = $state");

return generateNoctaReply(userInput: userInput, state: state, conversationHistory: conversationHistory);

  }


static String generateNoctaReply({
  required String userInput,
  required SleepState state,
  required List<String> conversationHistory,
}) {
  final step = conversationHistory.length;
  final text = userInput.toLowerCase();
  final historyText = conversationHistory.join(" ").toLowerCase();

  String? topic;

  if (historyText.contains("presentation")) topic = "presentation";
  if (historyText.contains("meeting")) topic = "meeting";
  if (historyText.contains("interview")) topic = "interview";
  if (historyText.contains("exam")) topic = "exam";

  if (step <= 1) {

    if (text.contains("presentation")) {
      return "Part of your attention is still staying with tomorrow's presentation.";
    }

    if (text.contains("meeting")) {
      return "Part of your mind still seems to be sitting in tomorrow's meeting.";
    }

    if (text.contains("interview")) {
      return "It sounds like tomorrow's interview is asking for a lot of your attention tonight.";
    }

    if (text.contains("exam")) {
      return "Part of you is already trying to be with tomorrow's exam.";
    }

    switch (state) {
      case SleepState.overthinking:
        return NoctaConversations.overthinkingOpeners[
          DateTime.now().millisecond %
              NoctaConversations.overthinkingOpeners.length
        ];
      case SleepState.workStress:

        if (topic == "presentation") {
          return "Nothing about tomorrow's presentation needs anything more from you right now.";
        }

        if (topic == "meeting") {
          return "Nothing about tomorrow's meeting needs your attention right now.";
        }

        if (topic == "interview") {
          return "You do not need to keep preparing for tomorrow's interview right now.";
        }

        if (topic == "exam") {
          return "Nothing more is needed from you for tomorrow's exam tonight.";
        }

        return _pick(NoctaConversations.workStressOpeners);
      case SleepState.relationship:
        return "Something about this connection still feels present tonight.";

      case SleepState.futureAnxiety:
        return _pick(NoctaConversations.futureAnxietyOpeners);

      case SleepState.loneliness:
        return "Tonight feels a little too quiet around you.";
      default:
        return "Something in you still feels awake tonight.";
    }
  }

  if (step == 2) {
    switch (state) {
      case SleepState.overthinking:
        return [
          "Not all of tomorrow is here right now.",
          "It may not need quite as much space right now.",
          "Not everything needs your attention tonight.",
          "For now, it can be just tonight.",
          "It does not all belong to this moment."
        ][DateTime.now().millisecond % 5];

      case SleepState.workStress:

        if (topic == "presentation") {
          return "Nothing about tomorrow's presentation needs anything more from you right now.";
        }

        if (topic == "meeting") {
          return "Nothing about tomorrow's meeting needs your attention right now.";
        }

        if (topic == "interview") {
          return "You do not need to keep preparing for tomorrow's interview right now.";
        }

        if (topic == "exam") {
          return "Nothing more is needed from you for tomorrow's exam tonight.";
        }

        return _pick(NoctaConversations.workStressMiddle);

      case SleepState.relationship:
        return "Not all of this needs your attention right now.";

      case SleepState.futureAnxiety:
        return _pick(NoctaConversations.futureAnxietyMiddle);

      case SleepState.loneliness:
        return "This moment does not need to hold the whole weight of that feeling.";

      default:
        return "It may not need quite as much space right now.";
    }
  }

  switch (state) {
    case SleepState.overthinking:
      return _pick(NoctaConversations.overthinkingClosers);
    case SleepState.workStress:
      return _pick(NoctaConversations.workStressClosers);
    case SleepState.relationship:
      return "You do not need to understand all of it before you rest. For now, we can let it soften.";

    case SleepState.futureAnxiety:
      return _pick(NoctaConversations.futureAnxietyClosers);

    case SleepState.loneliness:
      return "You do not have to fill the whole quiet tonight. Just let this moment hold you for a while.";
    default:
      return "You do not need to solve it tonight. We can leave it here for now.";
  }
}
}
