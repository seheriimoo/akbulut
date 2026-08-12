import 'package:flutter_test/flutter_test.dart';
import 'package:slowave/core/brain/conversation_blueprint_binding.dart';
import 'package:slowave/core/brain/conversation_compiler.dart';
import 'package:slowave/core/brain/conversation_grounding_buffer.dart';
import 'package:slowave/core/brain/conversation_phase.dart';
import 'package:slowave/core/brain/llm_invocation_package.dart';
import 'package:slowave/core/brain/naming_intelligence.dart';

void main() {
  const intelligence = NamingIntelligence();
  const compiler = ConversationCompiler();

  final namingStage =
      ConversationBlueprintCanon.instance.bindingFor(ConversationPhase.naming)!;

  ConversationGroundingBuffer grounding(String utterance) =>
      const ConversationGroundingBuffer.empty().appendUserUtterance(utterance);

  group('Naming Intelligence V1', () {
    test('targets quiet recognition without interpretation or diagnosis', () {
      final slice = intelligence.compile(stage: namingStage);

      expect(slice.recognitionDirective, contains('Quiet recognition'));
      expect(slice.aim, contains('exactly what’s happening'));
      expect(slice.forbiddenMoves.join(' '), contains('hidden motives'));
      expect(slice.forbiddenMoves.join(' '), contains('Diagnosis'));
      expect(slice.forbiddenMoves.join(' '), contains('psychological'));
      expect(slice.forbiddenMoves.join(' '), contains('Permission'));
      expect(slice.forbiddenMoves.join(' '), contains('Release'));
      expect(slice.responseLength, contains('45 words'));
      expect(slice.responseLength, contains('45 words'));
    });

    test('continues from Receipt and forbids re-acknowledgment drift', () {
      final slice = intelligence.compile(stage: namingStage);
      expect(slice.systemAppendix, contains('Continuity rule'));
      expect(slice.systemAppendix, contains('successful Receipt'));
      expect(slice.forbiddenMoves.join(' '), contains('Receipt filler'));
      expect(slice.sealedWhatSignature, contains('Continue from Receipt'));
    });

    test('grounds naming in current-turn conversation grounding only', () {
      final slice = intelligence.compile(
        stage: namingStage,
        conversationGrounding: grounding(
          'It’s the same loops over and over. I can’t get them to stop.',
        ),
      );

      expect(slice.userContent, contains('already admitted'));
      expect(slice.userContent, contains('name only what is evident'));
      expect(slice.userContent, contains('loops over and over'));
      expect(slice.systemAppendix, contains('Evidence rule'));
      expect(slice.userContent, isNot(contains('Lived expression already received')));
    });

    test('compiler Naming output carries Naming Intelligence bindings', () {
      final compiled = compiler.compile(
        LlmInvocationPackage(
          what: ConversationPhase.naming,
          conversationGrounding: grounding('My mind keeps replaying tomorrow.'),
        ),
      )!;

      expect(compiled.stage.stage, BlueprintStage.naming);
      expect(compiled.systemContent, contains('Naming Intelligence v1.0'));
      expect(compiled.systemContent, contains('Single recognition rule'));
      expect(compiled.userContent, contains('replaying tomorrow'));
      expect(
        compiled.realizationDirective,
        contains('exactly what’s happening'),
      );
      expect(compiled.systemContent, isNot(contains('Receipt Intelligence')));
    });

    test('ignores standalone livedExpression; uses conversationGrounding only', () {
      final compiled = compiler.compile(
        LlmInvocationPackage(
          what: ConversationPhase.naming,
          livedExpression: 'livedExpression must not ground Naming',
          conversationGrounding: grounding('My mind keeps replaying tomorrow.'),
        ),
      )!;

      expect(compiled.userContent, contains('replaying tomorrow'));
      expect(
        compiled.userContent,
        isNot(contains('livedExpression must not ground Naming')),
      );
    });

    test('truncates oversized current-turn grounding deterministically', () {
      final long = 'y' * 600;
      final slice = intelligence.compile(
        stage: namingStage,
        conversationGrounding: grounding(long),
      );
      expect(
        slice.userContent
            .contains('y' * NamingIntelligence.maxCurrentGroundingChars),
        isTrue,
      );
      expect(slice.userContent.contains('y' * 600), isFalse);
    });
  });
}
