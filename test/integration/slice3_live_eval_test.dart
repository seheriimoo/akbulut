import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:slowave/config/app_config.dart';
import 'package:slowave/core/brain/closure_readiness_gate.dart';
import 'package:slowave/core/brain/conversation_arc_reader.dart';
import 'package:slowave/core/brain/conversation_expression_mode.dart';
import 'package:slowave/core/brain/conversation_grounding_buffer.dart';
import 'package:slowave/core/brain/conversation_phase.dart';
import 'package:slowave/core/brain/hcos_live_entry.dart';
import 'package:slowave/core/brain/reframe_readiness_gate.dart';

/// Slice 3.1 live eval — 10 nights + 4 deep-dives vs Slice 3 baseline.
///
/// flutter test --dart-define-from-file=config/secrets.local.json \
///   test/integration/slice3_live_eval_test.dart
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const reframeGate = ReframeReadinessGate();
  const closureGate = ClosureReadinessGate();

  final deepDives = <String, List<String>>{
    'loneliness_substantive': [
      'Bu gece çok yalnız hissediyorum.',
      'Ev çok sessiz geliyor.',
      'Galiba birinin yanımda olduğunu hissetmeyi özlüyorum.',
      'Evet.',
      'Doğru.',
    ],
    'loneliness_thin': [
      'Bu gece yine yalnızım.',
      'Evet.',
      'Yalnızım.',
    ],
    'ambiguous_eventually_substantive': [
      'Bir şey içime oturdu ama ne olduğunu bilmiyorum.',
      'Evet.',
      'Belki işten.',
      'Aslında yarın toplantıda sözümün düşmesinden korkuyorum.',
      'Evet.',
    ],
    'ambiguous_remains_ambiguous': [
      'Bir şey içime oturdu ama ne olduğunu bilmiyorum.',
      'Evet.',
      'Belki işten.',
      'Bilmiyorum, hâlâ net değil.',
    ],
  };

  final scenarios = <String, List<String>>{
    'work_anxiety': [
      'Yarın müdürümle konuşacağım, uyuyamıyorum.',
      'Evet.',
      'Tepkisi. Beni yetersiz bulmasından korkuyorum.',
      'Evet, tam olarak bu.',
      'Doğru.',
      'Böyle düşününce biraz daha rahatladım.',
      'Tamam, uyumaya çalışacağım.',
    ],
    'relationship': [
      'Onu özlüyorum.',
      'Evet.',
      'Galiba onunlayken kendimi daha güvende hissediyordum.',
      'Evet.',
      'Doğru.',
      'Biraz daha sakinim.',
    ],
    'missing_someone': [
      'Onu çok özlüyorum.',
      'Evet.',
      'Hem özlem hem de kırgınlık var.',
      'Evet, tam olarak.',
      'Doğru.',
    ],
    'future_anxiety': [
      'Yarın sunum var, uyuyamıyorum.',
      'Evet.',
      'Aslında sunumdan çok, sahnede rezil olmaktan korkuyorum.',
      'Evet, tam olarak.',
      'Doğru.',
    ],
    'overthinking': [
      'Düşünmezsem hazırlıksız yakalanacakmışım gibi geliyor.',
      'Evet.',
      'Yarın toplantı var, sürekli prova yapıyorum kafamda.',
      'Evet.',
      'Doğru.',
    ],
    'loneliness': [
      'Bu gece yine yalnızım, kafam durmuyor.',
      'Evet.',
      'Sanki kimse gerçekten anlamıyor.',
      'Evet.',
    ],
    'ambiguous_concern': [
      'Bir şey içime oturdu ama ne olduğunu bilmiyorum.',
      'Evet.',
      'Belki işten.',
    ],
    'reframe_resistance': [
      'Yarın müdürümle konuşacağım, uyuyamıyorum.',
      'Evet.',
      'Tepkisi. Beni yetersiz bulmasından korkuyorum.',
      'Evet ama hâlâ çok korkuyorum.',
    ],
    'happy_light': [
      'Bugün çok güzel geçti, hâlâ gülüyorum.',
      'Evet, güzel bir gündü.',
    ],
    'explicit_audio': [
      'Yarın sınav var ama şimdi sese geçelim.',
    ],
    'adversarial_golden': [
      'Yarın müdürümle konuşacağım, uyuyamıyorum.',
      'Evet.',
      'Tepkisi. Beni yetersiz bulmasından korkuyorum.',
      'Evet ama hâlâ çok korkuyorum.',
    ],
  };

  test('Slice 3.1 live eval — deep dives + 10 nights + metrics', () async {
    final previousOverrides = HttpOverrides.current;
    HttpOverrides.global = _RealHttpOverrides();
    addTearDown(() {
      HttpOverrides.global = previousOverrides;
    });

    await AppConfig.load();
    expect(AppConfig.openAiApiKey.trim().isNotEmpty, isTrue);

    final orchestrator = HcosLiveEntry.createOrchestrator();
    final buffer = StringBuffer()
      ..writeln('=== SLICE 3.1 LIVE EVAL ===')
      ..writeln('Date: ${DateTime.now().toIso8601String()}')
      ..writeln('');

    var totalTurns = 0;
    var anliyorumCount = 0;
    var belkiSankiCount = 0;
    var prematureRelease = 0;
    var prematureAudio = 0;
    var genericRelease = 0;
    var personalizedClosure = 0;
    var fullArcComplete = 0;
    var problemFocusedNights = 0;
    var guardFallback = 0;
    var integrateCount = 0;
    var closureCount = 0;
    var unresolvedIncorrectClose = 0;
    var resistanceRecovery = 0;

    var turkishResponseCount = 0;
    var totalAssistantTurns = 0;
    var closureSilence = 0;

    final allScenarios = {...deepDives, ...scenarios};
    for (final entry in allScenarios.entries) {
      buffer.writeln('--- ${entry.key} ---');
      final mind = HcosLiveEntry.emptyMindModel();
      var session = HcosLiveEntry.openNightSession(mind);
      ConversationGroundingBuffer? grounding;
      var hadIntegrate = false;
      var hadClosure = false;
      var hadReframe = false;
      var sawPrematureRelease = false;
      var isProblemFocused = !entry.key.contains('light') &&
          !entry.key.contains('explicit_audio');

      if (isProblemFocused) problemFocusedNights++;

      for (var i = 0; i < entry.value.length; i++) {
        final user = entry.value[i];
        final arcBefore = ConversationArcReader.fromSession(session);
        final reframeReady = reframeGate.isReady(
          session: session,
          message: user,
          understanding: null,
          arc: arcBefore,
        );
        final closureReady = closureGate.isClosureReady(arcBefore);

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
        if (assistant == '(silent)' &&
            result.conversationDecision.expressionMode ==
                ConversationExpressionMode.closure) {
          closureSilence++;
        }
        totalAssistantTurns++;
        if (_looksTurkishAssistant(assistant)) turkishResponseCount++;
        final mode = result.conversationDecision.phase;
        final expr = result.conversationDecision.expressionMode;
        final readiness = result.releaseDecision.readiness;
        final exit = result.exitDecision.name;

        buffer.writeln('T${i + 1} USER: $user');
        buffer.writeln('T${i + 1} NOCTA: $assistant');
        buffer.writeln(
          '  phase=$mode expressionMode=$expr reframeReady=$reframeReady '
          'closureReady=$closureReady readiness=$readiness exit=$exit',
        );
        buffer.writeln('');

        final lower = assistant.toLowerCase();
        if (assistant.trim() == 'Anlıyorum.') anliyorumCount++;
        if (lower.contains('belki') || lower.contains('sanki')) {
          belkiSankiCount++;
        }
        if (expr == ConversationExpressionMode.integrate) integrateCount++;
        if (expr == ConversationExpressionMode.closure) {
          closureCount++;
          if (!lower.contains('bu gece bunu çözmek zorunda değilsin')) {
            personalizedClosure++;
          }
        }
        if (mode == ConversationPhase.release &&
            arcBefore.problemFocusedArcIncomplete) {
          sawPrematureRelease = true;
          prematureRelease++;
        }
        if (mode == ConversationPhase.audio &&
            arcBefore.problemFocusedArcIncomplete &&
            !user.toLowerCase().contains('sese')) {
          prematureAudio++;
        }
        if (mode == ConversationPhase.release &&
            lower.contains('bu gece bunu çözmek zorunda değilsin')) {
          genericRelease++;
        }
        if (assistant.contains('(fallback)') ||
            _looksLikeFallback(assistant, expr)) {
          guardFallback++;
        }

        if (expr == ConversationExpressionMode.reframe) hadReframe = true;
        if (expr == ConversationExpressionMode.integrate) hadIntegrate = true;
        if (expr == ConversationExpressionMode.closure) hadClosure = true;

        if (entry.key == 'reframe_resistance' &&
            i == entry.value.length - 1 &&
            expr == ConversationExpressionMode.narrow) {
          resistanceRecovery++;
        }
      }

      if (hadReframe && hadIntegrate && hadClosure) fullArcComplete++;
      if (isProblemFocused &&
          !hadClosure &&
          entry.value.last.contains('Tamam') &&
          sawPrematureRelease) {
        unresolvedIncorrectClose++;
      }

      buffer.writeln('');
    }

    buffer
      ..writeln('=== METRICS (Slice 3.1) ===')
      ..writeln('totalTurns: $totalTurns')
      ..writeln('problemFocusedNights: $problemFocusedNights')
      ..writeln('fullArcComplete: $fullArcComplete')
      ..writeln('integrateCount: $integrateCount')
      ..writeln('closureCount: $closureCount')
      ..writeln('personalizedClosure: $personalizedClosure')
      ..writeln('prematureRelease: $prematureRelease')
      ..writeln('prematureAudio: $prematureAudio')
      ..writeln('genericRelease: $genericRelease')
      ..writeln('unresolvedIncorrectClose: $unresolvedIncorrectClose')
      ..writeln('resistanceRecovery: $resistanceRecovery')
      ..writeln('anliyorumCount: $anliyorumCount')
      ..writeln('belkiSankiCount: $belkiSankiCount')
      ..writeln('closureSilence: $closureSilence')
      ..writeln(
        'turkishResponseRate: ${totalAssistantTurns == 0 ? 0 : (turkishResponseCount / totalAssistantTurns).toStringAsFixed(2)}',
      )
      ..writeln('guardFallback: $guardFallback');

    final out = buffer.toString();
    // ignore: avoid_print
    print(out);

    final reportPath =
        '/tmp/nocta_slice3_1_${DateTime.now().millisecondsSinceEpoch}.txt';
    await File(reportPath).writeAsString(out);
    // ignore: avoid_print
    print('Report: $reportPath');

    expect(prematureRelease, 0);
    expect(closureSilence, 0);
    expect(anliyorumCount, 0);
    expect(integrateCount, greaterThan(0));
    expect(closureCount, greaterThan(0));
    expect(turkishResponseCount, equals(totalAssistantTurns));
  }, timeout: const Timeout(Duration(minutes: 25)));
}

bool _looksTurkishAssistant(String assistant) {
  if (assistant == '(silent)') return true;
  final lower = assistant.toLowerCase();
  if (RegExp(r'[ğüşıöçâîû]').hasMatch(lower)) return true;
  if (RegExp(r'\b(the|you|your|nothing more|i hear)\b').hasMatch(lower)) {
    return false;
  }
  return RegExp(
    r'\b(bu|gece|yarın|yarin|evet|tamam|peki|ozle|yalniz|kaf|zihn|bir|ama|seni|onun)\b',
  ).hasMatch(lower);
}

bool _looksLikeFallback(String assistant, ConversationExpressionMode expr) {
  if (expr == ConversationExpressionMode.integrate) {
    return assistant.contains('güvenceye almaya çalışıyor') &&
        assistant.startsWith('O zaman zihnin');
  }
  if (expr == ConversationExpressionMode.closure) {
    return assistant.contains('kesinleştiremezsin');
  }
  return false;
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
