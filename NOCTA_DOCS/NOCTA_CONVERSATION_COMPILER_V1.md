# Nocta Conversation Compiler v1

## Version

1.1

## Status

Architecture Design — Canonical

Effective Date: 2026-08-07

Incorporates frozen Amendment 003 — ConversationCompiler Shaping Contract.

This document defines the **Nocta Conversation Compiler**: the deterministic translation system that turns frozen Nocta canon and sealed HCOS decisions into a vendor-ready LLM instruction package.

The compiler does not think.
The compiler does not choose psychology.
The compiler does not own conversation.

It only translates.

---

## Purpose

Given that:

- HCOS Architecture is frozen
- Conversation Constitution is frozen
- Conversation Philosophy is frozen
- Conversation Blueprint is frozen
- Conversation LLM Contract / Vendor Integration Contracts remain authoritative for ownership

the compiler answers one remaining system question:

**How are sealed HCOS decisions transformed into vendor-ready language instructions without reopening cognition?**

The compiler is the missing translation layer between:

1. Sealed expression intent (`LlmInvocationPackage`)
2. Vendor invocation (via `LanguageModelClient` / `VendorProvider`)

---

## Position in the Frozen Pipeline

Canonical ownership remains unchanged:

```
Release → ConversationPolicy → Exit → Conversation
```

Inside Conversation expression:

```
PromptArchitecture
        │
        ├── abstain ──────────────────────► no conversational language
        │
        └── LlmInvocationPackage
                    │
                    ▼
          Conversation Compiler
                    │
                    ▼
          CompiledInstructionPackage
                    │
                    ▼
          LanguageModelClient
                    │
                    ▼
          VendorProvider (transport)
                    │
                    ▼
          candidate utterance
                    │
                    ▼
          UtteranceGuard
                    │
                    ▼
          ConversationEngine emission
```

Rules:

1. The compiler runs only after PromptArchitecture emits a package.
2. The compiler never runs on abstention.
3. The compiler never calls a vendor.
4. The compiler never validates final emission (`UtteranceGuard` remains owner).
5. `LanguageModelClient` remains the sole owner of vendor invocation.
6. HCOS decisions remain upstream and immutable to the compiler.

---

## 1. Inputs

The compiler accepts exactly two input classes.

### A. Sealed turn inputs (variable per turn)

Required:

1. One `LlmInvocationPackage`
2. The sealed speakable WHAT already fixed inside that package
3. Bound LLM Contract bounds carried by the package
4. Bound Conversation DNA carried by the package

Optional shaping only (never decision authority).
The shaping surface is closed. Field-specific modes apply:

5. Optional `understanding` — presence-only
6. Optional `workingMind` — presence-only
7. Optional `conversationGrounding` — deterministic materialization only

Standalone `livedExpression` is not a legal Compiler input.
Its current-turn shaping role is superseded by `conversationGrounding`.
No fourth shaping field is permitted.

Forbidden as compiler inputs:

- Raw release decisions
- Alternate WHAT candidates
- Exit re-judgment
- Memory-write authority
- Free-form product requests from screens
- Vendor credentials or transport configuration
- Prior unfinished “prompt drafts”
- Live user transcript as a source of new protocol choice
- Unknown shaping fields outside the closed surface
- Standalone `livedExpression`
- Admitted `conversationGrounding` used as protocol, release, exit, or decision authority

### B. Frozen canon inputs (invariant across turns)

Canonical documents compiled by reference, never reinterpreted creatively:

1. Conversation Constitution
2. Conversation Philosophy
3. Conversation Blueprint (stage corresponding to sealed WHAT)
4. Conversation DNA (already bound on the package)
5. LLM Contract bounds (already bound on the package)

The compiler may only select and bind the portions of canon that correspond to the sealed WHAT / Blueprint stage.
It may not invent new canon.

---

## 2. Outputs

The compiler emits exactly one of:

### Success

One immutable **CompiledInstructionPackage** containing vendor-ready language material derived solely from inputs.

A CompiledInstructionPackage must include:

1. **Identity of sealed WHAT** — the already-decided stage/move to realize
2. **Stage binding** — Blueprint stage purpose, aim, and forbidden moves for that WHAT
3. **Constitutional constraints** — non-negotiable rules applicable to all speech
4. **Philosophical stance** — enduring stance statements applicable to realization
5. **DNA / LLM bounds** — already sealed package constraints, restated for realization only
6. **Realization directive** — deterministic instruction to emit exactly one short utterance faithful to the sealed WHAT
7. **Field-specific shaping material** — derived only from the closed shaping surface:
   - presence-only note for admitted `understanding` and/or `workingMind` (wording permission only; never analysis narration; contents never rendered)
   - deterministic materialization of admitted `conversationGrounding` by fixed non-interpretive rules
   - if no optional shaping is admitted, an explicit note that no additional shaping context was supplied

A CompiledInstructionPackage must not include:

- Multiple candidate WHATs
- Multiple utterances
- Retry policy
- Timeout policy
- Transport headers / credentials
- Guard enforcement logic
- Memory or persistence instructions
- Open-ended “be helpful” mandates outside sealed WHAT

