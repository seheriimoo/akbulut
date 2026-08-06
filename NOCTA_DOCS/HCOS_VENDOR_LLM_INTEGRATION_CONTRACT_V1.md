# HCOS Vendor LLM Integration Contract v1

## Version

1.0

## Status

Architecture Design — Sprint 7 Canonical

Effective Date: 2026-08-06

This document is the canonical architecture specification for Sprint 7 Vendor LLM Integration.

It does not modify:

- HCOS Architecture v1.1
- HCOS Conversation LLM Contract V1 (Sprint 5)
- Sprint 6 Cutover Contract

Architectural changes to this contract require a formal Architecture Review.

## Purpose

Sprint 5 froze the Conversation LLM Contract: expression is HOW-only after WHAT is sealed.

Sprint 6 made `CognitiveOrchestrator.processTurn` the sole live cognitive entry and `CognitiveTurnResult` the sole production turn exit.

Sprint 7 replaces the deterministic placeholder realization inside `LanguageModelClient` with a vendor-backed realization path — without moving cognitive ownership, without redesigning the expression plane, and without changing the live cutover boundary.

The vendor is an expression transport only.

It is never a cognitive owner.

## Source Contracts (Frozen)

This design inherits and does not reopen:

1. HCOS Architecture v1.1
2. Conversation LLM Contract V1
3. Sprint 6 Cutover Contract
4. Sprint 4/5 frozen Conversation responsibilities, DNA (enduring), Output Contract, Prompt Architecture ownership

## Position in the Pipeline

Canonical turn path remains:

```
Release → ConversationPolicy → Exit → Conversation
```

Inside Conversation, the expression path remains:

```
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
          VendorProvider (transport only)
                    │
                    ▼
          candidate ConversationUtterance
                    │
                    ▼
             UtteranceGuard
                    │
                    ▼
          ConversationEngine final emission
```

Live cognitive entry remains `CognitiveOrchestrator.processTurn`.

Live turn exit remains `CognitiveTurnResult`.

---

## 1. Live Vendor Entry Point

The sole live vendor invocation entry is:

`LanguageModelClient.realize(LlmInvocationPackage package)`

Rules:

1. Only `LanguageModelClient` may call a vendor provider.
2. Only an authorized `LlmInvocationPackage` produced by `PromptArchitecture` may reach the vendor.
3. No app screen, `CognitiveOrchestrator`, `PromptArchitecture`, `UtteranceGuard`, or Memory path may call a vendor API directly.
4. Non-speech remains abstention before packaging; the vendor is never invoked to invent silence.
5. Sprint 6 live cognitive entry (`processTurn`) is unchanged; vendor integration is nested inside Conversation expression only.

---

## 2. Vendor Responsibilities

A Vendor Provider is a transport adapter behind `LanguageModelClient`.

### Required

1. Accept a provider request derived solely from one `LlmInvocationPackage`.
2. Return exactly one natural-language text candidate for that sealed WHAT.
3. Honor transport constraints supplied by `LanguageModelClient` (timeout, non-streaming completion for V1).
4. Surface transport failures as provider errors to `LanguageModelClient` (no silent empty success).

### Allowed

1. Provider-specific HTTP/SDK wiring.
2. Provider-specific auth/config loading.
3. Provider-specific request serialization of already-sealed package contents.
4. Provider model-id / endpoint selection within configured bounds.

### Forbidden

1. Release, protocol/phase, or exit judgment.
2. Changing or rechoosing the sealed WHAT.
3. Emitting multiple candidates for ConversationEngine to choose among.
4. Emitting empty text as a successful speech result.
5. Conversation DNA / Output Contract enforcement (owned by `UtteranceGuard`).
6. Persistent memory / Living Mind Model writes.
7. Calling upstream HCOS engines.
8. Owning retries, timeouts policy, or final Conversation emission (see ownership sections below).
9. Streaming partial tokens into the live Conversation stage in V1.
10. Becoming the app live cognitive entry.

### Ownership summary

Vendor owns transport to/from an external model.

Vendor does not own HCOS decisions, validation, or stage emission.

---

## 3. LanguageModelClient Responsibilities

`LanguageModelClient` remains the HOW-only expression adapter and the sole owner of vendor invocation.

### Required

1. Accept exactly one `LlmInvocationPackage`.
2. Validate package integrity (speakable WHAT already guaranteed; frozen LLM bounds; bound Conversation DNA).
3. Build the provider request from the package without expanding WHAT.
4. Invoke exactly one configured `VendorProvider`.
5. Map a successful provider text into exactly one candidate `ConversationUtterance`.
6. Never return empty text on success.
7. Translate provider/transport failures into the Sprint 7 error contract (Section 6).
8. Remain decision-free: no release/protocol/exit/memory ownership.

### Allowed

