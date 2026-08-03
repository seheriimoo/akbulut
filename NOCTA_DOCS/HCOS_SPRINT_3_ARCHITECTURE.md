# HCOS Sprint 3 Architecture

## Purpose

This document defines the architectural changes introduced in Sprint 3.

HCOS Architecture v1.0 remains the authoritative architecture specification.

This document does not replace HCOS Architecture v1.0.

It extends it with implementation-level architectural decisions required for Sprint 3.

The purpose of Sprint 3 is to transform the HCOS architecture into a production-ready cognitive pipeline while preserving all architectural principles established in Version 1.0.


---

# Sprint 3 Goals

Sprint 3 transforms the HCOS architecture into an executable cognitive pipeline.

The objectives are:

- Introduce Release Intelligence.
- Separate temporary session state from long-term memory.
- Replace strategy-based reasoning with protocol-based conversation flow.
- Introduce ConversationPolicy as the protocol decision owner.
- Prepare Exit Intelligence.
- Prepare the production Conversation Engine.
- Preserve the architectural principles established in HCOS Architecture v1.0.

Sprint 3 does not introduce new product features.

Its purpose is architectural maturation.


---

# Sprint 3 Deliverables

Sprint 3 will introduce the following production components:

- ConversationDecision
- ConversationPolicy
- ConversationEngine
- ConversationUtterance
- ExitDecision
- ExitIntelligence
- NightSession
- SessionTurn
- SessionSummary
- SessionSummarizer
- WorkingMindView
- CognitiveTurnResult
- CognitiveOrchestrator

The following components will be refactored:

- ReleaseEngine
- MemoryEngine
- NoctaAIBrain

The following components will be deprecated:

- ReasoningEngine
- ReasoningDecision

Sprint 3 is complete when the HCOS cognitive pipeline executes end-to-end while preserving all HCOS V1 architectural principles.

