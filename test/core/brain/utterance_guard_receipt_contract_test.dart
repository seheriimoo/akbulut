import 'package:flutter_test/flutter_test.dart';
import 'package:slowave/core/brain/belief_detector.dart';
import 'package:slowave/core/brain/cognitive_orchestrator.dart';
import 'package:slowave/core/brain/conversation_engine.dart';
import 'package:slowave/core/brain/conversation_phase.dart';
import 'package:slowave/core/brain/conversation_policy.dart';
import 'package:slowave/core/brain/conversation_utterance.dart';
import 'package:slowave/core/brain/emotional_pattern_detector.dart';
import 'package:slowave/core/brain/exit_decision.dart';
import 'package:slowave/core/brain/exit_intelligence.dart';
import 'package:slowave/core/brain/hcos_live_entry.dart';
import 'package:slowave/core/brain/language_model_client.dart';
import 'package:slowave/core/brain/memory_engine.dart';
import 'package:slowave/core/brain/mental_pattern_detector.dart';
import 'package:slowave/core/brain/need_detector.dart';
import 'package:slowave/core/brain/perception_engine.dart';
import 'package:slowave/core/brain/preference_detector.dart';
import 'package:slowave/core/brain/receipt_realization_contract.dart';
import 'package:slowave/core/brain/release_decision.dart';
import 'package:slowave/core/brain/release_engine.dart';
import 'package:slowave/core/brain/session_summarizer.dart';
import 'package:slowave/core/brain/turn_response_stance.dart';
import 'package:slowave/core/brain/turn_response_stance_detector.dart';
import 'package:slowave/core/brain/utterance_guard.dart';
import 'package:slowave/core/brain/vendor_provider.dart';

