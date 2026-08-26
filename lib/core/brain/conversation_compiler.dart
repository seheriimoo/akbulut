import 'closure_intelligence.dart';
import 'conversation_blueprint_binding.dart';
import 'conversation_constitution.dart';
import 'conversation_dna.dart';
import 'conversation_expression_mode.dart';
import 'conversation_grounding_buffer.dart';
import 'conversation_philosophy.dart';
import 'compiled_instruction_package.dart';
import 'enough_intelligence.dart';
import 'exit_decision.dart';
import 'integration_intelligence.dart';
import 'language_style.dart';
import 'llm_invocation_package.dart';
import 'naming_intelligence.dart';
import 'narrow_intelligence.dart';
import 'neutral_entry_intelligence.dart';
import 'permission_intelligence.dart';
import 'receipt_intelligence.dart';
import 'release_intelligence.dart';
import 'repair_intelligence.dart';
import 'reframe_intelligence.dart';

/// Conversation Compiler V1
///
/// Deterministic translation only: sealed [LlmInvocationPackage] + frozen
/// conversation canon → one [CompiledInstructionPackage], or fail closed.
///
/// Does not choose WHAT, psychology, release, exit, memory, or protocol.
/// Does not call a vendor. Does not validate emission ([UtteranceGuard] owns
/// admit/reject). Same inputs → same compiled output.
///
/// Stage F uses field-specific shaping modes (Amendment 003):
/// - understanding / workingMind → presence-only
/// - conversationGrounding → deterministic materialization
///
/// Stage compilation aids:
/// - [ReceiptIntelligence] for Receipt / First Stop Moment
/// - [NamingIntelligence] for Naming / quiet recognition
/// - [PermissionIntelligence] for Permission / non-resolution ease
/// - [ReleaseIntelligence] for Release / putting-down + anti-repeat lean
/// - [EnoughIntelligence] for Enough / continuity close
/// - [NeutralEntryIntelligence] for Neutral Entry / greeting acknowledgment
///
/// Voice shaping:
/// - [LanguageStyle] for naturalness, quiet warmth, unforced speech only
class ConversationCompiler {
  const ConversationCompiler({
    this.receiptIntelligence = const ReceiptIntelligence(),
    this.namingIntelligence = const NamingIntelligence(),
    this.permissionIntelligence = const PermissionIntelligence(),
    this.releaseIntelligence = const ReleaseIntelligence(),
    this.enoughIntelligence = const EnoughIntelligence(),
    this.neutralEntryIntelligence = const NeutralEntryIntelligence(),
    this.repairIntelligence = const RepairIntelligence(),
    this.narrowIntelligence = const NarrowIntelligence(),
    this.reframeIntelligence = const ReframeIntelligence(),
    this.integrationIntelligence = const IntegrationIntelligence(),
    this.closureIntelligence = const ClosureIntelligence(),
    this.languageStyle = LanguageStyle.instance,
  });

  final ReceiptIntelligence receiptIntelligence;
  final NamingIntelligence namingIntelligence;
  final PermissionIntelligence permissionIntelligence;
  final ReleaseIntelligence releaseIntelligence;
  final EnoughIntelligence enoughIntelligence;
  final NeutralEntryIntelligence neutralEntryIntelligence;
  final RepairIntelligence repairIntelligence;
  final NarrowIntelligence narrowIntelligence;
  final ReframeIntelligence reframeIntelligence;
  final IntegrationIntelligence integrationIntelligence;
  final ClosureIntelligence closureIntelligence;
  final LanguageStyle languageStyle;

  static const String expectedConstitutionVersion =
      ConversationConstitution.version;
  static const String expectedPhilosophyVersion =
      ConversationPhilosophy.version;
  static const String expectedBlueprintVersion =
      ConversationBlueprintCanon.version;

