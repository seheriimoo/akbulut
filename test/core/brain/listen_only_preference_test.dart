import 'package:flutter_test/flutter_test.dart';
import 'package:slowave/core/brain/conversation_grounding_buffer.dart';
import 'package:slowave/core/brain/listen_only_preference.dart';

void main() {
  test('detects listen-only declaration and analysis lift', () {
    expect(
      ListenOnlyPreference.declaresListenOnly('sadece dinle yeter'),
      isTrue,
    );
    expect(
      ListenOnlyPreference.requestsAnalysis('Sence neden böyle hissediyorum?'),
      isTrue,
    );

    final grounding = const ConversationGroundingBuffer.empty()
        .appendUserUtterance('bugün patronla tartıştım')
        .appendUserUtterance('sadece dinle yeter');

    expect(
      ListenOnlyPreference.isActive(
        currentMessage: 'tamam',
        grounding: grounding,
      ),
      isTrue,
    );
    expect(
      ListenOnlyPreference.isActive(
        currentMessage: 'Sence neden sinirliyim?',
        grounding: grounding,
      ),
      isFalse,
    );
  });

  test('flags interpretive assistant under listen-only', () {
    expect(
      ListenOnlyPreference.violatesListenOnly(
        'Sinirli olmanın altında yatan sebep mi seni rahatsız ediyor?',
      ),
      isTrue,
    );
    expect(
      ListenOnlyPreference.violatesListenOnly(
        'Henüz tam oturmadı ama seni kaybetmedim.',
      ),
      isFalse,
    );
  });
}
