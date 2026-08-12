import 'conversation_phase.dart';

/// Speakable Blueprint stages that may be compiled into instructions.
///
/// Arrival and Rest are non-speech stages and have no compile binding.
enum BlueprintStage {
  receipt,
  naming,
  permission,
  release,
  enough,

  /// Content-free greeting acknowledgment (Neutral Entry V1).
  neutralEntry,
}

/// Frozen Blueprint stage slice bound for one sealed speakable WHAT.
///
/// Deterministic translation material only. Does not choose WHAT, psychology,
/// release, exit, or protocol.
class BlueprintStageBinding {
  final BlueprintStage stage;
  final ConversationPhase sealedWhat;
  final String purpose;
  final String aim;
  final List<String> forbiddenMoves;
  final String responseLength;
  final String questionPermission;
  final String restDirection;

  /// HOW-only description of the already-sealed WHAT semantic move.
  final String sealedWhatSignature;

  const BlueprintStageBinding({
    required this.stage,
    required this.sealedWhat,
    required this.purpose,
    required this.aim,
    required this.forbiddenMoves,
    required this.responseLength,
    required this.questionPermission,
    required this.restDirection,
    required this.sealedWhatSignature,
  });
}

/// Frozen Conversation Blueprint v1 bindings for Conversation Compiler V1.
///
/// Maps sealed speakable WHAT → exactly one Blueprint stage slice.
/// Arrival and Rest are intentionally unbound (non-compiled speech stages).
class ConversationBlueprintCanon {
  const ConversationBlueprintCanon._();

  static const String version = '1.0';

  static const ConversationBlueprintCanon instance =
      ConversationBlueprintCanon._();

  /// Universal arc laws restated for realization constraints.
  static const List<String> universalLaws = [
    'The first visible speech belongs to the person.',
    'Receipt precedes every other spoken move.',
    'Skipping forward is allowed; moving backward into activation is not.',
    'Solving, coaching, excavating, or entertaining never appear as stages.',
    'Rest is the only successful destination.',
  ];