  /// Compile one sealed package into vendor-ready instructions.
  ///
  /// Returns null on any admission, binding, integrity, or assembly failure
  /// (fail closed). Never invents substitute speech or alternate WHAT.
  CompiledInstructionPackage? compile(LlmInvocationPackage package) {
    // Stage A — Admit Package
    if (!_admit(package)) {
      return null;
    }

    // Stage B — Bind Blueprint Stage
    final stage = ConversationBlueprintCanon.instance.bindingFor(package.what);
    if (stage == null) {
      return null;
    }

    // Stage C — Bind Constitution
    if (!_constitutionAvailable()) {
      return null;
    }

    // Stage D — Bind Philosophy
    if (!_philosophyAvailable()) {
      return null;
    }

    // Stage E — Bind Package Constraints (DNA + LLM bounds integrity)
    if (!_packageConstraintsIntact(package)) {
      return null;
    }

    // Stage F — Bind Optional Shaping (field-specific)
    final stageF = _bindOptionalShaping(package);
    if (stageF == null) {
      return null;
    }

    // Stage intelligence overlays (stage-scoped; never choose WHAT).
    final _StageOverlay? overlay = _stageOverlay(stage, package);

    // Stage G — Seal CompiledInstructionPackage
    return _seal(
      package: package,
      stage: stage,
      shapingNote: stageF.shapingNote,
      groundingMaterialization: stageF.groundingMaterialization,
      overlay: overlay,
      expressionMode: package.expressionMode,
    );
  }

