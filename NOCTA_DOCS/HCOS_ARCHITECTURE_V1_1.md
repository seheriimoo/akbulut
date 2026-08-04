# HCOS Architecture v1.1

---

# STATUS

Architecture Frozen

Effective Date:
2026-08-04

---

# Purpose

HCOS Architecture v1.1 is the single source of truth for the Nocta Cognitive Operating System.

This document supersedes previous HCOS architecture decisions where conflicts exist.

All V1 implementation must conform to this architecture.

---

# Architecture Governance

Rules:

- No architectural changes without a formal Architecture Review.
- New features must not introduce new architectural concepts.
- Implementation must follow the frozen HCOS architecture.
- Documentation must remain synchronized with implementation.

---

# Scope

HCOS v1.1 defines:

- Cognitive pipeline
- Memory lifecycle
- Ownership boundaries
- Conversation protocol
- Release protocol
- Exit protocol
- Session lifecycle

Future versions may extend behavior, but must preserve these architectural principles unless formally revised.

