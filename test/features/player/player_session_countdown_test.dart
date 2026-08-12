import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:slowave/features/player/player_screen.dart';

void main() {
  group('sessionRemainingAfterElapsed', () {
    test('pause subtracts elapsed from remaining', () {
      expect(
        sessionRemainingAfterElapsed(
          remaining: const Duration(minutes: 30),
          elapsed: const Duration(minutes: 5),
        ),
        const Duration(minutes: 25),
      );
    });

    test('pause does not advance remaining when elapsed is zero', () {
      expect(
        sessionRemainingAfterElapsed(
          remaining: const Duration(minutes: 12),
          elapsed: Duration.zero,
        ),
        const Duration(minutes: 12),
      );
    });

    test('remaining never goes negative', () {
      expect(
        sessionRemainingAfterElapsed(
          remaining: const Duration(seconds: 10),
          elapsed: const Duration(seconds: 40),
        ),
        Duration.zero,
      );
    });

    test('resume continues from remaining, not full session length', () {
      const full = Duration(minutes: 30);
      final afterPause = sessionRemainingAfterElapsed(
        remaining: full,
        elapsed: const Duration(minutes: 8),
      );
      expect(afterPause, const Duration(minutes: 22));
      // Second pause while already on remaining budget.
      final afterSecondPause = sessionRemainingAfterElapsed(
        remaining: afterPause,
        elapsed: const Duration(minutes: 2),
      );
      expect(afterSecondPause, const Duration(minutes: 20));
      expect(afterSecondPause < full, isTrue);
    });
  });

  test('Player pause path cancels session timer before resume re-arms', () {
    final source =
        File('lib/features/player/player_screen.dart').readAsStringSync();
    expect(source.contains('_pauseSessionTimer()'), isTrue);
    expect(source.contains('_remaining'), isTrue);
    expect(source.contains('sessionRemainingAfterElapsed'), isTrue);

    final toggleIdx = source.indexOf('Future<void> _togglePlay()');
    final toggleBlock = source.substring(toggleIdx, toggleIdx + 450);
    expect(toggleBlock.contains('_pauseSessionTimer()'), isTrue);

    final startIdx = source.indexOf('void _startSessionTimer()');
    final startBlock = source.substring(startIdx, startIdx + 350);
    expect(startBlock.contains('Timer(_remaining'), isTrue);
    expect(startBlock.contains('Timer(widget.sessionLength'), isFalse);
  });
}
