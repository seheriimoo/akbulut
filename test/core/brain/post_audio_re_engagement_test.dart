import 'package:flutter_test/flutter_test.dart';
import 'package:slowave/core/brain/cognitive_orchestrator.dart';
import 'package:slowave/core/brain/conversation_decision.dart';
import 'package:slowave/core/brain/conversation_engine.dart';
import 'package:slowave/core/brain/conversation_phase.dart';
import 'package:slowave/core/brain/conversation_policy.dart';
import 'package:slowave/core/brain/conversation_utterance.dart';
import 'package:slowave/core/brain/exit_decision.dart';
import 'package:slowave/core/brain/belief_detector.dart';
import 'package:slowave/core/brain/emotional_pattern_detector.dart';
import 'package:slowave/core/brain/exit_intelligence.dart';
import 'package:slowave/core/brain/memory_engine.dart';
import 'package:slowave/core/brain/mental_pattern_detector.dart';
import 'package:slowave/core/brain/need_detector.dart';
import 'package:slowave/core/brain/perception_engine.dart';
import 'package:slowave/core/brain/preference_detector.dart';
import 'package:slowave/core/brain/session_summarizer.dart';
import 'package:slowave/core/brain/hcos_live_entry.dart';
import 'package:slowave/core/brain/language_model_client.dart';
import 'package:slowave/core/brain/night_session.dart';
import 'package:slowave/core/brain/post_audio_re_engagement.dart';
import 'package:slowave/core/brain/release_decision.dart';
import 'package:slowave/core/brain/release_engine.dart';
import 'package:slowave/core/brain/session_turn.dart';
import 'package:slowave/core/brain/validated_understanding.dart';
import 'package:slowave/core/brain/working_mind_view.dart';

import 'faithful_test_vendor_provider.dart';

