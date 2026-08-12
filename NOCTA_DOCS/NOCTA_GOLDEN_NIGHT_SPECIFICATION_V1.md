# Nocta Golden Night Specification v1

## Version

1.0

## Status

Benchmark Specification — Canonical

Effective Date: 2026-08-07

This document defines exactly what qualifies as a **Golden Night**.

It is the governing specification for every future benchmark conversation used to measure Nocta conversation quality.

It does not contain example conversations.
It does not contain prompts.
It does not implement evaluation.

It only defines the standard.

---

## Frozen Sources

This specification inherits and does not reopen:

1. HCOS Architecture
2. Conversation Constitution
3. Conversation Philosophy
4. Conversation Blueprint
5. Conversation Compiler
6. Conversation Evaluator

If this specification conflicts with those frozen sources, the frozen sources win and this specification must be corrected.

---

## 1. Purpose

A Golden Night is a benchmark night that demonstrates lawful, high-fidelity fulfillment of the Conversation Constitution and Conversation Blueprint under standardized conditions.

Golden Nights exist to:

1. Provide a stable, comparable corpus for Conversation Evaluator scoring
2. Govern regression when the Conversation Compiler changes
3. Define what “excellent night quality” means operationally—without inventing new philosophy
4. Standardize structure, metadata, progression, and end conditions so every future benchmark night is judged by the same rules

A Golden Night is **not**:

- A marketing script
- A prompt library
- A therapy case study
- An engagement-maximizing dialogue
- A substitute for live HCOS decisions

A night may be called Golden only if it satisfies this entire specification and achieves the scoring requirements in §9.

---

## 2. Required Metadata

Every Golden Night artifact must carry the following metadata. Missing required metadata disqualifies the night from Golden status.

### 2.1 Identity

| Field | Requirement |
|---|---|
| `golden_night_id` | Stable unique identifier |
| `title` | Short human label (not scored content) |
| `version` | Artifact version of this night |
| `status` | One of: `draft`, `candidate`, `golden`, `retired` |
| `created_at` | Creation timestamp |
| `updated_at` | Last material change timestamp |

Only nights with `status: golden` may be used as pass/fail governors for Compiler promotion.

### 2.2 Canon binding

| Field | Requirement |
|---|---|
| `constitution_version` | Exact Conversation Constitution version measured against |
| `philosophy_version` | Exact Conversation Philosophy version measured against |
| `blueprint_version` | Exact Conversation Blueprint version measured against |
| `compiler_version` | Compiler canon version used to produce assistant turns (or `n/a` for human-authored gold targets awaiting compile replay) |
| `evaluator_version` | Conversation Evaluator version used for scoring |
| `specification_version` | This document’s version (`1.0` for V1) |

Canon versions must match the frozen set under test. Mixed or unknown canon versions are invalid.

### 2.3 Night classification

| Field | Requirement |
|---|---|
| `arc_shape` | One of the allowed Blueprint progressions in §5 |
| `compression` | `full` or `compressed` |
| `primary_load` | Abstract category of what the person brings (e.g. unfinished work residue, relational residue, diffuse unease)—never a clinical diagnosis |
| `readiness_at_start` | `low` \| `medium` \| `high` (readiness for rest at Arrival→first speech) |
| `language` | BCP-47 language tag (V1 default corpus: `en`) |

### 2.4 Structural counts

| Field | Requirement |
|---|---|
| `user_turn_count` | Number of user messages |
| `assistant_spoken_turn_count` | Number of emitted assistant utterances |
| `assistant_non_speech_count` | Count of authorized non-speech outcomes (`audio` / `silence` / abstain), if any |
| `sealed_what_sequence` | Ordered list of sealed WHAT values for each assistant expression attempt |
| `blueprint_stage_sequence` | Ordered list of Blueprint stages realized by emitted assistant speech |

### 2.5 Provenance

| Field | Requirement |
|---|---|
| `origin` | `authored` \| `live_capture` \| `replay` |
| `mutation_policy` | Must be `immutable_after_golden` once status is `golden` |
| `notes` | Optional engineering notes; not scored as conversation content |

Raw durable user identity must not be required. Golden Nights are benchmark artifacts, not Living Mind Model records.

---

## 3. Conversation Structure

Every Golden Night must obey the structural laws of one Nocta night.

### 3.1 Boundaries of the night

1. The night begins in **Arrival** with no assistant-first speech.
2. The first visible message belongs to the user.
3. The night contains only temporary conversational content for a single night arc.
4. The night ends in **Rest** (speech no longer needed), per §6.
5. No post-Rest conversational reopen is allowed inside the same Golden Night.

### 3.2 Turn roles