  _StageOverlay? _stageOverlay(
    BlueprintStageBinding stage,
    LlmInvocationPackage package,
  ) {
    switch (stage.stage) {
      case BlueprintStage.receipt:
        if (package.expressionMode == ConversationExpressionMode.repair) {
          final slice = repairIntelligence.compile(
            stage: stage,
            conversationGrounding: package.conversationGrounding,
            repetitionProtest: package.repairRepetitionProtest,
          );
          return _StageOverlay(
            aim: slice.aim,
            sealedWhatSignature: slice.sealedWhatSignature,
            forbiddenMoves: slice.forbiddenMoves,
            responseLength: slice.responseLength,
            realizationDirective: slice.realizationDirective,
            userContent: slice.userContent,
            systemAppendix: slice.systemAppendix,
          );
        }
        if (package.expressionMode == ConversationExpressionMode.narrow) {
          final slice = narrowIntelligence.compile(
            stage: stage,
            conversationGrounding: package.conversationGrounding,
            refinementAfterPartial: package.narrowRefinementAfterPartial,
            thinkingFunctionHypothesis:
                package.understanding?.thinkingFunctionHypothesis,
            discoveryObjective: package.discoveryObjective,
          );
          return _StageOverlay(
            aim: slice.aim,
            sealedWhatSignature: slice.sealedWhatSignature,
            forbiddenMoves: slice.forbiddenMoves,
            responseLength: slice.responseLength,
            realizationDirective: slice.realizationDirective,
            userContent: slice.userContent,
            systemAppendix: slice.systemAppendix,
          );
        }
        if (package.expressionMode == ConversationExpressionMode.reframe) {
          final slice = reframeIntelligence.compile(
            stage: stage,
            conversationGrounding: package.conversationGrounding,
          );
          return _StageOverlay(
            aim: slice.aim,
            sealedWhatSignature: slice.sealedWhatSignature,
            forbiddenMoves: slice.forbiddenMoves,
            responseLength: slice.responseLength,
            realizationDirective: slice.realizationDirective,
            userContent: slice.userContent,
            systemAppendix: slice.systemAppendix,
          );
        }
        if (package.expressionMode == ConversationExpressionMode.integrate) {
          final slice = integrationIntelligence.compile(
            stage: stage,
            conversationGrounding: package.conversationGrounding,
            confirmedReframeText: package.priorAdmittedExpression?.text,
          );
          return _StageOverlay(
            aim: slice.aim,
            sealedWhatSignature: slice.sealedWhatSignature,
            forbiddenMoves: slice.forbiddenMoves,
            responseLength: slice.responseLength,
            realizationDirective: slice.realizationDirective,
            userContent: slice.userContent,
            systemAppendix: slice.systemAppendix,
          );
        }
        if (package.expressionMode == ConversationExpressionMode.closure) {
          final slice = closureIntelligence.compile(
            stage: stage,
            conversationGrounding: package.conversationGrounding,
            integrateText: package.priorAdmittedExpression?.text,
          );
          return _StageOverlay(
            aim: slice.aim,
            sealedWhatSignature: slice.sealedWhatSignature,
            forbiddenMoves: slice.forbiddenMoves,
            responseLength: slice.responseLength,
            realizationDirective: slice.realizationDirective,
            userContent: slice.userContent,
            systemAppendix: slice.systemAppendix,
          );
        }
        // Observe / post-reframe listen / grounded hold: strip TF (mirror-only).
        // Phase 1 mechanism recognition uses `standard` so supported TF reaches
        // ReceiptIntelligence soft-hinge shaping (never canned GOLD lines).
        final observePurity = package.expressionMode ==
                ConversationExpressionMode.observePurity ||
            package.expressionMode ==
                ConversationExpressionMode.postReframeListen ||
            package.expressionMode == ConversationExpressionMode.groundedHold;
        final slice = receiptIntelligence.compile(
          stage: stage,
          conversationGrounding: package.conversationGrounding,
          thinkingFunctionHypothesis: observePurity
              ? null
              : package.understanding?.thinkingFunctionHypothesis,
          priorAdmittedExpression: package.priorAdmittedExpression,
          observePurity: observePurity,
          postReframeListen: package.expressionMode ==
              ConversationExpressionMode.postReframeListen,
          postRecognitionDeepen: package.postRecognitionDeepen,
        );
        return _StageOverlay(
          aim: slice.aim,
          sealedWhatSignature: slice.sealedWhatSignature,
          forbiddenMoves: slice.forbiddenMoves,
          responseLength: slice.responseLength,
          realizationDirective: slice.realizationDirective,
          userContent: slice.userContent,
          systemAppendix: slice.systemAppendix,
        );
      case BlueprintStage.naming:
        final slice = namingIntelligence.compile(
          stage: stage,
          conversationGrounding: package.conversationGrounding,
        );
        return _StageOverlay(
          aim: slice.aim,
          sealedWhatSignature: slice.sealedWhatSignature,
          forbiddenMoves: slice.forbiddenMoves,
          responseLength: slice.responseLength,
          realizationDirective: slice.realizationDirective,
          userContent: slice.userContent,
          systemAppendix: slice.systemAppendix,
        );
      case BlueprintStage.permission:
        final slice = permissionIntelligence.compile(
          stage: stage,
          conversationGrounding: package.conversationGrounding,
          thinkingFunctionHypothesis:
              package.understanding?.thinkingFunctionHypothesis,
          priorAdmittedExpression: package.priorAdmittedExpression,
        );
        return _StageOverlay(
          aim: slice.aim,
          sealedWhatSignature: slice.sealedWhatSignature,
          forbiddenMoves: slice.forbiddenMoves,
          responseLength: slice.responseLength,
          realizationDirective: slice.realizationDirective,
          userContent: slice.userContent,
          systemAppendix: slice.systemAppendix,
        );
      case BlueprintStage.release:
        final slice = releaseIntelligence.compile(
          stage: stage,
          conversationGrounding: package.conversationGrounding,
          thinkingFunctionHypothesis:
              package.understanding?.thinkingFunctionHypothesis,
          priorAdmittedExpression: package.priorAdmittedExpression,
        );
        return _StageOverlay(
          aim: slice.aim,
          sealedWhatSignature: slice.sealedWhatSignature,
          forbiddenMoves: slice.forbiddenMoves,
          responseLength: slice.responseLength,
          realizationDirective: slice.realizationDirective,
          userContent: slice.userContent,
          systemAppendix: slice.systemAppendix,
        );
      case BlueprintStage.enough:
        final slice = enoughIntelligence.compile(
          stage: stage,
          conversationGrounding: package.conversationGrounding,
          priorAdmittedExpression: package.priorAdmittedExpression,
          // Spoken rest-audio promise only when Exit already chose transition.
          authorizeRestAudioHandoff:
              package.exitDecision == ExitDecision.transitionToAudio,
        );
        return _StageOverlay(
          aim: slice.aim,
          sealedWhatSignature: slice.sealedWhatSignature,
          forbiddenMoves: slice.forbiddenMoves,
          responseLength: slice.responseLength,
          realizationDirective: slice.realizationDirective,
          userContent: slice.userContent,
          systemAppendix: slice.systemAppendix,
        );
      case BlueprintStage.neutralEntry:
        final slice = neutralEntryIntelligence.compile(
          stage: stage,
          conversationGrounding: package.conversationGrounding,
          lightChatMode:
              package.expressionMode == ConversationExpressionMode.lightChat,
        );
        return _StageOverlay(
          aim: slice.aim,
          sealedWhatSignature: slice.sealedWhatSignature,
          forbiddenMoves: slice.forbiddenMoves,
          responseLength: slice.responseLength,
          realizationDirective: slice.realizationDirective,
          userContent: slice.userContent,
          systemAppendix: slice.systemAppendix,
        );
    }
  }