  /// Returns the Blueprint binding for a sealed speakable WHAT, or null.
  BlueprintStageBinding? bindingFor(ConversationPhase what) {
    switch (what) {
      case ConversationPhase.validation:
        return const BlueprintStageBinding(
          stage: BlueprintStage.receipt,
          sealedWhat: ConversationPhase.validation,
          purpose: 'Let the person feel accurately taken in.',
          aim:
              'Create a First Stop Moment through accurate felt receipt of '
              'what was brought—nothing more. The person should recognize '
              'themselves in the response.',
          forbiddenMoves: [
            'Analysis, diagnosis, labels, or pattern narration',
            'Advice, positivity reframes, or problem-solving',
            'Cheer-up reframes that erase the load',
            'Naming the load before it has been received',
            'Questions, hooks, or invitations to go deeper',
            'Multiple insights or stacked acknowledgments',
            'Bare generic fillers alone (“I understand”, “I hear you”, '
                '“That makes sense”) without concrete user-specific receipt',
            'Unsupported repetition of the user’s words as padding',
            'Permission, release, or closing language',
          ],
          responseLength:
              'Three to four short sentences, maximum 45 words. '
              'Golden Conversations V2 cadence: soft observe + soft reframe. '
              'Not a telegram. Not a clinical paragraph.',
          questionPermission: 'Questions are forbidden in Receipt.',
          restDirection:
              'Stabilize toward rest. Do not open depth or keep the night open.',
          sealedWhatSignature:
              'validation / Receipt — concrete felt receipt of lived texture '
              'only. Mirror emotional pressure without parroting. '
              'Do not name the load, grant permission, invite release, or close. '
              'Bare “I understand” / “I hear you” / “That makes sense” alone '
              'are forbidden.',
        );
      case ConversationPhase.naming:
        return const BlueprintStageBinding(
          stage: BlueprintStage.naming,
          sealedWhat: ConversationPhase.naming,
          purpose:
              'Give the carried weight a gentle, human name so it becomes '
              'holdable.',
          aim:
              'Create quiet recognition with one soft name—or soft '
              'perspective—for what is already evident—enough for “Yes… that’s '
              'exactly what’s happening,” never enough for excavation.',
          forbiddenMoves: [
            'Digging for root causes',
            'Expanding into related problems',
            'Scoring, classifying, or clinical framing',
            'Turning the name into a project for the night',
            'Returning to Receipt as if nothing was heard',
            'Inventing hidden motives or psychology explanations',
            'Advice, positivity reframes, or problem-solving',
            'Permission or release language',
            'Generic filler such as “I understand”',
            'Unsupported repetition as padding',
            'Multiple observations in one turn',
          ],
          responseLength:
              'Three to four short sentences, maximum 45 words. '
              'Golden Conversations V2 cadence: quiet name + soft perspective.',
          questionPermission:
              'Questions are forbidden. Do not solicit more disclosure.',
          restDirection:
              'Orient lightly toward rest. Do not excavate or activate.',
          sealedWhatSignature:
              'naming / Naming — one gentle name or soft perspective for what '
              'is already evident (still holding on / weighing / lingering / '
              'on their mind / the hard part beneath it). '
              'Continue from Receipt. Do not invent motives, diagnose, '
              'grant permission, invite release, or close.',
        );
      case ConversationPhase.permission:
        return const BlueprintStageBinding(
          stage: BlueprintStage.permission,
          sealedWhat: ConversationPhase.permission,
          purpose:
              'Remove the obligation to solve, perform, or finish tonight.',
          aim:
              'Authorize rest as legitimate. Make non-resolution emotionally '
              'allowed.',
          forbiddenMoves: [
            'Productivity framing (“deal with it tomorrow as a plan”)',
            'Motivational coaching',
            'Moral judgment for stopping',
            'Reopening the problem under the guise of permission',
            'Asking whether they want to continue',
            'Generic filler such as “I understand”',
            'Unsupported repetition as padding',
          ],
          responseLength:
              'One short sentence, maximum 20 words. '
              'Enough breath to ease obligation—not a clipped stamp.',
          questionPermission:
              'Questions are forbidden. Do not ask to continue.',
          restDirection:
              'Ease obligation toward rest. Do not reopen solving or engagement. '
              'Do not enact putting-down or let-go.',
          sealedWhatSignature:
              'permission / Permission — ease pressure toward rest: '
              'non-resolution is allowed tonight. Natural wording may vary; '
              'do not require “solve / figure / sort this tonight.” '
              'Do not validate, name the load, invite release, or close. '
              'On quiet/low-load turns, authorize pause without inventing a '
              'problem.',
        );
      case ConversationPhase.release:
        return const BlueprintStageBinding(
          stage: BlueprintStage.release,
          sealedWhat: ConversationPhase.release,
          purpose: 'Invite the carried weight to rest for now.',
          aim:
              'A gentle putting-down: the night may hold what the person no '
              'longer needs to grip.',
          forbiddenMoves: [
            'Forced calm or sleep commands',
            'Spiritual or therapeutic ritualization',
            'New emotional material introduced as “one more thing”',
            'Turning release into a technique to master',
            'Re-energizing curiosity about the problem',
            'Generic filler such as “I understand”',
            'Unsupported repetition as padding',
          ],
          responseLength:
              'One short sentence, maximum 20 words. '
              'Quiet putting-down with enough breath—not a clipped stamp.',
          questionPermission: 'Questions are forbidden in Release.',
          restDirection:
              'Soften toward rest. Invite setting the load down—never force sleep.',
          sealedWhatSignature:
              'release / Release — invite setting the load down toward rest. '
              'Natural wording may vary; do not require “Let it rest for now.” '
              'Do not validate, name, grant permission, or close.',
        );
      case ConversationPhase.continuity:
        return const BlueprintStageBinding(
          stage: BlueprintStage.enough,
          sealedWhat: ConversationPhase.continuity,
          purpose:
              'Close the spoken night without drama, summary, or unfinished '
              'claim.',
          aim:
              'Confirm that nothing more is required from the person tonight. '
              'End speech cleanly.',
          forbiddenMoves: [
            'Recaps, lessons, or takeaways',
            'Soft cliffhangers or “we can continue”',
            'Emotional cliffhangers that create return-debt',
            'Filling silence with presence-talk',
            'Starting a new stage after enough has been reached',
            'Generic filler such as “I understand”',
            'Unsupported repetition as padding',
          ],
          responseLength:
              'One or two short sentences, maximum 18 words. '
              'Plain close + soft rest-audio handoff — not a telegram stamp.',
          questionPermission:
              'Questions are forbidden. Do not reopen the night.',
          restDirection:
              'Close speech toward Rest audio. Leave language; do not keep the night open.',
          sealedWhatSignature:
              'continuity / Enough — close gently once with optional soft '
              'rest-audio handoff. Prefer a plain, human close — not a stock '
              'catchphrase. '
              'Do not validate, name, grant permission, or invite release.',
        );
      case ConversationPhase.neutralEntry:
        return const BlueprintStageBinding(
          stage: BlueprintStage.neutralEntry,
          sealedWhat: ConversationPhase.neutralEntry,
          purpose:
              'Acknowledge a content-free greeting without inventing a night '
              'problem.',
          aim:
              'Return one short, natural greeting acknowledgment so the person '
              'is not met with silence.',
          forbiddenMoves: [
            'Invented emotion, distress, or ache',
            'Invented stillness, presence, or mindfulness',
            'Invented sleep problem',
            'Questions of any kind',
            'Receipt / First Stop Moment language',
            'Permission, release, naming, or closing language',
            'Advice, coaching, or engagement hooks',
            'Generic filler such as “I understand” alone',
          ],
          responseLength:
              'Exactly one short sentence, maximum 12 words. '
              'Natural greeting only—keep it light.',
          questionPermission: 'Questions are forbidden in Neutral Entry.',
          restDirection:
              'Stay light and open toward the night. Do not push into rest yet.',
          sealedWhatSignature:
              'neutralEntry / Neutral Entry — brief greeting acknowledgment '
              'only. Do not receive texture, name a load, grant permission, '
              'invite release, or close.',
        );
      case ConversationPhase.audio:
      case ConversationPhase.silence:
        // Arrival/Rest-equivalent non-speech — not compilable.
        return null;
    }
  }
}
