# HCOS Conversation LLM Contract v1

## Version

1.0

## Status

Architecture Design — Sprint 5 Canonical

Effective Date: 2026-08-06

This document is the canonical architecture specification for the Conversation LLM Contract.

It defines the boundary between PromptArchitecture and LanguageModelClient inside the Conversation expression plane.

It does not modify HCOS Architecture v1.1.

HCOS Architecture v1.1 remains frozen and authoritative for overall HCOS ownership, turn order, memory lifecycle, and product purpose.

Architectural changes to this contract require a formal Architecture Review.

## Purpose

After upstream HCOS judgment is complete, Conversation must turn authorized decisions into either one user-facing utterance or no conversational language.

The Conversation LLM Contract freezes how that expression handoff works:

- PromptArchitecture packages constrained expression intent.
- LanguageModelClient realizes that intent as natural language.
- ConversationEngine owns the final speech outcome for the turn.
- UtteranceGuard validates emission against the Output Contract and Conversation DNA.

The language model is an expression mechanism only.

It is never a cognitive owner.

## Source Contracts

This design inherits and does not reopen:

- HCOS Architecture v1.1
- Conversation Stage Responsibilities
- Conversation Input Contract
- Conversation Output Contract
- LLM Contract (required / allowed / forbidden)
- Prompt Architecture responsibilities
- Conversation DNA principles and anti-rules (enduring response character only; not V2 adaptive Conversation DNA)

## Position in the Pipeline

Canonical turn path remains:

Release → ConversationPolicy → Exit → Conversation

Inside Conversation, the expression path is:

```
ConversationDecision + ExitDecision
(+ optional ValidatedUnderstanding, WorkingMindView)
        │
        ▼
PromptArchitecture
        │
        ├── abstain ──────────────────────────────► no conversational language
        │
        └── LlmInvocationPackage
                    │
                    ▼
          LanguageModelClient
                    │
                    ▼
          candidate ConversationUtterance
                    │
                    ▼
             UtteranceGuard
                    │
                    ├── reject ───────────────────► no conversational language
                    │
                    └── allow
                          │
                          ▼
              ConversationEngine emits
              final ConversationUtterance
```

Upstream cognitive owners remain ReleaseEngine, ConversationPolicy, and ExitIntelligence.

Conversation does not re-decide release, protocol, or exit.

## Design Principles for This Contract

1. WHAT is sealed before the model runs.
2. HOW is linguistic realization only.
3. Invocation is optional; abstention is a valid expression outcome.
4. Exactly one speech outcome leaves Conversation: one utterance, or none.
5. Conversation DNA is binding on every emitted response.
6. Validation is mandatory after model return and before stage emission.
7. Forward-only flow: expression never revises upstream decisions in the same turn.
8. Persistent memory remains outside the expression plane.

---

## 1. Exact Input the LLM Receives

The LLM receives exactly one `LlmInvocationPackage`.

No other invocation input is canonical.

### Package contents

| Field | Role | Mutability at invoke |
|---|---|---|
| `what` | Sealed expression intent (`ConversationPhase`) | Immutable |
| `understanding` | Optional wording-shaping context | Read-only shaping |
| `workingMind` | Optional wording-shaping context | Read-only shaping |
| `dna` | Bound Conversation DNA constraints | Immutable reference |
| `llmRequired` | Bound LLM Contract required duties | Immutable |
| `llmAllowed` | Bound LLM Contract allowed duties | Immutable |
| `llmForbidden` | Bound LLM Contract forbidden duties | Immutable |

### Authorized speakable WHAT values

Only these phases may appear in an invoked package:

- validation
- naming
- permission
- release
- continuity

### Inputs that must never reach the LLM

- ReleaseDecision or release judgment
- Direct Living Mind Model
- Raw conversation transcript as authority
- Memory-write authority
- Deprecated ReasoningDecision
- Alternate or candidate WHAT values
- Permission to choose silence vs speech
- Permission to choose exit or protocol phase

### Invocation eligibility

The LLM is invoked only when PromptArchitecture emits a package.