  bool _admit(LlmInvocationPackage package) {
    // Speakable WHAT is already enforced by LlmInvocationPackage construction.
    // Re-check DNA binding presence for admission integrity.
    if (!identical(package.dna, ConversationDNA.instance)) {
      return false;
    }
    // Bounds must be bound (package getters always expose frozen bounds;
    // integrity against frozen lists is checked in Stage E).
    if (package.llmRequired.isEmpty ||
        package.llmAllowed.isEmpty ||
        package.llmForbidden.isEmpty) {
      return false;
    }
    return true;
  }

  bool _constitutionAvailable() {
    return ConversationConstitution.version == expectedConstitutionVersion &&
        ConversationConstitution.laws.isNotEmpty;
  }

  bool _philosophyAvailable() {
    return ConversationPhilosophy.version == expectedPhilosophyVersion &&
        ConversationPhilosophy.beliefs.isNotEmpty &&
        ConversationPhilosophy.stance.isNotEmpty;
  }

  bool _packageConstraintsIntact(LlmInvocationPackage package) {
    if (!identical(package.dna, ConversationDNA.instance)) {
      return false;
    }
    if (!_sameStrings(package.llmRequired, LlmContractBounds.required) ||
        !_sameStrings(package.llmAllowed, LlmContractBounds.allowed) ||
        !_sameStrings(package.llmForbidden, LlmContractBounds.forbidden)) {
      return false;
    }
    if (ConversationDNA.principles.isEmpty ||
        ConversationDNA.antiRules.isEmpty) {
      return false;
    }
    if (ConversationBlueprintCanon.version != expectedBlueprintVersion) {
      return false;
    }
    return true;
  }

  /// Stage F — field-specific optional shaping.
  ///
  /// Returns null to fail closed on illegal shaping.
  /// Never infers, summarizes, selects salience, changes WHAT, or invents grounding.
  ///
  /// Closed Stage F surface: understanding, workingMind, conversationGrounding.
  /// Typed [LlmInvocationPackage] cannot carry unknown dynamic shaping fields.
  ///
  /// Standalone [LlmInvocationPackage.livedExpression] is not part of the
  /// canonical Stage F surface (Amendment 003). It is ignored by Stage F
  /// (not materialized, not presence-bound). Receipt/Naming overlays may still
  /// read it until Task 11 cutover; Stage F must not treat it as shaping input.
  _StageFBinding? _bindOptionalShaping(LlmInvocationPackage package) {
    final hasUnderstanding = package.understanding != null;
    final hasWorkingMind = package.workingMind != null;
    final ConversationGroundingBuffer? grounding = package.conversationGrounding;
    final hasGrounding = grounding != null && !grounding.isEmpty;

    final presenceParts = <String>[];
    if (hasUnderstanding || hasWorkingMind) {
      // Presence-only: never render understanding / WorkingMind contents.
      presenceParts.add(
        'Attentive wording from supplied expression context is allowed. '
        'Do not narrate analysis, scores, patterns, memories, or storage. '
        'Do not render understanding or WorkingMind contents.',
      );
    }

    String? groundingMaterialization;
    if (hasGrounding) {
      // Deterministic materialization: fixed chronological user utterances only.
      final lines = grounding.userUtterances.map((u) => '- $u').join('\n');
      groundingMaterialization =
          'Same-night conversation grounding (user utterances only; '
          'shaping only; not decision authority):\n'
          '$lines\n'
          'Use only for wording continuity of the sealed WHAT. '
          'Do not infer, summarize, select salience, invent grounding, '
          'or change WHAT.';
    }

    if (presenceParts.isEmpty && groundingMaterialization == null) {
      return const _StageFBinding(
        shapingNote: 'No additional shaping context was supplied.',
        groundingMaterialization: null,
      );
    }

    final shapingNote = presenceParts.isEmpty
        ? 'Conversation grounding admitted for wording continuity only. '
            'Do not narrate analysis, scores, patterns, memories, or storage.'
        : presenceParts.join('\n');

    return _StageFBinding(
      shapingNote: shapingNote,
      groundingMaterialization: groundingMaterialization,
    );
  }

