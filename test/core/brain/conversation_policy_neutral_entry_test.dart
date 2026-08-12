import 'package:flutter_test/flutter_test.dart';
import 'package:slowave/core/brain/conversation_phase.dart';
import 'package:slowave/core/brain/conversation_policy.dart';
import 'package:slowave/core/brain/emotional_pattern.dart';
import 'package:slowave/core/brain/identity.dart';
import 'package:slowave/core/brain/living_mind_model.dart';
import 'package:slowave/core/brain/mental_pattern.dart';
import 'package:slowave/core/brain/mental_pattern_status.dart';
import 'package:slowave/core/brain/night_session.dart';
import 'package:slowave/core/brain/release_decision.dart';
import 'package:slowave/core/brain/session_turn.dart';
import 'package:slowave/core/brain/validated_understanding.dart';
import 'package:slowave/core/brain/working_mind_view.dart';

void main() {
  const policy = ConversationPolicy();

  NightSession emptySession() {
    final now = DateTime.utc(2026, 1, 1);
    final mind = WorkingMindView(
      model: LivingMindModel(
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
      ),
    );
    return NightSession(workingMind: mind, turns: const []);
  }

  const hold = ReleaseDecision(
    readiness: ReleaseReadiness.hold,
    confidence: 1,
  );

  group('ConversationPolicy Neutral Entry V1', () {
    test('first-turn hold + greeting → neutralEntry', () {
      final decision = policy.decide(
        releaseDecision: hold,
        message: 'hi',
        session: emptySession(),
        understanding: const ValidatedUnderstanding(),
      );

      expect(decision.phase, ConversationPhase.neutralEntry);
      expect(decision.shouldSpeak, isTrue);
    });

    test('emotional first-turn hold still routes to validation/Receipt', () {
      final decision = policy.decide(
        releaseDecision: hold,
        message: 'I keep replaying tomorrow and my mind will not settle.',
        session: emptySession(),
        understanding: const ValidatedUnderstanding(),
      );

      expect(decision.phase, ConversationPhase.validation);
      expect(decision.shouldSpeak, isTrue);
    });

    test('greeting with load evidence never hijacks to Neutral Entry', () {
      final withMental = policy.decide(
        releaseDecision: hold,
        message: 'hi',
        session: emptySession(),
        understanding: const ValidatedUnderstanding(
          mentalPatterns: [
            MentalPattern(
              id: 'm1',
              name: 'loop',
              description: 'looping',
              confidence: 0.9,
              observations: 1,
              status: MentalPatternStatus.observed,
            ),
          ],
        ),
      );
      final withEmotional = policy.decide(
        releaseDecision: hold,
        message: 'hello',
        session: emptySession(),
        understanding: const ValidatedUnderstanding(
          emotionalPatterns: [
            EmotionalPattern(
              id: 'e1',
              name: 'ache',
              description: 'ache',
              confidence: 0.9,
              observations: 1,
            ),
          ],
        ),
      );

      expect(withMental.phase, ConversationPhase.validation);
      expect(withEmotional.phase, ConversationPhase.validation);
    });

    test('greeting after first turn does not select Neutral Entry', () {
      final session = emptySession().recordTurn(
        const SessionTurn(
          releaseDecision: hold,
          phase: ConversationPhase.validation,
        ),
      );

      final decision = policy.decide(
        releaseDecision: hold,
        message: 'hi',
        session: session,
        understanding: const ValidatedUnderstanding(),
      );

      expect(decision.phase, ConversationPhase.validation);
    });

    test('non-hold readiness ignores Neutral Entry', () {
      final decision = policy.decide(
        releaseDecision: const ReleaseDecision(
          readiness: ReleaseReadiness.regulated,
          confidence: 1,
        ),
        message: 'hi',
        session: emptySession(),
        understanding: const ValidatedUnderstanding(),
      );

      expect(decision.phase, ConversationPhase.permission);
    });
  });
}
