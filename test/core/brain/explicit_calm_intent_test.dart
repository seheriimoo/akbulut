import 'package:flutter_test/flutter_test.dart';
import 'package:slowave/core/brain/conversation_phase.dart';
import 'package:slowave/core/brain/conversation_policy.dart';
import 'package:slowave/core/brain/explicit_calm_intent.dart';
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
  const detector = ExplicitCalmIntent();
  const policy = ConversationPolicy();

  NightSession sessionWithReceipt() {
    final now = DateTime.utc(2026, 1, 1);
    final mind = WorkingMindView(
      model: LivingMindModel(
        identity: Identity(
          userId: 'test',
          preferredLanguage: 'tr',
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
    return NightSession(workingMind: mind, turns: const []).recordTurn(
      const SessionTurn(
        releaseDecision: ReleaseDecision(
          readiness: ReleaseReadiness.hold,
          confidence: 0.45,
        ),
        phase: ConversationPhase.validation,
      ),
    );
  }

  group('ExplicitCalmIntent', () {
    test('admits clear EN/TR calm desires', () {
      for (final message in const [
        'I just want to calm down',
        'I want to relax',
        'help me settle',
        'sakinleşmek istiyorum',
        'Sadece sakinleşmek istiyorum',
        'rahatlamak istiyorum',
        'dinlenmek istiyorum',
      ]) {
        expect(detector.matches(message), isTrue, reason: message);
      }
    });

    test('rejects inability-to-calm load talk', () {
      for (final message in const [
        "I can't calm down",
        'sakinleşemiyorum',
        'rahatlayamıyorum',
        'my mind will not settle',
      ]) {
        expect(detector.matches(message), isFalse, reason: message);
      }
    });
  });

  group('ConversationPolicy explicit calm routing', () {
    test('hold + calm desire → Permission, not Naming', () {
      final decision = policy.decide(
        releaseDecision: const ReleaseDecision(
          readiness: ReleaseReadiness.hold,
          confidence: 0.45,
        ),
        message: 'Sakinleşmek istiyorum',
        session: sessionWithReceipt(),
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

      expect(decision.phase, ConversationPhase.permission);
      expect(decision.shouldSpeak, isTrue);
    });

    test('settling + calm desire → Release rest step', () {
      final decision = policy.decide(
        releaseDecision: const ReleaseDecision(
          readiness: ReleaseReadiness.settling,
          confidence: 0.78,
        ),
        message: 'I just want to calm down',
        session: sessionWithReceipt(),
      );

      expect(decision.phase, ConversationPhase.release);
    });
  });
}
