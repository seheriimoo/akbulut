# NOCTA Contract Amendments V1

---

## Purpose

This document records every frozen HCOS contract that must be formally amended before Conversation Memory V1 can be implemented.

No implementation.

No code.

Only contract amendments.


---

# CONTRACTS TO AMEND

## 001 — HCOS Principle 3 (Temporary Conversation Grounding)

[PENDING]

---

## 002 — LlmInvocationPackage

[PENDING]

---

## 003 — ConversationCompiler Shaping Contract

[PENDING]

---

## 004 — CognitiveOrchestrator Ownership

[PENDING]

---

## 005 — NightSession Lifecycle

[PENDING]

---

## Acceptance Criteria

Conversation Memory V1 implementation may begin only after every amendment above is marked APPROVED.


---

# AMENDMENT 001 — HCOS Principle 3 + Memory Storage Clarification

## Status

APPROVED

## Existing Principle

Raw conversations are never stored.

## Amendment

Raw conversations are never durably stored.

HCOS may permit temporary runtime conversation grounding during an active NightSession.

Temporary conversation grounding:

- exists only in volatile runtime memory
- remains governed by all frozen HCOS principles
- never becomes durable memory
- never modifies or replaces HCOS decision authority
- must be discarded when the active NightSession ends
- must not remain retained in process memory after NightSession completion

Product-specific grounding scope, window size, and eligibility rules are defined exclusively by the Conversation Memory Contract.

## Memory Architecture Clarification

For HCOS Memory Architecture, the existing statements:

- Raw conversations are never stored
- Nightly dialogue is never stored

are re-scoped to mean:

- Raw conversations are never durably stored
- Nightly dialogue is never durably stored

This clarification permits only explicitly authorized temporary runtime grounding under the Conversation Memory Contract.

It does not authorize:

- durable transcript storage
- dialogue persistence to LivingMindModel
- MemoryEngine dialogue writes
- analytics or logging of raw dialogue
- vendor-maintained conversation history
- retention after the active NightSession ends

## Reason

Conversation continuity may require bounded same-night grounding while HCOS must continue to prohibit durable dialogue archives and preserve all existing cognitive ownership boundaries.

## Acceptance Test

The amendment passes only if:

1. temporary grounding remains subject to all HCOS principles
2. no raw conversation becomes durable memory
3. no raw conversation survives NightSession completion
4. the Memory Architecture no longer contradicts the temporary-runtime exception
5. product-specific grounding rules remain owned only by Conversation Memory documentation


---

# AMENDMENT 002 — LlmInvocationPackage

## Status

APPROVED

## Purpose

Determine whether LlmInvocationPackage should admit temporary conversation grounding as an explicit contract field.

No implementation.

No code.

Only contract design.

## Questions

1. Should conversation grounding become an explicit package field?

[FINAL — YES]

Conversation grounding must become an explicit field of LlmInvocationPackage.

Reason:

The frozen expression path permits only one canonical handoff into the LLM expression plane:

PromptArchitecture → LlmInvocationPackage → ConversationCompiler → VendorProvider.

Conversation grounding therefore requires an explicit sealed package field so that PromptArchitecture may admit it and ConversationCompiler may materialize it without side-channels or ownership leaks.

The field is shaping-only and does not grant cognitive authority.

---

2. Who owns that field?

[FINAL]

Ownership is split by responsibility.

Conversation Grounding Buffer

Owner:
CognitiveOrchestrator

Responsibilities:

- owns the temporary same-night grounding buffer
- updates the buffer
- discards the buffer at NightSession completion

Package Field

Owner:
PromptArchitecture

Responsibilities:

- admits or rejects conversation grounding
- writes the Conversation Grounding field into LlmInvocationPackage
- never owns the underlying buffer

Read Access

ConversationCompiler:
May read only for deterministic materialization.

LanguageModelClient:
May carry the immutable package only.

No Mutation After Emit

After LlmInvocationPackage is emitted, the Conversation Grounding field is immutable.

ConversationCompiler, VendorProvider, CognitiveOrchestrator, WorkingMind and MemoryEngine must never modify it.


---

3. Is conversation grounding required or optional?

[FINAL — OPTIONAL]

Conversation Grounding is an optional shaping field.

Reason:

The sealed WHAT remains sufficient for invocation.

Conversation Grounding improves continuity but never becomes a prerequisite for expression.

PromptArchitecture may admit or omit the field.

If no conversation grounding exists:

- PromptArchitecture omits the field
- LlmInvocationPackage remains valid
- ConversationCompiler must compile successfully
- VendorProvider transports the compiled package normally
- no grounding may ever be invented

The absence of Conversation Grounding must never cause expression to fail.

Only ExitDecision and HCOS protocol determine whether conversation proceeds.


---

4. Does Conversation Grounding have cognitive authority?

[FINAL — NO]

Conversation Grounding has zero cognitive authority.

Its only purpose is shaping wording after cognition has already finished.

Conversation Grounding must never:

- choose WHAT
- change ConversationPolicy
- influence ReleaseDecision
- influence ExitDecision
- determine whether conversation proceeds
- modify WorkingMind
- write MemoryEngine
- reopen any upstream HCOS decision

PromptArchitecture may only admit or omit it.

ConversationCompiler may only materialize it.

VendorProvider may only transport compiled output.

Grounding may shape wording after cognition is finished.

It must never participate in cognition.


---

5. What reaches the Compiler?

[FINAL]

ConversationCompiler receives exactly one sealed LlmInvocationPackage.

