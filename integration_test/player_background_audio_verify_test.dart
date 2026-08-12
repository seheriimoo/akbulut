import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:slowave/billing/premium_product_access.dart';
import 'package:slowave/features/player/player_screen.dart';

/// Task 19 — verify live Player background/foreground coherence on device/simulator.
///
/// OS-level lock-screen audio continuity still requires a physical iPhone.
///
/// Run:
///   flutter test integration_test/player_background_audio_verify_test.dart \
///     -d <ios-simulator-or-device-id>
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'Player survives background/foreground; pause/resume; session can end',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              return Scaffold(
                body: Center(
                  child: TextButton(
                    onPressed: () {
                      Navigator.of(context).push<bool>(
                        MaterialPageRoute(
                          builder: (_) => PlayerScreen(
                            goal: 'sleep',
                            blocker: 'mind',
                            sleepLatency: 'medium',
                            energy: 'medium',
                            sessionLength:
                                PremiumProductAccess.freeSessionLength,
                            audioAssetPath:
                                PremiumProductAccess.freeSleepBedAsset,
                            premiumUnlocked: false,
                          ),
                        ),
                      );
                    },
                    child: const Text('start nocta session'),
                  ),
                ),
              );
            },
          ),
        ),
      );

      await tester.tap(find.text('start nocta session'));
      await tester.pump();

      // 3. Start a real Nocta audio session (live free bed asset).
      var playing = false;
      for (var i = 0; i < 60; i++) {
        await tester.pump(const Duration(milliseconds: 250));
        if (find.text('Pause Session').evaluate().isNotEmpty) {
          playing = true;
          break;
        }
        if (find.text('This session could not start.').evaluate().isNotEmpty) {
          fail('Player failed to load the live free sleep bed asset');
        }
      }
      expect(playing, isTrue, reason: 'Real Nocta audio session must start');

      // 4/6. Background then foreground — UI remains coherent.
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      await tester.pump();
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      await tester.pump(const Duration(milliseconds: 400));
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.text('Pause Session'), findsOneWidget);
      expect(find.text('Start Session'), findsNothing);
      // 9. No duplicate transport controls after transitions.
      expect(find.text('Pause Session'), findsOneWidget);

      // 7. Pause / Resume after foreground return.
      await tester.tap(find.text('Pause Session'));
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text('Start Session'), findsOneWidget);

      await tester.tap(find.text('Start Session'));
      await tester.pump(const Duration(milliseconds: 600));
      expect(find.text('Pause Session'), findsOneWidget);

      // 8. Ending the session leaves Player (host then runs Night Complete).
      final dynamic widgetsBinding = tester.binding;
      widgetsBinding.handlePopRoute();
      var returnedToHost = false;
      for (var i = 0; i < 60; i++) {
        await tester.pump(const Duration(milliseconds: 250));
        if (find.text('start nocta session').evaluate().isNotEmpty &&
            find.text('Pause Session').evaluate().isEmpty) {
          returnedToHost = true;
          break;
        }
      }
      expect(
        returnedToHost,
        isTrue,
        reason: 'Ending Player must return to host for Night Complete handoff',
      );
    },
  );
}