1. Selecting among configured providers through the provider abstraction (Section 10).
2. Applying timeout and non-retry / limited-retry policy as defined in Sections 7–8.
3. Deterministic local fallback realization only when explicitly classified as a transport failure under Section 6 — and only if it still yields a single non-empty WHAT-faithful candidate.
   - Fallback is expression continuity, not a new decision engine.
   - Fallback must not bypass `UtteranceGuard`.

### Forbidden

1. Invoking a vendor without a package.
2. Asking the vendor to choose WHAT, speak/stop, or exit.
3. Performing DNA / Output Contract enforcement.
4. Emitting the final Conversation stage result.
5. Writing memory.
6. Streaming into the Conversation stage in V1.
7. Changing Sprint 6 live entry/exit contracts.

### Ownership summary

`LanguageModelClient` owns vendor call orchestration and candidate utterance production.

It does not own final emission.

---

## 4. PromptArchitecture Responsibilities

Unchanged in role from Conversation LLM Contract V1.

### Required

1. Gate invoke vs abstain.
2. Seal immutable speakable WHAT.
3. Admit optional shaping context only.
4. Bind LLM Contract bounds and Conversation DNA.
5. Emit exactly one `LlmInvocationPackage` or abstain.

### Forbidden (still)

1. Generating language.
2. Invoking a vendor or `LanguageModelClient`.
3. Enforcing DNA on emission.
4. Owning retries, timeouts, streaming, or vendor selection.
5. Re-deciding release/protocol/exit.

### Sprint 7 clarification

PromptArchitecture may later attach prompt-rendering fields derived only from the sealed package, if needed for provider serialization.

It must not attach alternate WHAT options, decision authority, or vendor credentials.

---

## 5. ConversationEngine Responsibilities

Unchanged in ownership from Conversation LLM Contract V1 and Sprint 6.

### Required

1. Call PromptArchitecture.
2. On package: call `LanguageModelClient.realize`.
3. Pass candidate through `UtteranceGuard`.
4. Emit final `ConversationUtterance` or `null`.
5. Remain the sole Conversation-stage owner of the final speech outcome.

### Forbidden (still)

1. Calling vendors directly.
2. Bypassing PromptArchitecture or UtteranceGuard.
3. Interpreting provider errors as release/protocol/exit decisions.
4. Writing memory.
5. Owning Sprint 6 live cognitive entry (`processTurn`).

### Sprint 7 clarification

If `LanguageModelClient` fails under Section 6 with no admissible candidate, ConversationEngine emits no conversational language (`null`) for that turn.

It must not reopen upstream decisions to “recover” speech.

---

## 6. Error Ownership

| Error class | Owner | Result |
|---|---|---|
| Invalid / non-speakable package construction | `LlmInvocationPackage` / PromptArchitecture gate | No vendor call |
| Package integrity / bound DNA/bounds failure before call | `LanguageModelClient` | No vendor call; no empty success utterance |
| Transport / HTTP / auth / provider SDK failure | Vendor Provider detects; `LanguageModelClient` owns handling | Candidate path fails closed unless allowed fallback yields one valid candidate |
| Provider returns empty / multi-message / unusable text | `LanguageModelClient` rejects as failed candidate | No success utterance |
| Candidate fails Output Contract / WHAT / DNA | `UtteranceGuard` | `null` emission |
| Cognitive / protocol / exit errors | Upstream HCOS owners only | Outside vendor path |

Rules:

1. Vendors do not own product-level error policy.
2. `LanguageModelClient` owns mapping provider failures into expression-plane failure.
3. `ConversationEngine` owns turning expression-plane failure into `null` stage emission when no candidate passes.
4. Errors must not mutate `NightSession` ownership rules or write memory.
5. Errors must not invent a different WHAT.

---

## 7. Retry Ownership

| Concern | Owner |
|---|---|
| Whether to retry a vendor call | `LanguageModelClient` only |
| Provider-level automatic retries | Forbidden unless configured and still gated by `LanguageModelClient` policy |
| Retrying by re-entering PromptArchitecture / changing WHAT | Forbidden |
| Retrying by calling Release / Policy / Exit again | Forbidden |
| App/UI retry of cognition | Outside expression plane; if present, must re-enter only via `CognitiveOrchestrator.processTurn` (Sprint 6), not via direct vendor calls |

V1 retry policy bounds:

1. Retries are optional and limited.
2. Retries use the same sealed `LlmInvocationPackage` only.
3. Retries are for transient transport failures only.
4. Semantic/content rejection by UtteranceGuard is not a retry trigger in V1.

---

## 8. Timeout Ownership

| Concern | Owner |
|---|---|
| Timeout policy for vendor calls | `LanguageModelClient` |
| Enforcing timeout on the wire | Vendor Provider under client-supplied limit |
| Extending conversation protocol because of timeout | Forbidden |
| Treating timeout as exit/audio decision | Forbidden |

On timeout:

