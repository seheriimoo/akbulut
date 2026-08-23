import 'package:flutter_test/flutter_test.dart';
import 'package:slowave/core/brain/conversation_dna.dart';
import 'package:slowave/core/brain/conversation_decision.dart';
import 'package:slowave/core/brain/conversation_engine.dart';
import 'package:slowave/core/brain/conversation_phase.dart';
import 'package:slowave/core/brain/conversation_utterance.dart';
import 'package:slowave/core/brain/exit_decision.dart';
import 'package:slowave/core/brain/language_model_client.dart';
import 'package:slowave/core/brain/llm_invocation_package.dart';

import 'faithful_test_vendor_provider.dart';

void main() {
  group('ConversationDNA model', () {
    test('exposes exactly ten frozen principles', () {
      expect(ConversationDNA.principles, hasLength(10));
      expect(ConversationDNA.principles.first.id, 1);
      expect(ConversationDNA.principles.last.id, 10);
    });

    test('exposes exactly six frozen anti-rules', () {
      expect(ConversationDNA.antiRules, hasLength(6));
    });

    test('is a single immutable canonical instance', () {
      expect(identical(ConversationDNA.instance, ConversationDNA.instance), isTrue);
      expect(ConversationDNA.principles, same(ConversationDNA.principles));
      expect(ConversationDNA.antiRules, same(ConversationDNA.antiRules));
    });

    test('remains declarative constraint data only', () {
      expect(ConversationDNA.principles.every((p) => p.name.isNotEmpty), isTrue);
      expect(ConversationDNA.principles.every((p) => p.rule.isNotEmpty), isTrue);
      expect(ConversationDNA.antiRules.every((r) => r.name.isNotEmpty), isTrue);
      expect(ConversationDNA.antiRules.every((r) => r.reason.isNotEmpty), isTrue);
    });
  });

  group('ConversationDNA enforcement via Conversation emission', () {
    test('clinical framing cannot leave Conversation layer', () async {
      final engine = ConversationEngine(
        languageModelClient: const _FixedLanguageModelClient(
          'As your therapist, that makes sense.',
        ),
      );

      final spoken = await engine.generate(
        conversationDecision: const ConversationDecision(
          phase: ConversationPhase.validation,
          shouldSpeak: true,
        ),
        exitDecision: ExitDecision.continueConversation,
        livedExpression: 'I keep thinking.',
      );
      // P1-1: Guard-safe fallback may speak; rejected clinical text must not.
      expect(spoken, isNotNull);
      expect(spoken!.text.toLowerCase(), isNot(contains('therapist')));
    });

    test('sleep-command language cannot leave Conversation layer', () async {
      final engine = ConversationEngine(
        languageModelClient: const _FixedLanguageModelClient(
          'You should sleep now.',
        ),
      );

      final spoken = await engine.generate(
        conversationDecision: const ConversationDecision(
          phase: ConversationPhase.validation,
          shouldSpeak: true,
        ),
        exitDecision: ExitDecision.continueConversation,
        livedExpression: 'I am still awake.',
      );
      expect(spoken, isNotNull);
      expect(spoken!.text.toLowerCase(), isNot(contains('should sleep')));
    });

    test('faithful placeholder language can leave Conversation layer', () async {
      const engine = ConversationEngine(
        languageModelClient: LanguageModelClient(
          vendorProvider: FaithfulTestVendorProvider(),
        ),
      );

      final utterance = await engine.generate(
        conversationDecision: const ConversationDecision(
          phase: ConversationPhase.permission,
          shouldSpeak: true,
        ),
        exitDecision: ExitDecision.continueConversation,
      );

      expect(utterance, isA<ConversationUtterance>());
      expect(utterance!.text, 'You do not have to solve this tonight.');
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
