enum RegulationStage {
  observe,
  narrow,
  release,
}

class RegulationState {
  final String blocker;
  final RegulationStage stage;

  const RegulationState({
    required this.blocker,
    required this.stage,
  });
}

class ConversationRegulationEngine {

  static RegulationState analyze({
    required String userInput,
    required int messageCount,
  }) {

    String blocker = "general";

    final text = userInput.toLowerCase();

    if (text.contains("iş") ||
        text.contains("çalış") ||
        text.contains("hastane")) {
      blocker = "work_stress";
    } else if (text.contains("ayrılık") ||
        text.contains("özlüyorum")) {
      blocker = "breakup";
    } else if (text.contains("kaygı") ||
        text.contains("endişe")) {
      blocker = "anxiety";
    } else if (text.contains("düşün")) {
      blocker = "overthinking";
    }

    RegulationStage stage;

    if (messageCount <= 1) {
      stage = RegulationStage.observe;
    } else if (messageCount == 2) {
      stage = RegulationStage.narrow;
    } else {
      stage = RegulationStage.release;
    }

    return RegulationState(
      blocker: blocker,
      stage: stage,
    );
  }
}