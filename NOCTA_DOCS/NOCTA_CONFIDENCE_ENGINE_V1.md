# NOCTA CONFIDENCE ENGINE V1

## PURPOSE

This document defines how Nocta evaluates confidence during state detection.

The goal is not simply to identify a state.

The goal is to determine how certain Nocta should be before making downstream decisions.

Confidence influences:

- Playbook Selection
- Insight Selection
- Sleep Profile Selection
- Audio Experience Selection

---

# CONFIDENCE LEVELS

## HIGH CONFIDENCE

Definition:

One state clearly dominates the conversation.

Characteristics:

- Strong emotional signal
- Multiple matching patterns
- Little ambiguity

Example:

"I can't stop worrying about tomorrow."

Result:

Future Anxiety
Confidence: High

---

## MEDIUM CONFIDENCE

Definition:

One state leads, but secondary states are also present.

Characteristics:

- Mixed emotional signals
- One dominant theme
- Some ambiguity

Example:

"I'm worried about tomorrow and I can't stop thinking about it."

Result:

Future Anxiety
Confidence: Medium

Secondary State:

Overthinking

---

## LOW CONFIDENCE

Definition:

The user's state cannot be reliably determined.

Characteristics:

- Vague language
- Multiple competing signals
- Insufficient context

Example:

"I don't know what's wrong. I just feel off."

Result:

Unknown
Confidence: Low

---

# PRIMARY STATE RULE

Nocta should always identify:

Primary State

and optionally:

Secondary State

Example:

Future Anxiety: 70%
Overthinking: 30%

Primary State:

Future Anxiety

Secondary State:

Overthinking

---

# DECISION RULES

High Confidence:

- Proceed normally

Medium Confidence:

- Preserve awareness of secondary state
- Use dominant state for routing

Low Confidence:

- Delay precise routing
- Ask a gentle narrowing question
- Avoid committing to a specific sleep profile

---

# ROUTING EXAMPLES

Example 01

Future Anxiety: 85%
Overthinking: 15%

Selected State:

Future Anxiety

---

Example 02

Relationship: 55%
Loneliness: 45%

Selected State:

Relationship

Secondary State:

Loneliness

---

Example 03

Work Stress: 35%
Overthinking: 35%
Future Anxiety: 30%

Selected State:

Unknown

Action:

Ask for clarification

---

# CORE RULE

Nocta should not force certainty when certainty does not exist.

A slower correct decision is better than a confident wrong decision.