  CompiledInstructionPackage? _seal({
    required LlmInvocationPackage package,
    required BlueprintStageBinding stage,
    required String shapingNote,
    String? groundingMaterialization,
    _StageOverlay? overlay,
    ConversationExpressionMode expressionMode =
        ConversationExpressionMode.standard,
  }) {
    final aim = overlay?.aim ?? stage.aim;
    final signature =
        overlay?.sealedWhatSignature ?? stage.sealedWhatSignature;
    final forbiddenMoves = overlay?.forbiddenMoves ?? stage.forbiddenMoves;
    final responseLength = overlay?.responseLength ?? stage.responseLength;

    // Assembly completeness: required slices must be present.
    if (stage.purpose.isEmpty ||
        aim.isEmpty ||
        forbiddenMoves.isEmpty ||
        responseLength.isEmpty ||
        stage.questionPermission.isEmpty ||
        stage.restDirection.isEmpty ||
        signature.isEmpty) {
      return null;
    }

    final constitutional = List<String>.from(ConversationConstitution.laws);
    final philosophical = <String>[
      ...ConversationPhilosophy.beliefs,
      ...ConversationPhilosophy.stance,
    ];
    final dnaPrinciples = ConversationDNA.principles
        .map((p) => '${p.name}: ${p.rule}')
        .toList(growable: false);
    final dnaAntiRules = ConversationDNA.antiRules
        .map((r) => '${r.name}: ${r.reason}')
        .toList(growable: false);
    final llmRequired = List<String>.from(package.llmRequired);
    final llmAllowed = List<String>.from(package.llmAllowed);
    final llmForbidden = List<String>.from(package.llmForbidden);

    final realizationDirective = overlay?.realizationDirective ??
        'Realize only the sealed WHAT (${package.what.name} / '
            '${stage.stage.name}) as exactly one short utterance. '
            'Stay inside that WHAT semantic signature; do not drift into another '
            'phase. Do not choose release, protocol, exit, silence, or a different '
            'WHAT.';

    final languageBinding = languageStyle.compileBinding();
    final languageLock = _languageLockDirective(package);
    final baseUserContent = overlay?.userContent ?? realizationDirective;
    final userContent = _withLanguageStyle(
      languageLock == null
          ? baseUserContent
          : '$languageLock\n\n$baseUserContent',
      languageBinding,
    );

    final systemContent = _assembleSystemContent(
      stage: stage,
      aim: aim,
      signature: signature,
      forbiddenMoves: forbiddenMoves,
      responseLength: responseLength,
      constitutional: constitutional,
      philosophical: philosophical,
      dnaPrinciples: dnaPrinciples,
      dnaAntiRules: dnaAntiRules,
      llmRequired: llmRequired,
      llmAllowed: llmAllowed,
      llmForbidden: llmForbidden,
      shapingNote: shapingNote,
      groundingMaterialization: groundingMaterialization,
      realizationDirective: realizationDirective,
      stageAppendix: overlay?.systemAppendix,
      languageBinding: languageBinding,
      languageLock: languageLock,
      expressionMode: expressionMode,
    );

    if (systemContent.trim().isEmpty || userContent.trim().isEmpty) {
      return null;
    }

    // Preserve stage identity; overlay stage-intelligence fields onto a
    // compile-time binding snapshot for the sealed package output.
    final boundStage = BlueprintStageBinding(
      stage: stage.stage,
      sealedWhat: stage.sealedWhat,
      purpose: stage.purpose,
      aim: aim,
      forbiddenMoves: List<String>.from(forbiddenMoves),
      responseLength: responseLength,
      questionPermission: stage.questionPermission,
      restDirection: stage.restDirection,
      sealedWhatSignature: signature,
    );

    return CompiledInstructionPackage(
      sealedWhat: package.what,
      stage: boundStage,
      constitutionalConstraints: constitutional,
      philosophicalStance: philosophical,
      dnaPrinciples: dnaPrinciples,
      dnaAntiRules: dnaAntiRules,
      llmRequired: llmRequired,
      llmAllowed: llmAllowed,
      llmForbidden: llmForbidden,
      realizationDirective: realizationDirective,
      shapingNote: shapingNote,
      constitutionVersion: ConversationConstitution.version,
      philosophyVersion: ConversationPhilosophy.version,
      blueprintVersion: ConversationBlueprintCanon.version,
      systemContent: systemContent,
      userContent: userContent,
    );
  }