Non-speech turns produce no package and therefore no LLM input.

Absence of invocation is the canonical non-speech path.

It is not an LLM-invented silence.

---

## 2. Exact Output the LLM Must Return

When invoked, the LLM must return exactly one candidate `ConversationUtterance`.

### Form

- One natural-language text string
- One speech artifact for the turn
- Faithful realization of the sealed `what`
- Minimal helpful wording for that WHAT
- Invisible intelligence in the wording

### Canonical output object

```
ConversationUtterance {
  text: <single natural-language utterance>
}
```

### Output rules at the LLM boundary

| Rule | Requirement |
|---|---|
| Cardinality | Exactly one utterance object |
| Content | Non-empty after trim |
| Structure | Single speech outcome; no multi-message bundle |
| Meaning | Must realize sealed WHAT; must not invent another agenda |
| Side channels | None |

### What the LLM must not return as its contractual output

- `null` / abstention (abstention belongs to PromptArchitecture before invoke)
- Multiple utterances
- Scores, analysis objects, decision objects, or memory updates
- Structured cognitive judgments
- Alternate phrasings for Conversation to choose among
- Upstream revision proposals

The LLM return is a candidate only.

It is not yet the final Conversation stage output.

---

## 3. Decisions Forbidden for the LLM

The LLM may never own or reopen any of the following:

1. Release readiness judgment
2. Conversation protocol / phase selection
3. Exit / speak-stop / audio-transition judgment
4. Changing the sealed WHAT
5. Choosing silence or speech contrary to authorization
6. Emitting multiple insights, tips, or threads in one turn
7. Surfacing analysis, scores, pattern narration, or system reasoning
8. Persistent memory, Living Mind Model, or durable learning writes
9. Same-turn upstream revision of Release, ConversationPolicy, or Exit
10. Clinical, diagnostic, therapeutic, crisis, productivity, or chatbot-engagement roles

These remain exclusive non-responsibilities under all conditions.

---

## 4. Responsibilities of PromptArchitecture

PromptArchitecture is the expression-binding transformation inside Conversation.

It packages. It does not speak. It does not invoke. It does not enforce DNA.

### Required

1. Gate invoke vs abstain from Exit permission and protocol speak intent.
2. Seal the authorized protocol phase as immutable WHAT.
3. Admit optional `ValidatedUnderstanding` and `WorkingMindView` as shaping-only context.
4. Exclude forbidden inputs from the invocation package.
5. Bind LLM Contract required / allowed / forbidden bounds.
6. Bind Conversation DNA as expression constraints on the package.
7. Emit exactly one `LlmInvocationPackage`, or abstain with no invocation.

### Allowed

- Include optional shaping context when present.
- Abstain with no model call when speaking is unauthorized or the phase is non-speech (`audio`, `silence`).

### Forbidden

- Re-decide release, protocol/phase, or exit.
- Ask the model to choose WHAT.
- Expand or rewrite the decided WHAT.
- Produce multiple invocation intents for one turn.
- Generate natural language.
- Invoke the language model.
- Enforce Conversation DNA as emission validation.
- Open a memory-write or durable-learning path.
- Feed back into upstream owners in the same turn.

### Ownership summary

PromptArchitecture owns packaging of WHAT + constraints.

It does not own HOW wording.

It does not own the final utterance.

---

## 5. Responsibilities of LanguageModelClient

LanguageModelClient is the HOW-only expression adapter.

It realizes a sealed package as natural language.

It does not decide. It does not validate emission. It does not own the stage output.

### Required

1. Accept exactly one `LlmInvocationPackage`.
2. Realize `package.what` as natural language under the bound LLM Contract.
3. Return exactly one candidate `ConversationUtterance`.
4. Remain faithful to the sealed WHAT.
5. Prefer the smallest helpful wording for that WHAT.
6. Keep intelligence invisible in the wording.

### Allowed

- Lexical and syntactic phrasing choice within the sealed WHAT.
- Attentive wording from already-supplied shaping context.
- Natural nighttime relief tone.

