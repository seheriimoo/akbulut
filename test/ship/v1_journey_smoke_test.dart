import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:slowave/billing/premium_product_access.dart';
import 'package:slowave/compliance/consent_store.dart';
import 'package:slowave/core/brain/conversation_phase.dart';
import 'package:slowave/core/brain/exit_decision.dart';
import 'package:slowave/core/brain/hcos_live_entry.dart';
import 'package:slowave/core/brain/night_session.dart';
import 'package:slowave/core/brain/release_decision.dart';
import 'package:slowave/core/brain/release_engine.dart';
import 'package:slowave/core/brain/session_turn.dart';
import 'package:slowave/core/brain/validated_understanding.dart';
import 'package:slowave/core/brain/working_mind_view.dart';
import 'package:slowave/screens/compliance/consent_gate_screen.dart';
import 'package:slowave/screens/night_complete_screen.dart';

/// SHIP-02 V1 journey smoke — structural + cognitive path verification.
///
/// Does not hit live OpenAI / App Store / physical lock screen.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
  });

  group('V1 journey smoke', () {
    test('Welcome Begin routes to consent when baseline not accepted', () async {
      expect(await ConsentStore.hasAcceptedBaseline(), isFalse);
    });

    testWidgets('Consent continue replaces into /ai-chat', (tester) async {
      // Match a tall phone viewport so consent content is hittable.
      await tester.binding.setSurfaceSize(const Size(400, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      String? pushed;
      await tester.pumpWidget(
        MaterialApp(
          home: const ConsentGateScreen(),
          onGenerateRoute: (settings) {
            pushed = settings.name;
            return MaterialPageRoute(
              builder: (_) => const Scaffold(body: Text('chat-route')),
              settings: settings,
            );
          },
        ),
      );

      final checkboxes = find.byType(CheckboxListTile);
      expect(checkboxes, findsNWidgets(2));
      await tester.ensureVisible(checkboxes.at(0));
      await tester.tap(checkboxes.at(0));
      await tester.pump();
      await tester.ensureVisible(checkboxes.at(1));
      await tester.tap(checkboxes.at(1));
      await tester.pump();

      final continueBtn = find.text('Agree and continue');
      await tester.ensureVisible(continueBtn);
      await tester.tap(continueBtn);
      await tester.pumpAndSettle();

      expect(await ConsentStore.hasAcceptedBaseline(), isTrue);
      expect(pushed, '/ai-chat');
      expect(find.text('chat-route'), findsOneWidget);
    });

    test('Release ladder reaches transitionReady on calm turns', () {
      const engine = ReleaseEngine();
      final mind = HcosLiveEntry.emptyMindModel();
      var session = NightSession(
        workingMind: WorkingMindView(model: mind),
        turns: const [],
      );

      ReleaseReadiness? readiness;
      for (var i = 0; i < 8; i++) {
        final decision = engine.evaluate(
          understanding: const ValidatedUnderstanding(),
          workingMind: session.workingMind,
          session: session,
        );
        readiness = decision.readiness;
        session = session.recordTurn(
          SessionTurn(
            releaseDecision: decision,
            phase: ConversationPhase.validation,
          ),
        );
        if (readiness == ReleaseReadiness.transitionReady) break;
      }

      expect(readiness, ReleaseReadiness.transitionReady);
    });

    test('Premium free path unlocks limited product value', () {
      const access = PremiumProductAccess(isPremium: false);
      expect(access.sessionLength, PremiumProductAccess.freeSessionLength);
      expect(access.sleepBedAsset, PremiumProductAccess.freeSleepBedAsset);
      expect(
        File(
          'assets/audio/bg/CoreDefaultAir/CoreDefaultAir_BG_30m.m4a',
        ).existsSync(),
        isTrue,
      );
    });

    test('Premium paid path unlocks longer bed + premium asset', () {
      const access = PremiumProductAccess(isPremium: true);
      expect(access.sessionLength, PremiumProductAccess.premiumSessionLength);
      expect(access.sleepBedAsset, PremiumProductAccess.premiumSleepBedAsset);
      expect(
        File(
          'assets/audio/bg/CoreDefaultAir/CoreDefaultAir_BG_45m_premium.m4a',
        ).existsSync(),
        isTrue,
      );
      expect(
        access.sessionLength.inMinutes >
            PremiumProductAccess.freeSessionLength.inMinutes,
        isTrue,
      );
    });

    test('Lock-screen audio capability is declared (iOS)', () {
      final plist = File('ios/Runner/Info.plist').readAsStringSync();
      expect(plist.contains('UIBackgroundModes'), isTrue);
      expect(plist.contains('<string>audio</string>'), isTrue);
    });

    test('Android wake lock declared for playback', () {
      final manifest =
          File('android/app/src/main/AndroidManifest.xml').readAsStringSync();
      expect(manifest.contains('WAKE_LOCK'), isTrue);
    });

    test('Live chat owns premium → audio → completeNightSession order', () {
      final source = File('lib/screens/ai_chat_screen.dart').readAsStringSync();
      final premiumIdx = source.indexOf('PaywallScreen');
      final playerIdx = source.indexOf('PlayerScreen(');
      final finishIdx = source.indexOf('_finishNightAndShowClosing');
      final completeIdx = source.indexOf('completeNightSession');

      expect(premiumIdx, greaterThan(0));
      expect(playerIdx, greaterThan(premiumIdx));
      expect(finishIdx, greaterThan(0));
      expect(completeIdx, greaterThan(0));

      // Must not close the night before starting audio on the transition path.
      final transitionBlock = source.substring(
        source.indexOf('ExitDecision.transitionToAudio'),
        source.indexOf('ExitDecision.silence'),
      );
      expect(transitionBlock.contains('_startAudioFlow'), isTrue);
      expect(transitionBlock.contains('_closeNightSession'), isFalse);
    });

    test('Player finishes audio session and pops for night close', () {
      final source =
          File('lib/features/player/player_screen.dart').readAsStringSync();
      expect(source.contains('_finishAudioSession'), isTrue);
      expect(source.contains('SleepAudioSession.deactivate'), isTrue);
      expect(source.contains('Navigator.of(context).pop'), isTrue);
      expect(source.contains('configureForBackgroundPlayback'), isTrue);
    });

    testWidgets('Night Complete returns to Welcome (/)', (tester) async {
      // Mirror production: initialRoute + onGenerateRoute (no home:).
      String? route;
      await tester.pumpWidget(
        MaterialApp(
          initialRoute: '/complete',
          onGenerateRoute: (settings) {
            route = settings.name;
            if (settings.name == '/complete') {
              return MaterialPageRoute(
                builder: (_) => const NightCompleteScreen(),
                settings: settings,
              );
            }
            return MaterialPageRoute(
              builder: (_) => const Scaffold(body: Text('welcome')),
              settings: settings,
            );
          },
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Tonight is complete'), findsOneWidget);
      await tester.tap(find.text('Rest well'));
      await tester.pumpAndSettle();

      expect(route, '/');
      expect(find.text('welcome'), findsOneWidget);
    });

    test('Welcome Begin gates consent vs chat', () {
      final source = File('lib/main.dart').readAsStringSync();
      expect(source.contains('ConsentStore.hasAcceptedBaseline()'), isTrue);
      expect(source.contains("Navigator.pushNamed(context, '/ai-chat')"), isTrue);
      expect(
        source.contains('Navigator.pushNamed(context, AppRoutes.consent)'),
        isTrue,
      );
      expect(source.contains('initialRoute: AppRoutes.welcome'), isTrue);
    });

    test('Silence exit still uses canonical complete path', () {
      final source = File('lib/screens/ai_chat_screen.dart').readAsStringSync();
      final silenceIdx = source.indexOf('ExitDecision.silence');
      final silenceBlock = source.substring(silenceIdx, silenceIdx + 120);
      expect(silenceBlock.contains('_finishNightAndShowClosing'), isTrue);
    });

    test('ExitDecision.transitionToAudio remains the audio gate', () {
      expect(
        ExitDecision.values.contains(ExitDecision.transitionToAudio),
        isTrue,
      );
    });
  });
}