  String _withLanguageStyle(String content, String languageBinding) {
    return '$content\n\n${languageBinding.trim()}';
  }

  /// Hard same-language bind from the current user turn only.
  /// Mixed / unknown turns do not invent a lock.
  String? _languageLockDirective(LlmInvocationPackage package) {
    final turn = package.conversationGrounding?.currentUserUtterance;
    final lang = _nightLanguage(turn);
    if (lang == 'tr') {
      return 'LANGUAGE LOCK: the person wrote Turkish this turn. '
          'Reply in Turkish only. Every word must be Turkish. '
          'English is forbidden.';
    }
    if (lang == 'en') {
      return 'LANGUAGE LOCK: the person wrote English this turn. '
          'Reply in English only. Every word must be English. '
          'Turkish is forbidden.';
    }
    return null;
  }

  String? _nightLanguage(String? text) {
    if (text == null || text.trim().isEmpty) return null;
    final lower = text.toLowerCase();
    final hasTr = RegExp(r'[ğüşıöçâîû]').hasMatch(lower) ||
        lower.contains('gece') ||
        lower.contains('yalniz') ||
        lower.contains('yalnız') ||
        lower.contains('uyuyamiyorum') ||
        lower.contains('uyuyamıyorum') ||
        lower.contains('dusun') ||
        lower.contains('düşün') ||
        lower.contains('konusmak') ||
        lower.contains('konuşmak') ||
        lower.contains('bilmiyorum') ||
        lower.contains('kafam') ||
        lower.contains('aklim') ||
        lower.contains('aklım') ||
        lower.contains('ozledim') ||
        lower.contains('özledim') ||
        lower.contains('durmuyor') ||
        lower.contains('kafayi') ||
        lower.contains('kafayı') ||
        lower.contains('yarin') ||
        lower.contains('yarın') ||
        lower.contains('birak') ||
        lower.contains('bırak');
    final hasEn = RegExp(
      r"\b(i|you|your|the|tonight|don't|need|perhaps|mind|thinking|"
      r"can't|cannot|about|tomorrow|feel|feeling|idk|miss|him)\b",
    ).hasMatch(lower);
    if (hasTr && hasEn) return 'mixed';
    if (hasTr) return 'tr';
    if (hasEn) return 'en';
    return null;
  }

