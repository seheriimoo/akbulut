import 'package:flutter_test/flutter_test.dart';
import 'package:slowave/core/brain/conversation_decision.dart';
import 'package:slowave/core/brain/conversation_engine.dart';
import 'package:slowave/core/brain/conversation_expression_mode.dart';
import 'package:slowave/core/brain/conversation_grounding_buffer.dart';
import 'package:slowave/core/brain/conversation_phase.dart';
import 'package:slowave/core/brain/conversation_utterance.dart';
import 'package:slowave/core/brain/exit_decision.dart';
import 'package:slowave/core/brain/language_model_client.dart';
import 'package:slowave/core/brain/llm_invocation_package.dart';
import 'package:slowave/core/brain/mode_safe_terminal_fallback.dart';
import 'package:slowave/core/brain/utterance_guard.dart';
import 'package:slowave/core/brain/vendor_provider.dart';

/// B1 — Zero Silence Contract: terminal lines must always admit via Guard.
void main() {
  const guard = UtteranceGuard();

  group('ModeSafeTerminalFallback Guard admission', () {
    for (final mode in ConversationExpressionMode.values) {
      test('TR validation terminal admits for $mode', () {
        const user = 'Uyuyamıyorum, kafam karışık.';
        final terminal = ModeSafeTerminalFallback.forExpression(
          what: ConversationPhase.validation,
          expressionMode: mode,
          userUtterance: user,
        );
        expect(terminal, isNotNull);
        final admitted = guard.allow(
          utterance: terminal!,
          what: ConversationPhase.validation,
          userUtterance: user,
          expressionMode: mode,
        );
        expect(
          admitted,
          isNotNull,
          reason: '${mode.name}: ${terminal.text}',
        );
      });
    }

    test('TR narrow refinement terminal admits', () {
      const user = 'Belki işten.';
      final terminal = ModeSafeTerminalFallback.forExpression(
        what: ConversationPhase.validation,
        expressionMode: ConversationExpressionMode.narrow,
        userUtterance: user,
        narrowRefinementAfterPartial: true,
      );
      expect(terminal, isNotNull);
      expect(
        guard.allow(
          utterance: terminal!,
          what: ConversationPhase.validation,
          userUtterance: user,
          expressionMode: ConversationExpressionMode.narrow,
        ),
        isNotNull,
      );
    });

    test('EN reframe terminal admits for typo user', () {
      const user = 'uyuyamiom ya cok yorgunum';
      final terminal = ModeSafeTerminalFallback.forExpression(
        what: ConversationPhase.validation,
        expressionMode: ConversationExpressionMode.reframe,
        userUtterance: user,
      );
      expect(terminal, isNotNull);
      expect(
        guard.allow(
          utterance: terminal!,
          what: ConversationPhase.validation,
          userUtterance: user,
          expressionMode: ConversationExpressionMode.reframe,
        ),
        isNotNull,
        reason: terminal.text,
      );
    });
  });

  group('ConversationEngine zero silence B1', () {
    test('reframe Guard double-reject yields terminal, not silence', () async {
      final engine = ConversationEngine(
        languageModelClient: const _RejectTextClient(
          'Belki de bu gece yalnızlık seni etkiliyor olabilir?',
        ),
      );

      final spoken = await engine.generate(
        conversationDecision: const ConversationDecision(
          phase: ConversationPhase.validation,
          shouldSpeak: true,
          expressionMode: ConversationExpressionMode.reframe,
        ),
        exitDecision: ExitDecision.continueConversation,
        conversationGrounding: const ConversationGroundingBuffer.empty()
            .appendUserUtterance(
          'Sanırım yanımda birinin nefes aldığını duymak istiyorum.',
        ),
      );

      expect(spoken, isNotNull);
      expect(spoken!.text, isNot('Anlıyorum.'));
      expect(
        spoken.text.contains('?') ||
            spoken.text.contains('olabilir') ||
            spoken.text == 'Tamam.',
        isTrue,
      );
    });

    test('narrow Guard double-reject yields terminal question', () async {
      final engine = ConversationEngine(
        languageModelClient: const _RejectTextClient(
          'Anlıyorum.',
        ),
      );

      final spoken = await engine.generate(
        conversationDecision: const ConversationDecision(
          phase: ConversationPhase.validation,
          shouldSpeak: true,
          expressionMode: ConversationExpressionMode.narrow,
        ),
        exitDecision: ExitDecision.continueConversation,
        conversationGrounding: const ConversationGroundingBuffer.empty()
            .appendUserUtterance('Bilmiyorum, hâlâ net değil.'),
      );

      expect(spoken, isNotNull);
      expect(spoken!.text, contains('?'));
    });
    test('vendor fail yields terminal when shouldSpeak', () async {
      final engine = ConversationEngine(
        languageModelClient: const _ThrowVendorClient(),
      );

      final spoken = await engine.generate(
        conversationDecision: const ConversationDecision(
          phase: ConversationPhase.validation,
          shouldSpeak: true,
          expressionMode: ConversationExpressionMode.narrow,
        ),
        exitDecision: ExitDecision.continueConversation,
        livedExpression: 'Sevinç ve korku aynı anda.',
      );

      expect(spoken, isNotNull);
      expect(spoken!.text, contains('?'));
    });
  });
}

class _ThrowVendorClient extends LanguageModelClient {
  const _ThrowVendorClient();

  @override
  Future<ConversationUtterance> realize(LlmInvocationPackage package) async {
    throw const VendorError(kind: VendorErrorKind.transport, message: 'test');
  }
}

class _RejectTextClient extends LanguageModelClient {
  const _RejectTextClient(this.text);

  final String text;

  @override
  Future<ConversationUtterance> realize(LlmInvocationPackage package) async {
    return ConversationUtterance(text: text);
  }
}
