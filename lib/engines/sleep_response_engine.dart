class SleepResponseEngine {
  static String generateResponse({
    required String userInput,
    required String category,
  }) {
    final input = userInput.toLowerCase();

    // 🪞 REFLECTION
    String reflection;
    if (input.contains("mind") || input.contains("thinking")) {
      reflection = "Your mind feels quite active right now.";
    } else if (input.contains("stress") || input.contains("anx")) {
      reflection = "There seems to be some internal tension.";
    } else if (input.contains("tired")) {
      reflection = "Your body may feel tired, but not fully relaxed.";
    } else {
      reflection = "Your system doesn't seem fully settled yet.";
    }

    // 🧠 EXPLANATION
    String explanation;
    switch (category) {
      case "overthinking":
        explanation =
            "This usually happens when the mind keeps trying to resolve things.";
        break;
      case "stress":
        explanation =
            "Your nervous system may still be slightly activated.";
        break;
      case "emotional":
        explanation =
            "Some emotional residue from today may still be present.";
        break;
      case "dopamine":
        explanation =
            "Your mind may have been overstimulated during the day.";
        break;
      case "physical":
        explanation =
            "Your body may not have fully shifted into relaxation mode yet.";
        break;
      default:
        explanation =
            "Your system may simply need a slower transition into rest.";
    }

    // 🎯 DIRECTION
    String direction =
        "A softer, slower transition into sleep would be the most supportive choice tonight.";

    return "$reflection\n\n$explanation\n\n$direction";
  }
}