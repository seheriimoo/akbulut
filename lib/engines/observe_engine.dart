import '../models/conversation_types.dart';
import '../content/observe_library.dart';

class ObserveEngine {
  const ObserveEngine._();

  static String generate({
    required SleepState state,
    required String userInput,
    required List<String> conversationHistory,
  }) {
    switch (state) {
      case SleepState.overthinking:
        return ObserveLibrary.overthinking.first.text;

      case SleepState.futureAnxiety:
        return "It feels like part of your attention has already moved into tomorrow.";

      case SleepState.workStress:
        return "It seems like work is still occupying your mind.";

      case SleepState.relationship:
        return "Some relationships can stay with us long after the conversation ends.";

      case SleepState.missSomeone:
        return "It sounds like someone has been on your mind tonight.";

      case SleepState.loneliness:
        return "Feeling alone can make the night feel much longer.";

      case SleepState.emotional:
        return "It seems like you've been carrying something emotionally heavy.";

      case SleepState.physical:
        return "Your body sounds tired, even if your mind is still awake.";

      case SleepState.unknown:
        return "Tell me a little more about what's keeping you awake tonight.";
    }
  }
}