1. `LanguageModelClient` fails the candidate path (or uses allowed fallback if policy permits).
2. `ConversationEngine` emits `null` if no admissible candidate exists.
3. Upstream ExitDecision already computed for the turn remains authoritative.

---

## 9. Streaming Ownership

V1 streaming policy:

1. Streaming is not part of the live Conversation stage contract.
2. Vendor Providers must return a completed single text result to `LanguageModelClient`.
3. No partial tokens, incremental UI speech, or multi-chunk Conversation emissions in V1.
4. Future streaming, if ever introduced, requires a formal Architecture Review and must not bypass UtteranceGuard or ConversationEngine final ownership.

Ownership:

- Streaming capability: out of V1 scope
- Completion assembly: Vendor Provider (if SDK streams internally) before returning to client
- Stage emission: still `ConversationEngine` after guard

---

## 10. Provider Abstraction

### Canonical abstraction

`VendorProvider` (name may vary in code; responsibility is frozen):

```
Input:  provider request derived from one LlmInvocationPackage
Output: one completed text string OR provider error
```

### Rules

1. `LanguageModelClient` depends on the abstraction, not on a specific vendor SDK at the ownership boundary.
2. One active provider configuration is selected per realization call.
3. Provider implementations are interchangeable without changing PromptArchitecture, ConversationEngine, UtteranceGuard, or Sprint 6 cutover entry/exit.
4. Provider config (API keys, model ids, base URLs) lives outside cognitive ownership and must not appear in Living Mind Model or NightSession decision fields.
5. Deprecated legacy `AIService` remains outside this abstraction and outside the live path (Sprint 6).

### Forbidden abstraction leaks

1. Exposing vendor APIs to screens or Orchestrator.
2. Encoding protocol/phase selection into provider interfaces.
3. Returning scores, tool-calls, or multi-candidate lists as production Conversation outputs.

---

## 11. What Must NOT Change from Sprint 5 / Sprint 6

### From Sprint 5 — Conversation LLM Contract V1

1. PromptArchitecture packages or abstains; does not speak; does not invoke vendors.
2. `LlmInvocationPackage` sealed speakable WHAT + bounds + DNA binding.
3. `LanguageModelClient` produces candidate utterance only.
4. `UtteranceGuard` is the sole DNA / Output Contract enforcement point; admit/reject only.
5. `ConversationEngine` is the sole final `ConversationUtterance` / `null` owner.
6. Non-speech is absence, never empty product text.
7. No mid-turn persistent memory writes from the expression plane.
8. LLM / vendor never owns release, protocol, or exit.

### From Sprint 6 — Cutover Contract

1. Live cognitive entry remains `CognitiveOrchestrator.processTurn`.
2. Live turn exit remains `CognitiveTurnResult`.
3. App shell remains session lifecycle host only.
4. NightSession mid-turn updates come only from `CognitiveTurnResult`.
5. MemoryEngine remains session-end only via complete-session path.
6. Deprecated `AIService` / `NoctaAIBrain` / `ReasoningEngine` stay out of the live production flow.
7. Vendor integration must not reintroduce legacy generation as a parallel live cognition path.

### From HCOS Architecture v1.1

1. Forward-only cognitive pipeline.
2. Single Memory Writer.
3. Conversations temporary.
4. Conversation has cost; prefer fewer words.
5. Intelligence invisible.
6. No redesign of Release / ConversationPolicy / Exit ownership.

---

## Acceptance Criteria for Sprint 7 Implementation

Implementation conforms when all of the following are true:

1. Only `LanguageModelClient.realize` invokes vendors.
2. Vendors receive only sealed package-derived requests.
3. Candidate utterances still pass through `UtteranceGuard` before emission.
4. `ConversationEngine` remains final speech owner.
5. Timeouts/retries are owned by `LanguageModelClient` within this contract.
6. No V1 streaming into Conversation stage.
7. Provider abstraction allows vendor swap without changing Sprint 5/6 boundaries.
8. Sprint 6 live entry/exit and Sprint 5 expression ownership remain intact.
9. Transport failure never becomes a cognitive re-decision in the same turn.

## Non-Goals

This contract does not:

1. Redesign HCOS Architecture v1.1
2. Reopen Conversation LLM Contract V1 ownership
3. Reopen Sprint 6 cutover entry/exit
4. Select a specific commercial vendor as architecture law
5. Introduce V2 adaptive Conversation DNA
6. Add tool-calling, multi-agent planning, or retrieval-augmented cognition
7. Persist raw prompts/transcripts into Living Mind Model

## Authority

HCOS Architecture v1.1 remains the single source of truth for overall HCOS architecture.

Conversation LLM Contract V1 remains the single source of truth for PromptArchitecture ↔ LanguageModelClient cognitive/expression ownership.

Sprint 6 Cutover Contract remains the single source of truth for live app entry/exit.

This document is the single source of truth for Sprint 7 vendor integration ownership inside the expression plane.
