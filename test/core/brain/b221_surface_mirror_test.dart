import 'package:flutter_test/flutter_test.dart';
import 'package:slowave/core/brain/conversation_expression_mode.dart';
import 'package:slowave/core/brain/conversation_phase.dart';
import 'package:slowave/core/brain/conversation_utterance.dart';
import 'package:slowave/core/brain/conversation_phase.dart';
import 'package:slowave/core/brain/guard_safe_fallback.dart';
import 'package:slowave/core/brain/surface_utterance_kind.dart';
import 'package:slowave/core/brain/user_object_mirror.dart';
import 'package:slowave/core/brain/utterance_guard.dart';

/// B2.2.1 — OOD surface mirror + zero-silence + hedge removal.
void main() {
  const guard = UtteranceGuard();

  group('B2.2.1 OOD silence cases', () {
    const cases = [
      'Stres max seviyede.',
      'bilmiyom ki ne olcak',
      'Var olmak garip geliyor bazen.',
    ];

    for (final user in cases) {
      test('mirror admits: $user', () {
        final mirror = UserObjectMirror.forValidation(
          userUtterance: user,
          expressionMode: ConversationExpressionMode.observePurity,
        );
        expect(mirror, isNotNull, reason: user);
        expect(mirror!.text, isNot('Anlıyorum.'));
        expect(mirror.text.toLowerCase(), isNot(contains(' gibi.')));
        expect(
          guard.allow(
            utterance: mirror,
            what: ConversationPhase.validation,
            userUtterance: user,
            mirrorGroundingUtterance:
                UserObjectMirror.mirrorEvidenceSource(userUtterance: user),
            expressionMode: ConversationExpressionMode.observePurity,
          ),
          isNotNull,
          reason: mirror.text,
        );
      });

      test('fallback admits: $user', () {
        final fallback = GuardSafeFallback.forPhase(
          what: ConversationPhase.validation,
          userUtterance: user,
          expressionMode: ConversationExpressionMode.observePurity,
        );
        expect(fallback, isNotNull);
        expect(fallback!.text, isNot('Anlıyorum.'));
      });
    }
  });

  group('B2.2.1 fuzzy classification', () {
    test('typo uncertainty is not abstain', () {
      expect(
        SurfaceUtteranceReader.classify('bilmiyom ki ne olcak'),
        SurfaceUtteranceKind.uncertainty,
      );
    });

    test('belki minimal absence is uncertainty', () {
      expect(
        SurfaceUtteranceReader.classify('Belki hiçbir şey.'),
        SurfaceUtteranceKind.uncertainty,
      );
    });

    test('experiential surface is statedFeeling', () {
      expect(
        SurfaceUtteranceReader.classify('Var olmak garip geliyor bazen.'),
        SurfaceUtteranceKind.statedFeeling,
      );
    });
  });

  group('B2.2.1 blind blockers', () {
    test('typo uncertainty mirrors in Turkish', () {
      const user = 'bilmiyom ki ne olcak';
      final mirror = UserObjectMirror.forValidation(
        userUtterance: user,
        expressionMode: ConversationExpressionMode.observePurity,
      );
      expect(mirror, isNotNull);
      expect(mirror!.text.toLowerCase(), isNot(contains('that part')));
      expect(mirror.text, isNot('Anlıyorum.'));
    });

    test('belki minimal absence avoids generic fallback', () {
      const user = 'Belki hiçbir şey.';
      final fallback = GuardSafeFallback.forPhase(
        what: ConversationPhase.validation,
        userUtterance: user,
        expressionMode: ConversationExpressionMode.observePurity,
      );
      expect(fallback, isNotNull);
      expect(fallback!.text, isNot('Anlıyorum.'));
    });
  });

  group('B2.2.1 hedge removal', () {
    test('settling mirror prefers act-native over gibi', () {
      const user = 'Tamam yavaş yavaş sakinleşiyorum.';
      final mirror = UserObjectMirror.forValidation(
        userUtterance: user,
        expressionMode: ConversationExpressionMode.observePurity,
      );
      expect(mirror, isNotNull);
      expect(mirror!.text.toLowerCase(), isNot(contains(' gibi.')));
    });

    test('paraphrase event avoids bare gibi tail', () {
      const user = 'Neyse yapacak bişi yok.';
      final mirror = UserObjectMirror.forValidation(
        userUtterance: user,
        expressionMode: ConversationExpressionMode.observePurity,
      );
      expect(mirror, isNotNull);
      expect(mirror!.text.toLowerCase(), isNot(endsWith(' gibi.')));
    });
  });
}
