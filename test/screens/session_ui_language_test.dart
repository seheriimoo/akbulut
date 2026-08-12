import 'package:flutter_test/flutter_test.dart';
import 'package:slowave/core/brain/conversation_phase.dart';
import 'package:slowave/core/brain/conversation_policy.dart';
import 'package:slowave/core/brain/exit_decision.dart';
import 'package:slowave/core/brain/exit_intelligence.dart';
import 'package:slowave/core/brain/explicit_exit_intent.dart';
import 'package:slowave/core/brain/hcos_live_entry.dart';
import 'package:slowave/core/brain/night_session.dart';
import 'package:slowave/core/brain/release_decision.dart';
import 'package:slowave/core/brain/session_turn.dart';
import 'package:slowave/core/brain/working_mind_view.dart';
import 'package:slowave/quality/conversation_evaluator.dart';
import 'package:slowave/screens/session_ui_language.dart';

void main() {
  const resolver = SessionUiLanguageResolver();
  const intent = ExplicitExitIntent();
  const policy = ConversationPolicy();
  const exitIntel = ExitIntelligence();

  NightSession sessionAfterRelease() {
    final mind = HcosLiveEntry.emptyMindModel();
    return NightSession(
      workingMind: WorkingMindView(model: mind),
      turns: const [
        SessionTurn(
          releaseDecision: ReleaseDecision(
            readiness: ReleaseReadiness.receptive,
            confidence: 1,
          ),
          phase: ConversationPhase.release,
        ),
      ],
    );
  }

  Map<String, Object?> probe({
    required List<String> userTurns,
    List<String> assistantTurns = const [],
  }) {
    var lang = SessionUiLanguage.unknown;
    String? lastExit;
    var explicitExit = false;
    var exitName = 'none';
    var audioFlowCalls = 0;
    var inputEnabled = true;

    for (var i = 0; i < userTurns.length; i++) {
      final turn = userTurns[i];
      lang = resolver.resolveNext(current: lang, message: turn);
      if (i < assistantTurns.length) {
        lang = resolver.resolveNext(
          current: lang,
          message: assistantTurns[i],
        );
      }
      lastExit = turn;
      explicitExit = intent.matches(turn);
      if (!explicitExit) {
        exitName = 'continueConversation';
        audioFlowCalls = 0;
        inputEnabled = true;
        continue;
      }
      final session = sessionAfterRelease();
      const release = ReleaseDecision(
        readiness: ReleaseReadiness.receptive,
        confidence: 1,
      );
      final decision = policy.decide(
        releaseDecision: release,
        message: turn,
        session: session,
      );
      final exitDecision = exitIntel.decide(
        releaseDecision: release,
        conversationDecision: decision,
        session: session,
        message: turn,
      );
      exitName = exitDecision.name;
      audioFlowCalls =
          exitDecision == ExitDecision.transitionToAudio ? 1 : 0;
      inputEnabled = exitDecision == ExitDecision.continueConversation;
    }

    return {
      'sessionLanguage': lang.name,
      'lastExit': lastExit,
      'explicitExit': explicitExit,
      'exitDecision': exitName,
      'audioFlowCallCount': audioFlowCalls,
      'ctaLocale': resolver.continueAudioLabel(lang),
      'inputEnabled': inputEnabled,
    };
  }

  void expectStable20(
    String name,
    List<String> turns,
    Map<String, Object?> want, {
    List<String> assistantTurns = const [],
  }) {
    test('$name — 20 identical repeats', () {
      late Map<String, Object?> first;
      for (var i = 0; i < 20; i++) {
        final row = probe(userTurns: turns, assistantTurns: assistantTurns);
        if (i == 0) {
          first = row;
        } else {
          expect(row, first, reason: 'run ${i + 1} diverged');
        }
      }
      expect(first['explicitExit'], want['explicitExit']);
      expect(first['exitDecision'], want['exitDecision']);
      expect(first['audioFlowCallCount'], want['audioFlowCallCount']);
      expect(first['ctaLocale'], want['ctaLocale']);
      expect(first['sessionLanguage'], want['sessionLanguage']);
      expect(first['inputEnabled'], want['inputEnabled']);
    });
  }

  const trOpener = 'Bu gece kendimi çok yalnız hissediyorum.';
  const enOpener = "I can't stop thinking about tomorrow tonight.";
  const trAiReply =
      'Anlıyorum. Bu gece zihnin biraz daha sessizleşebilir; yanındayım.';

  expectStable20(
    'TR + tmm yeter',
    const [trOpener, 'tmm yeter'],
    {
      'explicitExit': true,
      'exitDecision': 'transitionToAudio',
      'audioFlowCallCount': 1,
      'ctaLocale': 'Sese devam et',
      'sessionLanguage': 'tr',
      'inputEnabled': false,
    },
  );

  expectStable20(
    'TR + tamam yeter',
    const [trOpener, 'tamam yeter'],
    {
      'explicitExit': true,
      'exitDecision': 'transitionToAudio',
      'audioFlowCallCount': 1,
      'ctaLocale': 'Sese devam et',
      'sessionLanguage': 'tr',
      'inputEnabled': false,
    },
  );

  expectStable20(
    'TR + ok yeter',
    const [trOpener, 'ok yeter'],
    {
      'explicitExit': true,
      'exitDecision': 'transitionToAudio',
      'audioFlowCallCount': 1,
      'ctaLocale': 'Sese devam et',
      'sessionLanguage': 'tr',
      'inputEnabled': false,
    },
  );

  expectStable20(
    'TR + bare yeter keeps TR CTA',
    const [trOpener, 'yeter'],
    {
      'explicitExit': true,
      'exitDecision': 'transitionToAudio',
      'audioFlowCallCount': 1,
      'ctaLocale': 'Sese devam et',
      'sessionLanguage': 'tr',
      'inputEnabled': false,
    },
  );

  expectStable20(
    'EN + enough keeps EN CTA',
    const [enOpener, 'enough'],
    {
      'explicitExit': true,
      'exitDecision': 'transitionToAudio',
      'audioFlowCallCount': 1,
      'ctaLocale': 'Continue to audio',
      'sessionLanguage': 'en',
      'inputEnabled': false,
    },
  );

  expectStable20(
    'ASCII TR uyuyamiyorum + TR AI + yeter → Sese devam et',
    const ['uyuyamiyorum', 'yeter'],
    {
      'explicitExit': true,
      'exitDecision': 'transitionToAudio',
      'audioFlowCallCount': 1,
      'ctaLocale': 'Sese devam et',
      'sessionLanguage': 'tr',
      'inputEnabled': false,
    },
    assistantTurns: const [trAiReply],
  );

  expectStable20(
    'ASCII TR cok yorgunum + tmm yeter → Sese devam et',
    const ['cok yorgunum', 'tmm yeter'],
    {
      'explicitExit': true,
      'exitDecision': 'transitionToAudio',
      'audioFlowCallCount': 1,
      'ctaLocale': 'Sese devam et',
      'sessionLanguage': 'tr',
      'inputEnabled': false,
    },
  );

  expectStable20(
    'ASCII TR zihnim susmuyor locks TR',
    const ['zihnim susmuyor'],
    {
      'explicitExit': false,
      'exitDecision': 'continueConversation',
      'audioFlowCallCount': 0,
      'ctaLocale': 'Sese devam et',
      'sessionLanguage': 'tr',
      'inputEnabled': true,
    },
  );

  expectStable20(
    'ASCII TR dusunmekten uyuyamiyorum locks TR',
    const ['dusunmekten uyuyamiyorum'],
    {
      'explicitExit': false,
      'exitDecision': 'continueConversation',
      'audioFlowCallCount': 0,
      'ctaLocale': 'Sese devam et',
      'sessionLanguage': 'tr',
      'inputEnabled': true,
    },
  );

  test('detectLanguage tags ASCII Turkish night stems as tr', () {
    for (final text in const [
      'uyuyamiyorum',
      'cok yorgunum',
      'zihnim susmuyor',
      'dusunmekten uyuyamiyorum',
    ]) {
      expect(
        ConversationEvaluator.detectLanguage(text),
        'tr',
        reason: text,
      );
    }
  });

  test('English opener is not TR from a single Turkish-looking token', () {
    expect(
      ConversationEvaluator.detectLanguage(
        'I feel enough pressure tonight about tomorrow',
      ),
      'en',
    );
    expect(
      resolver.strongSignal(
        'I feel enough pressure tonight about tomorrow',
      ),
      SessionUiLanguage.en,
    );
  });

  test('reliable TR assistant reply can lock session UI language', () {
    var lang = SessionUiLanguage.unknown;
    lang = resolver.resolveNext(current: lang, message: trAiReply);
    expect(lang, SessionUiLanguage.tr);
    lang = resolver.resolveNext(current: lang, message: 'yeter');
    expect(lang, SessionUiLanguage.tr);
    expect(resolver.continueAudioLabel(lang), 'Sese devam et');
  });

  test('short/unstable messages do not flip locked TR language', () {
    var lang = SessionUiLanguage.unknown;
    lang = resolver.resolveNext(current: lang, message: trOpener);
    expect(lang, SessionUiLanguage.tr);
    for (final unstable in const [
      'yeter',
      'tmm yeter',
      'tamam',
      'ok',
      'okey',
      'peki',
      '123',
      '😊',
    ]) {
      lang = resolver.resolveNext(current: lang, message: unstable);
      expect(lang, SessionUiLanguage.tr, reason: unstable);
    }
    expect(resolver.continueAudioLabel(lang), 'Sese devam et');
  });

  test('rebuild-equivalent: sticky state survives without transcript recompute', () {
    var lang = SessionUiLanguage.unknown;
    lang = resolver.resolveNext(current: lang, message: 'uyuyamiyorum');
    lang = resolver.resolveNext(current: lang, message: trAiReply);
    lang = resolver.resolveNext(current: lang, message: 'yeter');
    // Simulate Player pop + rebuild reading only sticky state (no join heuristic).
    expect(resolver.continueAudioLabel(lang), 'Sese devam et');
    expect(lang, SessionUiLanguage.tr);
  });

  test('affirmation-alone never exits', () {
    for (final token in const ['tmm', 'tamam', 'ok', 'okey', 'peki']) {
      expect(intent.matches(token), isFalse);
    }
  });

  test('affirmation false positives stay non-exit', () {
    for (final message in const [
      'tmm yeter mi',
      'tamam yeter mi',
      'ok ses yeterli',
      'okey ses yeterince yüksek',
      'peki bu kadar uyku yeter mi',
      'tamam onunla konuşmak istemiyorum',
      'tmm ama başka bir şey anlatacağım',
    ]) {
      expect(intent.matches(message), isFalse, reason: message);
    }
  });
}