void main() {
  const detector = PostAudioReEngagement();
  const policy = ConversationPolicy();
  const exit = ExitIntelligence();
  const release = ReleaseEngine();

  NightSession sessionAfterAudio() {
    final mind = HcosLiveEntry.emptyMindModel();
    return NightSession(
      workingMind: WorkingMindView(model: mind),
      turns: const [
        SessionTurn(
          releaseDecision: ReleaseDecision(
            readiness: ReleaseReadiness.transitionReady,
            confidence: 0.92,
          ),
          phase: ConversationPhase.audio,
        ),
      ],
    );
  }

  group('PostAudioReEngagement detector', () {
    test('meaningful TR re-engagement phrases match', () {
      for (final msg in const [
        'Korkuyorum.',
        'Neden bu kadar ağır geliyor?',
        'Hâlâ düşünüyorum.',
        'Aslında bir şey daha var.',
        'Uyuyamadım.',
        'Bekle.',
        'Noldu şimdi?',
      ]) {
        expect(detector.isMeaningful(msg), isTrue, reason: msg);
      }
    });

    test('closing acknowledgements do not match', () {
      for (final msg in const [
        'Tamam.',
        'İyi geceler.',
        '👍',
        'ok',
        'peki',
        'tamam ben yatıyorum artık',
        'peki iyi geceler o zaman',
        'thanks for tonight',
      ]) {
        expect(detector.isMeaningful(msg), isFalse, reason: msg);
      }
    });
  });

  group('ConversationPolicy post-audio re-open', () {
    test('meaningful post-audio input routes to validation and speaks', () {
      final session = sessionAfterAudio();
      for (final msg in const [
        'Korkuyorum.',
        'Neden bu kadar ağır geliyor?',
        'Hâlâ düşünüyorum.',
        'Aslında bir şey daha var.',
        'Uyuyamadım.',
      ]) {
        final decision = policy.decide(
          releaseDecision: const ReleaseDecision(
            readiness: ReleaseReadiness.transitionReady,
            confidence: 0.92,
          ),
          message: msg,
          session: session,
        );
        expect(decision.phase, ConversationPhase.validation, reason: msg);
        expect(decision.shouldSpeak, isTrue, reason: msg);
      }
    });

    test('closing ack after audio stays on audio path', () {
      final session = sessionAfterAudio();
      for (final msg in const ['Tamam.', 'İyi geceler.', '👍']) {
        final decision = policy.decide(
          releaseDecision: const ReleaseDecision(
            readiness: ReleaseReadiness.transitionReady,
            confidence: 0.92,
          ),
          message: msg,
          session: session,
        );
        expect(decision.phase, ConversationPhase.audio, reason: msg);
        expect(decision.shouldSpeak, isFalse, reason: msg);
      }
    });
  });

  group('ReleaseEngine post-audio reset', () {
    test('meaningful post-audio message resets readiness to hold', () {
      final session = sessionAfterAudio();
      final decision = release.evaluate(
        understanding: const ValidatedUnderstanding(),
        workingMind: session.workingMind,
        session: session,
        message: 'Korkuyorum.',
      );
      expect(decision.readiness, ReleaseReadiness.hold);
    });

    test('closing ack after audio keeps transitionReady', () {
      final session = sessionAfterAudio();
      final decision = release.evaluate(
        understanding: const ValidatedUnderstanding(),
        workingMind: session.workingMind,
        session: session,
        message: 'Tamam.',
      );
      expect(decision.readiness, ReleaseReadiness.transitionReady);
    });
  });

  group('End-to-end post-audio speak path', () {
    test('meaningful post-audio turn yields user-visible utterance', () async {
      final session = sessionAfterAudio();
      const releaseDecision = ReleaseDecision(
        readiness: ReleaseReadiness.hold,
        confidence: 0.45,
      );
      const conversationDecision = ConversationDecision(
        phase: ConversationPhase.validation,
        shouldSpeak: true,
      );
      const exitDecision = ExitDecision.continueConversation;

      final exitResult = exit.decide(
        releaseDecision: releaseDecision,
        conversationDecision: conversationDecision,
        session: session,
        message: 'Korkuyorum.',
      );
      expect(exitResult, ExitDecision.continueConversation);

      final engine = ConversationEngine(
        languageModelClient: const LanguageModelClient(
          vendorProvider: FaithfulTestVendorProvider(),
        ),
      );
      final utterance = await engine.generate(
        conversationDecision: conversationDecision,
        exitDecision: exitDecision,
        livedExpression: 'Korkuyorum.',
      );
      expect(utterance, isA<ConversationUtterance>());
      expect(utterance!.text, isNotEmpty);
    });

    test('closing ack after audio remains silent', () async {
      final session = sessionAfterAudio();
      const releaseDecision = ReleaseDecision(
        readiness: ReleaseReadiness.transitionReady,
        confidence: 0.92,
      );
      final conversationDecision = policy.decide(
        releaseDecision: releaseDecision,
        message: 'Tamam.',
        session: session,
      );
      final exitDecision = exit.decide(
        releaseDecision: releaseDecision,
        conversationDecision: conversationDecision,
        session: session,
        message: 'Tamam.',
      );

      expect(conversationDecision.phase, ConversationPhase.audio);
      expect(conversationDecision.shouldSpeak, isFalse);
      expect(exitDecision, ExitDecision.transitionToAudio);

      final engine = ConversationEngine(
        languageModelClient: const LanguageModelClient(
          vendorProvider: FaithfulTestVendorProvider(),
        ),
      );
      final utterance = await engine.generate(
        conversationDecision: conversationDecision,
        exitDecision: exitDecision,
      );
      expect(utterance, isNull);
    });

    test('orchestrator speaks after meaningful post-audio message', () async {
      final orchestrator = CognitiveOrchestrator(
        perceptionEngine: const PerceptionEngine(),
        mentalPatternDetector: const MentalPatternDetector(),
        emotionalPatternDetector: const EmotionalPatternDetector(),
        beliefDetector: const BeliefDetector(),
        needDetector: const NeedDetector(),
        preferenceDetector: const PreferenceDetector(),
        releaseEngine: const ReleaseEngine(),
        conversationPolicy: const ConversationPolicy(),
        conversationEngine: ConversationEngine(
          languageModelClient: const LanguageModelClient(
            vendorProvider: FaithfulTestVendorProvider(),
          ),
        ),
        exitIntelligence: const ExitIntelligence(),
        sessionSummarizer: const SessionSummarizer(),
        memoryEngine: MemoryEngine(),
      );

      final session = sessionAfterAudio();
      final result = await orchestrator.processTurn(
        message: 'Korkuyorum.',
        session: session,
        workingMind: session.workingMind,
      );

      expect(result.conversationDecision.phase, ConversationPhase.validation);
      expect(result.conversationDecision.shouldSpeak, isTrue);
      expect(result.exitDecision, ExitDecision.continueConversation);
      expect(result.releaseDecision.readiness, ReleaseReadiness.hold);
      expect(result.utterance, isNotNull);
      expect(result.utterance!.text, isNotEmpty);
    });

    test('orchestrator stays silent on post-audio closing ack', () async {
      final orchestrator = CognitiveOrchestrator(
        perceptionEngine: const PerceptionEngine(),
        mentalPatternDetector: const MentalPatternDetector(),
        emotionalPatternDetector: const EmotionalPatternDetector(),
        beliefDetector: const BeliefDetector(),
        needDetector: const NeedDetector(),
        preferenceDetector: const PreferenceDetector(),
        releaseEngine: const ReleaseEngine(),
        conversationPolicy: const ConversationPolicy(),
        conversationEngine: ConversationEngine(
          languageModelClient: const LanguageModelClient(
            vendorProvider: FaithfulTestVendorProvider(),
          ),
        ),
        exitIntelligence: const ExitIntelligence(),
        sessionSummarizer: const SessionSummarizer(),
        memoryEngine: MemoryEngine(),
      );

      final session = sessionAfterAudio();
      final result = await orchestrator.processTurn(
        message: 'Tamam.',
        session: session,
        workingMind: session.workingMind,
      );

      expect(result.conversationDecision.phase, ConversationPhase.audio);
      expect(result.conversationDecision.shouldSpeak, isFalse);
      expect(result.exitDecision, ExitDecision.transitionToAudio);
      expect(result.utterance, isNull);
    });

    test('orchestrator stays silent on multi-word post-audio close', () async {
      final orchestrator = CognitiveOrchestrator(
        perceptionEngine: const PerceptionEngine(),
        mentalPatternDetector: const MentalPatternDetector(),
        emotionalPatternDetector: const EmotionalPatternDetector(),
        beliefDetector: const BeliefDetector(),
        needDetector: const NeedDetector(),
        preferenceDetector: const PreferenceDetector(),
        releaseEngine: const ReleaseEngine(),
        conversationPolicy: const ConversationPolicy(),
        conversationEngine: ConversationEngine(
          languageModelClient: const LanguageModelClient(
            vendorProvider: FaithfulTestVendorProvider(),
          ),
        ),
        exitIntelligence: const ExitIntelligence(),
        sessionSummarizer: const SessionSummarizer(),
        memoryEngine: MemoryEngine(),
      );

      final session = sessionAfterAudio();
      final result = await orchestrator.processTurn(
        message: 'tamam ben yatıyorum artık',
        session: session,
        workingMind: session.workingMind,
      );

      expect(result.conversationDecision.phase, ConversationPhase.audio);
      expect(result.conversationDecision.shouldSpeak, isFalse);
      expect(result.exitDecision, ExitDecision.transitionToAudio);
      expect(result.utterance, isNull);
    });
  });
}
