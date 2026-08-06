import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:slowave/core/brain/belief_detector.dart';
import 'package:slowave/core/brain/cognitive_orchestrator.dart';
import 'package:slowave/core/brain/cognitive_turn_result.dart';
import 'package:slowave/core/brain/conversation_engine.dart';
import 'package:slowave/core/brain/conversation_policy.dart';
import 'package:slowave/core/brain/emotional_pattern_detector.dart';
import 'package:slowave/core/brain/exit_intelligence.dart';
import 'package:slowave/core/brain/hcos_live_entry.dart';
import 'package:slowave/core/brain/language_model_client.dart';
import 'package:slowave/core/brain/living_mind_model.dart';
import 'package:slowave/core/brain/memory_engine.dart';
import 'package:slowave/core/brain/mental_pattern_detector.dart';
import 'package:slowave/core/brain/need_detector.dart';
import 'package:slowave/core/brain/perception_engine.dart';
import 'package:slowave/core/brain/preference_detector.dart';
import 'package:slowave/core/brain/release_engine.dart';
import 'package:slowave/core/brain/session_summarizer.dart';
import 'package:slowave/core/brain/session_summary.dart';

import 'faithful_test_vendor_provider.dart';

void main() {
  group('Sprint 6 Cutover compliance — production entry', () {
    test('HcosLiveEntry processTurn is the production cognitive entry', () async {
      expect(HcosLiveEntry.createOrchestrator(), isA<CognitiveOrchestrator>());

      final orchestrator = _orchestratorWithMemory(_CountingMemoryEngine());
      final model = HcosLiveEntry.emptyMindModel();
      final session = HcosLiveEntry.openNightSession(model);

      final result = await orchestrator.processTurn(
        message: 'I am thinking',
        session: session,
        workingMind: HcosLiveEntry.workingMindOf(session),
      );

      expect(result, isA<CognitiveTurnResult>());
    });

    test('live chat screen invokes processTurn and not legacy entry APIs', () {
      final source = File('lib/screens/ai_chat_screen.dart').readAsStringSync();

      expect(source.contains("import '../services/ai_service.dart'"), isFalse);
      expect(source.contains("import '../core/brain/ai_brain.dart'"), isFalse);
      expect(
        source.contains("import '../core/brain/reasoning_engine.dart'"),
        isFalse,
      );
      expect(source.contains('processTurn('), isTrue);
      // Comment may mention legacy names; imports/calls must not exist.
      expect(RegExp(r'\bAIService\.').hasMatch(source), isFalse);
      expect(RegExp(r'\bNoctaAIBrain\s*\(').hasMatch(source), isFalse);
      expect(RegExp(r'\bReasoningEngine\s*\(').hasMatch(source), isFalse);
    });
  });

  group('Sprint 6 Cutover compliance — production exit', () {
    test('processTurn returns only CognitiveTurnResult to the app', () async {
      final orchestrator = _orchestratorWithMemory(_CountingMemoryEngine());
      final session = HcosLiveEntry.openNightSession(
        HcosLiveEntry.emptyMindModel(),
      );

      final result = await orchestrator.processTurn(
        message: 'I am thinking',
        session: session,
        workingMind: HcosLiveEntry.workingMindOf(session),
      );

      expect(result, isA<CognitiveTurnResult>());
      expect(result.session, isNotNull);
      expect(result.exitDecision, isNotNull);
      expect(result.releaseDecision, isNotNull);
      expect(result.conversationDecision, isNotNull);
      // Utterance may be present or null; both are valid CognitiveTurnResult exits.
      expect(result.utterance == null || result.utterance!.text.isNotEmpty, isTrue);
    });

    test('live chat screen consumes CognitiveTurnResult as sole turn exit', () {
      final source = File('lib/screens/ai_chat_screen.dart').readAsStringSync();

      expect(source.contains('CognitiveTurnResult'), isTrue);
      expect(source.contains('BrainTurnResult'), isFalse);
      expect(source.contains('ReasoningDecision'), isFalse);
      expect(source.contains('exitDecision'), isTrue);
    });
  });

  group('Sprint 6 Cutover compliance — legacy path excluded', () {
    test('production live entry bootstrap does not reference legacy path', () {
      final source = File('lib/core/brain/hcos_live_entry.dart').readAsStringSync();

      expect(source.contains('ai_service'), isFalse);
      expect(source.contains('ai_brain'), isFalse);
      expect(source.contains('ReasoningEngine'), isFalse);
      expect(source.contains('NoctaAIBrain'), isFalse);
      expect(source.contains('BrainTurnResult'), isFalse);
      expect(source.contains('CognitiveOrchestrator'), isTrue);
    });

    test('no production lib caller invokes legacy cognitive APIs', () {
      final productionRoots = <String>[
        'lib/screens',
        'lib/core/brain/hcos_live_entry.dart',
        'lib/core/brain/cognitive_orchestrator.dart',
      ];

      // Imports and invocations only — comments may name legacy types.
      final forbidden = <RegExp>[
        RegExp(r"import\s+'[^']*ai_service\.dart'"),
        RegExp(r"import\s+'[^']*ai_brain\.dart'"),
        RegExp(r"import\s+'[^']*reasoning_engine\.dart'"),
        RegExp(r'\bAIService\.'),
        RegExp(r'\bNoctaAIBrain\s*\('),
        RegExp(r'\bReasoningEngine\s*\('),
        RegExp(r'\bBrainTurnResult\s*\('),
        RegExp(r'\.processMessage\s*\('),
        RegExp(r'\.generateReply\s*\('),
      ];

      for (final root in productionRoots) {
        final entity = FileSystemEntity.typeSync(root);
        final files = <File>[];
        if (entity == FileSystemEntityType.file) {
          files.add(File(root));
        } else if (entity == FileSystemEntityType.directory) {
          files.addAll(
            Directory(root)
                .listSync(recursive: true)
                .whereType<File>()
                .where((f) => f.path.endsWith('.dart')),
          );
        }

        for (final file in files) {
          final source = file.readAsStringSync();
          for (final pattern in forbidden) {
            expect(
              pattern.hasMatch(source),
              isFalse,
              reason: '${file.path} matches ${pattern.pattern}',
            );
          }
        }
      }
    });
  });

  group('Sprint 6 Cutover compliance — NightSession lifecycle', () {
    test('NightSession is carried across turns via CognitiveTurnResult only', () async {
      final orchestrator = _orchestratorWithMemory(_CountingMemoryEngine());
      var session = HcosLiveEntry.openNightSession(
        HcosLiveEntry.emptyMindModel(),
      );

      expect(session.turns, isEmpty);
      expect(
        identical(
          HcosLiveEntry.workingMindOf(session),
          session.workingMind,
        ),
        isTrue,
      );

      final first = await orchestrator.processTurn(
        message: 'I am thinking',
        session: session,
        workingMind: HcosLiveEntry.workingMindOf(session),
      );
      session = HcosLiveEntry.applyTurnResult(first);

      expect(session.turns.length, 1);
      expect(
        identical(
          HcosLiveEntry.workingMindOf(session),
          session.workingMind,
        ),
        isTrue,
      );

      final second = await orchestrator.processTurn(
        message: 'Still on my mind',
        session: session,
        workingMind: HcosLiveEntry.workingMindOf(session),
      );
      session = HcosLiveEntry.applyTurnResult(second);

      expect(session.turns.length, 2);
      expect(second, isA<CognitiveTurnResult>());
    });

    test('live chat screen carries NightSession from turn results', () {
      final source = File('lib/screens/ai_chat_screen.dart').readAsStringSync();

      expect(source.contains('NightSession'), isTrue);
      expect(source.contains('applyTurnResult'), isTrue);
      expect(source.contains('workingMindOf'), isTrue);
      expect(source.contains('openNightSession'), isTrue);
    });
  });

  group('Sprint 6 Cutover compliance — MemoryEngine session-end only', () {
    test('MemoryEngine is not reached mid-turn', () async {
      final memory = _CountingMemoryEngine();
      final orchestrator = _orchestratorWithMemory(memory);
      final model = HcosLiveEntry.emptyMindModel();
      final session = HcosLiveEntry.openNightSession(model);

      await orchestrator.processTurn(
        message: 'I am thinking',
        session: session,
        workingMind: HcosLiveEntry.workingMindOf(session),
      );

      expect(memory.updateCount, 0);
    });

    test('MemoryEngine is reached only via completeNightSession', () async {
      final memory = _CountingMemoryEngine();
      final orchestrator = _orchestratorWithMemory(memory);
      var model = HcosLiveEntry.emptyMindModel();
      var session = HcosLiveEntry.openNightSession(model);

      final result = await orchestrator.processTurn(
        message: 'I am thinking',
        session: session,
        workingMind: HcosLiveEntry.workingMindOf(session),
      );
      session = HcosLiveEntry.applyTurnResult(result);
      expect(memory.updateCount, 0);

      model = HcosLiveEntry.completeNightSession(
        orchestrator: orchestrator,
        session: session,
        model: model,
      );

      expect(memory.updateCount, 1);
      expect(model, isA<LivingMindModel>());
    });

    test('live chat screen closes nights through completeNightSession only', () {
      final source = File('lib/screens/ai_chat_screen.dart').readAsStringSync();

      expect(source.contains('completeNightSession'), isTrue);
      expect(source.contains('memoryEngine.update'), isFalse);
      expect(RegExp(r'\.completeSession\s*\(').hasMatch(source), isFalse);
    });
  });
}

CognitiveOrchestrator _orchestratorWithMemory(MemoryEngine memoryEngine) {
  return CognitiveOrchestrator(
    perceptionEngine: const PerceptionEngine(),
    mentalPatternDetector: const MentalPatternDetector(),
    emotionalPatternDetector: const EmotionalPatternDetector(),
    beliefDetector: const BeliefDetector(),
    needDetector: const NeedDetector(),
    preferenceDetector: const PreferenceDetector(),
    releaseEngine: const ReleaseEngine(),
    conversationPolicy: const ConversationPolicy(),
    conversationEngine: const ConversationEngine(
      languageModelClient: LanguageModelClient(
        vendorProvider: FaithfulTestVendorProvider(),
      ),
    ),
    exitIntelligence: const ExitIntelligence(),
    sessionSummarizer: const SessionSummarizer(),
    memoryEngine: memoryEngine,
  );
}

class _CountingMemoryEngine extends MemoryEngine {
  int updateCount = 0;

  @override
  LivingMindModel update(LivingMindModel model, SessionSummary summary) {
    updateCount++;
    return super.update(model, summary);
  }
}
