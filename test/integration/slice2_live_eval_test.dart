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

/// Slice 2 live UX eval — 8 multi-turn scenarios + golden conversation.
///
/// flutter test --dart-define-from-file=config/secrets.local.json \
///   test/integration/slice2_live_eval_test.dart
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const gate = ReframeReadinessGate();

  final scenarios = <String, List<String>>{
    'work_anxiety': [
      'Yarın müdürümle konuşacağım, uyuyamıyorum.',
      'Evet.',
      'Tepkisi. Beni yetersiz bulmasından korkuyorum.',
      'Evet, tam olarak bu.',
      'Yine de kafam susmuyor.',
    ],
    'relationship': [
      'Az önce sevgilimle kavga ettik, mesajını okuyup duruyorum.',
      'Keşke o cümleyi söylemeseydim.',
      'Yazsam mı yazmasam mı diye dönüp duruyorum.',
      'Galiba yazmak istiyorum ama ne diyeceğimi bilmiyorum.',
    ],
    'future_anxiety': [
      'Yarın sunum var, uyuyamıyorum.',
      'Evet.',
      'Aslında sunumdan çok, sahnede rezil olmaktan korkuyorum.',
      'Evet, tam olarak.',
    ],
    'missing_someone': [
      'Onu çok özlüyorum.',
      'Evet.',
      'Hem özlem hem de kırgınlık var.',
      'Biraz ikisi birden.',
    ],
    'overthinking': [
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
      'Sadece erken kalkmam lazım, o dönüp duruyor.',
    ],
    'happy_light': [
      'Arkadaşlarla kahve içtik, çok güldük.',
      'En komik an garson tabağı düşürdü.',
      'Şimdi eve geldim, hâlâ gülüyorum.',
    ],
    'ambiguous_concern': [
      'Garip bir gerginlik var içimde.',
      'Evet.',
      'Yarın bir şeyler olacak ama ne olduğunu bilmiyorum.',
      'Belki işten.',
    ],
  };

  test('Slice 2 live eval — 8 scenarios + golden metrics', () async {
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
      ..writeln('=== SLICE 2 LIVE EVAL (AFTER) ===')
      ..writeln('Date: ${DateTime.now().toIso8601String()}')
      ..writeln('');

    var totalBelkiSanki = 0;
    var totalTurns = 0;
    var observeFallbackAnliyorum = 0;
    var goldenArcMatch = 0;
    var goldenArcChecks = 0;
    final retention = <String, List<String>>{};

    for (final entry in scenarios.entries) {
      buffer.writeln('--- ${entry.key} ---');
      final mind = HcosLiveEntry.emptyMindModel();
      var session = HcosLiveEntry.openNightSession(mind);
      ConversationGroundingBuffer? grounding;
      final modes = <ConversationExpressionMode>[];

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
        final mode = result.conversationDecision.expressionMode;
        final phase = result.conversationDecision.phase;
        final exit = result.exitDecision;
        modes.add(mode);

        buffer.writeln('T${i + 1} USER: $user');
        buffer.writeln(
          'T${i + 1} NOCTA: $assistant',
        );
        buffer.writeln(
          '  phase=$phase expressionMode=$mode reframeReady=$reframeReady '
          'exit=${exit.name}',
        );
        buffer.writeln('');

        final lower = assistant.toLowerCase();
        if (lower.contains('belki') || lower.contains('sanki')) {
          totalBelkiSanki++;
        }
        if (mode == ConversationExpressionMode.observePurity &&
            assistant.trim() == 'Anlıyorum.') {
          observeFallbackAnliyorum++;
        }

        if (entry.key == 'work_anxiety' && i < 4) {
          goldenArcChecks++;
          final expected = [
            ConversationExpressionMode.observePurity,
            ConversationExpressionMode.narrow,
            ConversationExpressionMode.reframe,
            ConversationExpressionMode.postReframeListen,
          ][i];
          if (mode == expected) goldenArcMatch++;
        }
      }

      retention[entry.key] = _retentionNotes(entry.key, modes);
      buffer.writeln('RETENTION ${entry.key}: ${retention[entry.key]!.join(' | ')}');
      buffer.writeln('');
    }

    buffer
      ..writeln('=== METRICS ===')
      ..writeln('totalTurns: $totalTurns')
      ..writeln('belkiSankiCount: $totalBelkiSanki (target <=2 on ~similar set)')
      ..writeln('observeFallbackAnliyorum: $observeFallbackAnliyorum')
      ..writeln('goldenArcMatch: $goldenArcMatch / $goldenArcChecks')
      ..writeln('')
      ..writeln('=== RETENTION SUMMARY ===');
    for (final e in retention.entries) {
      buffer.writeln('${e.key}: ${e.value.join(' | ')}');
    }

    final out = buffer.toString();
    // ignore: avoid_print
    print(out);

    final reportPath =
        '/tmp/nocta_slice2_after_${DateTime.now().millisecondsSinceEpoch}.txt';
    await File(reportPath).writeAsString(out);
    // ignore: avoid_print
    print('Report: $reportPath');

    expect(goldenArcMatch, greaterThanOrEqualTo(3));
  }, timeout: const Timeout(Duration(minutes: 15)));
}

List<String> _retentionNotes(
  String scenario,
  List<ConversationExpressionMode> modes,
) {
  if (scenario == 'happy_light') {
    return ['understood: YES', 'noticed: NO', 'return: MAYBE'];
  }
  final hadNarrow = modes.contains(ConversationExpressionMode.narrow);
  final hadReframe = modes.contains(ConversationExpressionMode.reframe);
  return [
    'understood: ${hadNarrow || hadReframe ? 'YES' : 'PARTIAL'}',
    'noticed: ${hadReframe ? 'YES' : 'NO'}',
    'return: ${hadReframe ? 'YES' : 'MAYBE'}',
  ];
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
