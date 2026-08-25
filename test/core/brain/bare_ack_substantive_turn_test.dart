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
import 'package:slowave/core/brain/surface_utterance_kind.dart';
import 'package:slowave/core/brain/utterance_guard.dart';

/// Build 4 release regression: bare Okay must not close substantive EN turns.
void main() {
  const guard = UtteranceGuard();

  const t1 = "I can't stop thinking tonight.";
  const t2 =
      'My mind keeps thinking about everything that could go wrong tomorrow.';
  const t3 =
      "It's not one specific thing. My mind keeps creating different scenarios, "
      'and every one of them ends badly.';

  bool isBareAckVariant(String text) {
    final n = text
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[.!?…]+$'), '')
        .trim();
    return n == 'okay' || n == 'ok' || n == 'tamam';
  }

  group('substantive-turn bare-ack detection', () {
    test('T3 real-device line is substantive', () {
      expect(SurfaceUtteranceReader.isSubstantiveUserTurn(t3), isTrue);
    });

    test('minimal okay is not substantive', () {
      expect(SurfaceUtteranceReader.isSubstantiveUserTurn('okay'), isFalse);
      expect(SurfaceUtteranceReader.isSubstantiveUserTurn('Okay.'), isFalse);
    });

    test('generalizes to other EN catastrophe lines', () {
      for (final line in const [
        'My brain keeps imagining everything going wrong.',
        'Every scenario ends badly.',
        'I keep thinking of new worst-case outcomes.',
        "I don't know what exactly I'm afraid of, but everything feels like it could fall apart.",
      ]) {
        expect(
          SurfaceUtteranceReader.isSubstantiveUserTurn(line),
          isTrue,
          reason: line,
        );
      }
    });
  });

  group('A) substantive EN + model Okay.', () {
    test('observePurity Guard rejects Okay.', () {
      final admitted = guard.allow(
        utterance: const ConversationUtterance(text: 'Okay.'),
        what: ConversationPhase.validation,
        userUtterance: t3,
        expressionMode: ConversationExpressionMode.observePurity,
      );
      expect(admitted, isNull);
    });

    test('standard Guard rejects Ok / Tamam variants', () {
      for (final text in const ['Okay', 'Ok.', 'Ok', 'Tamam.', 'Tamam']) {
        expect(
          guard.allow(
            utterance: ConversationUtterance(text: text),
            what: ConversationPhase.validation,
            userUtterance: t3,
            expressionMode: ConversationExpressionMode.standard,
          ),
          isNull,
          reason: text,
        );
      }
    });
  });

  group('B) minimal user ack landing remains allowed', () {
    test('user "okay" + assistant Okay. admits under postReframeListen', () {
      final admitted = guard.allow(
        utterance: const ConversationUtterance(text: 'Okay.'),
        what: ConversationPhase.validation,
        userUtterance: 'okay',
        expressionMode: ConversationExpressionMode.postReframeListen,
      );
      expect(admitted, isNotNull);
      expect(admitted!.text, 'Okay.');
    });

    test('user "Okay." + observe Okay. admits', () {
      final admitted = guard.allow(
        utterance: const ConversationUtterance(text: 'Okay.'),
        what: ConversationPhase.validation,
        userUtterance: 'Okay.',
        expressionMode: ConversationExpressionMode.observePurity,
      );
      expect(admitted, isNotNull);
    });
  });

  group('C) true postReframeListen', () {
    test('minimal confirm keeps short-ack terminal', () {
      final terminal = ModeSafeTerminalFallback.forExpression(
        what: ConversationPhase.validation,
        expressionMode: ConversationExpressionMode.postReframeListen,
        userUtterance: 'yes',
      );
      expect(terminal, isNotNull);
      expect(isBareAckVariant(terminal!.text), isTrue);
      expect(
        guard.allow(
          utterance: terminal,
          what: ConversationPhase.validation,
          userUtterance: 'yes',
          expressionMode: ConversationExpressionMode.postReframeListen,
        ),
        isNotNull,
      );
    });

    test('substantive turn does not emit bare Okay terminal', () {
      final terminal = ModeSafeTerminalFallback.forExpression(
        what: ConversationPhase.validation,
        expressionMode: ConversationExpressionMode.postReframeListen,
        userUtterance: t3,
      );
      expect(terminal, isNotNull);
      expect(isBareAckVariant(terminal!.text), isFalse);
      expect(terminal.text.trim().length, greaterThan(8));
    });
  });

  group('D) zero-silence / engine on substantive turn', () {
    test('model Okay. yields non-bare continuation', () async {
      var grounding = const ConversationGroundingBuffer.empty()
          .appendUserUtterance(t1)
          .appendUserUtterance(t2)
          .appendUserUtterance(t3);

      final engine = ConversationEngine(
        languageModelClient: const _FixedTextClient('Okay.'),
      );

      final spoken = await engine.generate(
        conversationDecision: const ConversationDecision(
          phase: ConversationPhase.validation,
          shouldSpeak: true,
          expressionMode: ConversationExpressionMode.observePurity,
        ),
        exitDecision: ExitDecision.continueConversation,
        conversationGrounding: grounding,
        livedExpression: t3,
      );

      expect(spoken, isNotNull);
      expect(spoken!.text.trim(), isNotEmpty);
      expect(isBareAckVariant(spoken.text), isFalse);
      expect(spoken.text.trim().length, greaterThan(8));
    });

    test('exact real-device T3 regression via engine', () async {
      final grounding = const ConversationGroundingBuffer.empty()
          .appendUserUtterance(t1)
          .appendUserUtterance(t2)
          .appendUserUtterance(t3);

      final engine = ConversationEngine(
        languageModelClient: const _FixedTextClient('Okay.'),
      );

      final spoken = await engine.generate(
        conversationDecision: const ConversationDecision(
          phase: ConversationPhase.validation,
          shouldSpeak: true,
          expressionMode: ConversationExpressionMode.observePurity,
        ),
        exitDecision: ExitDecision.continueConversation,
        conversationGrounding: grounding,
        livedExpression: t3,
      );

      expect(spoken, isNotNull);
      expect(isBareAckVariant(spoken!.text), isFalse);
      // Meaningful continuation: not empty, not bare ack, speech plane intact.
      expect(spoken.text.contains(RegExp(r'[.!?]|still|tonight|there|hard')), isTrue);
    });
  });
}

class _FixedTextClient extends LanguageModelClient {
  const _FixedTextClient(this.text);

  final String text;

  @override
  Future<ConversationUtterance> realize(LlmInvocationPackage package) async {
    return ConversationUtterance(text: text);
  }
}
