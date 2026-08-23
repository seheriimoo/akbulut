import 'package:flutter_test/flutter_test.dart';
import 'package:slowave/core/brain/post_audio_re_engagement.dart';

void main() {
  const detector = PostAudioReEngagement();

  group('PostAudioReEngagement precision audit', () {
    test('multi-word closings do not reopen', () {
      for (final msg in const [
        'tamam ben yatıyorum artık',
        'peki iyi geceler o zaman',
        'tamam sonra konuşuruz',
        'neyse uyumaya çalışayım',
        'tamamdır teşekkür ederim',
        'iyi geceler nocta',
        'thanks for tonight',
        'ok good night then',
        'yarın konuşuruz tamam',
        'peki tamam o zaman',
        'hadi iyi geceler',
        'tamam o zaman iyi geceler',
      ]) {
        expect(detector.isMeaningful(msg), isFalse, reason: msg);
      }
    });

    test('meaningful re-engagement stays true', () {
      for (final msg in const [
        'korkuyorum',
        'bekle hâlâ korkuyorum',
        'hâlâ düşünüyorum',
        'uyuyamadım yine',
        'aslında bir şey daha var',
        'neden böyle hissediyorum',
        'noldu',
        'neden sessizsin',
        'tamam ama hâlâ korkuyorum',
        "I'm scared",
        'what happened',
        'one more thing',
        'why are you silent',
      ]) {
        expect(detector.isMeaningful(msg), isTrue, reason: msg);
      }
    });
  });
}
