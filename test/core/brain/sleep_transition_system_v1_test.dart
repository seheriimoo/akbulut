import 'package:flutter_test/flutter_test.dart';
import 'package:slowave/billing/premium_product_access.dart';
import 'package:slowave/billing/sleep_bed_catalog.dart';
import 'package:slowave/core/brain/conversation_grounding_buffer.dart';
import 'package:slowave/core/brain/conversation_phase.dart';
import 'package:slowave/core/brain/conversation_utterance.dart';
import 'package:slowave/core/brain/emotional_pattern.dart';
import 'package:slowave/core/brain/hcos_live_entry.dart';
import 'package:slowave/core/brain/mental_pattern.dart';
import 'package:slowave/core/brain/mental_pattern_status.dart';
import 'package:slowave/core/brain/night_audio_handoff.dart';
import 'package:slowave/core/brain/night_session.dart';
import 'package:slowave/core/brain/perception_engine.dart';
import 'package:slowave/core/brain/release_decision.dart';
import 'package:slowave/core/brain/session_summarizer.dart';
import 'package:slowave/core/brain/session_turn.dart';
import 'package:slowave/core/brain/working_mind_view.dart';
import 'package:slowave/core/brain/memory_engine.dart';
import 'package:slowave/core/brain/utterance_guard.dart';
import 'package:slowave/quality/conversation_evaluator.dart';

