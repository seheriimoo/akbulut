import 'package:flutter_test/flutter_test.dart';
import 'package:slowave/core/brain/conversation_blueprint_binding.dart';
import 'package:slowave/core/brain/conversation_compiler.dart';
import 'package:slowave/core/brain/conversation_grounding_buffer.dart';
import 'package:slowave/core/brain/conversation_phase.dart';
import 'package:slowave/core/brain/conversation_utterance.dart';
import 'package:slowave/core/brain/llm_invocation_package.dart';
import 'package:slowave/core/brain/permission_intelligence.dart';
import 'package:slowave/core/brain/permission_realization_contract.dart';
import 'package:slowave/core/brain/release_intelligence.dart';
import 'package:slowave/core/brain/thinking_function_hypothesis.dart';
import 'package:slowave/core/brain/thinking_function_kind.dart';
import 'package:slowave/core/brain/utterance_guard.dart';
import 'package:slowave/core/brain/validated_understanding.dart';

void main() {
  const guard = UtteranceGuard();
  const permission = PermissionIntelligence();
  const release = ReleaseIntelligence();
  const compiler = ConversationCompiler();

  final permissionStage = ConversationBlueprintCanon.instance
      .bindingFor(ConversationPhase.permission)!;
  final releaseStage = ConversationBlueprintCanon.instance
      .bindingFor(ConversationPhase.release)!;

  ThinkingFunctionHypothesis worstCase() => ThinkingFunctionHypothesis(
        kind: ThinkingFunctionKind.worstCaseRehearsal,
        confidence: 0.82,
        evidenceIds: const ['current:worst_case'],
        supportTurnCount: 1,
      );

  group('Permission Realization Contract V1', () {
    test('A. shared-contract alignment Intelligence + Guard', () {
      expect(PermissionRealizationContract.version, '1.0');
      expect(
        UtteranceGuard.permissionContractVersion,
        PermissionRealizationContract.version,
      );
      expect(PermissionIntelligence.version, '1.2');

      final slice = permission.compile(stage: permissionStage);
      final all = '${slice.userContent}\n${slice.systemAppendix}';
      expect(all, contains('Permission Realization Contract v1.0'));
      expect(all, contains('Vary naturally only inside'));
      expect(all, contains('Speech-act'));
    });

    test('B. admits legal obligation-ease / soft-modal Permission forms', () {
      for (final text in const [
        "You don't need to keep worrying about this tonight.",
        'You do not have to keep rehearsing tonight.',
        'No need to solve this tonight.',
        'You can pause the rehearsal for tonight.',
        'You can leave this unresolved tonight.',
      ]) {
        final admitted = guard.allow(
          utterance: ConversationUtterance(text: text),
          what: ConversationPhase.permission,
        );
        expect(admitted, isNotNull, reason: text);
      }
    });

    test('C. rejects Release enactment / bare okay under Permission', () {
      for (final text in const [
        'You can let go of that tonight.',
        'You can set this down tonight.',
        'Let it rest.',
        'Release this.',
        'Loosen your grip.',
        "It's okay.",
      ]) {
        expect(
          guard.allow(
            utterance: ConversationUtterance(text: text),
            what: ConversationPhase.permission,
          ),
          isNull,
          reason: text,
        );
      }
    });

    test('D. supported worstCase Permission compile is obligation-only', () {
      final slice = permission.compile(
        stage: permissionStage,
        conversationGrounding: const ConversationGroundingBuffer.empty()
            .appendUserUtterance(
          'I know nothing has happened yet, but my mind keeps preparing '
          'for the worst.',
        ),
        thinkingFunctionHypothesis: worstCase(),
      );
      final all =
          '${slice.userContent}\n${slice.systemAppendix}\n${slice.forbiddenMoves.join('\n')}';

      expect(all.toLowerCase(), contains('not required to keep rehearsing'));
      expect(all, contains('Speech-act barrier'));
      expect(all, contains('let go'));
      expect(all.toLowerCase(), contains('put-down'));
      expect(all, isNot(contains('Put-down TYPE')));
      expect(all, isNot(contains('Unburden')));
    });

    test('E. Release contrast — put-down remains Release-owned', () {
      final permissionSlice = permission.compile(
        stage: permissionStage,
        thinkingFunctionHypothesis: worstCase(),
      );
      final releaseSlice = release.compile(
        stage: releaseStage,
        thinkingFunctionHypothesis: worstCase(),
      );

      expect(
        permissionSlice.userContent.toLowerCase(),
        contains('not required to keep rehearsing'),
      );
      expect(permissionSlice.userContent, isNot(contains('Put-down TYPE')));
      expect(releaseSlice.userContent, contains('Put-down TYPE'));
      expect(
        releaseSlice.userContent.toLowerCase(),
        contains('rehearsal stop'),
      );
    });

    test('F. Blueprint Permission restDirection eases obligation, not Unburden',
        () {
      expect(permissionStage.restDirection, contains('Ease obligation'));
      expect(permissionStage.restDirection.toLowerCase(), isNot(contains('unburden')));
      expect(permissionStage.restDirection.toLowerCase(), contains('putting-down'));

      final compiled = compiler.compile(
        LlmInvocationPackage(
          what: ConversationPhase.permission,
          understanding: ValidatedUnderstanding(
            thinkingFunctionHypothesis: worstCase(),
          ),
        ),
      )!;
      expect(compiled.systemContent, contains('Ease obligation toward rest'));
      expect(compiled.systemContent.toLowerCase(), isNot(contains('unburden')));
    });

    test('G. other phase admission unchanged; Permission soft-modal stays scoped',
        () {
      const pause = 'You can pause the rehearsal for tonight.';
      for (final phase in const [
        ConversationPhase.validation,
        ConversationPhase.naming,
        ConversationPhase.release,
        ConversationPhase.continuity,
        ConversationPhase.neutralEntry,
      ]) {
        expect(
          guard.allow(
            utterance: const ConversationUtterance(text: pause),
            what: phase,
          ),
          isNull,
          reason: phase.name,
        );
      }

      expect(
        guard.allow(
          utterance: const ConversationUtterance(
            text: 'Let it rest for now.',
          ),
          what: ConversationPhase.release,
        ),
        isNotNull,
      );
      expect(
        guard.allow(
          utterance: const ConversationUtterance(
            text: 'Your thoughts are swirling, making it hard to find calm.',
          ),
          what: ConversationPhase.validation,
        ),
        isNotNull,
      );
    });
  });
}