  String _assembleSystemContent({
    required BlueprintStageBinding stage,
    required String aim,
    required String signature,
    required List<String> forbiddenMoves,
    required String responseLength,
    required List<String> constitutional,
    required List<String> philosophical,
    required List<String> dnaPrinciples,
    required List<String> dnaAntiRules,
    required List<String> llmRequired,
    required List<String> llmAllowed,
    required List<String> llmForbidden,
    required String shapingNote,
    String? groundingMaterialization,
    required String realizationDirective,
    required String languageBinding,
    String? stageAppendix,
    String? languageLock,
    ConversationExpressionMode expressionMode =
        ConversationExpressionMode.standard,
  }) {
    final forbidden = forbiddenMoves.map((m) => '- $m').join('\n');
    final laws = constitutional.map((l) => '- $l').join('\n');
    final philosophy = philosophical.map((p) => '- $p').join('\n');
    final principles = dnaPrinciples.map((p) => '- $p').join('\n');
    final antiRules = dnaAntiRules.map((r) => '- $r').join('\n');
    final required = llmRequired.map((item) => '- $item').join('\n');
    final allowed = llmAllowed.map((item) => '- $item').join('\n');
    final llmForbiddenLines = llmForbidden.map((item) => '- $item').join('\n');
    final universal = ConversationBlueprintCanon.universalLaws
        .map((l) => '- $l')
        .join('\n');

    final appendixBlock =
        stageAppendix == null ? '' : '\n${stageAppendix.trim()}\n';
    final groundingBlock = groundingMaterialization == null
        ? ''
        : '\n${groundingMaterialization.trim()}\n';
    final lockBlock =
        languageLock == null ? '' : '${languageLock.trim()}\n\n';
    final questionRule = _questionRuleFor(expressionMode);

    return '''
${lockBlock}You are a transport HOW adapter. Realize only the sealed speakable WHAT.
Do not choose release, protocol, exit, silence, or a different WHAT.
Emit one natural conversational response.
On Receipt and Naming, use Golden Conversations V2 cadence: two short
lines — one specific observe, one hinge — not a telegram stamp and
not one dense clinical paragraph. Never a third restatement.
Never open Receipt with "It sounds like" / "It seems like".
Keep their night-objects (tomorrow, the list, the person). Never paste
their clause with I/you swapped.
Other stages stay to one short sentence.
$questionRule
Never ask more than one question.
No multi-message bundles. Prefer short spoken lines that land the felt truth.
Do not paste canned Gold library lines.
On Enough / continuity close, a soft rest-audio handoff line is welcome
(Golden Conversations V2 TYPE) — not a product pitch.
If the handoff landed, stop. Do not reuse Release night-hold imagery
(night can hold / let the night hold).
Never use bare generic filler such as "I understand", "I hear you", or "That makes sense".
Never pad with unsupported repetition of the user's words.
Reply in the same language as the current-turn user line. Do not switch.

$realizationDirective
$appendixBlock
${languageBinding.trim()}

Blueprint stage binding:
- Stage: ${stage.stage.name}
- Sealed WHAT: ${stage.sealedWhat.name}
- Purpose: ${stage.purpose}
- Aim: $aim
- Response length: $responseLength
- Question permission: ${stage.questionPermission}
- Rest direction: ${stage.restDirection}

Sealed WHAT semantic signature (realize this move only):
$signature

Stage forbidden moves:
$forbidden

Blueprint universal laws:
$universal

Constitutional constraints:
$laws

Philosophical stance:
$philosophy

Required:
$required

Allowed:
$allowed

Forbidden:
$llmForbiddenLines

Conversation DNA principles:
$principles

Conversation DNA anti-rules:
$antiRules

$shapingNote
$groundingBlock''';
  }

  String _questionRuleFor(ConversationExpressionMode expressionMode) {
    switch (expressionMode) {
      case ConversationExpressionMode.lightChat:
        return 'Light chat: exactly one natural follow-up question is allowed.';
      case ConversationExpressionMode.repair:
        return 'Repair: one short clarifying question is allowed after conceding the misread.';
      case ConversationExpressionMode.narrow:
        return 'Narrow: exactly one fork question is required. No other sentences.';
      case ConversationExpressionMode.reframe:
        return 'Reframe: no question on this turn — wait for their confirm/correct next turn.';
      case ConversationExpressionMode.observePurity:
        return 'Observe purity: questions are forbidden. No reframe on this turn.';
      case ConversationExpressionMode.postReframeListen:
        return 'Post-reframe listen: one brief acknowledgment only. No new reframe. No question.';
      case ConversationExpressionMode.integrate:
        return 'Integrate: no question. Connect confirmed reframe to tonight loop only.';
      case ConversationExpressionMode.closure:
        return 'Closure: no question. Tonight boundary + personalized put-down from their insight.';
      case ConversationExpressionMode.groundedHold:
        return 'Grounded hold: honest synthesis only. No question. No new psychology. Name uncertainty or repeat their surface anchor.';
      case ConversationExpressionMode.standard:
        return 'Questions are forbidden unless the stage explicitly allows them.';
    }
  }

  bool _sameStrings(List<String> actual, List<String> expected) {
    if (actual.length != expected.length) return false;
    for (var i = 0; i < actual.length; i++) {
      if (actual[i] != expected[i]) return false;
    }
    return true;
  }
}

/// Stage F binding: presence note + optional deterministic grounding material.
class _StageFBinding {
  final String shapingNote;
  final String? groundingMaterialization;

  const _StageFBinding({
    required this.shapingNote,
    required this.groundingMaterialization,
  });
}

/// Internal compile overlay shared by stage intelligences.
class _StageOverlay {
  final String aim;
  final String sealedWhatSignature;
  final List<String> forbiddenMoves;
  final String responseLength;
  final String realizationDirective;
  final String userContent;
  final String systemAppendix;

  const _StageOverlay({
    required this.aim,
    required this.sealedWhatSignature,
    required this.forbiddenMoves,
    required this.responseLength,
    required this.realizationDirective,
    required this.userContent,
    required this.systemAppendix,
  });
}