### Forbidden

- Any responsibility listed in Section 3.
- Abstaining after being invoked with a valid package.
- Emitting empty text as a substitute for valid speech.
- Choosing among multiple WHAT values.
- Performing Output Contract or Conversation DNA enforcement.
- Writing memory.
- Owning the final Conversation stage emission.

### Ownership summary

LanguageModelClient owns HOW realization of an already-packaged invocation.

It produces a candidate utterance only.

---

## 6. Responsibilities Remaining Inside ConversationEngine

ConversationEngine is the Conversation expression-stage owner.

It coordinates the expression path and owns the final speech outcome for the turn.

### Required

1. Accept authoritative Conversation inputs: `ConversationDecision`, `ExitDecision`, and optional shaping context.
2. Call PromptArchitecture to obtain one package or abstention.
3. If abstain: emit no conversational language (`null`).
4. If package: call LanguageModelClient to obtain one candidate utterance.
5. Pass the candidate through UtteranceGuard.
6. Emit exactly one final speech outcome:
   - one validated `ConversationUtterance`, or
   - no conversational language.
7. Preserve forward-only flow and temporary-conversation discipline.

### Forbidden

- Release, protocol, or exit judgment.
- Persistent memory writes.
- Bypassing PromptArchitecture packaging.
- Emitting an unvalidated LLM candidate.
- Emitting multiple utterances.
- Reopening upstream decisions after expression begins.

### Ownership summary

ConversationEngine remains the single Conversation-stage coordinator and the single owner of the final `ConversationUtterance` that leaves Conversation.

---

## 7. Validation Required After the LLM Returns

Every LLM return must pass UtteranceGuard before it may leave Conversation.

Validation is mandatory.

Failure yields no conversational language for the turn.

### Validation layers

#### A. Conversation Output Contract checks

1. Text is present and non-empty after normalization.
2. Exactly one speech artifact is present.
3. No multi-message / multi-line speech bundle.
4. No empty-utterance substitute for non-speech; non-speech is absence (`null`), not empty text.

#### B. WHAT faithfulness checks

1. The utterance expresses the sealed WHAT only.
2. The utterance does not invent a different phase, agenda, advice track, or exit choice.
3. Non-speech phases never emit language through this path.

#### C. Conversation DNA checks

1. All frozen DNA principles are respected in the emitted wording.
2. All frozen DNA anti-rules are absent from the emitted wording.
3. Especially reject:
   - multiple insights in one turn
   - analysis / scores / pattern narration as content
   - engagement hooks or follow-up bait
   - sleep commands or performance coaching
   - clinical / diagnostic / therapeutic framing
   - storage/database/profile-recall tone
   - rewrite of the decided conversational move

### Validation outcome

| Result | Stage emission |
|---|---|
| Pass | Final `ConversationUtterance` |
| Fail | `null` (no conversational language) |

No partial emit.

No automatic rewrite by the validator.

No second model call required by this contract.

---

## 8. Where Conversation DNA Is Enforced

### Definition owner

`ConversationDNA` owns the frozen enduring response principles and anti-rules.

It does not generate language.

It does not invoke a model.

It does not own cognitive decisions.

### Binding owner

PromptArchitecture binds `ConversationDNA` into `LlmInvocationPackage` so expression constraints travel with the invocation.

Binding is not enforcement.

### Enforcement owner

`UtteranceGuard` is the sole enforcement point for Conversation DNA on emission.

Enforcement occurs after LanguageModelClient returns and before ConversationEngine emits.

### Non-owners of DNA enforcement

- PromptArchitecture — binds only
- LanguageModelClient — may be guided by bound DNA, but does not enforce
- ConversationEngine — requires enforcement to pass; does not itself define or check DNA rules
- Upstream Release / ConversationPolicy / Exit — decide judgment, not response character validation

### Scope clarification

This DNA is the Sprint 4 enduring response character.

It is not the HCOS Architecture v1.1 deferred V2 adaptive Conversation DNA capability.

---

## 9. Which Components Own WHAT vs HOW

