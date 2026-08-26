import 'thinking_function_hypothesis.dart';
import 'thinking_function_kind.dart';

/// Stage HOW shaping doctrine for [ThinkingFunctionHypothesis].
///
/// Reasoning targets only — never a reply library, never keyword→reply,
/// never phase/readiness/exit/memory authority. Never emits runtime enum
/// names into user-visible prompt language.
class ThinkingFunctionIntelligenceShaping {
  const ThinkingFunctionIntelligenceShaping._();

  /// Supported band floor (matches detector contract).
  static const double supportedFloor = 0.65;

  /// Strong band floor (matches detector contract).
  static const double strongFloor = 0.80;

  static bool isSupportedOrStrong(ThinkingFunctionHypothesis? hypothesis) {
    return hypothesis != null && hypothesis.confidence >= supportedFloor;
  }

  static bool isTentativeOnly(ThinkingFunctionHypothesis? hypothesis) {
    return hypothesis != null &&
        hypothesis.confidence >= 0.45 &&
        hypothesis.confidence < supportedFloor;
  }

  static bool isStrong(ThinkingFunctionHypothesis hypothesis) {
    return hypothesis.confidence >= strongFloor;
  }

  /// Human prose label for compile steering (never camelCase enum ids).
  static String humanFunctionLabel(ThinkingFunctionKind kind) {
    switch (kind) {
      case ThinkingFunctionKind.protectiveHolding:
        return 'protective holding / keeping watch';
      case ThinkingFunctionKind.preparationRehearsal:
        return 'preparation / readiness pressure';
      case ThinkingFunctionKind.earlyTomorrowCarry:
        return 'carrying tomorrow into tonight';
      case ThinkingFunctionKind.worstCaseRehearsal:
        return 'rehearsing worst-case futures';
      case ThinkingFunctionKind.certaintyChase:
        return 'chasing certainty through one more thought';
    }
  }

  /// Receipt: MUST realize exactly one soft functional hinge (supported+ only).
  static String receiptHingeDirective(ThinkingFunctionHypothesis hypothesis) {
    final soft = isStrong(hypothesis)
        ? 'Slightly more direct functional wording is allowed, but stay soft—'
            'never hard diagnosis, never certainty about motives.'
        : 'Prefer epistemically soft framing: part of your mind / perhaps / '
            'it may be / almost as if.';

    final hinge = switch (hypothesis.kind) {
      ThinkingFunctionKind.earlyTomorrowCarry =>
        'Required hinge TYPE (not a fixed reply): cross from surface '
            'activation to temporal carrying/import. '
            'INSUFFICIENT TYPE (activation/content only—not the hinge): '
            'mind/thoughts busy with tomorrow; swirling around tomorrow; '
            'racing about tomorrow; spinning around tomorrow. '
            'REQUIRED FUNCTION TYPE (semantic types only—not fixed replies): '
            'attention already moved into tomorrow; tomorrow being mentally '
            'carried into tonight; part of the mind already living tomorrow '
            'before it arrives; future load brought into the present night. '
            'Anti-equivalence: busy/swirl/race/spin + tomorrow does NOT count '
            'as the authorized carrying-tomorrow-into-tonight functional hinge.',
      ThinkingFunctionKind.preparationRehearsal =>
        'Required hinge TYPE (not a fixed reply): notice that stopping may feel '
            'like being less prepared.',
      ThinkingFunctionKind.protectiveHolding =>
        'Required hinge TYPE (not a fixed reply): notice that stopping may feel '
            'costly / less safe than continuing to hold.',
      ThinkingFunctionKind.worstCaseRehearsal =>
        'Required hinge TYPE (not a fixed reply): notice that the mind may be '
            'rehearsing possible futures / preparing against being blindsided.',
      ThinkingFunctionKind.certaintyChase =>
        'Required hinge TYPE (not a fixed reply): notice that relief may keep '
            'being promised after one more thought.',
    };

    return 'Thinking-function Receipt (HOW only): authorized soft recognition '
        'of ${humanFunctionLabel(hypothesis.kind)}. '
        'Reasoning target: surface content → plausible function of thinking '
        '(NOT surface content → synonym/paraphrase of surface content). '
        'MUST realize exactly ONE soft functional recognition hinge—not an '
        'essay, not Naming, not Permission, not Release. '
        'Activation description is texture, not recognition. '
        'Do not stop at describing motion when an authorized function '
        'hypothesis exists. Anti-paraphrase: swirling / racing / spinning / '
        'busy / looping alone is not enough. No therapist cadence. '
        '$soft $hinge';
  }

