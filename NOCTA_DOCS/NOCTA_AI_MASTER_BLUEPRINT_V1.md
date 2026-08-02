# NOCTA AI MASTER BLUEPRINT V1

---

# PURPOSE

The AI Master Blueprint defines the complete architecture of the Nocta AI System.

Its purpose is to describe how every AI module works together from the moment a user sends a message until the final response is delivered.

This document is the architectural reference for every AI component in Version 1.

Every AI module must align with this blueprint.

---

# CORE PHILOSOPHY

Nocta does not respond directly to user messages.

Instead, every message passes through a sequence of specialized intelligence modules.

Each module has a single responsibility.

Each module produces structured information for the next module.

This modular architecture makes the system explainable, testable and scalable.

---

# HIGH LEVEL AI PIPELINE

User Message
        ↓
Language Analysis
        ↓
Context Extraction
        ↓
Mental State Detection
        ↓
Sleep Barrier Detection
        ↓
Mental Pattern Detection
        ↓
Conversation Strategy
        ↓
Conversation Generation
        ↓
Response Validation
        ↓
Audio Intelligence
        ↓
Final Response

---

# AI MODULES

## 1. Language Analysis

Purpose:
Analyze the linguistic characteristics of the user's message without interpreting psychological meaning.

Input:
Raw user message.

Output:
Structured linguistic features.

---

## 2. Context Extraction

Purpose:
Identify what the user is talking about by extracting topics, people, events, situations and relevant context.

Input:
Language Analysis output.

Output:
Structured contextual information.

---

## 3. Mental State Detection

Purpose:
Infer the user's current emotional and cognitive state from the extracted context.

Input:
Context data.

Output:
Mental state profile.

---

## 4. Sleep Barrier Detection

Purpose:
Determine what is preventing the user from naturally transitioning toward sleep.

Input:
Mental state profile.

Output:
Sleep barrier classification.

---

## 5. Mental Pattern Detection

Purpose:
Recognize recurring thinking patterns and cognitive loops influencing the user's current state.

Input:
Sleep barrier + mental state.

Output:
Mental pattern profile.

---

## 6. Conversation Strategy

Purpose:
Determine the most appropriate conversational approach before generating a response.

Input:
All previous AI analyses.

Output:
Conversation strategy.

---

## 7. Conversation Generation

Purpose:
Generate a personalized response using the selected strategy.

Input:
Conversation strategy.

Output:
Candidate response.

---

## 8. Response Validation

Purpose:
Ensure the response satisfies Nocta's standards for empathy, clarity, safety and quality.

Input:
Candidate response.

Output:
Validated response.

---

## 9. Audio Intelligence

Purpose:
Decide whether audio should be offered and select the most appropriate soundscape.

Input:
Validated response.

Output:
Recommended audio experience.

---

# ARCHITECTURAL PRINCIPLES

- Every module has one responsibility.
- Every module has a clearly defined input.
- Every module has a clearly defined output.
- Modules never skip one another.
- Higher-level modules never duplicate lower-level responsibilities.
- The pipeline remains deterministic and explainable.