No other object is a legal Compiler input.

Required package fields:

- what
- dna
- llmRequired
- llmAllowed
- llmForbidden

Optional shaping fields:

- understanding
- workingMind
- conversationGrounding

Authority

Only the following are authoritative:

- what
- dna
- llmRequired
- llmAllowed
- llmForbidden

All optional fields are shaping-only.

ConversationCompiler must never:

- invent conversation grounding
- invent vendor chat history
- invent a different WHAT
- reopen ReleaseDecision
- reopen ConversationPolicy
- reopen ExitDecision
- write MemoryEngine
- create durable memory
- accept any input outside the sealed package

On compile failure, ConversationCompiler fails closed.



---

# AMENDMENT 003 — ConversationCompiler Shaping Contract

## Status

APPROVED

## Purpose

Define how ConversationCompiler may legally consume optional shaping fields without gaining cognitive authority.

No implementation.

No code.

Only contract design.

## Questions

1. May ConversationCompiler materialize optional shaping fields?

[FINAL — YES]

ConversationCompiler may legally materialize optional shaping fields.

Materialization is defined as:

Deterministic, non-interpretive translation of shaping already admitted by PromptArchitecture into CompiledInstructionPackage.

Materialization may:

- include admitted shaping by fixed rules
- preserve deterministic compilation
- leave WHAT unchanged
- compile the same package into the same output every time

Materialization must never:

- interpret shaping
- infer psychology
- infer intent
- summarize dialogue
- select salient content
- reopen cognition
- change WHAT
- invent grounding
- generate user-facing language
- optimize engagement

Boundary Rule:

If the operation requires judgment, inference, interpretation, or cognition, it is not ConversationCompiler work.


---

2. What is the difference between shaping and authority?

[FINAL]

Authority determines what may happen.

Shaping determines only how already-authorized speech is expressed.

Authority owns cognitive judgment.

Examples of authority:

- ReleaseDecision
- ConversationDecision (WHAT)
- ExitDecision
- LLM invocation permission
- MemoryEngine durable writes

Shaping owns no cognitive judgment.

Examples of shaping:

- understanding
- workingMind
- conversationGrounding

If shaping is absent, conversation may still proceed.

Only wording or continuity may change.

Canonical Rule:

Authority decides WHAT.

Shaping affects only HOW.

Shaping must never override authority.


---

3. Which shaping fields are legal Compiler inputs?

[FINAL]

Legal shaping fields:

- understanding
- workingMind
- conversationGrounding

These are the only optional shaping fields that may legally reach ConversationCompiler.

Each field is shaping-only.

None may:

- choose WHAT
- influence ReleaseDecision
- influence ConversationDecision
- influence ExitDecision
- become durable memory
- gain cognitive authority

The shaping surface is closed.

Unknown shaping fields are illegal Compiler inputs.

If an unknown shaping field is present, ConversationCompiler must fail closed.

Canonical Rule:

ConversationCompiler may consume optional shaping only from:

- understanding
- workingMind
- conversationGrounding

No other shaping source is permitted.


---

4. What must ConversationCompiler never infer or invent?

[FINAL]

ConversationCompiler must never infer:

- user psychology
- user intent
- user emotion
- release readiness
- ConversationPolicy or WHAT
- Exit decisions
- salience of shaping
- engagement strategy
- durable memory worthiness

ConversationCompiler must never invent:

- conversationGrounding
- alternate WHAT values
- vendor chat history
- new canon
- analysis narration
- user-facing utterance text
- memory writes
- NightSession mutations
- transport policy
- shaping fields outside the closed surface

These prohibitions preserve HCOS ownership boundaries.

Canonical Rule:

ConversationCompiler may deterministically translate admitted shaping.

It must never infer meaning or invent cognition, memory, canon, or speech.

If an operation requires judgment, it is not ConversationCompiler work.


---

5. What Compiler doctrine must be amended?

[FINAL]

The following frozen ConversationCompiler doctrines are formally amended:

- Optional shaping input surface
- Stage F — Bind Optional Shaping Presence
- CompiledInstructionPackage shaping doctrine
- Presence-only shaping rule

Replacement Doctrine

ConversationCompiler uses field-specific shaping modes.

Presence-only shaping:

- understanding
- workingMind

Their contents must never be rendered into instructions.
Their presence may permit attentive wording only.
They must never expose analysis, stored knowledge, patterns, scores, or internal cognition.

Deterministically materialized shaping:

- conversationGrounding

ConversationGrounding may be rendered only by fixed, non-interpretive rules from the sealed LlmInvocationPackage.

Compiler responsibilities:

- deterministic translation only
- no interpretation
- no inference
- no invention
- no WHAT changes
- same package → same compiled output

Unknown shaping fields are illegal.

ConversationCompiler must fail closed.

Canonical Rule:

Shaping mode is field-specific.

Understanding and WorkingMind remain presence-only.

ConversationGrounding is the sole canonical user-grounding shaping field and may be deterministically materialized.

Standalone livedExpression is not part of the canonical shaping surface.

Its current-turn shaping role is superseded by ConversationGrounding.

No fourth shaping field is introduced.

No shaping field gains cognitive authority.

Cognitive decision authority remains exclusively upstream
(ReleaseDecision, ConversationDecision/WHAT, ExitDecision,
LLM invocation gating, and MemoryEngine durable writes).

Within the sealed LlmInvocationPackage,
WHAT is the sole authoritative expression intent.

Conversation DNA and LLM bounds are authoritative expression constraints only.

Shaping never overrides either.



---