void main() {
  group('Sleep-transition system climb V1', () {
    test('SessionSummarizer extracts patterns from turns', () {
      final mind = WorkingMindView(model: HcosLiveEntry.emptyMindModel());
      final session = NightSession(
        workingMind: mind,
        turns: const [
          SessionTurn(
            releaseDecision: ReleaseDecision(
              readiness: ReleaseReadiness.hold,
              confidence: 1,
            ),
            phase: ConversationPhase.validation,
            mentalPatterns: [
              MentalPattern(
                id: 'overanalyzing',
                name: 'Overanalyzing',
                description: 'load',
                confidence: 0.8,
                observations: 1,
                status: MentalPatternStatus.observed,
              ),
            ],
            emotionalPatterns: [
              EmotionalPattern(
                id: 'loneliness',
                name: 'Loneliness',
                description: 'alone',
                confidence: 0.82,
                observations: 1,
              ),
            ],
          ),
        ],
      );

      final summary = const SessionSummarizer().summarize(session);
      expect(summary.mentalPatterns, isNotEmpty);
      expect(summary.emotionalPatterns.first.id, 'loneliness');

      final updated = const MemoryEngine().update(
        HcosLiveEntry.emptyMindModel(),
        summary,
      );
      expect(updated.identity.totalSessions, 1);
      expect(updated.emotionalPatterns.first.id, 'loneliness');
    });

    test('MemoryEngine merges patterns across nights', () {
      final base = HcosLiveEntry.emptyMindModel().copyWith(
        mentalPatterns: const [
          MentalPattern(
            id: 'overanalyzing',
            name: 'Overanalyzing',
            description: 'prior',
            confidence: 0.7,
            observations: 2,
            status: MentalPatternStatus.observed,
          ),
        ],
      );
      final summary = const SessionSummarizer().summarize(
        NightSession(
          workingMind: WorkingMindView(model: base),
          turns: const [
            SessionTurn(
              releaseDecision: ReleaseDecision(
                readiness: ReleaseReadiness.hold,
                confidence: 1,
              ),
              phase: ConversationPhase.validation,
              mentalPatterns: [
                MentalPattern(
                  id: 'overanalyzing',
                  name: 'Overanalyzing',
                  description: 'new',
                  confidence: 0.85,
                  observations: 1,
                  status: MentalPatternStatus.observed,
                ),
              ],
            ),
          ],
        ),
      );
      final merged = const MemoryEngine().update(base, summary);
      expect(merged.mentalPatterns.single.observations, 3);
      expect(merged.mentalPatterns.single.confidence, 0.85);
    });

    test('NightAudioHandoff + SleepBedCatalog map loneliness beds', () {
      const handoff = NightAudioHandoff();
      const beds = SleepBedCatalog();
      final mind = WorkingMindView(model: HcosLiveEntry.emptyMindModel());
      final lonelySession = NightSession(
        workingMind: mind,
        turns: const [
          SessionTurn(
            releaseDecision: ReleaseDecision(
              readiness: ReleaseReadiness.hold,
              confidence: 1,
            ),
            phase: ConversationPhase.validation,
            emotionalPatterns: [
              EmotionalPattern(
                id: 'loneliness',
                name: 'Loneliness',
                description: 'alone',
                confidence: 0.9,
                observations: 1,
              ),
            ],
          ),
        ],
      );
      final blocker = handoff.blockerFor(
        session: lonelySession,
        grounding: const ConversationGroundingBuffer.empty()
            .appendUserUtterance('Bu gece kendimi çok yalnız hissediyorum.'),
      );
      expect(blocker, 'loneliness');
      expect(
        beds.assetFor(
          blocker: blocker,
          access: const PremiumProductAccess(isPremium: false),
        ),
        SleepBedCatalog.globalSleepBed,
      );
    });

    test('TR loneliness and EN overthinking admit under Receipt', () {
      const guard = UtteranceGuard();
      expect(
        guard.allow(
          utterance: const ConversationUtterance(
            text: 'Sanki bu yalnızlık ağır geliyor.',
          ),
          what: ConversationPhase.validation,
        ),
        isNotNull,
      );
      expect(
        guard.allow(
          utterance: const ConversationUtterance(
            text: 'Your mind is heavy with overthinking tonight.',
          ),
          what: ConversationPhase.validation,
        ),
        isNotNull,
      );
    });

    test('Perception marks TR loneliness and overthinking', () {
      const perception = PerceptionEngine();
      final lonely =
          perception.perceive('Bu gece kendimi çok yalnız hissediyorum.');
      expect(
        lonely.any((e) => e.value == 'loneliness_activation'),
        isTrue,
      );
      final over = perception.perceive("My mind won't stop.");
      expect(
        over.any((e) => e.value == 'repetitive_thinking'),
        isTrue,
      );
    });

    test('live drop RAWs now admit under sealed WHAT', () {
      const guard = UtteranceGuard();
      expect(
        guard.allow(
          utterance: const ConversationUtterance(
            text: 'Something is weighing on your mind.\n\n',
          ),
          what: ConversationPhase.naming,
        ),
        isNotNull,
      );
      expect(
        guard.allow(
          utterance: const ConversationUtterance(
            text:
                "You're feeling a little quieter now. Perhaps it's time to set some of that down. The night can hold what you don't need to carry anymore.",
          ),
          what: ConversationPhase.release,
        ),
        isNotNull,
      );
    });

    test('ConversationEvaluator passes clean handoff night', () {
      const evaluator = ConversationEvaluator();
      final report = evaluator.scoreNight(const [
        NightTurnTrace(
          phase: 'validation',
          spoken: 'Part of your mind is already in tomorrow.',
          guardDropped: false,
          language: 'en',
        ),
        NightTurnTrace(
          phase: 'permission',
          spoken: "You don't need to keep rehearsing tonight.",
          guardDropped: false,
          language: 'en',
        ),
        NightTurnTrace(
          phase: 'release',
          spoken: 'Leave some of that here. The night can hold it.',
          guardDropped: false,
          language: 'en',
        ),
        NightTurnTrace(
          phase: 'continuity',
          spoken: "I'm preparing a little quiet for you now.",
          guardDropped: false,
          language: 'en',
        ),
      ]);
      expect(report.disposition, EvalDisposition.pass);
      expect(report.handoffPresent, isTrue);
      expect(report.guardDrops, 0);
    });
  });
}
