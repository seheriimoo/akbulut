import 'package:flutter_test/flutter_test.dart';
import 'package:slowave/core/brain/conversation_decision.dart';
import 'package:slowave/core/brain/conversation_engine.dart';
import 'package:slowave/core/brain/conversation_phase.dart';
import 'package:slowave/core/brain/conversation_utterance.dart';
import 'package:slowave/core/brain/exit_decision.dart';
import 'package:slowave/core/brain/language_model_client.dart';
import 'package:slowave/core/brain/llm_invocation_package.dart';
import 'package:slowave/core/brain/vendor_provider.dart';

import 'faithful_test_vendor_provider.dart';

void main() {
  group('ConversationEngine output contract', () {
    const engine = ConversationEngine(
      languageModelClient: LanguageModelClient(
        vendorProvider: FaithfulTestVendorProvider(),
      ),
    );

    test('emits exactly one speech outcome when authorized', () async {
      final utterance = await engine.generate(
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

    test('non-speech path returns no conversational language on exit stop', () async {
      final utterance = await engine.generate(
        conversationDecision: const ConversationDecision(
          phase: ConversationPhase.validation,
          shouldSpeak: true,
        ),
        exitDecision: ExitDecision.silence,
      );

      expect(utterance, isNull);
    });

    test('non-speech path returns no conversational language for audio phase', () async {
      final utterance = await engine.generate(
        conversationDecision: const ConversationDecision(
          phase: ConversationPhase.audio,
          shouldSpeak: false,
        ),
        exitDecision: ExitDecision.transitionToAudio,
      );

      expect(utterance, isNull);
    });

    test('preserves Output Contract across speakable phases', () async {
      const phases = <ConversationPhase, String>{
        ConversationPhase.validation: 'That makes sense.',
        ConversationPhase.naming: 'Something is still holding on.',
        ConversationPhase.permission: 'You do not have to solve this tonight.',
        ConversationPhase.release: 'You can let this rest for now.',
        ConversationPhase.continuity: 'Nothing more is needed right now.',
        ConversationPhase.neutralEntry: "Hi whenever you're ready.",
      };

      for (final entry in phases.entries) {
        final utterance = await engine.generate(
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

    test('vendor failure fails closed to null without escaping VendorError', () async {
      final engine = ConversationEngine(
        languageModelClient: LanguageModelClient(
          vendorProvider: _FailingVendorProvider(
            const VendorError(
              kind: VendorErrorKind.transport,
              message: 'transport down',
            ),
          ),
        ),
      );

      await expectLater(
        engine.generate(
          conversationDecision: const ConversationDecision(
            phase: ConversationPhase.validation,
            shouldSpeak: true,
          ),
          exitDecision: ExitDecision.continueConversation,
        ),
        completion(isNull),
      );
    });
  });

  group('ConversationEngine DNA enforcement path', () {
    test('rejects WHAT drift from the language model', () async {
      final engine = ConversationEngine(
        languageModelClient: const _FixedLanguageModelClient(
          'A completely different agenda.',
        ),
      );

      final utterance = await engine.generate(
        conversationDecision: const ConversationDecision(
          phase: ConversationPhase.validation,
          shouldSpeak: true,
        ),
        exitDecision: ExitDecision.continueConversation,
      );

      expect(utterance, isNull);
    });

    test('rejects DNA-violating multi-insight language', () async {
      final engine = ConversationEngine(
        languageModelClient: const _FixedLanguageModelClient(
          'That makes sense. Also try this tip.',
        ),
      );

      final utterance = await engine.generate(
        conversationDecision: const ConversationDecision(
          phase: ConversationPhase.validation,
          shouldSpeak: true,
        ),
        exitDecision: ExitDecision.continueConversation,
      );

      expect(utterance, isNull);
    });

    test('rejects DNA-violating engagement hooks', () async {
      final engine = ConversationEngine(
        languageModelClient: const _FixedLanguageModelClient(
          'That makes sense?',
        ),
      );

      final utterance = await engine.generate(
        conversationDecision: const ConversationDecision(
          phase: ConversationPhase.validation,
          shouldSpeak: true,
        ),
        exitDecision: ExitDecision.continueConversation,
      );

      expect(utterance, isNull);
    });

    test('allows faithful DNA-compliant placeholder utterance', () async {
      final engine = ConversationEngine(
        languageModelClient: const _FixedLanguageModelClient(
          'That makes sense.',
        ),
      );

      final utterance = await engine.generate(
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
  Future<ConversationUtterance> realize(LlmInvocationPackage package) async {
    return ConversationUtterance(text: fixedText);
  }
}

class _FailingVendorProvider implements VendorProvider {
  final VendorError error;

  const _FailingVendorProvider(this.error);

  @override
  Future<VendorResponse> complete(VendorRequest request) async {
    throw error;
  }
}
