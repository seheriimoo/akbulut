import 'package:flutter_test/flutter_test.dart';
import 'package:slowave/core/brain/conversation_blueprint_binding.dart';
import 'package:slowave/core/brain/conversation_compiler.dart';
import 'package:slowave/core/brain/conversation_grounding_buffer.dart';
import 'package:slowave/core/brain/conversation_phase.dart';
import 'package:slowave/core/brain/llm_invocation_package.dart';
import 'package:slowave/core/brain/receipt_intelligence.dart';
import 'package:slowave/core/brain/receipt_realization_contract.dart';

void main() {
  const intelligence = ReceiptIntelligence();
  const compiler = ConversationCompiler();

  final receiptStage =
      ConversationBlueprintCanon.instance.bindingFor(ConversationPhase.validation)!;

  ConversationGroundingBuffer grounding(String utterance) =>
      const ConversationGroundingBuffer.empty().appendUserUtterance(utterance);

  group('Receipt Intelligence V1.6', () {
    test('targets First Stop Moment without Naming/advice/questions', () {
      final slice = intelligence.compile(stage: receiptStage);

      expect(ReceiptIntelligence.version, '1.6');
      expect(slice.fsmDirective, contains('First Stop Moment'));
      expect(slice.aim, contains('First Stop Moment'));
      expect(slice.forbiddenMoves.join(' '), contains('Naming'));
      expect(slice.forbiddenMoves.join(' '), contains('Advice'));
      expect(slice.forbiddenMoves.join(' '), contains('Questions'));
      expect(slice.forbiddenMoves.join(' '), contains('Release'));
      expect(slice.responseLength, contains('45 words'));
    });

    test('steers into shared Receipt Realization Contract V1.6', () {
      final slice = intelligence.compile(stage: receiptStage);
      final all = '${slice.systemAppendix}\n${slice.userContent}\n'
          '${slice.forbiddenMoves.join(' ')}';

      expect(all, contains('Receipt Realization Contract v1.6'));
      expect(all, contains('your mind'));
      expect(all, contains('racing'));
      expect(all, contains('weighing'));
      expect(all, contains('holding on'));
      expect(all, contains(", and that's"));
      expect(all, contains('do not emit a canned reply'));
      expect(
        all,
        isNot(contains("Your mind is racing with tomorrow's thoughts.")),
      );
      expect(all, contains('do not invent a mind-job'));
    });

    test('forbids bare generic fillers unless concrete receipt follows', () {
      final slice = intelligence.compile(stage: receiptStage);
      final forbidden = slice.forbiddenMoves.join(' ');

      expect(forbidden, contains('I understand'));
      expect(forbidden, contains('I hear you'));
      expect(forbidden, contains('That makes sense'));
      expect(forbidden, contains('concrete'));
      expect(slice.systemAppendix, contains('same sentence'));
    });

    test('forbids clinical essay padding and intensifiers; steers V2 cadence', () {
      final slice = intelligence.compile(stage: receiptStage);
      final forbidden = slice.forbiddenMoves.join(' ');
      final all = '${slice.systemAppendix}\n${slice.userContent}\n$forbidden';

      expect(forbidden, contains('clinical paragraph'));
      expect(forbidden, contains('Category remapping'));
      expect(forbidden, contains('really'));
      expect(forbidden, contains('It sounds like'));
      expect(all, contains('Anti-essay'));
      expect(all, contains('Golden Conversations V2'));
      expect(all, contains('No-remap rule'));
      expect(all, contains('Intensifier'));
      expect(all, contains('Anti-stack rule'));
      expect(all.toLowerCase(), contains('texture-first'));
    });

    test('forbids near-parroting and invented stillness/presence', () {
      final slice = intelligence.compile(stage: receiptStage);
      final forbidden = slice.forbiddenMoves.join(' ');

      expect(forbidden, contains('Near-parroting'));
      expect(forbidden, contains('stillness'));
      expect(forbidden, contains('presence'));
      expect(slice.systemAppendix, contains('Restraint rule'));
    });

    test('includes current-turn conversation grounding as shaping only', () {
      final slice = intelligence.compile(
        stage: receiptStage,
        conversationGrounding: grounding(
          'I keep replaying everything for tomorrow. My mind won’t settle.',
        ),
      );

      expect(
        slice.userContent,
        contains('Current-turn conversation grounding to receive'),
      );
      expect(slice.userContent, contains('do not parrot'));
      expect(slice.userContent, contains('won’t settle'));
      expect(slice.userContent, contains('shaping only'));
      expect(slice.userContent, contains('Night-object rule'));
      expect(slice.userContent, contains('Anti-stack rule'));
      expect(slice.userContent, isNot(contains('Lived expression to receive')));
      expect(slice.userContent, contains('Two short sentences'));
      expect(slice.userContent, contains('45 words'));
    });

    test('forbids inventing tomorrow on uyuyamiyorum / idk / bilmiyorum', () {
      for (final line in const [
        'uyuyamiyorum.',
        'idk',
        'bilmiyorum.',
        'konusmak istemiyorum.',
      ]) {
        final slice = intelligence.compile(
          stage: receiptStage,
          conversationGrounding: grounding(line),
        );
        final all = '${slice.userContent}\n${slice.systemAppendix}\n'
            '${slice.forbiddenMoves.join(' ')}';
        expect(all, contains('Anti-invention'));
        expect(all.toLowerCase(), contains('tomorrow'));
        expect(all, contains('tomorrow-carry scene'));
        expect(
          all,
          anyOf(contains('Turkish only'), contains('Language lock')),
        );
      }
    });

    test('keeps tomorrow object when the person named it', () {
      final slice = intelligence.compile(
        stage: receiptStage,
        conversationGrounding: grounding(
          "I can't stop thinking about tomorrow.",
        ),
      );
      expect(slice.userContent, contains('Night-object rule'));
      expect(
        slice.userContent,
        isNot(contains('do not import a tomorrow-carry scene they did not name')),
      );
    });

    test('adds relational specificity note without inventing who/why', () {
      final slice = intelligence.compile(
        stage: receiptStage,
        conversationGrounding: grounding('I miss them tonight.'),
      );

      expect(slice.userContent, contains('Relational note'));
      expect(slice.userContent, contains('longing'));
      expect(slice.userContent, contains('without inventing who'));
      expect(slice.systemAppendix, contains('missing someone'));
    });

    test('adds sparse-message restraint for thin user lines', () {
      final slice = intelligence.compile(
        stage: receiptStage,
        conversationGrounding: grounding('I am here.'),
      );

      expect(slice.userContent, contains('Sparse-message restraint'));
      expect(slice.userContent, contains('Do not invent stillness'));
      expect(slice.userContent, isNot(contains('Relational note')));
    });

    test('filler idk / bilmiyorum compile thin-turn honesty, not tomorrow', () {
      for (final line in const ['idk', 'bilmiyorum', 'hm', "I don't know"]) {
        final slice = intelligence.compile(
          stage: receiptStage,
          conversationGrounding: grounding(line),
        );
        expect(slice.userContent, contains('Sparse-message restraint'), reason: line);
        expect(slice.userContent, contains('do not invent night-objects'), reason: line);
        expect(slice.systemAppendix, contains('Anti-invention'), reason: line);
        expect(slice.systemAppendix.toLowerCase(), contains('tomorrow'), reason: line);
      }
    });

    test('ignores standalone livedExpression; uses conversationGrounding only', () {
      final compiled = compiler.compile(
        LlmInvocationPackage(
          what: ConversationPhase.validation,
          livedExpression: 'livedExpression must not ground Receipt',
          conversationGrounding: grounding(
            'The same loops over and over. I can’t stop.',
          ),
        ),
      )!;

      expect(compiled.userContent, contains('loops over and over'));
      expect(
        compiled.userContent,
        isNot(contains('livedExpression must not ground Receipt')),
      );
    });

    test('compiler Receipt output carries Receipt Intelligence bindings', () {
      final compiled = compiler.compile(
        LlmInvocationPackage(
          what: ConversationPhase.validation,
          conversationGrounding: grounding(
            'The same loops over and over. I can’t stop.',
          ),
        ),
      )!;

      expect(compiled.stage.stage, BlueprintStage.receipt);
      expect(compiled.systemContent, contains('Receipt Intelligence v1.6'));
      expect(compiled.systemContent, contains('Mirror rule'));
      expect(compiled.systemContent, contains('Anti-essay rule'));
      expect(compiled.userContent, contains('loops over and over'));
      expect(compiled.realizationDirective, contains('First Stop Moment'));
      expect(
        compiled.stage.sealedWhatSignature.toLowerCase(),
        contains('texture-first'),
      );
    });

    test('truncates oversized current-turn grounding deterministically', () {
      final long = 'x' * 600;
      final slice = intelligence.compile(
        stage: receiptStage,
        conversationGrounding: grounding(long),
      );
      expect(
        slice.userContent.contains(
          'x' * ReceiptIntelligence.maxCurrentGroundingChars,
        ),
        isTrue,
      );
      expect(slice.userContent.contains('x' * 600), isFalse);
    });
  });
}