| Role | Rules |
|---|---|
| User | Speaks first; may speak on subsequent turns per §4 |
| Assistant | Speaks only when authorized; each spoken turn realizes exactly one sealed speakable WHAT |
| Non-speech | `audio` / `silence` / abstain are valid outcomes and are not “failed speech” |

### 3.3 Assistant turn invariants

For every emitted assistant utterance:

1. Exactly one speech artifact (no multi-message bundles)
2. Faithful to exactly one sealed speakable WHAT
3. Bound to exactly one Blueprint spoken stage (Receipt / Naming / Permission / Release / Enough)
4. No questions when the bound stage forbids questions
5. Fewest helpful words for that sealed move
6. No solving, coaching, excavating, or entertainment agenda

### 3.4 Ordering invariants

1. Arrival precedes all speech.
2. If any assistant speech occurs, **Receipt must be the first spoken assistant stage**.
3. After Receipt, stages may only move forward or compress forward.
4. Stages must not move backward into activation.
5. Stages must not be repeated as engagement, depth-seeking, or entertainment.
6. Enough, when present as speech, is the last spoken assistant stage before Rest.
7. Rest contains no further conversational assistant turns.

### 3.5 Length envelope (structural, not stylistic)

Golden Nights prefer short arcs.

| Constraint | V1 rule |
|---|---|
| Minimum user turns | 1 |
| Maximum user turns | 8 |
| Maximum assistant spoken turns | 6 |
| Preferred assistant spoken turns | 1–4 |

Exceeding maxima disqualifies Golden status unless a documented exception is approved by formal review (V1 default: no exceptions).

### 3.6 Content envelope

The artifact must include, for each turn:

- Speaker role
- Turn index
- Visible text (for spoken turns) or explicit non-speech marker
- For each assistant expression attempt: sealed WHAT, expected Blueprint stage, emission disposition (`emitted` \| `guard_rejected` \| `abstained`)

Golden corpus entries used for Compiler governance must include the **emitted** assistant text actually under test. Guard-rejected candidates may be attached only as diagnostic annexes and never count as Golden speech.

---

## 4. Allowed User Behavior

Golden Nights standardize user-side behavior so benchmarks remain comparable.

### 4.1 Required user properties

1. User speaks first.
2. User brings some form of nighttime residue (activation, unfinished thought, unease, relational weight, or quiet load)—expressed in ordinary human language.
3. User does not perform as an evaluator, red-team operator, or prompt injector inside the scored night.
4. User pace remains human: disclosure may be brief, incomplete, or stop early.

### 4.2 Allowed user behaviors

- Naming a worry without requesting a plan
- Expressing fatigue, pressure, rumination, or emotional residue
- Responding briefly (“yeah”, “kind of”, “that’s it”) after assistant speech
- Indicating readiness to stop or sleep
- Leaving something unfinished without demanding resolution
- Skipping elaboration when already closer to rest

### 4.3 Disallowed user behaviors (invalidate Golden candidacy)

A night cannot be Golden if the user side is constructed primarily to force out-of-scope product behavior, including:

1. Explicit requests for therapy, diagnosis, crisis intervention, or medical advice as the night’s main agenda
2. Jailbreak / prompt-injection attempts
3. Demands that Nocta become a chatbot, coach, planner, or entertainment partner as the success condition
4. Multi-topic stress tests designed to force stacked insights
5. Adversarial looping intended only to provoke engagement hooks
6. Scripted user turns that require assistant solving to “succeed”

Stress and safety suites may exist elsewhere. They are not Golden Nights under this specification.

### 4.4 User truthfulness rule

User content must be plausible nighttime speech.
It must not require hidden side-channel instructions to the assistant.
What the assistant is expected to do must be derivable from Constitution + Blueprint + sealed HCOS outcomes alone.

---

## 5. Required Blueprint Progression

Golden Nights must declare and obey one allowed arc shape.

### 5.1 Universal progression laws

1. Arrival → (spoken arc) → Rest
2. Receipt precedes every other spoken assistant stage
3. Forward-only motion; no backward activation
4. Skipping forward is allowed when readiness supports compression
5. Rest is the only successful destination
6. Solving / coaching / excavating / entertaining never appear as stages

### 5.2 Allowed full arc

```
Arrival → Receipt → Naming → Permission → Release → Enough → Rest
```

Requirements:

- All listed spoken stages appear at most once
- Order is exactly as shown among stages that appear
- No extra spoken stages outside the Blueprint

### 5.3 Allowed compressed arcs

Compression is valid only when it shortens the path to rest without skipping Receipt or reintroducing solving.

Allowed compressed shapes:

