import 'package:flutter_test/flutter_test.dart';
import 'package:slowave/core/brain/conversation_expression_mode.dart';
import 'package:slowave/core/brain/conversation_phase.dart';
import 'package:slowave/core/brain/conversation_utterance.dart';
import 'package:slowave/core/brain/guard_safe_fallback.dart';
import 'package:slowave/core/brain/user_object_mirror.dart';
import 'package:slowave/core/brain/utterance_guard.dart';

import '../../integration/blind_retention_personas.dart';

/// B2.2 — Natural surface mirror tests.
void main() {
  const guard = UtteranceGuard();

  group('B2.1 hard examples', () {
    final cases = <({String user, String? grounding, List<String> mustNot, List<String> mayContain})>[
      (
        user: 'Bugün terfi aldım, hâlâ inanamıyorum!',
        grounding: null,
        mustNot: ['hâlâ orada', 'Bugün terfi aldım hâlâ'],
        mayContain: ['terfi', 'gerçek dışı', 'oturmamış'],
      ),
      (
        user: 'Evet, onu kaybettim.',
        grounding: 'Mutfakta çorba kaynattım, boş kaldı elim. Eskiden biri severdi bu çorbayı.',
        mustNot: ['kaybettim hâlâ orada', 'Onu kaybettim hâlâ'],
        mayContain: ['kaybetmiş', 'açık'],
      ),
      (
        user: 'Tamam yavaş yavaş sakinleşiyorum.',
        grounding: null,
        mustNot: ['sakinleşiyorum hâlâ orada'],
        mayContain: ['sakinleş'],
      ),
      (
        user: 'İyi geceler dene.',
        grounding: null,
        mustNot: ['hâlâ orada'],
        mayContain: [],
      ),
      (
        user: 'Mutfakta çorba kaynattım, boş kaldı elim.',
        grounding: null,
        mustNot: ['hâlâ orada'],
        mayContain: ['çorba', 'boş'],
      ),
      (
        user: 'Eskiden biri severdi bu çorbayı.',
        grounding: null,
        mustNot: ['hâlâ orada'],
        mayContain: ['çorba', 'eskiden', 'sevdi'],
      ),
      (
        user: 'Evde tek başıma oturuyorum, dışarıda yağmur var.',
        grounding: null,
        mustNot: ['hâlâ orada'],
        mayContain: ['oturuyorsun', 'yağmur'],
      ),
      (
        user: 'Yeni teklif heyecan verici ama maaş düşük.',
        grounding: null,
        mustNot: ['hâlâ orada', 'maaş düşük hâlâ orada'],
        mayContain: ['heyecan', 'maaş', 'teklif'],
      ),
    ];

    for (final c in cases) {
      test('hard: ${c.user.substring(0, c.user.length.clamp(0, 32))}', () {
        final mirror = UserObjectMirror.forValidation(
          userUtterance: c.user,
          groundingBlob: c.grounding,
          expressionMode: ConversationExpressionMode.observePurity,
        );
        if (c.user == 'İyi geceler dene.') {
          expect(mirror, isNull, reason: 'closing intent should abstain');
          return;
        }
        expect(mirror, isNotNull, reason: c.user);
        final text = mirror!.text;
        expect(text, isNot('Anlıyorum.'));
        for (final bad in c.mustNot) {
          expect(text.toLowerCase(), isNot(contains(bad.toLowerCase())));
        }
        if (c.mayContain.isNotEmpty) {
          expect(
            c.mayContain.any((m) => text.toLowerCase().contains(m.toLowerCase())),
            isTrue,
            reason: '$text should contain one of ${c.mayContain}',
          );
        }
        expect(
          guard.allow(
            utterance: mirror,
            what: ConversationPhase.validation,
            userUtterance: c.grounding ?? c.user,
            expressionMode: ConversationExpressionMode.observePurity,
          ),
          isNotNull,
          reason: text,
        );
      });
    }
  });

  group('UserObjectMirror Guard admission', () {
    test('standard TR admits paraphrase not literal paste', () {
      const user = 'Kafam durmuyor ya.';
      final mirror = UserObjectMirror.forValidation(
        userUtterance: user,
        expressionMode: ConversationExpressionMode.standard,
      );
      expect(mirror, isNotNull);
      expect(mirror!.text, isNot('Anlıyorum.'));
      expect(mirror.text.toLowerCase(), isNot(contains('hâlâ orada')));
    });

    test('minimal ack pulls grounding with natural mirror', () {
      const prior =
          'Kafam durmuyor, bugün review\'da aldığım yorumu tekrar tekrar okuyorum.';
      final mirror = UserObjectMirror.forValidation(
        userUtterance: 'Evet.',
        groundingBlob: prior,
        expressionMode: ConversationExpressionMode.standard,
      );
      expect(mirror, isNotNull);
      expect(mirror!.text.toLowerCase(), isNot(contains('anlıyorum')));
      expect(mirror.text.toLowerCase(), isNot(contains('hâlâ orada')));
    });
  });

  group('UserObjectMirror blind persona first turns', () {
    for (final persona in blindPersonas) {
      test('${persona.id} mirror never literal hâlâ-orada paste', () {
        final user = persona.turns.first;
        final mirror = UserObjectMirror.forValidation(
          userUtterance: user,
          expressionMode: ConversationExpressionMode.observePurity,
        );
        if (mirror == null) return;
        expect(mirror.text, isNot('Anlıyorum.'));
        expect(mirror.text.toLowerCase(), isNot(contains(' hâlâ orada.')));
      });
    }
  });
}
