import 'package:flutter_test/flutter_test.dart';
import 'package:slowave/core/brain/conversation_compiler.dart';
import 'package:slowave/core/brain/conversation_phase.dart';
import 'package:slowave/core/brain/conversation_policy.dart';
import 'package:slowave/core/brain/enough_intelligence.dart';
import 'package:slowave/core/brain/exit_decision.dart';
import 'package:slowave/core/brain/exit_intelligence.dart';
import 'package:slowave/core/brain/explicit_exit_intent.dart';
import 'package:slowave/core/brain/hcos_live_entry.dart';
import 'package:slowave/core/brain/llm_invocation_package.dart';
import 'package:slowave/core/brain/night_session.dart';
import 'package:slowave/core/brain/release_decision.dart';
import 'package:slowave/core/brain/session_turn.dart';
import 'package:slowave/core/brain/working_mind_view.dart';
import 'package:slowave/core/brain/conversation_blueprint_binding.dart';

void main() {
  const intent = ExplicitExitIntent();
  const policy = ConversationPolicy();
  const exit = ExitIntelligence();
  const compiler = ConversationCompiler();
  const enough = EnoughIntelligence();

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

  group('ExplicitExitIntent positives TR', () {
    for (final message in const [
      'yeter',
      'artık yeter',
      'sese geç',
      'sese geçelim',
      'sese geçmek istiyorum',
      'artık sese geçmek istiyorum',
      'Yeter, artık sese geçmek istiyorum.',
      'YETER',
      'yeter!',
      // Natural Turkish night-close / audio-move phrasing.
      'yeter bu kadar konuşmak',
      'bu kadar konuşmak yeter',
      'bu kadar yeter',
      'konuşmak istemiyorum artık',
      'artık konuşmak istemiyorum',
      'daha fazla konuşmak istemiyorum',
      'konuşmayı bitirelim',
      'burada bitirelim',
      'tamam artık sese geçelim',
      'sese geçebiliriz',
      'hazırım sese geçelim',
      'yeter artık dinlemek istiyorum',
      'Yeter Bu Kadar Konuşmak!',
      'BU KADAR YETER',
      // Affirmation + bare yeter (incl. tmm/ok/okey normalization).
      'tmm yeter',
      'tamam yeter',
      'tamam artık yeter',
      'ok yeter',
      'okey yeter',
      'peki yeter',
      'TMM Yeter!',
      'Ok Yeter',
    ]) {
      test('TR "$message" matches', () {
        expect(intent.matches(message), isTrue);
      });
    }
  });

  group('ExplicitExitIntent positives EN', () {
    for (final message in const [
      'enough',
      "let's move to audio",
      'I want to move to audio',
      "I'm ready for the audio",
      'take me to the audio',
      'Enough.',
      "THAT'S ENOUGH",
    ]) {
      test('EN "$message" matches', () {
        expect(intent.matches(message), isTrue);
      });
    }
  });

  group('ExplicitExitIntent false positives', () {
    for (final message in const [
      'Bu kadar uyku yeter mi?',
      'Ses yeterince yüksek mi?',
      'Yeterli zamanım yok.',
      "I didn't get enough sleep.",
      'Is the audio loud enough?',
      'I have enough time.',
      'Onunla artık konuşmak istemiyorum.',
      'Sevgilim benimle konuşmak istemiyor.',
      'Bu konu hakkında konuşmak istemiyorum ama başka bir şey anlatacağım.',
      'Yeterince konuşamadık.',
      'Ses yeterince yüksek değil.',
      'Konuşmak ilişkide yeterli mi?',
      'Burada bitirelim demişti.',
      'O da yeter bu kadar konuşmak demişti.',
      'tmm yeter mi',
      'tamam yeter mi',
      'ok ses yeterli',
      'okey ses yeterince yüksek',
      'peki bu kadar uyku yeter mi',
      'tamam onunla konuşmak istemiyorum',
      'tmm ama başka bir şey anlatacağım',
      'tmm',
      'tamam',
      'ok',
      'okey',
      'peki',
    ]) {
      test('FP "$message" does not match', () {
        expect(intent.matches(message), isFalse);
      });
    }
  });

  test('TR session + tmm yeter → transitionToAudio', () {
    final session = sessionAfterRelease();
    const release = ReleaseDecision(
      readiness: ReleaseReadiness.receptive,
      confidence: 1,
    );
    const message = 'tmm yeter';
    final decision = policy.decide(
      releaseDecision: release,
      message: message,
      session: session,
    );
    final exitDecision = exit.decide(
      releaseDecision: release,
      conversationDecision: decision,
      session: session,
      message: message,
    );
    expect(intent.matches(message), isTrue);
    expect(exitDecision, ExitDecision.transitionToAudio);
  });

  group('Exit overrides readiness', () {
    for (final readiness in const [
      ReleaseReadiness.receptive,
      ReleaseReadiness.settling,
      ReleaseReadiness.transitionReady,
    ]) {
      test('yeter + ${readiness.name} → transitionToAudio', () {
        final session = sessionAfterRelease();
        final release = ReleaseDecision(readiness: readiness, confidence: 1);
        final decision = policy.decide(
          releaseDecision: release,
          message: 'yeter',
          session: session,
        );
        final exitDecision = exit.decide(
          releaseDecision: release,
          conversationDecision: decision,
          session: session,
          message: 'yeter',
        );
        expect(decision.phase, ConversationPhase.continuity);
        expect(decision.shouldSpeak, isTrue);
        expect(exitDecision, ExitDecision.transitionToAudio);
      });
    }
  });

  test('LIVE FIX: yeter + receptive now transitions (was continueConversation)',
      () {
    final session = sessionAfterRelease();
    const release = ReleaseDecision(
      readiness: ReleaseReadiness.receptive,
      confidence: 1,
    );
    final decision = policy.decide(
      releaseDecision: release,
      message: 'yeter',
      session: session,
    );
    final exitDecision = exit.decide(
      releaseDecision: release,
      conversationDecision: decision,
      session: session,
      message: 'yeter',
    );
    expect(release.readiness, ReleaseReadiness.receptive);
    expect(exitDecision, ExitDecision.transitionToAudio);
  });

  test('yeter bu kadar konuşmak → transitionToAudio on receptive', () {
    final session = sessionAfterRelease();
    const release = ReleaseDecision(
      readiness: ReleaseReadiness.receptive,
      confidence: 1,
    );
    const message = 'yeter bu kadar konuşmak';
    final decision = policy.decide(
      releaseDecision: release,
      message: message,
      session: session,
    );
    final exitDecision = exit.decide(
      releaseDecision: release,
      conversationDecision: decision,
      session: session,
      message: message,
    );
    expect(intent.matches(message), isTrue);
    expect(decision.phase, ConversationPhase.continuity);
    expect(exitDecision, ExitDecision.transitionToAudio);
  });

  test('non-exit message keeps readiness-driven continue on receptive Enough',
      () {
    final session = sessionAfterRelease();
    const release = ReleaseDecision(
      readiness: ReleaseReadiness.receptive,
      confidence: 1,
    );
    final decision = policy.decide(
      releaseDecision: release,
      message: 'Biraz daha sessiz şimdi.',
      session: session,
    );
    final exitDecision = exit.decide(
      releaseDecision: release,
      conversationDecision: decision,
      session: session,
      message: 'Biraz daha sessiz şimdi.',
    );
    expect(decision.shouldSpeak, isTrue);
    expect(exitDecision, ExitDecision.continueConversation);
  });

  test('continueConversation Enough compile forbids audio-prep promise', () {
    final compiled = compiler.compile(
      LlmInvocationPackage(
        what: ConversationPhase.continuity,
        exitDecision: ExitDecision.continueConversation,
      ),
    )!;
    expect(compiled.systemContent, contains('Enough Intelligence v1.3'));
    expect(compiled.systemContent, contains('do not promise'));
    expect(
      compiled.systemContent.toLowerCase(),
      isNot(contains('prefer one soft directing line toward quiet rest audio')),
    );
    final lower = compiled.systemContent.toLowerCase();
    expect(lower, contains('do not promise'));
  });

  test('transitionToAudio Enough compile authorizes soft handoff TYPE', () {
    final compiled = compiler.compile(
      LlmInvocationPackage(
        what: ConversationPhase.continuity,
        exitDecision: ExitDecision.transitionToAudio,
      ),
    )!;
    expect(compiled.systemContent, contains('Enough Intelligence v1.3'));
    expect(compiled.systemContent.toLowerCase(), contains('handoff'));
    expect(compiled.systemContent, contains('preparing'));
  });

  test('EnoughIntelligence plain mode forbids audio promise lines', () {
    final stage = ConversationBlueprintCanon.instance
        .bindingFor(ConversationPhase.continuity)!;
    final slice = enough.compile(
      stage: stage,
      authorizeRestAudioHandoff: false,
    );
    expect(EnoughIntelligence.version, '1.3');
    expect(slice.systemAppendix, contains('do not promise'));
    expect(slice.closeDirective, contains('Do NOT promise'));
  });
}
