import 'package:flutter_test/flutter_test.dart';
import 'package:slowave/core/brain/neutral_entry_detector.dart';

void main() {
  const detector = NeutralEntryDetector();

  group('NeutralEntryDetector V1', () {
    test('admits content-free greeting full-message forms', () {
      for (final message in const [
        'hi',
        'hii',
        'hiii',
        'Hi',
        'HI!',
        'hey',
        'heyy',
        'hello',
        'Hello.',
        'hello!',
        'good evening',
        'Good Evening',
        'good night',
        'good morning',
        'hi there',
        'hey there!',
        'hello there…',
        '  hi  ',
      ]) {
        expect(
          detector.isNeutralGreeting(message),
          isTrue,
          reason: message,
        );
      }
    });

    test('rejects greetings with extra content', () {
      for (final message in const [
        "hi I'm spiraling",
        'hello I miss them',
        'hey, I cannot sleep',
        'hi there my mind will not settle',
        'good evening, tomorrow already feels heavy',
      ]) {
        expect(
          detector.isNeutralGreeting(message),
          isFalse,
          reason: message,
        );
      }
    });

    test('rejects emotional openers and non-greetings', () {
      for (final message in const [
        '',
        '   ',
        'I am here.',
        'I keep replaying tomorrow.',
        'Still here.',
        'how are you',
        'hiya',
        'greetings',
        'sup',
        'yo',
      ]) {
        expect(
          detector.isNeutralGreeting(message),
          isFalse,
          reason: message,
        );
      }
    });
  });
}
