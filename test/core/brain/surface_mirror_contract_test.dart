import 'package:flutter_test/flutter_test.dart';
import 'package:slowave/core/brain/conversation_expression_mode.dart';
import 'package:slowave/core/brain/conversation_grounding_buffer.dart';
import 'package:slowave/core/brain/conversation_phase.dart';
import 'package:slowave/core/brain/conversation_utterance.dart';
import 'package:slowave/core/brain/conversational_landing.dart';
import 'package:slowave/core/brain/guard_safe_fallback.dart';
import 'package:slowave/core/brain/surface_mirror_contract.dart';
import 'package:slowave/core/brain/user_object_mirror.dart';
import 'package:slowave/core/brain/utterance_guard.dart';

void main() {
  const guard = UtteranceGuard();

  group('SurfaceMirrorContract', () {
    test('admits natural paraphrase without bu gece', () {
      const user = 'Tamam yavaş yavaş sakinleşiyorum.';
      const mirror = 'Biraz sakinleşmeye başlamışsın.';
      expect(SurfaceMirrorContract.matches(mirror, user), isTrue);
    });

    test('admits positive event mirror', () {
      const user = 'Bugün terfi aldım, hâlâ inanamıyorum!';
      const mirror = 'Terfi haberi hâlâ biraz gerçek dışı geliyor.';
      expect(SurfaceMirrorContract.matches(mirror, user), isTrue);
    });

    test('rejects inference drift', () {
      const user = 'Kafam durmuyor.';
      const mirror = 'Belki kafan durmuyor gibi.';
      expect(SurfaceMirrorContract.matches(mirror, user), isFalse);
    });
  });

  group('B2.2 five failures', () {
    test('B04 affirmation mirrors grounding not Anlıyorum', () {
      const grounding =
          'Sürekli ailesi öncelik, ben ikinci plandayım gibi.';
      final fallback = GuardSafeFallback.forPhase(
        what: ConversationPhase.validation,
        userUtterance: 'Evet, tam olarak bu.',
        grounding: ConversationGroundingBuffer.empty()
            .appendUserUtterance(grounding),
      );
      expect(fallback, isNotNull);
      expect(fallback!.text, isNot('Anlıyorum.'));
      expect(
        fallback.text.toLowerCase(),
        anyOf(contains('ikinci'), contains('öncelik'), contains('oncelik')),
      );
    });

    test('B11 tamam lands as Tamam not Anlıyorum', () {
      final fallback = GuardSafeFallback.forPhase(
        what: ConversationPhase.validation,
        userUtterance: 'tamam.',
      );
      expect(fallback?.text, 'Tamam.');
    });

    test('B18 desire acknowledges positive want', () {
      const user = 'Uyumak istemiyorum aslında, günü tekrar yaşamak istiyorum.';
      final mirror = UserObjectMirror.forValidation(
        userUtterance: user,
        expressionMode: ConversationExpressionMode.standard,
      );
      expect(mirror, isNotNull);
      expect(mirror!.text.toLowerCase(), contains('günü'));
      expect(mirror.text.toLowerCase(), isNot(contains('anlıyorum')));
    });

    test('B19 closing lands İyi geceler', () {
      final fallback = GuardSafeFallback.forPhase(
        what: ConversationPhase.validation,
        userUtterance: 'İyi geceler dene.',
      );
      expect(fallback?.text, 'İyi geceler.');
    });

    test('B23 closing lands İyi geceler', () {
      final fallback = GuardSafeFallback.forPhase(
        what: ConversationPhase.validation,
        userUtterance: 'İyi geceler.',
      );
      expect(fallback?.text, 'İyi geceler.');
    });

    test('B19 mundane bored desire not Anlıyorum', () {
      final fallback = GuardSafeFallback.forPhase(
        what: ConversationPhase.validation,
        userUtterance: 'Sıkıldım, uyumak da istemiyorum.',
        expressionMode: ConversationExpressionMode.observePurity,
      );
      expect(fallback, isNotNull);
      expect(fallback!.text, isNot('Anlıyorum.'));
    });

    test('B27 stres mirror not silence path', () {
      final fallback = GuardSafeFallback.forPhase(
        what: ConversationPhase.validation,
        userUtterance: 'Stres max seviyede.',
        expressionMode: ConversationExpressionMode.observePurity,
      );
      expect(fallback, isNotNull);
      expect(fallback!.text.toLowerCase(), contains('stres'));
    });
  });

  group('ConversationalLanding guard admission', () {
    test('Tamam admits under standard validation', () {
      const user = 'tamam.';
      final landing = ConversationalLanding.forValidation(
        userUtterance: user,
      );
      expect(landing, isNotNull);
      expect(
        guard.allow(
          utterance: landing!,
          what: ConversationPhase.validation,
          userUtterance: user,
        ),
        isNotNull,
      );
    });
  });
}
