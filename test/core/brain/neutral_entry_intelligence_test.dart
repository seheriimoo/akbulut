import 'package:flutter_test/flutter_test.dart';
import 'package:slowave/core/brain/conversation_blueprint_binding.dart';
import 'package:slowave/core/brain/conversation_compiler.dart';
import 'package:slowave/core/brain/conversation_phase.dart';
import 'package:slowave/core/brain/llm_invocation_package.dart';
import 'package:slowave/core/brain/neutral_entry_intelligence.dart';

void main() {
  const intelligence = NeutralEntryIntelligence();
  const compiler = ConversationCompiler();

  final stage = ConversationBlueprintCanon.instance
      .bindingFor(ConversationPhase.neutralEntry)!;

  group('Neutral Entry Intelligence V1', () {
    test('targets brief greeting acknowledgment without Receipt/questions', () {
      final slice = intelligence.compile(stage: stage);

      expect(NeutralEntryIntelligence.version, '1.0');
      expect(slice.aim.toLowerCase(), contains('greeting'));
      expect(slice.responseLength, contains('one short sentence'));
      expect(slice.forbiddenMoves.join(' '), contains('Questions'));
      expect(slice.forbiddenMoves.join(' '), contains('Invented emotion'));
      expect(slice.forbiddenMoves.join(' '), contains('stillness'));
      expect(slice.forbiddenMoves.join(' '), contains('presence'));
      expect(slice.forbiddenMoves.join(' '), contains('Receipt'));
      expect(slice.sealedWhatSignature, contains('neutralEntry'));
      expect(slice.systemAppendix, contains('No-invention rule'));
      expect(slice.systemAppendix, contains('No-question rule'));
    });

    test('Compiler Neutral Entry overlay applies Intelligence, not Receipt', () {
      final compiled = compiler.compile(
        LlmInvocationPackage(what: ConversationPhase.neutralEntry),
      )!;

      expect(compiled.sealedWhat, ConversationPhase.neutralEntry);
      expect(compiled.stage.stage, BlueprintStage.neutralEntry);
      expect(compiled.systemContent, contains('Neutral Entry Intelligence'));
      expect(compiled.systemContent, isNot(contains('Receipt Intelligence')));
      expect(
        compiled.userContent,
        isNot(contains('Current-turn conversation grounding to receive')),
      );
      expect(compiled.userContent, contains('No question'));
      expect(compiled.stage.responseLength.toLowerCase(), contains('one short'));
    });

    test('Neutral Entry compile is deterministic', () {
      final package = LlmInvocationPackage(what: ConversationPhase.neutralEntry);
      final a = compiler.compile(package)!;
      final b = compiler.compile(package)!;
      expect(a.systemContent, b.systemContent);
      expect(a.userContent, b.userContent);
    });
  });
}
