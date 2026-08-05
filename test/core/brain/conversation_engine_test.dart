import 'package:flutter_test/flutter_test.dart';
import 'package:slowave/core/brain/conversation_decision.dart';
import 'package:slowave/core/brain/conversation_engine.dart';
import 'package:slowave/core/brain/conversation_phase.dart';
import 'package:slowave/core/brain/conversation_utterance.dart';
import 'package:slowave/core/brain/exit_decision.dart';
import 'package:slowave/core/brain/language_model_client.dart';
import 'package:slowave/core/brain/llm_invocation_package.dart';

void main() {
  group('ConversationEngine output contract', () {
    const engine = ConversationEngine();

    test('emits exactly one speech outcome when authorized', () {
      final utterance = engine.generate(
        conversationDecision: const ConversationDecision(
          phase: ConversationPhase.validation,
          shouldSpeak: true,
        ),
        exitDecision: ExitDecision.continueConversation,
      );

      expect(utterance, isNotNull);
      expect(utterance!.text, 'That makes sense.');
      expect(utterance.text.contains('\n'), isFalse);
    });

    test('non-speech path returns no conversational language on exit stop', () {
      final utterance = engine.generate(
        conversationDecision: const ConversationDecision(
          phase: ConversationPhase.validation,
          shouldSpeak: true,
        ),
        exitDecision: ExitDecision.silence,
      );

      expect(utterance, isNull);
    });

    test('non-speech path returns no conversational language for audio phase', () {
      final utterance = engine.generate(
        conversationDecision: const ConversationDecision(
          phase: ConversationPhase.audio,
          shouldSpeak: false,
        ),
        exitDecision: ExitDecision.transitionToAudio,
      );

      expect(utterance, isNull);
    });

    test('preserves Output Contract across speakable phases', () {
      const phases = <ConversationPhase, String>{
        ConversationPhase.validation: 'That makes sense.',
        ConversationPhase.naming: 'Something is still holding on.',
        ConversationPhase.permission: 'You do not have to solve this tonight.',
        ConversationPhase.release: 'You can let this rest for now.',
        ConversationPhase.continuity: 'Nothing more is needed right now.',
      };

      for (final entry in phases.entries) {
        final utterance = engine.generate(
          conversationDecision: ConversationDecision(
            phase: entry.key,
            shouldSpeak: true,
          ),
          exitDecision: ExitDecision.continueConversation,
        );
        expect(utterance, isNotNull, reason: entry.key.name);
        expect(utterance!.text, entry.value, reason: entry.key.name);
      }
    });
  });

  group('ConversationEngine DNA enforcement path', () {
    test('rejects WHAT drift from the language model', () {
      final engine = ConversationEngine(
        languageModelClient: const _FixedLanguageModelClient(
          'A completely different agenda.',
        ),
      );

      final utterance = engine.generate(
        conversationDecision: const ConversationDecision(
          phase: ConversationPhase.validation,
          shouldSpeak: true,
        ),
        exitDecision: ExitDecision.continueConversation,
      );

      expect(utterance, isNull);
    });

    test('rejects DNA-violating multi-insight language', () {
      final engine = ConversationEngine(
        languageModelClient: const _FixedLanguageModelClient(
          'That makes sense. Also try this tip.',
        ),
      );

      final utterance = engine.generate(
        conversationDecision: const ConversationDecision(
          phase: ConversationPhase.validation,
          shouldSpeak: true,
        ),
        exitDecision: ExitDecision.continueConversation,
      );

      expect(utterance, isNull);
    });

    test('rejects DNA-violating engagement hooks', () {
      final engine = ConversationEngine(
        languageModelClient: const _FixedLanguageModelClient(
          'That makes sense?',
        ),
      );

      final utterance = engine.generate(
        conversationDecision: const ConversationDecision(
          phase: ConversationPhase.validation,
          shouldSpeak: true,
        ),
        exitDecision: ExitDecision.continueConversation,
      );

      expect(utterance, isNull);
    });

    test('allows faithful DNA-compliant placeholder utterance', () {
      final engine = ConversationEngine(
        languageModelClient: const _FixedLanguageModelClient(
          'That makes sense.',
        ),
      );

      final utterance = engine.generate(
        conversationDecision: const ConversationDecision(
          phase: ConversationPhase.validation,
          shouldSpeak: true,
        ),
        exitDecision: ExitDecision.continueConversation,
      );

      expect(utterance, isA<ConversationUtterance>());
      expect(utterance!.text, 'That makes sense.');
    });
  });
}

class _FixedLanguageModelClient extends LanguageModelClient {
  final String fixedText;

  const _FixedLanguageModelClient(this.fixedText);

  @override
  ConversationUtterance realize(LlmInvocationPackage package) {
    return ConversationUtterance(text: fixedText);
  }
}