void main() {
  const guard = UtteranceGuard();

  group('Guard Receipt Contract V1.6', () {
    test('exposes Receipt contract version aligned with realization contract', () {
      expect(UtteranceGuard.receiptContractVersion, '1.6');
      expect(ReceiptRealizationContract.version, '1.6');
    });

    test('still admits classic Receipt stems', () {
      for (final text in const [
        'That makes sense.',
        'I hear that.',
        "That's hard.",
        'That sounds exhausting.',
      ]) {
        final admitted = guard.allow(
          utterance: ConversationUtterance(text: text),
          what: ConversationPhase.validation,
        );
        expect(admitted, isNotNull, reason: text);
      }
    });

    test('admits prior texture-first Receipt candidates', () {
      for (final text in const [
        'Your thoughts are swirling, making it hard to find calm.',
        'Tomorrow already feels heavy.',
        'Missing them sits heavy tonight.',
        "It's a lot of dread already.",
      ]) {
        final admitted = guard.allow(
          utterance: ConversationUtterance(text: text),
          what: ConversationPhase.validation,
        );
        expect(admitted, isNotNull, reason: text);
      }
    });

    test('admits proven live candidate #1 racing mind-load form', () {
      const captured = "Your mind is racing with tomorrow's thoughts.";
      final admitted = guard.allow(
        utterance: const ConversationUtterance(text: captured),
        what: ConversationPhase.validation,
      );
      expect(admitted, isNotNull);
      expect(admitted!.text, captured);
    });

    test('admits contract-legal busy mind-load without Naming/compound', () {
      expect(
        guard.allow(
          utterance: const ConversationUtterance(
            text: 'Your mind is busy with tomorrow.',
          ),
          what: ConversationPhase.validation,
        ),
        isNotNull,
      );
    });

    test('admits soft-functional Receipt forms (mechanism-agnostic)', () {
      for (final text in const [
        'Part of your mind may already be carrying tomorrow into tonight.',
        'It may feel like stopping would leave you less prepared.',
      ]) {
        final admitted = guard.allow(
          utterance: ConversationUtterance(text: text),
          what: ConversationPhase.validation,
        );
        expect(admitted, isNotNull, reason: text);
      }
    });

    test('rejects hard diagnosis / motive overclaim under Receipt', () {
      expect(
        guard.allow(
          utterance: const ConversationUtterance(
            text: 'Your mind is racing because you have an attachment disorder.',
          ),
          what: ConversationPhase.validation,
        ),
        isNull,
      );
    });

    test('rejects proven live candidate #2 Naming + compound form', () {
      expect(
        guard.allow(
          utterance: const ConversationUtterance(
            text:
                "Your mind is busy with tomorrow, and that's weighing on you.",
          ),
          what: ConversationPhase.validation,
        ),
        isNull,
      );
    });

    test('rejects Naming stem weighing even in short mind-load line', () {
      expect(
        guard.allow(
          utterance: const ConversationUtterance(
            text: 'Your mind is weighing on you.',
          ),
          what: ConversationPhase.validation,
        ),
        isNull,
      );
    });

    test('rejects compound second move without Naming', () {
      expect(
        guard.allow(
          utterance: const ConversationUtterance(
            text: "Your mind is racing, and that's a lot tonight.",
          ),
          what: ConversationPhase.validation,
        ),
        isNull,
      );
    });

    test('rejects your mind without activation/felt texture', () {
      expect(
        guard.allow(
          utterance: const ConversationUtterance(text: 'Your mind is here.'),
          what: ConversationPhase.validation,
        ),
        isNull,
      );
      expect(
        guard.allow(
          utterance: const ConversationUtterance(
            text: 'Your mind is peaceful.',
          ),
          what: ConversationPhase.validation,
        ),
        isNull,
      );
    });

    test('rejects stillness/presence invention', () {
      expect(
        guard.allow(
          utterance: const ConversationUtterance(
            text: 'That sounds like a moment of stillness, just being present.',
          ),
          what: ConversationPhase.validation,
        ),
        isNull,
      );
    });

    test('rejects Permission/Release/Naming/Enough drift under Receipt', () {
      expect(
        guard.allow(
          utterance: const ConversationUtterance(
            text: "You don't have to figure it out tonight.",
          ),
          what: ConversationPhase.validation,
        ),
        isNull,
      );
      expect(
        guard.allow(
          utterance: const ConversationUtterance(
            text: 'Let it rest for now.',
          ),
          what: ConversationPhase.validation,
        ),
        isNull,
      );
      expect(
        guard.allow(
          utterance: const ConversationUtterance(
            text: 'Something is still holding on.',
          ),
          what: ConversationPhase.validation,
        ),
        isNull,
      );
      expect(
        guard.allow(
          utterance: const ConversationUtterance(
            text: "That's enough for now.",
          ),
          what: ConversationPhase.validation,
        ),
        isNull,
      );
    });

    test('orchestrated path with racing candidate returns non-null utterance',
        () async {
      const captured = "Your mind is racing with tomorrow's thoughts.";
      final orchestrator = _orchestratorWithCandidate(captured);
      final session = HcosLiveEntry.openNightSession(
        HcosLiveEntry.emptyMindModel(),
      );
      final result = await orchestrator.processTurn(
        message: "I can't stop thinking about tomorrow.",
        session: session,
        workingMind: HcosLiveEntry.workingMindOf(session),
      );
      expect(result.utterance?.text, captured);
      expect(result.conversationDecision.phase, ConversationPhase.validation);
      expect(result.exitDecision, ExitDecision.continueConversation);
    });

    test('cognition remains continuedLoad + hold + validation', () async {
      const message = "I can't stop thinking about tomorrow.";
      const perception = PerceptionEngine();
      const mental = MentalPatternDetector();
      const emotional = EmotionalPatternDetector();
      const stanceDetector = TurnResponseStanceDetector();

      final evidence = perception.perceive(message);
      final mentalPatterns = mental.detect(evidence);
      final emotionalPatterns = emotional.detect(evidence);
      expect(
        stanceDetector.detect(
          evidence: evidence,
          hasLoad: mentalPatterns.isNotEmpty || emotionalPatterns.isNotEmpty,
          priorPhase: null,
        ),
        TurnResponseStance.continuedLoad,
      );

      final session = HcosLiveEntry.openNightSession(
        HcosLiveEntry.emptyMindModel(),
      );
      final result = await _orchestratorWithCandidate(
        "Your mind is racing with tomorrow's thoughts.",
      ).processTurn(
        message: message,
        session: session,
        workingMind: HcosLiveEntry.workingMindOf(session),
      );
      expect(result.releaseDecision.readiness, ReleaseReadiness.hold);
      expect(result.conversationDecision.phase, ConversationPhase.validation);
    });
  });
}

CognitiveOrchestrator _orchestratorWithCandidate(String text) {
  return CognitiveOrchestrator(
    perceptionEngine: const PerceptionEngine(),
    mentalPatternDetector: const MentalPatternDetector(),
    emotionalPatternDetector: const EmotionalPatternDetector(),
    beliefDetector: const BeliefDetector(),
    needDetector: const NeedDetector(),
    preferenceDetector: const PreferenceDetector(),
    turnResponseStanceDetector: const TurnResponseStanceDetector(),
    releaseEngine: const ReleaseEngine(),
    conversationPolicy: const ConversationPolicy(),
    conversationEngine: ConversationEngine(
      languageModelClient: LanguageModelClient(
        vendorProvider: _FixedCandidateVendor(text),
      ),
    ),
    exitIntelligence: const ExitIntelligence(),
    sessionSummarizer: const SessionSummarizer(),
    memoryEngine: const MemoryEngine(),
  );
}

class _FixedCandidateVendor implements VendorProvider {
  const _FixedCandidateVendor(this.text);
  final String text;

  @override
  Future<VendorResponse> complete(VendorRequest request) async {
    return VendorResponse(text: text);
  }
}
