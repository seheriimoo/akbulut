# NOCTA CONTEXT EXTRACTION SYSTEM V1

---

# DOCUMENT STATUS

Version: 1.0
Status: In Development
System Layer: Context Intelligence
Pipeline Position: Second Analysis Layer

---

# PURPOSE

The Context Extraction System is the second intelligence layer of the Nocta AI pipeline.

Its purpose is to transform structured linguistic evidence into structured contextual understanding.

This module does not interpret psychology.

It does not detect emotions.

It does not identify sleep barriers.

Its responsibility is to determine what the user is talking about and organize that information into a standardized context representation.

---

# SYSTEM ROLE

The Context Extraction System receives the output of the Language Analysis System.

It identifies:

- topics
- people
- places
- events
- situations
- time references
- ongoing circumstances

The resulting context becomes the foundation for all downstream psychological reasoning.

---

# CORE RESPONSIBILITY

The Context Extraction System answers one question:

"What is the user talking about?"

It does not answer:

- Why the user feels this way.
- What mental state is present.
- Which sleep barrier is active.
- How Nocta should respond.

Those responsibilities belong to later AI modules.

---

# PRIMARY SUCCESS CONDITION

The Context Extraction System succeeds when every downstream module receives a complete, standardized and contextually accurate representation of the user's situation without introducing psychological interpretation.

---

# END OF PART 1


---

# INTERNAL PROCESSING PIPELINE

The Context Extraction System processes the structured linguistic output through a fixed sequence of stages.

Each stage performs one responsibility before passing its output to the next stage.

---

# PROCESSING STAGES

## Stage 1 — Input Validation

Objective:

Verify that the LanguageAnalysisResult is complete and structurally valid.

---

## Stage 2 — Topic Extraction

Objective:

Identify the primary and secondary topics discussed by the user.

Examples include:

- Work
- Relationships
- Family
- Health
- Money
- Sleep
- Future
- Daily responsibilities

---

## Stage 3 — Entity Extraction

Objective:

Identify explicit entities mentioned in the message.

Examples include:

- People
- Places
- Organizations
- Events
- Objects
- Dates

---

## Stage 4 — Situation Identification

Objective:

Determine the immediate situation being described.

Examples:

- Upcoming meeting
- Relationship conflict
- Financial difficulty
- Health concern
- Work deadline

---

## Stage 5 — Time Context

Objective:

Determine whether the user's context primarily refers to:

- Past
- Present
- Future
- Multiple timeframes

---

## Stage 6 — Context Structuring

Objective:

Combine all extracted contextual information into a standardized ContextExtractionResult.

No psychological interpretation is performed.

---

# PIPELINE GUARANTEES

The Context Extraction System guarantees that:

- Context is extracted consistently.
- Multiple contexts may coexist.
- Original context is preserved.
- Missing context is represented explicitly.
- No psychological assumptions are introduced.

---

# END OF PART 2


---

# CONTEXT CATEGORIES

The Context Extraction System may identify one or more contextual categories within a single user message.

A context category represents what the user's message is primarily about.

The system records context only.

It does not interpret psychological meaning.

---

## 1. Work Context

Examples:

- Meetings
- Deadlines
- Colleagues
- Career
- Responsibilities

---

## 2. Relationship Context

Examples:

- Partner
- Marriage
- Breakup
- Conflict
- Family relationships
- Friendships

---

## 3. Health Context

Examples:

- Illness
- Symptoms
- Medication
- Medical appointments
- Physical wellbeing

---

## 4. Financial Context

Examples:

- Debt
- Bills
- Salary
- Expenses
- Money concerns

---

## 5. Education Context

Examples:

- Exams
- School
- University
- Studying
- Assignments

---

## 6. Sleep Context

Examples:

- Falling asleep
- Staying asleep
- Night awakenings
- Bedtime routine

---

## 7. Daily Life Context

Examples:

- Household tasks
- Shopping
- Travel
- Personal responsibilities
- Daily routines

