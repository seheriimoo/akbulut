# NOCTA EVIDENCE EXTRACTION SYSTEM V1


---

# PART 1 — PURPOSE

The Evidence Extraction System is the first intelligence layer in the Nocta AI Architecture.

Its purpose is to transform a raw user message into structured, observable evidence that can be reliably consumed by downstream AI systems.

The system extracts only evidence that is explicitly supported by the user's message.

It never interprets, diagnoses, predicts or generates responses.

The output of this system is a structured Evidence Object, which serves as the single source of truth for all subsequent AI modules.

---

# END OF PART 1


---

# PART 2 — RESPONSIBILITIES

The Evidence Extraction System is responsible for:

- Reading the complete user message.
- Identifying all observable evidence.
- Extracting evidence without interpretation.
- Classifying evidence into predefined Evidence Categories.
- Building a structured Evidence Object.
- Delivering the Evidence Object to downstream AI systems.

The Evidence Extraction System is NOT responsible for:

- Detecting Mental States.
- Detecting Sleep Barriers.
- Selecting Conversation Strategies.
- Generating responses.
- Recommending audio.
- Making psychological interpretations.
- Diagnosing the user.
- Predicting user intentions.

The system performs extraction only.

---

# END OF PART 2


---

# PART 3 — INPUT

The Evidence Extraction System accepts a single input:

## Raw User Message

The raw user message is the original message submitted by the user before any interpretation or processing.

The input may contain:

- Natural language
- Emojis
- Typing patterns
- Punctuation
- Multiple sentences
- Incomplete thoughts

The system processes the complete message as a single input.

No external knowledge, previous AI decisions or inferred information may be used during evidence extraction.

The Raw User Message is the only source of evidence.

---

# END OF PART 3


---

# PART 4 — OUTPUT

The output of the Evidence Extraction System is a structured Evidence Object.

The Evidence Object contains only observable evidence extracted from the user's message.

It consists of the following categories:

- Language Evidence
- Context Evidence
- Cognitive Evidence
- Emotional Evidence
- Behavioral Evidence

The Evidence Object must be:

- Structured
- Deterministic
- Evidence-based
- Complete
- Free from interpretation

Every downstream AI system consumes the Evidence Object instead of the raw user message.

The Evidence Object serves as the single source of truth throughout the Nocta AI pipeline.

---

# END OF PART 4


---

# PART 5 — INTERNAL PROCESS

The Evidence Extraction System follows a deterministic processing pipeline.

## Step 1 — Receive Input

Receive the complete Raw User Message.

## Step 2 — Parse Message

Analyze the message without interpretation.

Identify all observable linguistic, contextual, cognitive, emotional and behavioral signals.

## Step 3 — Extract Evidence

Extract only evidence that is explicitly supported by the user's message.

No assumptions or inferred conclusions are permitted.

## Step 4 — Classify Evidence

Assign every extracted observation to one of the predefined Evidence Categories.

- Language Evidence
- Context Evidence
- Cognitive Evidence
- Emotional Evidence
- Behavioral Evidence

## Step 5 — Build Evidence Object

Combine all classified evidence into a single structured Evidence Object.

## Step 6 — Deliver Output

Deliver the completed Evidence Object to the next AI module.

The Evidence Extraction System performs no reasoning beyond evidence extraction.

---

# END OF PART 5


---

# PART 6 — DECISION RULES

The Evidence Extraction System applies the following decision rules during extraction.

## Rule 1 — Evidence Must Be Observable

Only information explicitly present in the Raw User Message may be extracted.

---

## Rule 2 — No Interpretation

The system must never infer meaning beyond the user's message.

---

## Rule 3 — No Assumptions

Missing information must never be guessed or completed.

---

## Rule 4 — Single Classification

Each extracted observation should be assigned to the most appropriate Evidence Category.

---

## Rule 5 — Preserve Original Meaning

Extracted evidence must preserve the user's original meaning without modification.

---

## Rule 6 — Evidence Before Everything

If sufficient observable evidence does not exist, no evidence should be created.

---

# END OF PART 6


---

# PART 7 — VALIDATION RULES

Before delivering the Evidence Object to downstream AI systems, the Evidence Extraction System must validate its output.

## Validation Rule 1 — Evidence Integrity

Every extracted evidence item must be directly supported by the Raw User Message.

---

## Validation Rule 2 — No Fabricated Evidence

The system must never create evidence that is not explicitly observable.

---

## Validation Rule 3 — Correct Classification

Every evidence item must belong to exactly one Evidence Category.

---

## Validation Rule 4 — Completeness

All observable evidence contained in the Raw User Message should be extracted whenever possible.

---

## Validation Rule 5 — Output Consistency

The Evidence Object must follow the predefined structure before being delivered.

---

# END OF PART 7


---

# PART 8 — FAILURE HANDLING

The Evidence Extraction System must fail safely when sufficient observable evidence cannot be extracted.

## Failure Case 1 — Empty Message

If the Raw User Message is empty, no Evidence Object should be generated.

---

## Failure Case 2 — Insufficient Evidence

If the message does not contain sufficient observable evidence, the system should return an empty Evidence Object rather than creating unsupported evidence.

---

## Failure Case 3 — Ambiguous Information

If multiple interpretations are possible, the system must preserve ambiguity and avoid making assumptions.

---

## Failure Case 4 — Invalid Input

If the input cannot be processed, the system should terminate the extraction process without generating fabricated evidence.

---

# END OF PART 8


---

# PART 9 — TEST CASES

## Test Case 1 — Overthinking

### Input

"I can't stop thinking about tomorrow."

### Expected Evidence

- Cognitive Evidence → Repetitive thinking
- Context Evidence → Future
- Emotional Evidence → Worry

### Expected Output

A valid Evidence Object containing only observable evidence.

---

## Test Case 2 — Work Stress

### Input

"I feel exhausted because of work."

### Expected Evidence

- Context Evidence → Work
- Emotional Evidence → Exhaustion

### Expected Output

A valid Evidence Object without additional interpretation.

---

## Test Case 3 — Empty Message

### Input

""

### Expected Output

No Evidence Object generated.

---

## Test Case 4 — Ambiguous Message

### Input

"I don't know anymore."

### Expected Output

Only directly observable evidence should be extracted.

No assumptions about Mental State or Sleep Barrier are permitted.

---

# END OF PART 9

---

# END OF DOCUMENT

