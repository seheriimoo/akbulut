import 'package:flutter_test/flutter_test.dart';
import 'package:slowave/core/brain/conversation_blueprint_binding.dart';
import 'package:slowave/core/brain/conversation_compiler.dart';
import 'package:slowave/core/brain/conversation_grounding_buffer.dart';
import 'package:slowave/core/brain/conversation_phase.dart';
import 'package:slowave/core/brain/llm_invocation_package.dart';
import 'package:slowave/core/brain/permission_intelligence.dart';

void main() {
  const intelligence = PermissionIntelligence();
  const compiler = ConversationCompiler();

  final permissionStage =
      ConversationBlueprintCanon.instance.bindingFor(ConversationPhase.permission)!;

  ConversationGroundingBuffer grounding(String utterance) =>
      const ConversationGroundingBuffer.empty().appendUserUtterance(utterance);

  group('Permission Intelligence V1', () {
    test('keeps sealed Permission WHAT and forbids Receipt/Release/advice', () {
      final slice = intelligence.compile(stage: permissionStage);
      final forbidden = slice.forbiddenMoves.join(' ');

      expect(slice.sealedWhatSignature, contains('permission / Permission'));
      expect(slice.sealedWhatSignature, contains('non-resolution'));
      expect(slice.easeDirective, contains('Permission only'));
      expect(forbidden, contains('Receipt'));
      expect(forbidden, contains('Release'));
      expect(forbidden, contains('Advice'));
      expect(forbidden, contains('Questions'));
      expect(slice.responseLength, contains('18 words'));
    });

    test('does not structurally require figure/sort/solve-tonight stamps', () {
      final slice = intelligence.compile(stage: permissionStage);
      final all =
          '${slice.sealedWhatSignature}\n${slice.systemAppendix}\n${slice.forbiddenMoves.join(' ')}';

      expect(all, contains('Do not require'));
      expect(all, contains('Anti-stamp'));
      expect(all.toLowerCase(), contains('figure'));
      expect(all.toLowerCase(), contains('sort'));
    });

    test('low-load grounding authorizes pause without inventing a problem', () {
      final slice = intelligence.compile(
        stage: permissionStage,
        conversationGrounding: grounding('Still here.'),
      );

      expect(slice.userContent, contains('Low-load note'));
      expect(slice.userContent, contains('without inventing'));
      expect(slice.userContent, contains('Still here.'));
      expect(slice.systemAppendix, contains('Low-load rule'));
    });

    test('active grounding may shape texture without changing WHAT', () {
      final slice = intelligence.compile(
        stage: permissionStage,
        conversationGrounding: grounding(
          'I keep thinking about what if I mess everything up.',
        ),
      );

      expect(slice.userContent, contains('Active-load note'));
      expect(slice.userContent, contains('do not change WHAT'));
      expect(slice.userContent, contains('what if'));
      expect(slice.systemAppendix, contains('Grounding rule'));
      expect(slice.userContent, isNot(contains('First Stop Moment')));
    });

    test('self-permission grounding asks for neighboring ease, not echo', () {
      final slice = intelligence.compile(
        stage: permissionStage,
        conversationGrounding: grounding(
          "I don't have to figure it all out tonight.",
        ),
      );

      expect(slice.userContent, contains('Self-permission note'));
      expect(slice.userContent, contains('neighboring ease'));
      expect(slice.forbiddenMoves.join(' '), contains('Echoing a self-permission'));
      expect(slice.systemAppendix, contains('already granted themselves'));
    });

    test('compiler Permission overlay is deterministic and stage-scoped', () {
      final package = LlmInvocationPackage(
        what: ConversationPhase.permission,
        conversationGrounding: grounding('Still here.'),
      );
      final a = compiler.compile(package)!;
      final b = compiler.compile(package)!;

      expect(a.systemContent, b.systemContent);
      expect(a.userContent, b.userContent);
      expect(a.systemContent, contains('Permission Intelligence v1.2'));
      expect(a.systemContent, isNot(contains('Receipt Intelligence')));
      expect(a.systemContent, isNot(contains('Naming Intelligence')));
      expect(a.stage.sealedWhatSignature, contains('Do not require'));
      expect(a.userContent, contains('Still here.'));
    });
  });
}
