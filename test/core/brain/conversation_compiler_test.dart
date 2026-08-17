import 'package:flutter_test/flutter_test.dart';
import 'package:slowave/core/brain/conversation_blueprint_binding.dart';
import 'package:slowave/core/brain/conversation_compiler.dart';
import 'package:slowave/core/brain/conversation_constitution.dart';
import 'package:slowave/core/brain/conversation_dna.dart';
import 'package:slowave/core/brain/conversation_grounding_buffer.dart';
import 'package:slowave/core/brain/conversation_phase.dart';
import 'package:slowave/core/brain/conversation_philosophy.dart';
import 'package:slowave/core/brain/identity.dart';
import 'package:slowave/core/brain/language_style.dart';
import 'package:slowave/core/brain/living_mind_model.dart';
import 'package:slowave/core/brain/llm_invocation_package.dart';
import 'package:slowave/core/brain/validated_understanding.dart';
import 'package:slowave/core/brain/working_mind_view.dart';

void main() {
  const compiler = ConversationCompiler();

  group('ConversationCompiler V1 — Receipt (validation)', () {
    final package = LlmInvocationPackage(what: ConversationPhase.validation);
    final compiled = compiler.compile(package)!;

    test('binds Blueprint Receipt explicitly', () {
      expect(compiled.sealedWhat, ConversationPhase.validation);
      expect(compiled.stage.stage, BlueprintStage.receipt);
      expect(compiled.stage.purpose, contains('accurately taken in'));
    });

    test('binds purpose, forbidden moves, length, questions, rest direction', () {
      expect(compiled.stage.aim, isNotEmpty);
      expect(compiled.stage.forbiddenMoves, isNotEmpty);
      expect(
        compiled.stage.forbiddenMoves,
        contains(contains('Questions')),
      );
      expect(compiled.stage.responseLength, contains('45 words'));
      expect(compiled.stage.responseLength.toLowerCase(), contains('short sentence'));
      expect(compiled.stage.questionPermission, contains('forbidden'));
      expect(compiled.stage.restDirection.toLowerCase(), contains('rest'));
    });

    test('prevents generic filler and unsupported repetition', () {
      expect(compiled.systemContent, contains('I understand'));
      expect(compiled.systemContent, contains('First Stop Moment'));
      expect(compiled.systemContent, contains('Receipt Intelligence'));
      expect(
        compiled.stage.forbiddenMoves.join(' '),
        contains('I understand'),
      );
      expect(
        compiled.stage.sealedWhatSignature.contains('concrete felt receipt'),
        isTrue,
      );
      expect(
        compiled.stage.sealedWhatSignature.toLowerCase(),
        contains('forbidden'),
      );
    });

    test('Receipt Intelligence grounds First Stop Moment in conversation grounding', () {
      final withGrounding = compiler.compile(
        LlmInvocationPackage(
          what: ConversationPhase.validation,
          conversationGrounding: const ConversationGroundingBuffer.empty()
              .appendUserUtterance(
            'I keep replaying everything I still have to figure out for tomorrow. My mind won’t settle.',
          ),
        ),
      )!;

      expect(withGrounding.userContent, contains('First Stop Moment'));
      expect(
        withGrounding.userContent,
        contains('Current-turn conversation grounding to receive'),
      );
      expect(withGrounding.userContent, contains('won’t settle'));
      expect(withGrounding.userContent, contains('Do not drift into Naming'));
      expect(withGrounding.stage.responseLength, contains('45 words'));
      expect(withGrounding.systemContent, isNot(contains('e.g. that makes sense')));
      expect(withGrounding.systemContent, contains('Receipt Intelligence v1.6'));
      expect(withGrounding.systemContent, contains('Anti-essay rule'));
    });

    test('Receipt Intelligence does not apply to non-Receipt stages', () {
      final permission = compiler.compile(
        LlmInvocationPackage(what: ConversationPhase.permission),
      )!;
      expect(permission.systemContent, isNot(contains('Receipt Intelligence')));
      expect(permission.userContent, isNot(contains('First Stop Moment')));
      expect(permission.systemContent, isNot(contains('Naming Intelligence')));
      expect(permission.systemContent, contains('Permission Intelligence v1.2'));
    });

    test('binds Constitution and Philosophy without choosing WHAT', () {
      expect(compiled.constitutionVersion, ConversationConstitution.version);
      expect(compiled.philosophyVersion, ConversationPhilosophy.version);
      expect(compiled.constitutionalConstraints, isNotEmpty);
      expect(compiled.philosophicalStance, isNotEmpty);
      expect(compiled.systemContent, contains('Constitutional constraints'));
      expect(compiled.systemContent, contains('Philosophical stance'));
    });
  });

  group('ConversationCompiler V1 — Naming', () {
    final package = LlmInvocationPackage(what: ConversationPhase.naming);
    final compiled = compiler.compile(package)!;

    test('binds Blueprint Naming with sealed naming WHAT only', () {
      expect(compiled.sealedWhat, ConversationPhase.naming);
      expect(compiled.stage.stage, BlueprintStage.naming);
      expect(compiled.stage.purpose, contains('gentle, human name'));
      expect(compiled.stage.sealedWhatSignature, contains('naming / Naming'));
      expect(compiled.stage.forbiddenMoves.join(' '), contains('Digging'));
      expect(compiled.stage.questionPermission, contains('forbidden'));
      expect(compiled.stage.restDirection.toLowerCase(), contains('rest'));
    });

    test('Naming Intelligence targets quiet recognition without interpretation', () {
      final withGrounding = compiler.compile(
        LlmInvocationPackage(
          what: ConversationPhase.naming,
          conversationGrounding: const ConversationGroundingBuffer.empty()
              .appendUserUtterance(
            'It’s the same loops over and over. I can’t get them to stop.',
          ),
        ),
      )!;

      expect(withGrounding.systemContent, contains('Naming Intelligence'));
      expect(withGrounding.realizationDirective, contains('quiet recognition'));
      expect(withGrounding.userContent, contains('No interpretation'));
      expect(withGrounding.userContent, contains('loops over and over'));
      expect(withGrounding.stage.responseLength, contains('45 words'));
      expect(
        withGrounding.stage.forbiddenMoves.join(' '),
        contains('hidden motives'),
      );
      expect(
        withGrounding.stage.forbiddenMoves.join(' '),
        contains('Permission'),
      );
    });
  });

  group('ConversationCompiler V1 — Permission', () {
    final package = LlmInvocationPackage(what: ConversationPhase.permission);
    final compiled = compiler.compile(package)!;

    test('binds Permission and forbids asking to continue', () {
      expect(compiled.sealedWhat, ConversationPhase.permission);
      expect(compiled.stage.stage, BlueprintStage.permission);
      expect(compiled.stage.purpose, contains('obligation to solve'));
      expect(
        compiled.stage.forbiddenMoves.join(' '),
        contains('want to continue'),
      );
      expect(compiled.stage.questionPermission, contains('forbidden'));
      expect(compiled.stage.restDirection.toLowerCase(), contains('rest'));
      expect(compiled.systemContent, contains('Permission Intelligence v1.2'));
      expect(
        compiled.stage.sealedWhatSignature,
        contains('Do not require'),
      );
      expect(
        compiled.stage.sealedWhatSignature.toLowerCase(),
        isNot(contains("don't have to solve this tonight")),
      );
    });

    test('Permission grounding shapes wording without changing WHAT', () {
      final withGrounding = compiler.compile(
        LlmInvocationPackage(
          what: ConversationPhase.permission,
          conversationGrounding: const ConversationGroundingBuffer.empty()
              .appendUserUtterance('Still here.'),
        ),
      )!;
      final again = compiler.compile(
        LlmInvocationPackage(
          what: ConversationPhase.permission,
          conversationGrounding: const ConversationGroundingBuffer.empty()
              .appendUserUtterance('Still here.'),
        ),
      )!;

      expect(withGrounding.sealedWhat, ConversationPhase.permission);
      expect(withGrounding.userContent, contains('Still here.'));
      expect(withGrounding.userContent, contains('Low-load note'));
      expect(withGrounding.systemContent, contains('Anti-stamp rule'));
      expect(withGrounding.systemContent, again.systemContent);
      expect(withGrounding.userContent, again.userContent);
    });
  });

  group('ConversationCompiler V1 — Release', () {
    final package = LlmInvocationPackage(what: ConversationPhase.release);
    final compiled = compiler.compile(package)!;

    test('binds Release and forbids sleep commands / activation', () {
      expect(compiled.sealedWhat, ConversationPhase.release);
      expect(compiled.stage.stage, BlueprintStage.release);
      expect(compiled.stage.purpose, contains('rest for now'));
      expect(
        compiled.stage.forbiddenMoves.join(' '),
        contains('sleep commands'),
      );
      expect(compiled.stage.questionPermission, contains('forbidden'));
      expect(compiled.stage.restDirection.toLowerCase(), contains('rest'));
      expect(compiled.systemContent, contains('Release Intelligence v1.3'));
      expect(
        compiled.stage.sealedWhatSignature,
        contains('Do not require'),
      );
      expect(
        compiled.stage.sealedWhatSignature,
        contains('Let it rest for now'),
      );
    });

    test('Release grounding anti-repeat is deterministic for prior user turns', () {
      final withGrounding = compiler.compile(
        LlmInvocationPackage(
          what: ConversationPhase.release,
          conversationGrounding: const ConversationGroundingBuffer.empty()
              .appendUserUtterance('I am still thinking.')
              .appendUserUtterance('It is quieter but not gone.'),
        ),
      )!;
      final again = compiler.compile(
        LlmInvocationPackage(
          what: ConversationPhase.release,
          conversationGrounding: const ConversationGroundingBuffer.empty()
              .appendUserUtterance('I am still thinking.')
              .appendUserUtterance('It is quieter but not gone.'),
        ),
      )!;

      expect(withGrounding.sealedWhat, ConversationPhase.release);
      expect(withGrounding.userContent, contains('Anti-repeat'));
      expect(
        withGrounding.userContent,
        contains('prior user turns'),
      );
      expect(withGrounding.systemContent, contains('Anti-stamp rule'));
      expect(withGrounding.systemContent, again.systemContent);
      expect(withGrounding.userContent, again.userContent);
      expect(withGrounding.systemContent, isNot(contains('assistant utterance')));
    });
  });

  group('ConversationCompiler V1 — continuity across turns', () {
    test('Enough/continuity compiles independently after prior stages', () {
      final arc = <ConversationPhase>[
        ConversationPhase.validation,
        ConversationPhase.naming,
        ConversationPhase.permission,
        ConversationPhase.release,
        ConversationPhase.continuity,
      ];
      final expectedStages = <BlueprintStage>[
        BlueprintStage.receipt,
        BlueprintStage.naming,
        BlueprintStage.permission,
        BlueprintStage.release,
        BlueprintStage.enough,
      ];

      BlueprintStage? previous;
      for (var i = 0; i < arc.length; i++) {
        final compiled = compiler.compile(LlmInvocationPackage(what: arc[i]))!;
        expect(compiled.sealedWhat, arc[i]);
        expect(compiled.stage.stage, expectedStages[i]);
        // No backward bleed: each compile binds only its sealed stage.
        expect(compiled.stage.sealedWhat, arc[i]);
        expect(
          compiled.realizationDirective,
          contains(arc[i].name),
        );
        expect(
          compiled.systemContent,
          contains('Stage: ${expectedStages[i].name}'),
        );
        // Rest direction remains on every spoken turn.
        expect(compiled.stage.restDirection.toLowerCase(), contains('rest'));
        if (previous != null) {
          expect(compiled.stage.stage, isNot(previous));
        }
        previous = compiled.stage.stage;
      }
    });

    test('same sealed package compiles deterministically across turns', () {
      final package = LlmInvocationPackage(what: ConversationPhase.validation);
      final a = compiler.compile(package)!;
      final b = compiler.compile(package)!;
      expect(a.systemContent, b.systemContent);
      expect(a.userContent, b.userContent);
      expect(a.stage.stage, b.stage.stage);
      expect(a.realizationDirective, b.realizationDirective);
    });

    test('shaping presence is presence-only across turns', () {
      final bare = compiler.compile(
        LlmInvocationPackage(what: ConversationPhase.continuity),
      )!;
      final shaped = compiler.compile(
        LlmInvocationPackage(
          what: ConversationPhase.continuity,
          understanding: const ValidatedUnderstanding(),
          workingMind: WorkingMindView(model: _emptyModel()),
        ),
      )!;

      expect(bare.shapingNote, contains('No additional shaping'));
      expect(shaped.shapingNote, contains('Attentive wording'));
      expect(shaped.shapingNote, contains('Do not narrate analysis'));
      // Shaping must not inject cognitive content from the model view.
      expect(shaped.shapingNote, isNot(contains('userId')));
      expect(shaped.shapingNote, isNot(contains('compiler-test')));
      expect(shaped.sealedWhat, ConversationPhase.continuity);
      expect(shaped.stage.stage, BlueprintStage.enough);
    });
  });

  group('ConversationCompiler V1 — fail closed / ownership', () {
    test('never chooses DNA other than bound canonical instance', () {
      final compiled = compiler.compile(
        LlmInvocationPackage(what: ConversationPhase.naming),
      )!;
      expect(compiled.dnaPrinciples.length, ConversationDNA.principles.length);
      expect(compiled.llmRequired, LlmContractBounds.required);
    });

    test('compiled instructions carry frozen LLM bounds unchanged', () {
      final compiled = compiler.compile(
        LlmInvocationPackage(what: ConversationPhase.release),
      )!;
      expect(compiled.llmForbidden, LlmContractBounds.forbidden);
      expect(
        compiled.systemContent,
        contains('Release, protocol/phase, or exit judgment'),
      );
    });
  });

  group('ConversationCompiler V1 — Language Style shaping', () {
    test('binds Language Style V1 on every speakable stage without changing WHAT', () {
      const speakable = <ConversationPhase>[
        ConversationPhase.validation,
        ConversationPhase.naming,
        ConversationPhase.permission,
        ConversationPhase.release,
        ConversationPhase.continuity,
      ];

      for (final phase in speakable) {
        final compiled = compiler.compile(LlmInvocationPackage(what: phase))!;
        expect(compiled.sealedWhat, phase);
        expect(compiled.systemContent, contains('Language Style v${LanguageStyle.version}'));
        expect(compiled.systemContent, contains('quiet warmth'));
        expect(compiled.systemContent, contains('Golden Conversations V2'));
        expect(compiled.systemContent, contains('naturalness'));
        expect(
          compiled.systemContent,
          contains('that’s exactly what’s happening'),
        );
        expect(compiled.userContent, contains('Language Style v${LanguageStyle.version}'));
        // Style must not rewrite stage identity.
        expect(compiled.systemContent, contains('Stage: ${compiled.stage.stage.name}'));
      }
    });
  });

  test('TR current turn compiles a hard Turkish language lock', () {
    final compiled = compiler.compile(
      LlmInvocationPackage(
        what: ConversationPhase.validation,
        conversationGrounding: const ConversationGroundingBuffer.empty()
            .appendUserUtterance('uyuyamiyorum.'),
      ),
    )!;
    expect(compiled.systemContent, contains('LANGUAGE LOCK'));
    expect(compiled.systemContent, contains('Turkish only'));
    expect(compiled.userContent, contains('LANGUAGE LOCK'));
  });

  test('EN current turn compiles a hard English language lock', () {
    final compiled = compiler.compile(
      LlmInvocationPackage(
        what: ConversationPhase.release,
        conversationGrounding: const ConversationGroundingBuffer.empty()
            .appendUserUtterance("I can't stop thinking about tomorrow."),
      ),
    )!;
    expect(compiled.systemContent, contains('LANGUAGE LOCK'));
    expect(compiled.systemContent, contains('English only'));
  });
}

LivingMindModel _emptyModel() {
  final now = DateTime.utc(2026, 1, 1);
  return LivingMindModel(
    identity: Identity(
      userId: 'compiler-test',
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
