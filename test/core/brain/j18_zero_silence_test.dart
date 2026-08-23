import 'package:flutter_test/flutter_test.dart';
import 'package:slowave/core/brain/conversation_decision.dart';
import 'package:slowave/core/brain/conversation_expression_mode.dart';
import 'package:slowave/core/brain/conversation_grounding_buffer.dart';
import 'package:slowave/core/brain/conversation_engine.dart';
import 'package:slowave/core/brain/conversation_phase.dart';
import 'package:slowave/core/brain/conversation_utterance.dart';
import 'package:slowave/core/brain/exit_decision.dart';
import 'package:slowave/core/brain/hcos_live_entry.dart';
import 'package:slowave/core/brain/language_model_client.dart';
import 'package:slowave/core/brain/llm_invocation_package.dart';
import 'package:slowave/core/brain/night_session.dart';
import 'package:slowave/core/brain/user_object_mirror.dart';

class _RejectClient extends LanguageModelClient {
  const _RejectClient();

  @override
  Future<ConversationUtterance> realize(LlmInvocationPackage package) async {
    return const ConversationUtterance(text: '(rejected-by-test)');
  }
}

void main() {
  test('J18 T1 mirror uses Turkish on experiential ASCII turn', () {
    final blob =
        'garip hissediyorum aciklayamiyorum ne uzgun ne sinirli bisi var';
    final mirror = UserObjectMirror.forValidation(
      userUtterance: 'garip hissediyorum aciklayamiyorum',
      groundingBlob: blob,
      expressionMode: ConversationExpressionMode.observePurity,
    );
    expect(mirror, isNotNull);
    expect(mirror!.text.toLowerCase(), isNot(contains('that feeling')));
    expect(mirror.text.toLowerCase(), isNot(contains('tonight.')));
  });

  test('J18 T3 observePurity never silent when shouldSpeak', () async {
    final orchestrator = HcosLiveEntry.createOrchestrator();
    final mind = HcosLiveEntry.emptyMindModel(userId: 'J18');
    var session = HcosLiveEntry.openNightSession(mind);
    ConversationGroundingBuffer? grounding;

    for (final user in [
      'garip hissediyorum aciklayamiyorum',
      'ne uzgun ne sinirli bisi var',
    ]) {
      final r = await orchestrator.processTurn(
        message: user,
        session: session,
        workingMind: session.workingMind,
        conversationGroundingBuffer: grounding,
      );
      session = HcosLiveEntry.applyTurnResult(r);
      grounding = HcosLiveEntry.groundingBufferOf(r);
    }

    final engine = ConversationEngine(languageModelClient: const _RejectClient());
    final spoken = await engine.generate(
      conversationDecision: const ConversationDecision(
        phase: ConversationPhase.validation,
        shouldSpeak: true,
        expressionMode: ConversationExpressionMode.observePurity,
      ),
      exitDecision: ExitDecision.continueConversation,
      conversationGrounding: grounding,
      nightSession: session,
    );

    expect(spoken, isNotNull);
    expect(spoken!.text.trim(), isNotEmpty);
    expect(spoken.text, isNot('(silent)'));
  });
}
