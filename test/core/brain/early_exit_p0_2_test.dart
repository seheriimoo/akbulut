import 'package:flutter_test/flutter_test.dart';
import 'package:slowave/core/brain/conversation_phase.dart';
import 'package:slowave/core/brain/conversation_policy.dart';
import 'package:slowave/core/brain/emotional_pattern_detector.dart';
import 'package:slowave/core/brain/exit_decision.dart';
import 'package:slowave/core/brain/exit_intelligence.dart';
import 'package:slowave/core/brain/explicit_exit_intent.dart';
import 'package:slowave/core/brain/hcos_live_entry.dart';
import 'package:slowave/core/brain/mental_pattern_detector.dart';
import 'package:slowave/core/brain/night_session.dart';
import 'package:slowave/core/brain/perception_engine.dart';
import 'package:slowave/core/brain/release_decision.dart';
import 'package:slowave/core/brain/release_engine.dart';
import 'package:slowave/core/brain/session_turn.dart';
import 'package:slowave/core/brain/turn_response_stance_detector.dart';
import 'package:slowave/core/brain/validated_understanding.dart';
import 'package:slowave/core/brain/working_mind_view.dart';

void main() {
  const perception = PerceptionEngine();
  const mental = MentalPatternDetector();
  const emotional = EmotionalPatternDetector();
  const stanceDetector = TurnResponseStanceDetector();
  const release = ReleaseEngine();
  const policy = ConversationPolicy();
  const exit = ExitIntelligence();

  ValidatedUnderstanding understand(
    String message, {
    ConversationPhase? priorPhase,
  }) {
    final evidence = perception.perceive(message);
    final mentalPatterns = mental.detect(evidence);
    final emotionalPatterns = emotional.detect(evidence);
    return ValidatedUnderstanding(
      mentalPatterns: mentalPatterns,
      emotionalPatterns: emotionalPatterns,
      turnResponseStance: stanceDetector.detect(
        evidence: evidence,
        hasLoad: mentalPatterns.isNotEmpty || emotionalPatterns.isNotEmpty,
        priorPhase: priorPhase,
      ),
    );
  }

  Future<({
    ReleaseReadiness readiness,
    ConversationPhase phase,
    ExitDecision exitDecision,
  })> runTurn({
    required NightSession session,
    required String message,
  }) async {
    final priorPhase =
        session.turns.isEmpty ? null : session.turns.last.phase;
    final understanding = understand(message, priorPhase: priorPhase);
    final releaseDecision = release.evaluate(
      understanding: understanding,
      workingMind: session.workingMind,
      session: session,
      message: message,
    );
    final conversationDecision = policy.decide(
      releaseDecision: releaseDecision,
      message: message,
      session: session,
      understanding: understanding,
    );
    final exitDecision = exit.decide(
      releaseDecision: releaseDecision,
      conversationDecision: conversationDecision,
      session: session,
      message: message,
    );
    return (
      readiness: releaseDecision.readiness,
      phase: conversationDecision.phase,
      exitDecision: exitDecision,
    );
  }

  NightSession emptySession() {
    final mind = HcosLiveEntry.emptyMindModel();
    return NightSession(
      workingMind: WorkingMindView(model: mind),
      turns: const [],
    );
  }

  Future<NightSession> playScript(List<String> messages) async {
    var session = emptySession();
    for (final message in messages) {
      final priorPhase =
          session.turns.isEmpty ? null : session.turns.last.phase;
      final understanding = understand(message, priorPhase: priorPhase);
      final releaseDecision = release.evaluate(
        understanding: understanding,
        workingMind: session.workingMind,
        session: session,
        message: message,
      );
      final conversationDecision = policy.decide(
        releaseDecision: releaseDecision,
        message: message,
        session: session,
        understanding: understanding,
      );
      session = session.recordTurn(
        SessionTurn(
          releaseDecision: releaseDecision,
          phase: conversationDecision.phase,
          mentalPatterns: understanding.mentalPatterns,
          emotionalPatterns: understanding.emotionalPatterns,
        ),
      );
    }
    return session;
  }

  group('UX-P0-2 early exit prevention', () {
    test('scenario 1 overthinking does not reach audio in 5 turns', () async {
      final session = await playScript(const [
        'Uyuyamıyorum kafam susmuyor.',
        'Yarın toplantım var.',
        'Ya bir şeyi unutursam?',
        'Tam uykuya dalınca yeni bir şey geliyor.',
        'Hâlâ kapanmıyor kafam.',
      ]);

      expect(
        session.turns.any((t) => t.phase == ConversationPhase.audio),
        isFalse,
      );
      expect(
        session.turns.any((t) => t.releaseDecision.readiness ==
            ReleaseReadiness.transitionReady),
        isFalse,
      );
      expect(
        session.turns.last.releaseDecision.readiness,
        anyOf(ReleaseReadiness.hold, ReleaseReadiness.regulated),
      );
    });

    test('scenario 2 work stress does not reach release/audio early', () async {
      final session = await playScript(const [
        'İş yüzünden beynim çalışıyor.',
        'Slack mesajları kafamda.',
        'Yarın erken kalkacağım.',
        'Toplantıyı düşünüyorum.',
        'Patronun yüzü aklıma geliyor.',
        'Olmuyor işte.',
      ]);

      expect(
        session.turns.any((t) => t.phase == ConversationPhase.audio),
        isFalse,
      );
      expect(
        session.turns.any((t) => t.phase == ConversationPhase.release),
        isFalse,
      );
      expect(
        session.turns.any((t) => t.releaseDecision.readiness ==
            ReleaseReadiness.transitionReady),
        isFalse,
      );
    });

    test('scenario 3 real settling can climb toward audio', () async {
      var session = emptySession();
      final windDownScript = const [
        'Kafam çok doluydu.',
        'Biraz daha sakinim.',
        'Sanırım bunu sabaha bırakabilirim.',
        'Uyumaya çalışacağım.',
      ];

      ReleaseReadiness? lastReadiness;
      for (final message in windDownScript) {
        final result = await runTurn(session: session, message: message);
        lastReadiness = result.readiness;
        final priorPhase =
            session.turns.isEmpty ? null : session.turns.last.phase;
        final understanding = understand(message, priorPhase: priorPhase);
        session = session.recordTurn(
          SessionTurn(
            releaseDecision: ReleaseDecision(
              readiness: result.readiness,
              confidence: 1,
            ),
            phase: result.phase,
            mentalPatterns: understanding.mentalPatterns,
            emotionalPatterns: understanding.emotionalPatterns,
          ),
        );
      }

      expect(lastReadiness, isNotNull);
      expect(lastReadiness!, isNot(ReleaseReadiness.hold));
      expect(
        lastReadiness.index,
        greaterThan(ReleaseReadiness.hold.index),
      );
    });

    test('scenario 4 explicit audio unchanged', () async {
      var session = emptySession();
      final result = await runTurn(session: session, message: 'Sese geçelim.');
      expect(const ExplicitExitIntent().matches('Sese geçelim.'), isTrue);
      expect(result.phase, ConversationPhase.continuity);
      expect(result.exitDecision, ExitDecision.transitionToAudio);
    });

    test('bare ok after recent load does not jump to transitionReady', () async {
      var session = emptySession();
      session = await playScript(const [
        'Kafam durmuyor ya.',
        'Yarın toplantım var.',
      ]);

      final sessionWithRelease = NightSession(
        workingMind: session.workingMind,
        turns: [
          ...session.turns,
          SessionTurn(
            releaseDecision: const ReleaseDecision(
              readiness: ReleaseReadiness.settling,
              confidence: 1,
            ),
            phase: ConversationPhase.release,
            mentalPatterns: session.turns.last.mentalPatterns,
          ),
        ],
      );

      final understanding = understand('tamam', priorPhase: ConversationPhase.release);
      final decision = release.evaluate(
        understanding: understanding,
        workingMind: sessionWithRelease.workingMind,
        session: sessionWithRelease,
        message: 'tamam',
      );

      expect(decision.readiness, isNot(ReleaseReadiness.transitionReady));
    });
  });
}