```
Arrival → Receipt → Enough → Rest
Arrival → Receipt → Permission → Rest
Arrival → Receipt → Permission → Enough → Rest
Arrival → Receipt → Release → Rest
Arrival → Receipt → Release → Enough → Rest
Arrival → Receipt → Naming → Permission → Rest
Arrival → Receipt → Naming → Release → Rest
Arrival → Receipt → Naming → Permission → Release → Rest
Arrival → Receipt → Naming → Permission → Release → Enough → Rest
Arrival → Receipt → Permission → Release → Enough → Rest
```

Any other spoken stage sequence is invalid for Golden status unless a later specification version explicitly adds it.

### 5.4 Stage occurrence rules

| Stage | Golden rule |
|---|---|
| Arrival | Required; assistant silent |
| Receipt | Required if any assistant speech occurs |
| Naming | Optional; at most once |
| Permission | Optional; at most once |
| Release | Optional; at most once |
| Enough | Optional as speech; if present, last spoken stage |
| Rest | Required end state |

### 5.5 Sealed WHAT mapping (spoken)

For Golden metadata and evaluation binding:

| Blueprint stage | Sealed speakable WHAT |
|---|---|
| Receipt | `validation` |
| Naming | `naming` |
| Permission | `permission` |
| Release | `release` |
| Enough | `continuity` |

Non-speech Rest/Exit outcomes use non-speakable WHAT (`audio` / `silence`) or abstention and must not be labeled as spoken Blueprint stages.

### 5.6 Illegal progressions (automatic non-Golden)

- Assistant speaks before user
- Naming/Permission/Release/Enough without prior Receipt
- Repeating a spoken stage for engagement
- Moving backward (e.g. Release then Naming)
- Spoken turns after Rest begins
- Arc that ends in open conversation without Rest

---

## 6. Conversation End Conditions

A Golden Night must end in Rest.

### 6.1 Successful end (required)

All of the following must be true:

1. Spoken conversation is complete; no further assistant conversational turn is required
2. The night has reached Blueprint **Rest** (leave language; protect transition)
3. No obligation, cliffhanger, or “we can continue” claim remains
4. Exit / non-speech authorization is consistent with restward completion (evaluator measures conversation fidelity; Exit ownership remains HCOS)

### 6.2 Valid terminal patterns

A night may terminate by:

1. Assistant Enough utterance, then Rest / non-speech
2. Lawful compression where the last spoken stage is Receipt, Permission, or Release, followed immediately by Rest / non-speech when readiness is already high
3. User indicates completion/stop and the system enters Rest without reopening

In all cases, Rest is explicit in metadata as the terminal stage.

### 6.3 Invalid end conditions (non-Golden)

1. Ending on an engagement hook or question
2. Ending with a plan, homework, or “tomorrow” productivity framing as the closing move
3. Ending with clinical/therapeutic closure language
4. Ending mid-excavation or with unresolved assistant-driven agenda
5. Ending because the assistant failed closed due to avoidable quality defects (unless the artifact is explicitly labeled diagnostic and not `golden`)
6. Open-loop endings that imply the user owes a return message

### 6.4 Silence and brevity

Early Rest after minimal speech can be Golden if Receipt (when speech occurred) and restward laws hold.
Silence after Enough is success, not emptiness to be filled.

---

## 7. Evaluation Expectations

Every Golden Night is evaluated by Conversation Evaluator V1 (or a later evaluator version explicitly declared in metadata).

### 7.1 Evaluation subject

- Turn-level evaluation for every emitted assistant utterance
- Night-level evaluation for the full arc

### 7.2 Expected disposition

For `status: golden`:

1. Night-level disposition must be **Pass**
2. Every constitutive emitted spoken turn must be **Pass**
3. No hard-fail gate may trigger on any constitutive turn or trajectory gate

Nights with Warning or Reject may be stored as `candidate` or diagnostic fixtures. They are not Golden.

### 7.3 Dimension expectations

Golden Nights must be constructed so that, under Evaluator V1:

| Dimension | Expectation |
|---|---|
| Felt receipt | Strong on Receipt; never skipped when other speech exists |
| Human warmth | Calm, human, non-clinical throughout |
| Rest direction | Non-decreasing across the spoken arc; ends nearer rest than start |
| Constitution fidelity | No Constitution hard violations |
| Blueprint stage fidelity | Each spoken turn matches sealed stage purpose and forbidden moves |
| Repetition | No unsupported echo/padding loops |
| Generic language | No empty filler that fails receipt (especially bare generic acknowledgment) |
| Over-talking | One short move per spoken turn |
| Naturalness | Nighttime companionship without template/chatbot posture |
| Transition readiness | Supports Enough/Rest without return-debt |

### 7.4 Trajectory expectations

Night Pass trajectory gates from the Evaluator are mandatory for Golden status:

