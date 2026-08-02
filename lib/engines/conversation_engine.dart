import '../models/conversation_types.dart';
import '../services/conversation_flow.dart';
import 'observe_engine.dart';

class ConversationEngine {
  const ConversationEngine._();

  static String generate({
    required String userInput,
    required SleepState state,
    required List<String> conversationHistory,
  }) {
    final stage = ConversationFlow.stageFor(conversationHistory.length);

    switch (stage) {
      case ConversationStage.observe:
        return _observe(
          userInput: userInput,
          state: state,
          conversationHistory: conversationHistory,
        );

      case ConversationStage.understand:
        return _understand(
          userInput: userInput,
          state: state,
          conversationHistory: conversationHistory,
        );

      case ConversationStage.reframe:
        throw UnimplementedError();

      case ConversationStage.release:
        throw UnimplementedError();

      case ConversationStage.transition:
        return _transition(
          userInput: userInput,
          state: state,
          conversationHistory: conversationHistory,
        );
    }
  }

  static String _observe({
    required String userInput,
    required SleepState state,
    required List<String> conversationHistory,
  }) {
    return ObserveEngine.generate(
      state: state,
      userInput: userInput,
      conversationHistory: conversationHistory,
    );
  }

  static String _understand({
    required String userInput,
    required SleepState state,
    required List<String> conversationHistory,
  }) {
    throw UnimplementedError();
  }

  static String _transition({
    required String userInput,
    required SleepState state,
    required List<String> conversationHistory,
  }) {
    throw UnimplementedError();
  }
}