| Concern | Owner | Notes |
|---|---|---|
| Release readiness (cognitive WHAT-adjacent judgment) | ReleaseEngine | Outside expression plane |
| Protocol phase selection (conversational WHAT) | ConversationPolicy | Authoritative phase decision |
| Speak / stop / audio permission | ExitIntelligence | Authorizes whether expression may occur |
| Sealing WHAT into invocation | PromptArchitecture | Packages; does not re-decide |
| HOW wording | LanguageModelClient / LLM | Realization only |
| Expression constraint definition | ConversationDNA + LLM Contract bounds | Declarative only |
| Expression constraint enforcement | UtteranceGuard | Post-return gate |
| Final speech emission | ConversationEngine | Single stage output owner |

### Hard ownership rule

- WHAT is decided before PromptArchitecture completes.
- HOW begins only after WHAT is sealed in `LlmInvocationPackage`.
- No component may move HOW ownership upstream into cognitive judgment.
- No component may move WHAT ownership downstream into the language model.

---

## 10. Single Owner of the Final ConversationUtterance

`ConversationEngine` is the single owner of the final `ConversationUtterance`.

### Meaning of ownership

Only ConversationEngine may emit the turn’s Conversation-stage speech result to the rest of HCOS.

That result is either:

- one validated `ConversationUtterance`, or
- no conversational language (`null`)

### Candidate vs final

| Artifact | Producer | Status |
|---|---|---|
| `LlmInvocationPackage` | PromptArchitecture | Invocation handoff |
| Candidate `ConversationUtterance` | LanguageModelClient | Untrusted until validated |
| Validated `ConversationUtterance` | UtteranceGuard allow-path | Eligible for emission |
| Final Conversation speech outcome | ConversationEngine | Canonical stage output |

LanguageModelClient never owns the final utterance.

UtteranceGuard never owns the stage boundary; it only admits or rejects.

PromptArchitecture never owns language.

---

## Component Responsibility Map

| Component | Owns | Does not own |
|---|---|---|
| PromptArchitecture | Invoke/abstain gate; sealed WHAT package; constraint binding | Language generation; model invocation; DNA enforcement; final utterance |
| LanguageModelClient | HOW realization; candidate utterance | WHAT; exit/release/protocol; validation; final utterance; memory |
| UtteranceGuard | Output Contract + DNA + WHAT-faithfulness validation | Generation; decisions; packaging; stage emission authority |
| ConversationEngine | Expression-path coordination; final speech outcome | Upstream cognitive judgment; memory writes |
| ConversationDNA | Enduring response principles / anti-rules | Generation; enforcement execution; cognitive decisions |
| LLM Contract bounds | Required / allowed / forbidden model duties | Generation; enforcement execution |

## Non-Goals

This contract does not:

- Modify HCOS Architecture v1.1
- Redesign Release, ConversationPolicy, Exit, or Memory ownership
- Specify vendor APIs, model selection, temperature, or prompt wording templates
- Introduce V2 adaptive Conversation DNA
- Allow mid-turn persistent memory writes
- Permit the LLM to become a decision engine

## Acceptance Criteria for Sprint 5 Implementation

Implementation conforms to this contract when all of the following are true:

1. The LLM is invoked only through an `LlmInvocationPackage` produced by PromptArchitecture.
2. LanguageModelClient returns exactly one candidate utterance and never a cognitive decision.
3. UtteranceGuard validates every candidate before emission.
4. Conversation DNA is enforced only at UtteranceGuard.
5. ConversationEngine is the only component that emits the final Conversation utterance or `null`.
6. Non-speech remains absence of conversational language, never empty text as a product output.
7. No expression-plane component writes persistent memory.
8. HCOS Architecture v1.1 ownership and turn order remain intact.

## Authority

HCOS Architecture v1.1 remains the single source of truth for overall HCOS architecture.

This document is the single source of truth for the Conversation LLM Contract boundary between PromptArchitecture and LanguageModelClient.

Where implementation and this document conflict, this document governs the Conversation LLM Contract until a formal Architecture Review revises it.
