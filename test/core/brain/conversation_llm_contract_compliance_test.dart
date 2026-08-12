import 'package:flutter_test/flutter_test.dart';
import 'package:slowave/core/brain/conversation_dna.dart';
import 'package:slowave/core/brain/conversation_phase.dart';
import 'package:slowave/core/brain/conversation_utterance.dart';
import 'package:slowave/core/brain/identity.dart';
import 'package:slowave/core/brain/language_model_client.dart';
import 'package:slowave/core/brain/living_mind_model.dart';
import 'package:slowave/core/brain/llm_invocation_package.dart';
import 'package:slowave/core/brain/utterance_guard.dart';
import 'package:slowave/core/brain/validated_understanding.dart';
import 'package:slowave/core/brain/working_mind_view.dart';

import 'faithful_test_vendor_provider.dart';

void main() {
  const client = LanguageModelClient(
    vendorProvider: FaithfulTestVendorProvider(),
  );
  const guard = UtteranceGuard();

  const speakable = <ConversationPhase>[
    ConversationPhase.validation,
    ConversationPhase.naming,
    ConversationPhase.permission,
    ConversationPhase.release,
    ConversationPhase.continuity,
    ConversationPhase.neutralEntry,
  ];

  group('Conversation LLM Contract compliance — LlmInvocationPackage', () {
    test('rejects non-speakable WHAT audio', () {
      expect(
        () => LlmInvocationPackage(what: ConversationPhase.audio),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('rejects non-speakable WHAT silence', () {
      expect(
        () => LlmInvocationPackage(what: ConversationPhase.silence),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('accepts every speakable WHAT', () {
      for (final phase in speakable) {
        final package = LlmInvocationPackage(what: phase);
        expect(package.what, phase);
        expect(package.dna, ConversationDNA.instance);
      }
    });
  });

  group('Conversation LLM Contract compliance — LanguageModelClient', () {
    test('never emits empty text for any speakable WHAT', () async {
      for (final phase in speakable) {
        final utterance = await client.realize(LlmInvocationPackage(what: phase));
        expect(utterance.text.trim(), isNotEmpty, reason: phase.name);
      }
    });

    test('never emits empty text when shaping context is present', () async {
      final workingMind = WorkingMindView(model: _emptyModel());
      for (final phase in speakable) {
        final utterance = await client.realize(
          LlmInvocationPackage(
            what: phase,
            understanding: const ValidatedUnderstanding(),
            workingMind: workingMind,
          ),
        );
        expect(utterance.text.trim(), isNotEmpty, reason: phase.name);
      }
    });

    test('returns exactly one candidate utterance object', () async {
      final utterance = await client.realize(
        LlmInvocationPackage(what: ConversationPhase.validation),
      );
      expect(utterance, isA<ConversationUtterance>());
      expect(utterance.text.contains('\n'), isFalse);
    });
  });

  group('Conversation LLM Contract compliance — UtteranceGuard drift', () {
    test('rejects empty text', () {
      expect(
        guard.allow(
          utterance: const ConversationUtterance(text: '   '),
          what: ConversationPhase.validation,
        ),
        isNull,
      );
    });

    test('rejects unrelated agenda as WHAT drift', () {
      expect(
        guard.allow(
          utterance: const ConversationUtterance(
            text: 'A completely different agenda.',
          ),
          what: ConversationPhase.validation,
        ),
        isNull,
      );
    });

    test('rejects cross-phase semantic drift', () {
      // Permission wording under sealed validation WHAT.
      expect(
        guard.allow(
          utterance: const ConversationUtterance(
            text: 'You do not have to solve this tonight.',
          ),
          what: ConversationPhase.validation,
        ),
        isNull,
      );

      // Validation wording under sealed naming WHAT.
      expect(
        guard.allow(
          utterance: const ConversationUtterance(text: 'That makes sense.'),
          what: ConversationPhase.naming,
        ),
        isNull,
      );
    });

    test('soft newlines normalize into one speech plane', () {
      final admitted = guard.allow(
        utterance: const ConversationUtterance(
          text: 'Something is weighing on your mind.\nIt is still there.',
        ),
        what: ConversationPhase.naming,
      );
      expect(admitted, isNotNull);
      expect(admitted!.text.contains('\n'), isFalse);
    });

    test('rejects over-long speech stacks past sentence cap', () {
      expect(
        guard.allow(
          utterance: const ConversationUtterance(
            text: 'One. Two. Three. Four. Five. Six.',
          ),
          what: ConversationPhase.naming,
        ),
        isNull,
      );
    });
  });

  group('Conversation LLM Contract compliance — UtteranceGuard DNA', () {
    test('rejects engagement hooks', () {
      expect(
        guard.allow(
          utterance: const ConversationUtterance(text: 'That makes sense?'),
          what: ConversationPhase.validation,
        ),
        isNull,
      );
    });

    test('rejects multi-insight stacking', () {
      expect(
        guard.allow(
          utterance: const ConversationUtterance(
            text: 'That makes sense and also try this tip.',
          ),
          what: ConversationPhase.validation,
        ),
        isNull,
      );
    });

    test('rejects clinical framing', () {
      expect(
        guard.allow(
          utterance: const ConversationUtterance(
            text: 'That makes sense in therapy.',
          ),
          what: ConversationPhase.validation,
        ),
        isNull,
      );
    });

    test('rejects sleep commands', () {
      expect(
        guard.allow(
          utterance: const ConversationUtterance(
            text: 'That makes sense so go to sleep.',
          ),
          what: ConversationPhase.validation,
        ),
        isNull,
      );
    });

    test('rejects analysis / storage tone', () {
      expect(
        guard.allow(
          utterance: const ConversationUtterance(
            text: 'That makes sense per your profile says.',
          ),
          what: ConversationPhase.validation,
        ),
        isNull,
      );
    });
  });

  group('Conversation LLM Contract compliance — valid candidates pass', () {
    test('admits candidates when bound ConversationDNA.instance is supplied', () {
      expect(
        guard.allow(
          utterance: const ConversationUtterance(text: 'That makes sense.'),
          what: ConversationPhase.validation,
          dna: ConversationDNA.instance,
        )?.text,
        'That makes sense.',
      );
    });
    test('admits minimal faithful placeholders for every speakable WHAT', () {
      const expected = <ConversationPhase, String>{
        ConversationPhase.validation: 'That makes sense.',
        ConversationPhase.naming: 'Something is still holding on.',
        ConversationPhase.permission:
            'You do not have to solve this tonight.',
        ConversationPhase.release: 'You can let this rest for now.',
        ConversationPhase.continuity: 'Nothing more is needed right now.',
        ConversationPhase.neutralEntry: "Hi whenever you're ready.",
      };

      for (final entry in expected.entries) {
        final admitted = guard.allow(
          utterance: ConversationUtterance(text: entry.value),
          what: entry.key,
        );
        expect(admitted, isNotNull, reason: entry.key.name);
        expect(admitted!.text, entry.value, reason: entry.key.name);
      }
    });

    test('admits natural wording variation inside sealed WHAT', () {
      expect(
        guard.allow(
          utterance: const ConversationUtterance(text: 'I hear that.'),
          what: ConversationPhase.validation,
        )?.text,
        'I hear that.',
      );

      expect(
        guard.allow(
          utterance: const ConversationUtterance(
            text: 'Something is still weighing on you.',
          ),
          what: ConversationPhase.naming,
        )?.text,
        'Something is still weighing on you.',
      );

      expect(
        guard.allow(
          utterance: const ConversationUtterance(text: "That's enough for now."),
          what: ConversationPhase.continuity,
        )?.text,
        "That's enough for now.",
      );
    });

    test('client candidates for speakable WHAT pass the guard', () async {
      for (final phase in speakable) {
        final candidate = await client.realize(LlmInvocationPackage(what: phase));
        final admitted = guard.allow(utterance: candidate, what: phase);
        expect(admitted, isNotNull, reason: phase.name);
        expect(admitted!.text.trim(), isNotEmpty, reason: phase.name);
      }
    });

    test('shaped client candidates pass the guard', () async {
      final workingMind = WorkingMindView(model: _emptyModel());
      for (final phase in speakable) {
        final candidate = await client.realize(
          LlmInvocationPackage(
            what: phase,
            understanding: const ValidatedUnderstanding(),
            workingMind: workingMind,
          ),
        );
        final admitted = guard.allow(utterance: candidate, what: phase);
        expect(admitted, isNotNull, reason: phase.name);
        expect(admitted!.text.trim(), isNotEmpty, reason: phase.name);
      }
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
