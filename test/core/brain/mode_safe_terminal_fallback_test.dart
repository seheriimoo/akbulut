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
      if (mode == ConversationExpressionMode.reframe) continue;
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

    test('EN observe terminal admits for ASCII TR turn with TR grounding', () {
      const user = 'uyuyamiom ya cok yorgunum';
      const blob = 'yarın kan tahlili sonucu çıkıyor endişeliyim';
      final terminal = ModeSafeTerminalFallback.forExpression(
        what: ConversationPhase.validation,
        expressionMode: ConversationExpressionMode.observePurity,
        userUtterance: user,
        groundingBlob: blob,
      );
      expect(terminal, isNotNull);
      expect(
        guard.allow(
          utterance: terminal!,
          what: ConversationPhase.validation,
          userUtterance: user,
          mirrorGroundingUtterance: blob,
          expressionMode: ConversationExpressionMode.observePurity,
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
    test('ASCII TR turn with TR session grounding yields TR observe terminal', () {
      const user = 'sadece beklemek zor';
      const blob =
          'yarın kan tahlili sonucu çıkıyor doktor bir şey demedi ama endişeliyim';
      final terminal = ModeSafeTerminalFallback.forExpression(
        what: ConversationPhase.validation,
        expressionMode: ConversationExpressionMode.observePurity,
        userUtterance: user,
        groundingBlob: blob,
      );
      expect(terminal, isNotNull);
      expect(terminal!.text, 'Az önce söylediğin hâlâ orada.');
      expect(
        guard.allow(
          utterance: terminal,
          what: ConversationPhase.validation,
          userUtterance: user,
          mirrorGroundingUtterance: blob,
          expressionMode: ConversationExpressionMode.observePurity,
        ),
        isNotNull,
      );
    });

    test('G24 T4 EN short-ack reject chain yields non-null terminal', () async {
      const user = 'sadece beklemek zor';
      final grounding = const ConversationGroundingBuffer.empty()
          .appendUserUtterance('yarın kan tahlili sonucu çıkıyor')
          .appendUserUtterance('doktor bir şey demedi ama endişeliyim')
          .appendUserUtterance('google aramak istemiyorum')
          .appendUserUtterance(user);

      final engine = ConversationEngine(
        languageModelClient: const _RejectTextClient('Okay.'),
      );

      final spoken = await engine.generate(
        conversationDecision: const ConversationDecision(
          phase: ConversationPhase.validation,
          shouldSpeak: true,
          expressionMode: ConversationExpressionMode.observePurity,
        ),
        exitDecision: ExitDecision.continueConversation,
        conversationGrounding: grounding,
      );

      expect(spoken, isNotNull);
      expect(spoken!.text.trim(), isNotEmpty);
      expect(spoken.text, isNot('Okay.'));
    });
    test('H22 T4 rejects EN short ack on TR session blob', () async {
      const user = 'yine erteledim';
      final grounding = const ConversationGroundingBuffer.empty()
          .appendUserUtterance('5000 kelime yazmam lazım pazar')
          .appendUserUtterance('ekran boş bakıyorum')
          .appendUserUtterance('tembel değilim korkuyorum galiba')
          .appendUserUtterance(user);

      final engine = ConversationEngine(
        languageModelClient: const _RejectTextClient('Okay.'),
      );

      final spoken = await engine.generate(
        conversationDecision: const ConversationDecision(
          phase: ConversationPhase.validation,
          shouldSpeak: true,
          expressionMode: ConversationExpressionMode.groundedHold,
        ),
        exitDecision: ExitDecision.continueConversation,
        conversationGrounding: grounding,
      );

      expect(spoken, isNotNull);
      expect(spoken!.text.trim(), isNot('Okay.'));
      expect(spoken.text.trim().toLowerCase(), isNot('okay.'));
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