### Failure / abstention of compilation

Compilation produces no package when inputs are incomplete, inconsistent with frozen canon, non-speakable, or contain illegal/unknown shaping (including standalone `livedExpression`).
In that case the compiler fails closed: no CompiledInstructionPackage is emitted.

---

## 3. Responsibilities

The Conversation Compiler owns only translation.

### Required

1. Accept one sealed `LlmInvocationPackage` or refuse.
2. Map sealed WHAT onto exactly one Blueprint stage binding.
3. Attach the frozen Constitution and Philosophy as immutable constraints.
4. Attach bound DNA and LLM Contract bounds without alteration of meaning.
5. Apply field-specific shaping modes from the closed surface only:
   - `understanding` and `workingMind`: presence-only wording permission; never render contents; never expose analysis, stored knowledge, patterns, scores, or internal cognition
   - `conversationGrounding`: deterministic non-interpretive materialization by fixed rules from the sealed package
6. Emit exactly one deterministic CompiledInstructionPackage for a valid speakable package.
7. Remain pure with respect to decisions: same inputs → same compiled output.
8. Preserve the direction of the night: toward rest, never toward activation or solving.

### Allowed

1. Selecting the Blueprint stage slice that corresponds to sealed WHAT.
2. Deterministic ordering and structuring of already-frozen text into the instruction package.
3. Provider-agnostic packaging of instruction material (transport formatting remains VendorProvider-specific later).
4. Refusing to compile when invariants fail.
5. Deterministic materialization of admitted `conversationGrounding` by fixed non-interpretive rules.
6. Presence-only binding of admitted `understanding` and/or `workingMind` as wording permission.

### Ownership summary

Compiler owns **deterministic compilation** of sealed intent + frozen canon into vendor-ready instruction material.

Compiler does not own cognition, conversation emission, or transport.

---

## 4. Forbidden Responsibilities

The compiler must never:

1. Choose or change WHAT.
2. Choose release readiness, protocol phase, or exit.
3. Decide whether to speak or remain silent (that is PromptArchitecture / Exit upstream).
4. Invent psychology, empathy strategy, or therapeutic method.
5. Reinterpret Constitution, Philosophy, or Blueprint into new doctrine.
6. Expand one WHAT into multiple conversational agendas.
7. Ask the model to select among stages.
8. Generate user-facing language itself.
9. Call a vendor / LLM.
10. Enforce DNA or Output Contract on model output (`UtteranceGuard` owns enforcement).
11. Retry, time out, fall back, or stream.
12. Write memory or mutate Living Mind Model / NightSession.
13. Become the live cognitive entry.
14. Bypass PromptArchitecture or ConversationEngine.
15. Optimize for engagement, retention mechanics, or session length.
16. Infer meaning, psychology, intent, emotion, or salience from shaping.
17. Invent `conversationGrounding` or any grounding not admitted on the package.
18. Render `understanding` or `workingMind` contents into instructions.
19. Accept shaping fields outside the closed surface.
20. Accept standalone `livedExpression` as a Compiler input.

If a behavior requires judgment, it does not belong in the compiler.

---

## 5. Compilation Stages

Compilation is a fixed pipeline. No stage may think. Each stage only transforms or rejects.

### Stage A — Admit Package

**Purpose:** Accept only an authorized sealed package.

**Does:**
- Verify a package exists
- Verify WHAT is speakable
- Verify DNA and LLM bounds are bound

**Fails if:**
- No package / abstention
- Non-speakable WHAT (`audio`, `silence`)
- Missing bound DNA or bounds

**Output:** Admitted package, or compile failure.

---

### Stage B — Bind Blueprint Stage

**Purpose:** Attach the Blueprint stage that corresponds to sealed WHAT.

**Does:**
- Map WHAT → Blueprint stage (Receipt / Naming / Permission / Release / Enough)
- Bind that stage’s purpose, aim, and forbidden moves

**Fails if:**
- Sealed WHAT has no Blueprint binding
- Mapping would require choosing among multiple stages

**Output:** Stage-bound package slice, or compile failure.

Arrival and Rest are non-compiled speech stages:
- Arrival has no assistant speech package
- Rest has no assistant speech package

---

### Stage C — Bind Constitution

**Purpose:** Attach non-negotiable conversational law.

**Does:**
- Include the frozen Constitution as mandatory constraints on realization

**Fails if:**
- Constitution canon is unavailable or mismatched to the frozen version expected by the system

**Output:** Constitution-bound slice, or compile failure.

---

### Stage D — Bind Philosophy

**Purpose:** Attach enduring stance.

**Does:**
- Include the frozen Philosophy as stance constraints on realization

**Fails if:**
- Philosophy canon is unavailable or version-mismatched

**Output:** Philosophy-bound slice, or compile failure.

---

### Stage E — Bind Package Constraints

**Purpose:** Carry sealed DNA and LLM Contract bounds unchanged.

**Does:**
- Restate bound DNA principles / anti-rules
- Restate LLM required / allowed / forbidden bounds

**Fails if:**
- Package bounds differ from frozen LLM Contract bounds
- DNA identity is not the bound canonical DNA

