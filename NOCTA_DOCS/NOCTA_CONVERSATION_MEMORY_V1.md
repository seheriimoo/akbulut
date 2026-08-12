# NOCTA Conversation Memory V1

---

## Purpose

Define exactly what conversation context is allowed to reach the LLM during a live conversation.

This document decides the memory contract before any implementation.

No code decisions.

No prompt changes.

No implementation details.

Only architecture.


---

# QUESTIONS TO DECIDE

## 1. What conversation history reaches the LLM?

[FINAL]

Only bounded, same-night, user-side grounding.

The current user utterance plus up to two immediately prior user utterances may reach the LLM as shaping-only context.

Prior assistant utterances are excluded in V1.

---

## 2. How many previous turns are allowed?

[FINAL]

Maximum: two prior user utterances from the active night, plus the current user utterance.

No full transcript is permitted.

---

## 3. What must never be sent?

[FINAL]

Never send:

- full conversation transcripts
- prior assistant utterances in V1
- ReleaseDecision
- ConversationDecision
- ExitDecision
- raw LivingMindModel archives
- durable memory records
- vendor-maintained chat history
- semantic summaries or distilled dialogue created solely for conversation grounding

---

## 4. What belongs to WorkingMind instead of conversation history?

[FINAL]

WorkingMind carries durable or accumulated user understanding permitted by HCOS.

It does not carry or replay recent dialogue text.

Same-night raw user grounding remains a separate temporary buffer and never becomes WorkingMind dialogue history.

---

## 5. What is the final Conversation Memory Contract?

[FINAL]

Conversation Memory V1 is:

- temporary
- night-scoped
- user-side only
- bounded to current + two prior user utterances
- shaping-only
- non-authoritative
- non-durable

CognitiveOrchestrator owns the temporary buffer lifecycle.

PromptArchitecture only admits or rejects it.

ConversationCompiler materializes admitted grounding.

VendorProvider transports compiled material only.

The buffer is discarded when the night ends and is never written to MemoryEngine or LivingMindModel.

---

# ARCHITECTURAL DECISION — REVISED

Conversation Memory V1 is temporary, night-scoped, shaping-only context.

## Ownership

The CognitiveOrchestrator owns the temporary same-night grounding buffer.

PromptArchitecture does not own memory.
PromptArchitecture only admits or rejects conversation grounding as optional shaping.

ConversationCompiler may materialize only admitted grounding into vendor-ready instructions.

VendorProvider transports compiled material only and must never construct or maintain chat history.

WorkingMind and MemoryEngine remain responsible for durable cross-night knowing and must never receive the temporary dialogue buffer.

## V1 Grounding Scope

Only recent user-side utterances may be retained as same-night grounding.

Prior assistant utterances are excluded in V1.

The grounding window is:

- current user utterance
- up to two immediately prior user utterances from the same night

No semantic summarization or salience selection is allowed.

Only deterministic bounded retention / truncation is allowed.

## Lifecycle

The grounding buffer exists in memory for the active night only.

It is discarded when the NightSession ends.

It is never persisted to LivingMindModel.

It is never written by MemoryEngine.

It is not part of SessionTurn cognitive decision data.

## Authority

Conversation grounding is shaping only.

It must never:

- choose WHAT
- change ConversationPolicy
- change ReleaseDecision
- change ExitDecision
- become durable memory
- reopen an upstream decision

The currently sealed WHAT remains authoritative for every turn.

## Required Contract Work Before Implementation

Before code implementation:

1. Amend the no-dialogue-storage principle to explicitly permit temporary night-local RAM grounding.
2. Reopen LlmInvocationPackage to define a bounded conversation-grounding shaping field.
3. Reopen ConversationCompiler shaping doctrine to admit that field without cognitive ownership.
4. Preserve PromptArchitecture as admit-gate only.
5. Preserve VendorProvider as transport-only.
6. Preserve prior-assistant grounding as OFF for V1.

No implementation may begin until these amendments are frozen.