---

## 8. Multiple Contexts

A single message may contain multiple valid contexts.

Example:

"I have a presentation tomorrow and my dad is in the hospital."

Possible contexts:

- Work
- Health
- Family

All valid contexts must be preserved.

---

# PART 3 SUCCESS CONDITION

Part 3 is complete when:

- All primary context categories are standardized.
- Multiple contexts are supported.
- No psychological interpretation is introduced.
- Every detected context remains traceable to the original message.

---

# END OF PART 3


---

# OUTPUT STRUCTURE

Output Type:

ContextExtractionResult

The output contains contextual observations only.

It must never include psychological conclusions or inferred emotional states.

---

# OUTPUT FIELDS

The ContextExtractionResult may include:

- Primary Context
- Secondary Contexts
- Detected Topics
- Detected People
- Detected Places
- Detected Organizations
- Detected Events
- Detected Time References
- Current Situation
- Context Confidence
- Ambiguity Indicators

Each field must contain only observable contextual information.

---

# DESIGN RULE

The Context Extraction System answers only one question:

"What is the user's situation?"

It never answers:

"How does the user feel about the situation?"

That responsibility belongs to the Mental State Detection System.

---

# PART 4 SUCCESS CONDITION

Part 4 is complete when:

- The output format is fully standardized.
- Every downstream module can consume the ContextExtractionResult.
- No psychological interpretation appears in the output.
- Context remains fully traceable to the original message.

---

# END OF PART 4


---

# PART 5 — VALIDATION RULES

Every execution of the Context Extraction System must satisfy the following validation rules before its output is passed to downstream modules.

---

# REQUIRED VALIDATIONS

The module must verify that:

- Every required input field is present.
- Every extracted context references the original message.
- Context categories are valid.
- Confidence values are within valid limits.
- Ambiguous contexts are explicitly marked.
- No psychological conclusions are introduced.

---

# OUTPUT VALIDATION

Before returning the result, the module must ensure:

- The output follows the ContextExtractionResult contract.
- Required fields are complete.
- Duplicate contexts are merged consistently.
- Empty fields are handled consistently.
- Every confidence score is associated with a detected context.

---

# FAILURE HANDLING

If validation fails:

- Mark the extraction as invalid.
- Preserve the original message.
- Record the validation failure.
- Do not fabricate missing context.
- Return a structured validation error.

---

# DESIGN PRINCIPLE

Validation protects the integrity of the AI pipeline.

A downstream module must never receive malformed contextual data.

---

# PART 5 SUCCESS CONDITION

Part 5 is complete when:

- Every output is validated.
- Invalid context is detected consistently.
- Module integrity is preserved.
- Downstream modules can trust every ContextExtractionResult.

---

# END OF PART 5


---

# PART 6 — DETERMINISTIC TEST CASES

The following examples verify that the Context Extraction System produces consistent contextual outputs.

---

## Test Case 1

User:

"I have an important meeting tomorrow."

Expected Context:

- Work
- Future

---

## Test Case 2

User:

"My girlfriend left me last week."

Expected Context:

- Relationship
- Past

---

## Test Case 3

User:

"I can't pay my bills this month."

Expected Context:

- Financial
- Present

---

## Test Case 4

User:

"My dad is in the hospital."

Expected Context:

- Health
- Family
- Present

---

## Test Case 5

User:

"I have an exam tomorrow and I can't sleep."

Expected Context:

- Education
- Sleep
- Future

---

## Test Case 6

User:

"I need to buy groceries after work."

Expected Context:

- Daily Life
- Work
- Present

---

# SUCCESS CRITERIA

The Context Extraction System is considered deterministic when:

- The same input always produces the same contextual output.
- Context categories remain stable across executions.
- No psychological interpretation is introduced.
- Every extracted context is traceable to explicit evidence in the user's message.

---

# CONTEXT EXTRACTION SYSTEM V1 STATUS

Status: COMPLETE