**Output:** Constraint-bound slice, or compile failure.

---

### Stage F — Bind Optional Shaping (Field-Specific)

**Purpose:** Bind the closed optional shaping surface without cognitive leakage or authority.

**Does:**
- Accept only `understanding`, `workingMind`, and `conversationGrounding`
- For `understanding` and/or `workingMind` when present: bind presence-only wording permission; do not render contents
- For `conversationGrounding` when present: deterministically materialize by fixed non-interpretive rules from the sealed package
- If no optional shaping is admitted: mark that no additional shaping context was supplied
- Fail closed if unknown shaping fields or standalone `livedExpression` are present

**Must never:**
- Narrate analysis, scores, patterns, memories, or storage
- Turn shaping context into a new agenda
- Interpret, infer, summarize, or select salient content
- Invent grounding
- Change WHAT or reopen cognition

**Output:** Field-specific shaping material (presence note and/or materialized `conversationGrounding`), or compile failure.

---

### Stage G — Seal CompiledInstructionPackage

**Purpose:** Produce the immutable vendor-ready instruction package.

**Does:**
- Assemble Stages B–F into one immutable CompiledInstructionPackage, including Stage F field-specific shaping outputs
- Add the deterministic realization directive: emit exactly one short utterance for the sealed WHAT only

**Fails if:**
- Any prior stage failed
- Assembly would omit a required bound slice

**Output:** Exactly one CompiledInstructionPackage.

After Stage G, the compiler is finished.
`LanguageModelClient` may then invoke the vendor using this package.
`VendorProvider` may apply provider-specific transport serialization only—not cognitive translation.

---

## 6. Failure Behavior

The compiler fails closed.

### Failure classes

1. **Admission failure** — no valid sealed speakable package
2. **Binding failure** — WHAT cannot be bound to Blueprint / canon
3. **Integrity failure** — DNA, LLM bounds, or canon version invariants broken
4. **Assembly failure** — compiled package would be incomplete
5. **Illegal shaping failure** — unknown shaping fields, standalone `livedExpression`, or shaping outside the closed surface

### Required failure behavior

1. Emit no CompiledInstructionPackage.
2. Perform no vendor call.
3. Invent no substitute speech.
4. Choose no alternate WHAT.
5. Write no memory.
6. Invent no `conversationGrounding`.
7. Surface failure to the Conversation expression plane as “no compiled instruction,” equivalent in effect to no conversational language for that invoke path.
8. Leave upstream Exit / protocol / release decisions unchanged and authoritative.

### Explicitly forbidden failure behavior

1. Best-effort creative compilation
2. Falling back to a generic chatbot system prompt
3. Asking the model to recover missing WHAT
4. Silent success with empty instruction material
5. Retry loops inside the compiler
6. Ignoring illegal shaping and compiling anyway

---

## 7. Determinism Contract

For a fixed canon version and identical sealed package inputs:

**compilation is deterministic.**

Consequences:

1. No randomness in compilation.
2. No model calls during compilation.
3. No heuristic “tone choice” beyond sealed WHAT + frozen canon + admitted shaping applied only by fixed field-specific rules.
4. Provider differences may affect transport encoding later, not compiled meaning.
5. Canon updates are versioned events; they are not turn-time creativity.
6. Identical sealed package inputs, including identical admitted shaping, produce identical compiled output.

---

## 8. Relationship to Existing Frozen Owners

| Concern | Owner | Compiler role |
|---|---|---|
| Release / protocol / exit | HCOS upstream | Consume sealed result only |
| Speak vs abstain packaging | PromptArchitecture | Runs only after package exists |
| Vendor invocation | LanguageModelClient | Consumes compiled package; compiler does not invoke |
| Transport encoding / auth | VendorProvider | After compilation; no cognitive translation |
| Emission validation | UtteranceGuard | After model return |
| Final Conversation utterance | ConversationEngine | Unchanged |
| Memory writes | MemoryEngine at session end | Forbidden to compiler |

### Hard rule

The compiler may translate sealed decisions into instructions.
It may never make decisions.

---

## 9. Derivation Rule

A future implementation is a valid Conversation Compiler only if:

1. It accepts sealed packages and frozen canon as defined here
2. It emits CompiledInstructionPackage or fails closed
3. It never chooses psychology, WHAT, exit, or speech/silence
4. It never calls a vendor
5. It remains deterministic for identical inputs
6. It does not weaken Constitution, Philosophy, Blueprint, DNA, or HCOS ownership
7. It consumes optional shaping only from the closed surface: `understanding`, `workingMind`, `conversationGrounding`
8. It applies field-specific shaping modes: presence-only for `understanding`/`workingMind`; deterministic materialization for `conversationGrounding`
9. It rejects standalone `livedExpression` and any unknown shaping field (fail closed)
10. It never infers from shaping or invents grounding

If a proposed compiler behavior requires judgment, it belongs upstream.
If it requires wording realization, it belongs downstream in the model path.
If it requires validation of speech, it belongs in UtteranceGuard.

The compiler occupies only the middle: **deterministic translation**.
