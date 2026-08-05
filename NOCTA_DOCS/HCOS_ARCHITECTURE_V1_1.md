# HCOS Architecture v1.1

## Version

1.1

## Status

Architecture Frozen

Effective Date: 2026-08-04

This document is the canonical architecture specification for HCOS.

It supersedes HCOS Architecture v1.0 where the two conflict.

All V1 implementation must conform to this architecture.

Architectural changes require a formal Architecture Review.

## Purpose

HCOS (Human Cognitive Operating System) is the cognitive operating system of Nocta.

Its purpose is to reduce the cognitive load a person carries into the night and support a natural transition toward sleep.

HCOS does not exist to analyze people.

It does not exist to maximize conversation.

It does not exist to solve every problem.

It exists to subtract, not add.

Sleep is the outcome.

Relief is the product.

Every architectural decision must reduce, not increase, nighttime cognitive load.

## Design Principles

HCOS is governed by a small set of frozen architectural principles.

These principles remain stable across implementation changes.

### 1. One Living Mind Model

There is only one long-term cognitive model.

All persistent knowledge belongs here.

Living Mind Model stores durable knowledge only.

It must not store raw conversations, temporary emotions, or nightly dialogue.

### 2. One Memory Writer

Only MemoryEngine may update the Living Mind Model.

No other component writes persistent memory.

### 3. Conversations Are Temporary

A conversation exists only for the current night.

Only learned durable knowledge may survive.

Raw conversations are never stored.

### 4. Conversation Has Cost

Every additional message increases cognitive load.

HCOS always prefers fewer words.

### 5. Exit Is Success

The goal is not to maximize engagement.

The goal is to recognize when nothing more should be said.

### 6. Intelligence Must Be Invisible

Users should never feel analyzed.

They should only feel understood.

### 7. Memory Must Feel Like Attention

Personalization should feel like someone remembered.

Never like a system stored data.

### 8. Sleep Is Never Forced

HCOS never tries to make someone sleep.

It reduces what keeps them awake.

Sleep happens naturally.

### 9. Single Responsibility

Every component has one cognitive responsibility.

No component performs multiple cognitive roles.

### 10. Forward-Only Flow

Information moves only forward through the cognitive pipeline.

### 11. Persistent Memory Is Written Once

Persistent memory is written once per completed session.

Temporary session state is separated from long-term cognitive memory.

## What's New in v1.1

HCOS Architecture v1.1 preserves the product purpose and core principles of HCOS Architecture v1.0.

It incorporates the accepted Sprint 3 architecture decisions as the canonical V1 target.

The accepted architectural updates are:

1. Canonical pipeline ownership

Strategy-based Reasoning is replaced by protocol-based conversation flow.

ConversationPolicy is the protocol decision owner.

Release readiness, conversation protocol, and exit ownership are separated.

2. Canonical turn order

The target turn path is Release → ConversationPolicy → Exit → Conversation.

The v1.0 linear order that placed Conversation before Release and Exit is superseded.

3. ReasoningEngine deprecation

ReasoningEngine and ReasoningDecision are deprecated as decision producers.

Their former responsibilities are owned by ReleaseEngine, ConversationPolicy, and ExitIntelligence.

4. Cognitive orchestration

CognitiveOrchestrator is the forward-only coordinator of the production cognitive pipeline.

NoctaAIBrain is retained only as a transitional entry point pending cutover.

5. Temporary session isolation

NightSession, SessionTurn, WorkingMindView, SessionSummary, and SessionSummarizer define the separation between temporary night-session state and persistent Living Mind Model knowledge.

6. Session-end memory lifecycle

Durable knowledge is written through Night Session → Session Summary → Memory Engine → Living Mind Model.

Mid-turn persistent memory writes are not part of the canonical target architecture.

7. WorkingMindView boundary

Cognitive engines read persistent knowledge through WorkingMindView during a NightSession.

They do not own the mutable lifecycle of Living Mind Model.

8. Documentation authority

HCOS Architecture v1.1 is the single source of truth for V1.

Earlier HCOS documents remain historical where they conflict with these accepted updates.

v1.1 does not introduce new product features.

It records architectural maturation required for a production-ready cognitive pipeline.

## Scope

### This document covers

- The purpose and frozen design principles of HCOS
- The canonical V1 cognitive architecture after Sprint 3
- Ownership boundaries between cognitive components
- The conversation, release, and exit protocols at the architectural level
- The memory lifecycle and session lifecycle
- The separation of temporary session state from persistent knowledge
- V1 architectural scope and non-goals retained from HCOS Architecture v1.0

### This document does not cover

- Implementation status, unfinished wiring, or migration residue
- Code-level APIs, class internals, or engine algorithms
- Product UI, content libraries, or delivery surfaces
- Capabilities deferred to V2, including Conversation DNA, Adaptive Personality, Advanced Memory Decay, Recovery Signature, cross-session reasoning, predictive sleep modeling, and long-term behavioral adaptation
- Clinical, diagnostic, therapeutic, medical, crisis, journaling, productivity, or general chatbot responsibilities

HCOS remains intentionally limited.

It is not a therapist, psychologist, diagnostic system, medical device, sleep tracker, journaling application, productivity assistant, general-purpose chatbot, or crisis intervention system.

HCOS exists for one purpose:

To reduce the cognitive load a person carries into the night and support a natural transition toward sleep.
