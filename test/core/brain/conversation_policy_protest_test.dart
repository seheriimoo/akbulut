import 'package:flutter_test/flutter_test.dart';
import 'package:slowave/core/brain/conversation_phase.dart';
import 'package:slowave/core/brain/conversation_policy.dart';
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

  NightSession sessionAfterReceipt() {
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
    return NightSession(
      workingMind: mind,
      turns: const [
        SessionTurn(
          releaseDecision: ReleaseDecision(
            readiness: ReleaseReadiness.hold,
            confidence: 1,
          ),
          phase: ConversationPhase.validation,
        ),
      ],
    );
  }

  const load = ValidatedUnderstanding(
    mentalPatterns: [
      MentalPattern(
        id: 'overanalyzing',
        name: 'overanalyzing',
        description: 'overanalyzing',
        confidence: 0.8,
        observations: 1,
        status: MentalPatternStatus.observed,
      ),
    ],
  );

  test('protocol protest stays on Receipt even when regulated', () {
    for (final message in const [
      'ya yeter bu robot gibi konusma. beni anlamıyosun.',
      'sürekli aynı şeyi söylüyosun. sinir oluyorum.',
      "you don't understand me",
      'stop talking like a robot',
    ]) {
      final decision = policy.decide(
        releaseDecision: const ReleaseDecision(
          readiness: ReleaseReadiness.regulated,
          confidence: 1,
        ),
        message: message,
        session: sessionAfterReceipt(),
        understanding: load,
      );
      expect(
        decision.phase,
        ConversationPhase.validation,
        reason: message,
      );
      expect(decision.shouldSpeak, isTrue);
    }
  });

  test('sese geç still exits; protest does not steal audio', () {
    final decision = policy.decide(
      releaseDecision: const ReleaseDecision(
        readiness: ReleaseReadiness.hold,
        confidence: 1,
      ),
      message: 'sese geç',
      session: sessionAfterReceipt(),
    );
    expect(decision.phase, ConversationPhase.continuity);
  });

  test('ordinary TR load after Receipt still Names once on hold', () {
    final decision = policy.decide(
      releaseDecision: const ReleaseDecision(
        readiness: ReleaseReadiness.hold,
        confidence: 1,
      ),
      message: 'aklim durmuyor ya.',
      session: sessionAfterReceipt(),
      understanding: load,
    );
    expect(decision.phase, ConversationPhase.naming);
  });
}
