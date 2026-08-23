import 'package:flutter_test/flutter_test.dart';
import 'package:slowave/core/brain/conversation_decision.dart';
import 'package:slowave/core/brain/conversation_engine.dart';
import 'package:slowave/core/brain/conversation_grounding_buffer.dart';
import 'package:slowave/core/brain/conversation_phase.dart';
import 'package:slowave/core/brain/conversation_utterance.dart';
import 'package:slowave/core/brain/exit_decision.dart';
import 'package:slowave/core/brain/guard_safe_fallback.dart';
import 'package:slowave/core/brain/language_model_client.dart';
import 'package:slowave/core/brain/llm_invocation_package.dart';
import 'package:slowave/core/brain/utterance_guard.dart';
import 'package:slowave/core/brain/vendor_provider.dart';

/// P1-1 — Guard reject must not leave the user in silence.
void main() {
  group('GuardSafeFallback', () {
    const guard = UtteranceGuard();

    test('EN fallbacks admit for every speakable WHAT', () {
      for (final what in const [
        ConversationPhase.validation,
        ConversationPhase.naming,
        ConversationPhase.permission,
        ConversationPhase.release,
        ConversationPhase.continuity,
        ConversationPhase.neutralEntry,
      ]) {
        final fallback = GuardSafeFallback.forPhase(
          what: what,
          userUtterance: "I can't sleep. Keep going over the conversation.",
        );
        expect(fallback, isNotNull, reason: what.name);
        final admitted = guard.allow(
          utterance: fallback!,
          what: what,
          userUtterance: "I can't sleep. Keep going over the conversation.",
        );
        expect(admitted, isNotNull, reason: 'EN ${what.name}: ${fallback.text}');
      }
    });

    test('TR fallbacks admit for every speakable WHAT', () {
      for (final what in const [
        ConversationPhase.validation,
        ConversationPhase.naming,
        ConversationPhase.permission,
        ConversationPhase.release,
        ConversationPhase.continuity,
        ConversationPhase.neutralEntry,
      ]) {
        final fallback = GuardSafeFallback.forPhase(
          what: what,
          userUtterance: 'Uyuyamiyorum. Aklım durmuyor.',
        );
        expect(fallback, isNotNull, reason: what.name);
        final admitted = guard.allow(
          utterance: fallback!,
          what: what,
          userUtterance: 'Uyuyamiyorum. Aklım durmuyor.',
        );
        expect(admitted, isNotNull, reason: 'TR ${what.name}: ${fallback.text}');
      }
    });
  });

  group('ConversationEngine Guard-drop fallback', () {
    test('R17-like EN Guard reject yields safe response, never silence', () async {
      final engine = ConversationEngine(
        languageModelClient: const _FixedLanguageModelClient(
          // Multi-insight / tip stack — Guard reject (same family as S20).
          'Your thoughts are racing, going over that earlier conversation. '
          'It can feel heavy when those memories loop. '
          'Perhaps what feels difficult is the search for clarity. Also try this tip tonight.',
        ),
      );

      final grounding = const ConversationGroundingBuffer.empty()
          .appendUserUtterance(
        "Can't sleep. Keep going over the conversation from earlier.",
      );

      final spoken = await engine.generate(
        conversationDecision: const ConversationDecision(
          phase: ConversationPhase.validation,
          shouldSpeak: true,
        ),
        exitDecision: ExitDecision.continueConversation,
        conversationGrounding: grounding,
      );

      expect(spoken, isNotNull);
      expect(spoken!.text.trim(), isNotEmpty);
      expect(spoken.text, contains('conversation'));
      expect(spoken.text.toLowerCase(), isNot(contains('tip tonight')));
      expect(spoken.text.toLowerCase(), isNot(contains('search for clarity')));
    });

    test('rejected clinical text is not shown; Guard-safe fallback is', () async {
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
        livedExpression: 'I keep thinking about tomorrow.',
      );

      expect(spoken, isNotNull);
      expect(spoken!.text.toLowerCase(), isNot(contains('therapist')));
      expect(spoken.text.toLowerCase(), contains('tomorrow'));
    });

    test('rejected sleep-command text is not shown; Guard-safe fallback is', () async {
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
      expect(spoken.text.toLowerCase(), contains('awake'));
    });

    test('TR Guard reject uses Turkish fallback', () async {
      final engine = ConversationEngine(
        languageModelClient: const _FixedLanguageModelClient(
          'That makes sense. Also try this tip tonight.',
        ),
      );

      final grounding = const ConversationGroundingBuffer.empty()
          .appendUserUtterance('Kafam durmuyor ya.');

      final spoken = await engine.generate(
        conversationDecision: const ConversationDecision(
          phase: ConversationPhase.validation,
          shouldSpeak: true,
        ),
        exitDecision: ExitDecision.continueConversation,
        conversationGrounding: grounding,
      );

      expect(spoken, isNotNull);
      expect(spoken!.text, isNot('Anlıyorum.'));
      expect(spoken.text.toLowerCase(), anyOf(contains('kafam'), contains('kafan'), contains('durmuyor')));
      expect(spoken.text.toLowerCase(), isNot(contains('tip')));
    });
  });
}

class _FixedLanguageModelClient extends LanguageModelClient {
  const _FixedLanguageModelClient(this.text);

  final String text;

  @override
  Future<ConversationUtterance> realize(LlmInvocationPackage package) async {
    return ConversationUtterance(text: text);
  }
}
