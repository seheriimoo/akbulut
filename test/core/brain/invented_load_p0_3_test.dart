import 'package:flutter_test/flutter_test.dart';
import 'package:slowave/core/brain/conversation_phase.dart';
import 'package:slowave/core/brain/conversation_policy.dart';
import 'package:slowave/core/brain/emotional_pattern_detector.dart';
import 'package:slowave/core/brain/hcos_live_entry.dart';
import 'package:slowave/core/brain/light_conversation_detector.dart';
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
  const light = LightConversationDetector();

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

  bool hasLoad(String message) {
    final u = understand(message);
    return u.mentalPatterns.isNotEmpty || u.emotionalPatterns.isNotEmpty;
  }

  ConversationPhase routePhase(
    String message, {
    NightSession? session,
    ConversationPhase? priorPhase,
  }) {
    final activeSession = session ??
        NightSession(
          workingMind: WorkingMindView(model: HcosLiveEntry.emptyMindModel()),
          turns: const [],
        );
    final understanding = understand(message, priorPhase: priorPhase);
    final decision = release.evaluate(
      understanding: understanding,
      workingMind: activeSession.workingMind,
      session: activeSession,
      message: message,
    );
    return policy
        .decide(
          releaseDecision: decision,
          message: message,
          session: activeSession,
          understanding: understanding,
        )
        .phase;
  }

  const neutralPositiveMessages = [
    'Bugün çok güzel bir gündü.',
    'Arkadaşlarla kahve içtik, güldük.',
    'Hava çok güzeldi.',
    'Kedim az önce komik bir şey yaptı 😅',
    'Yarın markete gideceğim.',
    'Yarın makarna yapacağım.',
    'Bugün film izledim.',
    'Biraz sohbet etmek istedim.',
    'Seninle iki dakika konuşayım dedim.',
    'Bugün aslında keyfim yerinde.',
  ];

  const realLoadMessages = [
    'Yarın toplantım var ve çok kaygılıyım.',
    'Geleceği düşünmekten uyuyamıyorum.',
    'Kafam susmuyor.',
    'Çok yalnız hissediyorum.',
    'Onu özlemek içimi acıtıyor.',
    'İş yüzünden beynim kapanmıyor.',
    'Yarın ne olacağını bilmiyorum ve korkuyorum.',
  ];

  const forbiddenPhases = {
    ConversationPhase.permission,
    ConversationPhase.release,
    ConversationPhase.continuity,
    ConversationPhase.audio,
  };

  group('UX-P0-3 LightConversationDetector', () {
    test('positive/neutral messages are light', () {
      for (final message in neutralPositiveMessages) {
        expect(
          light.isLightConversation(message),
          isTrue,
          reason: '"$message" should be light',
        );
        expect(
          light.hasRealLoadMarkers(message),
          isFalse,
          reason: '"$message" should not carry real load markers',
        );
      }
    });

    test('real load messages are not light', () {
      for (final message in realLoadMessages) {
        expect(
          light.isLightConversation(message),
          isFalse,
          reason: '"$message" should not be light',
        );
        expect(
          light.hasRealLoadMarkers(message),
          isTrue,
          reason: '"$message" should carry real load markers',
        );
      }
    });
  });

  group('UX-P0-3 perception — no false load evidence', () {
    test('neutral/positive turns do not produce mental/emotional patterns', () {
      for (final message in neutralPositiveMessages) {
        expect(hasLoad(message), isFalse, reason: '"$message"');
      }
    });

    test('real load turns still produce patterns', () {
      for (final message in realLoadMessages) {
        expect(hasLoad(message), isTrue, reason: '"$message"');
      }
    });

    test('bare yarın plan does not emit future_uncertainty', () {
      final evidence = perception.perceive('Yarın markete gideceğim.');
      expect(
        evidence.any((e) => e.value == 'future_uncertainty'),
        isFalse,
      );
      expect(
        evidence.any((e) => e.value == 'light_conversation'),
        isTrue,
      );
    });
  });

  group('UX-P0-3 policy — no Permission/Release on light turns', () {
    test('single-turn neutral/positive routes neutralEntry', () {
      for (final message in neutralPositiveMessages) {
        final phase = routePhase(message);
        expect(
          phase,
          ConversationPhase.neutralEntry,
          reason: '"$message" → $phase',
        );
        expect(
          forbiddenPhases.contains(phase),
          isFalse,
          reason: '"$message" forced $phase',
        );
      }
    });

    test('real load still routes Receipt path', () {
      for (final message in realLoadMessages) {
        final phase = routePhase(message);
        expect(
          phase,
          anyOf(ConversationPhase.validation, ConversationPhase.naming),
          reason: '"$message" → $phase',
        );
      }
    });
  });

  group('UX-P0-3 multi-turn', () {
    test('happy user stays light — no Permission/Release', () {
      final turns = [
        'Bugün çok güzel bir gündü.',
        'Arkadaşlarla kahve içtik, çok güldük.',
        'Hava da harikaydı.',
        'Sadece uyumadan önce biraz konuşmak istedim.',
        'Yarın da güzel geçer umarım.',
      ];

      var session = NightSession(
        workingMind: WorkingMindView(model: HcosLiveEntry.emptyMindModel()),
        turns: const [],
      );

      for (final message in turns) {
        final priorPhase =
            session.turns.isEmpty ? null : session.turns.last.phase;
        expect(hasLoad(message), isFalse, reason: 'load on "$message"');
        final understanding = understand(message, priorPhase: priorPhase);
        final decision = release.evaluate(
          understanding: understanding,
          workingMind: session.workingMind,
          session: session,
          message: message,
        );
        final conversation = policy.decide(
          releaseDecision: decision,
          message: message,
          session: session,
          understanding: understanding,
        );

        expect(
          conversation.phase,
          ConversationPhase.neutralEntry,
          reason: '"$message" → ${conversation.phase}',
        );
        expect(forbiddenPhases.contains(conversation.phase), isFalse);

        session = session.recordTurn(
          SessionTurn(
            releaseDecision: decision,
            phase: conversation.phase,
          ),
        );
      }
    });

    test('neutral → load transition on turn 3', () {
      final turns = [
        'Bugün normal bir gündü.',
        'Yarın markete gideceğim.',
        'Ama aslında gece olunca kafam yine çok çalışıyor.',
      ];

      var session = NightSession(
        workingMind: WorkingMindView(model: HcosLiveEntry.emptyMindModel()),
        turns: const [],
      );
      final phases = <ConversationPhase>[];

      for (final message in turns) {
        final priorPhase =
            session.turns.isEmpty ? null : session.turns.last.phase;
        final understanding = understand(message, priorPhase: priorPhase);
        final decision = release.evaluate(
          understanding: understanding,
          workingMind: session.workingMind,
          session: session,
          message: message,
        );
        final conversation = policy.decide(
          releaseDecision: decision,
          message: message,
          session: session,
          understanding: understanding,
        );
        phases.add(conversation.phase);
        session = session.recordTurn(
          SessionTurn(
            releaseDecision: decision,
            phase: conversation.phase,
          ),
        );
      }

      expect(phases[0], ConversationPhase.neutralEntry);
      expect(phases[1], ConversationPhase.neutralEntry);
      expect(
        phases[2],
        anyOf(ConversationPhase.validation, ConversationPhase.naming),
      );
    });

    test('load → light cat after release path stays warm neutralEntry', () {
      final turns = [
        'Bugün çok stresliydim.',
        'İş kafamdan çıkmıyor.',
        'Ama kedim az önce komik bir şey yaptı 😅',
      ];

      var session = NightSession(
        workingMind: WorkingMindView(model: HcosLiveEntry.emptyMindModel()),
        turns: const [],
      );
      final phases = <ConversationPhase>[];

      for (final message in turns) {
        final priorPhase =
            session.turns.isEmpty ? null : session.turns.last.phase;
        final understanding = understand(message, priorPhase: priorPhase);
        final decision = release.evaluate(
          understanding: understanding,
          workingMind: session.workingMind,
          session: session,
          message: message,
        );
        final conversation = policy.decide(
          releaseDecision: decision,
          message: message,
          session: session,
          understanding: understanding,
        );
        phases.add(conversation.phase);
        session = session.recordTurn(
          SessionTurn(
            releaseDecision: decision,
            phase: conversation.phase,
          ),
        );
      }

      expect(
        phases[0],
        anyOf(ConversationPhase.validation, ConversationPhase.naming),
      );
      expect(
        phases[1],
        anyOf(ConversationPhase.validation, ConversationPhase.naming),
      );
      expect(phases[2], ConversationPhase.neutralEntry);
    });
  });
}
