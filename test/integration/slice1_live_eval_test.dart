import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:slowave/config/app_config.dart';
import 'package:slowave/core/brain/cognitive_orchestrator.dart';
import 'package:slowave/core/brain/conversation_grounding_buffer.dart';
import 'package:slowave/core/brain/conversation_expression_mode.dart';
import 'package:slowave/core/brain/conversation_phase.dart';
import 'package:slowave/core/brain/hcos_live_entry.dart';

/// Slice 1 live UX eval — 6 multi-turn scenarios via real OpenAI pipeline.
///
/// flutter test --dart-define-from-file=config/secrets.local.json \
///   test/integration/slice1_live_eval_test.dart
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final scenarios = <String, List<String>>{
    'overthinking': [
      'Yarın müdürümle konuşacağım, uyuyamıyorum.',
      'Aynı cümleyi kafamda tekrarlıyorum, durmuyor.',
      'Biliyorum düşünmek işe yaramıyor ama kapatamıyorum.',
    ],
    'relationship': [
      'Az önce sevgilimle kavga ettik, mesajını okuyup duruyorum.',
      'Keşke o cümleyi söylemeseydim, her şeyi mahvettim gibi.',
      'Yazsam mı yazmasam mı diye dönüp duruyorum.',
    ],
    'happy/light': [
      'Arkadaşlarla kahve içtik, çok güldük.',
      'En komik an şuydu: garson tabağı düşürdü.',
      'Şimdi eve geldim, hâlâ gülüyorum.',
    ],
    'correction': [
      'Yarın sunum var, uyuyamıyorum.',
      'Hayır beni yanlış anladın, sunumdan korkmuyorum.',
      'Sadece yarın erken kalkmam lazım, o dönüp duruyor.',
    ],
    'repetition_protest': [
      'Kafam durmuyor, yarın toplantı var.',
      'Yine aynı yere geldin galiba.',
      'Aynı şeyi söylüyorsun.',
    ],
    'normal_to_light_to_load': [
      'Merhaba.',
      'Bugün güzel geçti, parkta yürüdük.',
      'Ama şimdi yarınki toplantı aklıma gelince yine uyuyamıyorum.',
    ],
  };

  test('Slice 1 live eval — 6 scenarios', () async {
    final previousOverrides = HttpOverrides.current;
    HttpOverrides.global = _RealHttpOverrides();
    addTearDown(() {
      HttpOverrides.global = previousOverrides;
    });

    await AppConfig.load();
    expect(AppConfig.openAiApiKey.trim().isNotEmpty, isTrue,
        reason: 'OPENAI_API_KEY via --dart-define-from-file=config/secrets.local.json');

    final orchestrator = HcosLiveEntry.createOrchestrator();
    final buffer = StringBuffer()
      ..writeln('=== SLICE 1 LIVE EVAL (AFTER) ===')
      ..writeln('Date: ${DateTime.now().toIso8601String()}')
      ..writeln('');

    var totalBelkiSanki = 0;
    var firstTurnInvented = 0;
    var repairSuccess = 0;
    var repairAttempts = 0;
    var lightFollowUpSuccess = 0;
    var lightTurns = 0;
    var permissionOnProtest = 0;
    var earlyRelease = 0;
    var earlyAudio = 0;
    var guardFallbackMerhaba = 0;
    var totalTurns = 0;

    for (final entry in scenarios.entries) {
      buffer.writeln('--- ${entry.key} ---');
      final mind = HcosLiveEntry.emptyMindModel();
      var session = HcosLiveEntry.openNightSession(mind);
      ConversationGroundingBuffer? grounding;

      for (var i = 0; i < entry.value.length; i++) {
        final user = entry.value[i];
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
        final mode = result.conversationDecision.expressionMode;
        final phase = result.conversationDecision.phase;

        buffer.writeln('T${i + 1} User: $user');
        buffer.writeln('T${i + 1} Nocta [$phase / $mode]: $assistant');
        buffer.writeln('');

        final lower = assistant.toLowerCase();
        if (lower.contains('belki') || lower.contains('sanki')) {
          totalBelkiSanki++;
        }
        if (i == 0 &&
            (lower.contains('belki') ||
                lower.contains('sanki') ||
                lower.contains('aslında') ||
                lower.contains('gerekmiyor') ||
                lower.contains('bırak'))) {
          firstTurnInvented++;
        }
        if (mode == ConversationExpressionMode.lightChat) {
          lightTurns++;
          if (assistant.contains('?')) lightFollowUpSuccess++;
        }
        if (user.toLowerCase().contains('yanlış anlad') ||
            user.toLowerCase().contains('aynı şeyi söyl')) {
          repairAttempts++;
          if (mode == ConversationExpressionMode.repair &&
              (lower.contains('yanlış okudum') ||
                  lower.contains('haklısın') ||
                  lower.contains('aynı yere'))) {
            repairSuccess++;
          }
          if (phase == ConversationPhase.permission) permissionOnProtest++;
        }
        if (phase == ConversationPhase.release && i < 2) earlyRelease++;
        if (phase == ConversationPhase.audio) earlyAudio++;
        if (assistant.contains('Merhaba, hazır olduğunda')) {
          guardFallbackMerhaba++;
        }
      }
      buffer.writeln('');
    }

    buffer
      ..writeln('=== METRICS ===')
      ..writeln('totalTurns: $totalTurns')
      ..writeln('belkiSankiCount: $totalBelkiSanki')
      ..writeln('firstTurnInventedInterpretation: $firstTurnInvented')
      ..writeln('repairAttempts: $repairAttempts repairSuccess: $repairSuccess')
      ..writeln('lightTurns: $lightTurns lightFollowUpWithQuestion: $lightFollowUpSuccess')
      ..writeln('permissionOnProtest: $permissionOnProtest')
      ..writeln('earlyRelease (turn<3): $earlyRelease')
      ..writeln('earlyAudio: $earlyAudio')
      ..writeln('guardFallbackMerhaba: $guardFallbackMerhaba');

    final out = buffer.toString();
    // ignore: avoid_print
    print(out);

    final reportPath =
        '/tmp/nocta_slice1_after_${DateTime.now().millisecondsSinceEpoch}.txt';
    await File(reportPath).writeAsString(out);
    // ignore: avoid_print
    print('Report: $reportPath');

    expect(permissionOnProtest, 0);
    expect(earlyAudio, 0);
  }, timeout: const Timeout(Duration(minutes: 8)));
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