  /// Post-Recognition deepen / integrate-lite (HOW only).
  ///
  /// Adds one layer beyond Recognition — do not restate the same hinge.
  static String deepenHingeDirective(ThinkingFunctionHypothesis hypothesis) {
    final layer = switch (hypothesis.kind) {
      ThinkingFunctionKind.worstCaseRehearsal ||
      ThinkingFunctionKind.preparationRehearsal =>
        'Deepen TYPE (not a fixed reply): they confirmed thinking-as-preparation. '
            'Integrate one soft implication — that the preparation process itself '
            'may keep the mind active tonight. Do NOT restate “you think through '
            'possibilities to feel prepared” as the whole turn. Do NOT assert '
            'protection/safety motives. Do NOT grant Permission or Release.',
      ThinkingFunctionKind.earlyTomorrowCarry =>
        'Deepen TYPE (not a fixed reply): one soft implication that carrying '
            'tomorrow may itself keep tonight occupied — not a restatement of '
            'the first recognition hinge.',
      ThinkingFunctionKind.certaintyChase =>
        'Deepen TYPE (not a fixed reply): one soft implication that chasing '
            'one-more-thought may itself keep the loop running — not a repeat '
            'of the first recognition.',
      ThinkingFunctionKind.protectiveHolding =>
        'Deepen TYPE (not a fixed reply): one soft implication that the holding '
            'job itself may keep the system active — only if their words support '
            'holding. Never invent protection.',
    };

    return 'Thinking-function deepen / integrate-lite (HOW only): authorized '
        'job is ${humanFunctionLabel(hypothesis.kind)}. '
        'Recognition already happened — do not duplicate it. $layer '
        'Stay epistemically soft. Night-short. No diagnosis. No therapist cadence.';
  }

  /// Permission: reduce the obligation created by the mind-job.
  static String permissionObligationDirective(
    ThinkingFunctionHypothesis hypothesis,
  ) {
    final obligation = switch (hypothesis.kind) {
      ThinkingFunctionKind.preparationRehearsal =>
        'Obligation TYPE (not a fixed reply): not required to keep preparing '
            'tonight.',
      ThinkingFunctionKind.protectiveHolding =>
        'Obligation TYPE (not a fixed reply): not required to keep watch / '
            'keep holding tonight.',
      ThinkingFunctionKind.earlyTomorrowCarry =>
        'Obligation TYPE (not a fixed reply): not required to carry all of '
            'tomorrow tonight.',
      ThinkingFunctionKind.worstCaseRehearsal =>
        'Obligation TYPE (not a fixed reply): not required to keep rehearsing '
            'possibilities tonight.',
      ThinkingFunctionKind.certaintyChase =>
        'Obligation TYPE (not a fixed reply): not required to reach certainty '
            'tonight.',
    };

    return 'Thinking-function Permission (HOW only): authorized mind-job is '
        '${humanFunctionLabel(hypothesis.kind)}. $obligation '
        'Speech-act: reduce obligation only—do not put down / let go / set '
        'down the job (that is Release). Do not solve. Do not diagnose. Do not '
        'name internal labels. Stay epistemically soft unless confidence is '
        'clearly strong. Vary only inside the Permission realization contract.';
  }

  /// Release: put down the job, not a generic “let go.”
  static String releaseJobDirective(ThinkingFunctionHypothesis hypothesis) {
    final job = switch (hypothesis.kind) {
      ThinkingFunctionKind.preparationRehearsal =>
        'Put-down TYPE (not a fixed reply): invite pausing preparation.',
      ThinkingFunctionKind.protectiveHolding =>
        'Put-down TYPE (not a fixed reply): invite stopping the keep-watch / '
            'holding job.',
      ThinkingFunctionKind.earlyTomorrowCarry =>
        'Put-down TYPE (not a fixed reply): invite leaving tomorrow where it is.',
      ThinkingFunctionKind.worstCaseRehearsal =>
        'Put-down TYPE (not a fixed reply): invite letting the rehearsal stop '
            'for now.',
      ThinkingFunctionKind.certaintyChase =>
        'Put-down TYPE (not a fixed reply): invite pausing the search.',
    };

    return 'Thinking-function Release (HOW only): authorized mind-job is '
        '${humanFunctionLabel(hypothesis.kind)}. Put down that JOB—not a '
        'generic let-go stamp. $job Do not diagnose. Do not solve. Do not emit '
        'internal labels.';
  }

  /// Narrow: mechanism fork TYPE when supported TF exists (Phase 2).
  ///
  /// Reasoning targets only — never a fixed question bank.
  static String narrowMechanismDirective(ThinkingFunctionHypothesis hypothesis) {
    final fork = switch (hypothesis.kind) {
      ThinkingFunctionKind.worstCaseRehearsal =>
        'Fork TYPE (not a fixed reply): split rehearsing/generating bad '
            'possible futures vs seeking certainty because the unknown feels '
            'unfinished — soft only. Do NOT assert protection/safety motives. '
            'Preparation/anti-blindsiding may appear as one soft side only if '
            'their words already suggest getting ready — never invent it.',
      ThinkingFunctionKind.earlyTomorrowCarry =>
        'Fork TYPE (not a fixed reply): split carrying tomorrow into tonight '
            'vs general night activation without temporal import.',
      ThinkingFunctionKind.preparationRehearsal =>
        'Fork TYPE (not a fixed reply): split readiness/preparation pressure '
            'vs open uncertainty without a prep job — only if their words '
            'support prep language.',
      ThinkingFunctionKind.certaintyChase =>
        'Fork TYPE (not a fixed reply): split chasing one-more-thought '
            'certainty vs holding a settled worry without more figuring.',
      ThinkingFunctionKind.protectiveHolding =>
        'Fork TYPE (not a fixed reply): split keeping-watch/holding vs plain '
            'continuation of thoughts — only if holding/safety language is '
            'already in their words. Never invent protection.',
    };

    return 'Thinking-function Narrow (HOW only): authorized soft job is '
        '${humanFunctionLabel(hypothesis.kind)}. $fork '
        'Ask one original or/yoksa question. No GOLD paste. No diagnosis.';
  }
}
