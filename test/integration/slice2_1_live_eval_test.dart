import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:slowave/config/app_config.dart';
import 'package:slowave/core/brain/conversation_arc_reader.dart';
import 'package:slowave/core/brain/conversation_expression_mode.dart';
import 'package:slowave/core/brain/conversation_grounding_buffer.dart';
import 'package:slowave/core/brain/conversation_phase.dart';
import 'package:slowave/core/brain/hcos_live_entry.dart';
import 'package:slowave/core/brain/reframe_readiness_gate.dart';

/// Slice 2.1 tuning live eval — 6 scenarios + golden regression.
///
/// flutter test --dart-define-from-file=config/secrets.local.json \
///   test/integration/slice2_1_live_eval_test.dart
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const gate = ReframeReadinessGate();

  final scenarios = <String, List<String>>{
    'relationship': [
      'Onu özlüyorum.',
      'Evet.',
      'Galiba onunlayken kendimi daha güvende hissediyordum.',
    ],
    'missing_someone': [
      'Onu çok özlüyorum.',
      'Evet.',
      'Hem özlem hem de kırgınlık var.',
    ],
    'ambiguous_concern': [
      'Bir şey içime oturdu ama ne olduğunu bilmiyorum.',
      'Evet.',
      'Belki işten.',
    ],
    'future_anxiety': [
      'Yarın sunum var, uyuyamıyorum.',
      'Evet.',
      'Aslında sunumdan çok, sahnede rezil olmaktan korkuyorum.',
      'Evet, tam olarak.',
    ],
    'partial_confirm': [
      'İş yüzünden beynim kapanmıyor.',
      'Evet.',
      'Yetiştiremeyeceğim bir şey yok aslında, ama yarın yine aynı baskı var.',
      'Evet, baskı kısmı.',
    ],
    'reframe_correction': [
      'Yarın toplantı var, uyuyamıyorum.',
      'Evet.',
      'Tepkisinden korkuyorum.',
      'Hayır, alakası yok.',
    ],
    'golden_work_anxiety': [
      'Yarın müdürümle konuşacağım, uyuyamıyorum.',
      'Evet.',
      'Tepkisi. Beni yetersiz bulmasından korkuyorum.',
      'Evet, tam olarak bu.',
    ],
  };

  test('Slice 2.1 live eval — tuning scenarios + golden', () async {
    final previousOverrides = HttpOverrides.current;
    HttpOverrides.global = _RealHttpOverrides();
    addTearDown(() {
      HttpOverrides.global = previousOverrides;
    });

    await AppConfig.load();
    expect(AppConfig.openAiApiKey.trim().isNotEmpty, isTrue);

    final orchestrator = HcosLiveEntry.createOrchestrator();
    final buffer = StringBuffer()
      ..writeln('=== SLICE 2.1 LIVE EVAL ===')
      ..writeln('Date: ${DateTime.now().toIso8601String()}')
      ..writeln('');

    var anliyorumCount = 0;
    var belkiSankiCount = 0;
    var narrowToReframe = 0;
    var prematureReframeT1 = 0;
    var totalTurns = 0;
    var goldenArcMatch = 0;

    for (final entry in scenarios.entries) {
      buffer.writeln('--- ${entry.key} ---');
      final mind = HcosLiveEntry.emptyMindModel();
      var session = HcosLiveEntry.openNightSession(mind);
      ConversationGroundingBuffer? grounding;
      var sawNarrow = false;
      var sawReframeAfterNarrow = false;

      for (var i = 0; i < entry.value.length; i++) {
        final user = entry.value[i];
        final arcBefore = ConversationArcReader.fromSession(session);
        final reframeReady = gate.isReady(
          session: session,
          message: user,
          understanding: null,
          arc: arcBefore,
        );

        final result = await orchestrator.processTurn(
          message: user,
          session: session,
          workingMind: session.workingMind,
          conversationGroundingBuffer: grounding,
        );
        session = HcosLiveEntry.applyTurnResult(result);
        grounding = HcosLiveEntry.groundingBufferOf(result);
        totalTurns++;

        final assistant = result.utterance?.text ?? '(silent)';
        final mode = result.conversationDecision.phase;
        final expr = result.conversationDecision.expressionMode;
        final readiness = result.releaseDecision.readiness;
        final exit = result.exitDecision.name;

        buffer.writeln('T${i + 1} USER: $user');
        buffer.writeln('T${i + 1} NOCTA: $assistant');
        buffer.writeln(
          '  phase=$mode expressionMode=$expr reframeReady=$reframeReady '
          'readiness=$readiness exit=$exit '
          'narrowRefine=${result.conversationDecision.narrowRefinementAfterPartial}',
        );
        buffer.writeln('');

        final lower = assistant.toLowerCase();
        if (assistant.trim() == 'Anlıyorum.') anliyorumCount++;
        if (lower.contains('belki') || lower.contains('sanki')) belkiSankiCount++;
        if (i == 0 && expr == ConversationExpressionMode.reframe) {
          prematureReframeT1++;
        }
        if (expr == ConversationExpressionMode.narrow) sawNarrow = true;
        if (sawNarrow && expr == ConversationExpressionMode.reframe) {
          sawReframeAfterNarrow = true;
        }

        if (entry.key == 'golden_work_anxiety' && i < 4) {
          final expected = [
            ConversationExpressionMode.observePurity,
            ConversationExpressionMode.narrow,
            ConversationExpressionMode.reframe,
            ConversationExpressionMode.postReframeListen,
          ][i];
          if (expr == expected) goldenArcMatch++;
        }
      }

      if (sawReframeAfterNarrow) narrowToReframe++;
      buffer.writeln('');
    }

    buffer
      ..writeln('=== METRICS ===')
      ..writeln('totalTurns: $totalTurns')
      ..writeln('anliyorumFallback: $anliyorumCount (target 0)')
      ..writeln('belkiSankiCount: $belkiSankiCount')
      ..writeln('narrowToReframeScenarios: $narrowToReframe')
      ..writeln('prematureReframeT1: $prematureReframeT1')
      ..writeln('goldenArcMatch: $goldenArcMatch / 4');

    final out = buffer.toString();
    // ignore: avoid_print
    print(out);

    final reportPath =
        '/tmp/nocta_slice2_1_${DateTime.now().millisecondsSinceEpoch}.txt';
    await File(reportPath).writeAsString(out);
    // ignore: avoid_print
    print('Report: $reportPath');

    expect(prematureReframeT1, 0);
    expect(goldenArcMatch, 4);
  }, timeout: const Timeout(Duration(minutes: 12)));
}

class _RealHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    HttpOverrides.global = null;
    try {
      return HttpClient(context: context);
    } finally {
      HttpOverrides.global = this;
    }
  }
}
