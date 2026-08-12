import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:slowave/billing/premium_product_access.dart';
import 'package:slowave/billing/sleep_bed_catalog.dart';
import 'package:slowave/compliance/consent_store.dart';
import 'package:slowave/core/brain/conversation_grounding_buffer.dart';
import 'package:slowave/core/brain/conversation_phase.dart';
import 'package:slowave/core/brain/emotional_pattern.dart';
import 'package:slowave/core/brain/exit_decision.dart';
import 'package:slowave/core/brain/hcos_live_entry.dart';
import 'package:slowave/core/brain/mental_pattern.dart';
import 'package:slowave/core/brain/mental_pattern_status.dart';
import 'package:slowave/core/brain/night_audio_handoff.dart';
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
      // V1 free duration matches shipped 30m bed asset (not a shorter timer).
      expect(access.sessionLength, const Duration(minutes: 30));
      expect(access.sleepBedAsset, contains('_30m'));
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
      // V1 premium duration matches shipped 45m premium bed asset.
      expect(access.sessionLength, const Duration(minutes: 45));
      expect(access.sleepBedAsset, contains('_45m'));
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
        source.indexOf('case ExitDecision.transitionToAudio:'),
        source.indexOf('case ExitDecision.silence:'),
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
      expect(source.contains('_loadFailed'), isTrue);
      expect(source.contains('This session could not start.'), isTrue);
      expect(source.contains('End Session'), isTrue);
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
      expect(
        source.contains('Navigator.pushNamed(context, AppRoutes.aiChat)') ||
            source.contains("Navigator.pushNamed(context, '/ai-chat')"),
        isTrue,
      );
      expect(
        source.contains('Navigator.pushNamed(context, AppRoutes.consent)') ||
            source.contains("Navigator.pushNamed(context, '/consent')"),
        isTrue,
      );
      expect(source.contains('initialRoute: AppRoutes.welcome'), isTrue);
    });

    test('Silence exit still uses canonical complete path', () {
      final source = File('lib/screens/ai_chat_screen.dart').readAsStringSync();
      final silenceIdx = source.indexOf('case ExitDecision.silence:');
      final silenceBlock = source.substring(silenceIdx, silenceIdx + 120);
      expect(silenceBlock.contains('_finishNightAndShowClosing'), isTrue);
    });

    test('ExitDecision.transitionToAudio remains the audio gate', () {
      expect(
        ExitDecision.values.contains(ExitDecision.transitionToAudio),
        isTrue,
      );
    });

    test('Handoff blocker → SleepBedCatalog → shipped GlobalSleep asset', () {
      const handoff = NightAudioHandoff();
      const beds = SleepBedCatalog();
      const free = PremiumProductAccess(isPremium: false);
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
      final lonelyBlocker = handoff.blockerFor(
        session: lonelySession,
        grounding: const ConversationGroundingBuffer.empty()
            .appendUserUtterance('Bu gece kendimi çok yalnız hissediyorum.'),
      );
      expect(lonelyBlocker, 'loneliness');
      final lonelyAsset =
          beds.assetFor(blocker: lonelyBlocker, access: free);
      expect(lonelyAsset, SleepBedCatalog.globalSleepBed);
      expect(File(lonelyAsset).existsSync(), isTrue);

      final mindSession = NightSession(
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
                id: 'repetitive_thinking',
                name: 'Repetitive thinking',
                description: 'overthinking',
                confidence: 0.9,
                observations: 1,
                status: MentalPatternStatus.observed,
              ),
            ],
          ),
        ],
      );
      final mindBlocker = handoff.blockerFor(
        session: mindSession,
        grounding: const ConversationGroundingBuffer.empty()
            .appendUserUtterance("My mind won't stop."),
      );
      expect(mindBlocker, 'mind');
      final mindAsset = beds.assetFor(blocker: mindBlocker, access: free);
      expect(mindAsset, PremiumProductAccess.freeSleepBedAsset);
      expect(File(mindAsset).existsSync(), isTrue);
    });

    test('Live chat shows spoken handoff before PlayerScreen', () {
      final source = File('lib/screens/ai_chat_screen.dart').readAsStringSync();
      expect(source.contains('_startAudioFlow'), isTrue);
      expect(source.contains('_audioHandoff.blockerFor'), isTrue);
      expect(source.contains('_sleepBeds.assetFor'), isTrue);
      // Spoken Enough / handoff lands in the bubble list, then a short delay,
      // then player navigation — not a silent jump.
      final addIdx = source.indexOf('await _addAIMessage(reply)');
      final delayIdx = source.indexOf(
        'Duration(milliseconds: 1600)',
        addIdx,
      );
      final startIdx = source.indexOf('await _startAudioFlow()', delayIdx);
      expect(addIdx, greaterThan(0));
      expect(delayIdx, greaterThan(addIdx));
      expect(startIdx, greaterThan(delayIdx));
    });

    test('Chat→Player wires blocker bed into PlayerScreen audioAssetPath', () {
      final chat = File('lib/screens/ai_chat_screen.dart').readAsStringSync();
      final player =
          File('lib/features/player/player_screen.dart').readAsStringSync();
      final session =
          File('lib/features/player/sleep_audio_session.dart').readAsStringSync();

      expect(chat.contains('audioAssetPath: bedAsset'), isTrue);
      expect(chat.contains('PlayerScreen('), isTrue);
      expect(chat.contains('_finishNightAndShowClosing'), isTrue);
      expect(player.contains('widget.audioAssetPath'), isTrue);
      expect(player.contains('configureForBackgroundPlayback'), isTrue);
      expect(player.contains('AppLifecycleState'), isTrue);
      expect(player.contains('keep sleep bed playing'), isTrue);
      expect(session.contains('configureForBackgroundPlayback'), isTrue);
      expect(session.contains('AudioSessionConfiguration'), isTrue);

      // Free + loneliness beds both ship on disk for the wired paths.
      expect(
        File(PremiumProductAccess.freeSleepBedAsset).existsSync(),
        isTrue,
      );
      expect(File(SleepBedCatalog.globalSleepBed).existsSync(), isTrue);
    });
  });
}
