import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:slowave/features/player/player_screen.dart';

void main() {
  testWidgets(
    'audio load failure shows recovery UI and hides usable Start Session',
    (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: PlayerScreen(
            blocker: 'mind',
            sleepLatency: 'medium',
            energy: 'medium',
            goal: 'sleep',
            sessionLength: Duration(minutes: 30),
            audioAssetPath:
                'assets/audio/bg/CoreDefaultAir/does_not_exist.m4a',
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.text('This session could not start.'), findsOneWidget);
      expect(find.text('End Session'), findsOneWidget);
      // Must not leave a tappable Start Session affordance when audio cannot play.
      expect(find.text('Start Session'), findsNothing);
      expect(find.text('Pause Session'), findsNothing);
      expect(find.text('Preparing session…'), findsNothing);
    },
  );
}