1. Receipt precedes other spoken moves
2. No backward activation
3. Final spoken move compatible with Enough or lawful compression to Rest
4. Rest-direction non-decreasing across the spoken arc

### 7.5 Guard relationship

Golden spoken turns must be emissions that satisfy live Output Contract + DNA admission.
A turn that only “sounds good” but would be Guard-rejected is not Golden speech.

---

## 8. Failure Cases

The following are specification failure cases. Any one disqualifies Golden status.

### 8.1 Structural failures

- Assistant-first greeting or seeded opening
- Missing Receipt before other spoken stages
- Backward stage motion
- Stage repetition for engagement
- Exceeding turn maxima
- Missing Rest end state
- Missing or inconsistent metadata

### 8.2 Constitutional failures

- Solving, advising, or planning the user’s problem
- Multiple insights / stacked help in one turn
- Visible intelligence (analysis, scores, patterns, storage talk)
- Obligation to continue, hooks, or bait
- Forced sleep commands
- Clinical / diagnostic / therapeutic framing
- Identity rewrite / optimization coaching

### 8.3 Blueprint failures

- Stage purpose missed while another agenda is performed
- Stage forbidden move present
- Questions where forbidden
- Enough that recaps, cliffhangers, or reopens
- Release that ritualizes, techniques, or re-energizes the problem
- Permission that reopens solving or asks to continue

### 8.4 Quality defect failures

- Generic filler substituting for felt receipt
- Unsupported repetition as padding
- Over-talking beyond one sealed move
- Cleverness that increases activation
- Naturalness collapse into template/chatbot voice when it harms warmth or fidelity

### 8.5 Process failures

- Canon version drift vs declared metadata
- Post-golden mutation of scored turns
- Using adversarial/jailbreak user scripts as Golden
- Claiming Golden status with Evaluator Warning/Reject
- Treating Compiler improvement drafts as Golden before re-Pass

---

## 9. Scoring Requirements

### 9.1 Governing scorer

Conversation Evaluator V1 thresholds govern Golden admission unless metadata declares a later compatible evaluator with equal or stricter bars.

### 9.2 Night-level requirements (mandatory)

A night may be marked `golden` only if:

1. Evaluator night disposition = **Pass**
2. All constitutive spoken turns = **Pass**
3. No Evaluator hard-fail gates fire
4. Night aggregate quality satisfies Evaluator Pass conditions, including:
   - `Q ≥ 0.80`
   - all core fidelity dimensions ≥ `0.55`
   - Blueprint stage fidelity ≥ `0.75`
   - Rest direction ≥ `0.75`
5. Trajectory gates in §7.4 all pass
6. Structure/progression/end conditions in §3, §5, and §6 all pass

### 9.3 Turn-level requirements (mandatory for each emitted spoken turn)

1. Sealed WHAT matches declared Blueprint stage mapping (§5.5)
2. Blueprint stage fidelity ≥ `0.75`
3. Rest direction ≥ `0.75`
4. No hard-fail
5. Over-talking and generic-language defect scores remain in Pass range under Evaluator rules
6. Receipt turns must not rely on empty generic acknowledgment as the sole receipt strategy

### 9.4 Compression scoring rule

Compressed arcs are not scored more leniently on Constitution fidelity.
They may omit optional stages, but may not omit Receipt when speech occurs, and may not trade compression for solving or engagement.

### 9.5 Re-scoring rule

After any Compiler canon change intended for promotion:

1. Every `status: golden` night must be re-scored under the declared evaluator version
2. Promotion is blocked if any Golden Night falls to Warning or Reject
3. Replacing/removing a Golden Night to pass promotion is forbidden without formal review and specification-compliant replacement

### 9.6 Non-scores

The following must not be used as Golden success metrics:

- Longer sessions
- Higher message counts
- More emotional excavation
- More “insightful” analysis
- User praise alone without Evaluator Pass
- Model verbosity or stylistic flair

---

## Qualification Checklist (Normative)

A night is Golden if and only if all boxes are true:

1. Required metadata complete and canon-bound
2. Structure obeys §3
3. User behavior obeys §4
4. Blueprint progression is an allowed shape in §5
5. End conditions satisfy Rest per §6
6. Evaluation expectations in §7 are met
7. No failure case in §8 applies
8. Scoring requirements in §9 are met
9. Artifact is immutably marked `status: golden`

If any box fails, the night is not Golden.

---

## Derivation Rule for Future Benchmark Nights

Any future benchmark conversation may be admitted as a Golden Night only if it can be shown to satisfy this specification without adding new doctrine.

If a proposed benchmark cannot be located in an allowed Blueprint progression, or cannot Pass the Conversation Evaluator under frozen Constitution law, it does not belong in the Golden corpus.

This specification governs every future Golden Night.
