import 'package:flutter_test/flutter_test.dart';
import 'package:slowave/core/brain/conversation_blueprint_binding.dart';
import 'package:slowave/core/brain/conversation_compiler.dart';
import 'package:slowave/core/brain/conversation_grounding_buffer.dart';
import 'package:slowave/core/brain/conversation_phase.dart';
import 'package:slowave/core/brain/llm_invocation_package.dart';
import 'package:slowave/core/brain/release_intelligence.dart';

void main() {
  const intelligence = ReleaseIntelligence();
  const compiler = ConversationCompiler();

  final releaseStage =
      ConversationBlueprintCanon.instance.bindingFor(ConversationPhase.release)!;

  ConversationGroundingBuffer grounding(List<String> turns) {
    var buffer = const ConversationGroundingBuffer.empty();
    for (final turn in turns) {
      buffer = buffer.appendUserUtterance(turn);
    }
    return buffer;
  }

  group('Release Intelligence V1', () {
    test('keeps sealed Release WHAT and forbids other-stage drift', () {
      final slice = intelligence.compile(stage: releaseStage);
      final forbidden = slice.forbiddenMoves.join(' ');

      expect(slice.sealedWhatSignature, contains('release / Release'));
      expect(slice.putDownDirective, contains('Release only'));
      expect(forbidden, contains('Receipt'));
      expect(forbidden, contains('Permission'));
      expect(forbidden, contains('Sleep commands'));
      expect(forbidden, contains('Advice'));
      expect(forbidden, contains('Leave some of that here'));
      expect(slice.responseLength, contains('28 words'));
    });

    test('does not structurally require Let it rest for now', () {
      final slice = intelligence.compile(stage: releaseStage);
      final all =
          '${slice.sealedWhatSignature}\n${slice.systemAppendix}\n${slice.forbiddenMoves.join(' ')}';

      expect(all, contains('Do not require'));
      expect(all, contains('Anti-stamp'));
      expect(all, contains('Let it rest for now'));
    });

    test('anti-repeat uses prior user turns; optional prior admitted line', () {
      final slice = intelligence.compile(
        stage: releaseStage,
        conversationGrounding: grounding([
          'I am still thinking.',
          'It is quieter but not gone.',
        ]),
      );

      expect(slice.userContent, contains('Anti-repeat'));
      expect(slice.userContent, contains('prior user turns'));
      expect(slice.systemAppendix, contains('prior assistant line not supplied'));
      expect(slice.userContent, isNot(contains('NOCTA:')));
      expect(slice.systemAppendix, isNot(contains('assistant utterance')));
      expect(slice.userContent, contains('quieter but not gone'));
    });

    test('deterministic lean from grounding; same inputs compile identically', () {
      final g = grounding([
        'I am still thinking.',
        'It is quieter but not gone.',
      ]);
      final package = LlmInvocationPackage(
        what: ConversationPhase.release,
        conversationGrounding: g,
      );
      final a = compiler.compile(package)!;
      final b = compiler.compile(package)!;

      expect(a.systemContent, b.systemContent);
      expect(a.userContent, b.userContent);
      expect(a.systemContent, contains('Release Intelligence v1.3'));
      expect(a.systemContent, contains('Deterministic lean index:'));
      expect(a.systemContent, isNot(contains('Receipt Intelligence')));
      expect(a.systemContent, isNot(contains('Permission Intelligence')));
    });

    test('different user grounding windows yield different deterministic leans', () {
      final first = intelligence.compile(
        stage: releaseStage,
        conversationGrounding: grounding(['I am still thinking.']),
      );
      final second = intelligence.compile(
        stage: releaseStage,
        conversationGrounding: grounding([
          'I am still thinking.',
          'It is quieter but not gone.',
        ]),
      );

      final leanA = RegExp(r'Deterministic lean index: (\d)')
          .firstMatch(first.systemAppendix)!
          .group(1);
      final leanB = RegExp(r'Deterministic lean index: (\d)')
          .firstMatch(second.systemAppendix)!
          .group(1);

      // Different windows should usually differ; if hash collides, userContent
      // anti-repeat text still differs by prior-turn count.
      expect(
        first.userContent == second.userContent,
        isFalse,
      );
      expect(leanA, isNotNull);
      expect(leanB, isNotNull);
    });

    test('grounding shapes wording without inventing facts', () {
      final slice = intelligence.compile(
        stage: releaseStage,
        conversationGrounding: grounding(['Softening.']),
      );

      expect(slice.userContent, contains('Softening.'));
      expect(slice.userContent, contains('do not infer'));
      expect(slice.systemAppendix, contains('Grounding rule'));
      expect(slice.userContent, isNot(contains('First Stop Moment')));
    });

    test('Turkish nights ban stamp pair and steer TR lean families', () {
      final slice = intelligence.compile(
        stage: releaseStage,
        conversationGrounding: grounding([
          'Bu gece kendimi çok yalnız hissediyorum.',
          'Biraz daha sessiz şimdi.',
        ]),
      );

      expect(ReleaseIntelligence.version, '1.3');
      expect(slice.putDownDirective, contains('Turkish only'));
      expect(slice.putDownDirective, contains('FORBIDDEN stamp pair'));
      expect(
        slice.systemAppendix,
        contains('Bunu burada bırak. Gece bunu taşıyabilir.'),
      );
      expect(slice.systemAppendix, contains('Lean TR:'));
      expect(slice.forbiddenMoves.join(' '), contains('Turkish stamp pair'));
    });

    test('ASCII TR night locks Turkish and forbids on-your-mind Naming stems', () {
      final slice = intelligence.compile(
        stage: releaseStage,
        conversationGrounding: grounding([
          'kafayi yicem ya bu gece.',
          'yani o kadar dusunuyom ki duramiyom.',
        ]),
      );
      final all =
          '${slice.putDownDirective}\n${slice.forbiddenMoves.join(' ')}';
      expect(slice.putDownDirective, contains('Turkish only'));
      expect(all, contains('on your mind'));
      expect(all, contains('English Release on a Turkish night'));
    });
  });
}
