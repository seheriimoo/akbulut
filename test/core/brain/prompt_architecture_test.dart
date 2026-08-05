import 'package:flutter_test/flutter_test.dart';
import 'package:slowave/core/brain/conversation_decision.dart';
import 'package:slowave/core/brain/conversation_dna.dart';
import 'package:slowave/core/brain/conversation_phase.dart';
import 'package:slowave/core/brain/exit_decision.dart';
import 'package:slowave/core/brain/identity.dart';
import 'package:slowave/core/brain/living_mind_model.dart';
import 'package:slowave/core/brain/llm_invocation_package.dart';
import 'package:slowave/core/brain/prompt_architecture.dart';
import 'package:slowave/core/brain/validated_understanding.dart';
import 'package:slowave/core/brain/working_mind_view.dart';

void main() {
  const architecture = PromptArchitecture();

  group('PromptArchitecture invoke vs abstain', () {
    test('invokes with authorized speakable decision and exit continue', () {
      final package = architecture.package(
        conversationDecision: const ConversationDecision(
          phase: ConversationPhase.validation,
          shouldSpeak: true,
        ),
        exitDecision: ExitDecision.continueConversation,
      );

      expect(package, isNotNull);
      expect(package!.what, ConversationPhase.validation);
      expect(package.dna, ConversationDNA.instance);
    });

    test('abstains when Exit does not permit continuation', () {
      final package = architecture.package(
        conversationDecision: const ConversationDecision(
          phase: ConversationPhase.validation,
          shouldSpeak: true,
        ),
        exitDecision: ExitDecision.silence,
      );

      expect(package, isNull);
    });

    test('abstains when Exit transitions to audio', () {
      final package = architecture.package(
        conversationDecision: const ConversationDecision(
          phase: ConversationPhase.audio,
          shouldSpeak: false,
        ),
        exitDecision: ExitDecision.transitionToAudio,
      );

      expect(package, isNull);
    });

    test('abstains for non-speech protocol phases', () {
      final silencePackage = architecture.package(
        conversationDecision: const ConversationDecision(
          phase: ConversationPhase.silence,
          shouldSpeak: false,
        ),
        exitDecision: ExitDecision.continueConversation,
      );
      final audioPackage = architecture.package(
        conversationDecision: const ConversationDecision(
          phase: ConversationPhase.audio,
          shouldSpeak: true,
        ),
        exitDecision: ExitDecision.continueConversation,
      );

      expect(silencePackage, isNull);
      expect(audioPackage, isNull);
    });

    test('abstains when protocol shouldSpeak is false', () {
      final package = architecture.package(
        conversationDecision: const ConversationDecision(
          phase: ConversationPhase.validation,
          shouldSpeak: false,
        ),
        exitDecision: ExitDecision.continueConversation,
      );

      expect(package, isNull);
    });
  });

  group('PromptArchitecture authorized inputs', () {
    test('packages with required inputs only', () {
      final package = architecture.package(
        conversationDecision: const ConversationDecision(
          phase: ConversationPhase.permission,
          shouldSpeak: true,
        ),
        exitDecision: ExitDecision.continueConversation,
      );

      expect(package, isNotNull);
      expect(package!.understanding, isNull);
      expect(package.workingMind, isNull);
      expect(package.what, ConversationPhase.permission);
    });

    test('admits optional shaping context without changing WHAT', () {
      const understanding = ValidatedUnderstanding();
      final workingMind = WorkingMindView(model: _emptyModel());

      final package = architecture.package(
        conversationDecision: const ConversationDecision(
          phase: ConversationPhase.release,
          shouldSpeak: true,
        ),
        exitDecision: ExitDecision.continueConversation,
        understanding: understanding,
        workingMind: workingMind,
      );

      expect(package, isNotNull);
      expect(package!.what, ConversationPhase.release);
      expect(identical(package.understanding, understanding), isTrue);
      expect(identical(package.workingMind, workingMind), isTrue);
    });

    test('binds frozen immutable LLM Contract bounds', () {
      final package = architecture.package(
        conversationDecision: const ConversationDecision(
          phase: ConversationPhase.naming,
          shouldSpeak: true,
        ),
        exitDecision: ExitDecision.continueConversation,
      )!;

      expect(package.llmRequired, LlmContractBounds.required);
      expect(package.llmAllowed, LlmContractBounds.allowed);
      expect(package.llmForbidden, LlmContractBounds.forbidden);
      expect(
        () => package.llmRequired.add('mutate'),
        throwsUnsupportedError,
      );
    });
  });
}

LivingMindModel _emptyModel() {
  final now = DateTime.utc(2026, 1, 1);
  return LivingMindModel(
    identity: Identity(
      userId: 'test',
      preferredLanguage: 'en',
      timezone: 'UTC',
      createdAt: now,
      lastInteractionAt: now,
      totalSessions: 0,
    ),
    mentalPatterns: const [],
    emotionalPatterns: const [],
    triggers: const [],
    beliefs: const [],
    needs: const [],
    preferences: const [],
  );
}
