# NOCTA LANGUAGE ANALYSIS SYSTEM V1

---

# DOCUMENT STATUS

Version: 1.0  
Status: In Development  
System Layer: Linguistic Intelligence  
Pipeline Position: First Analysis Layer  

---

# PURPOSE

The Nocta Language Analysis System is the first intelligence layer of the Nocta AI pipeline.

Its purpose is to transform a user's raw message into a structured representation of the language used in that message.

The system identifies how the user expresses their experience before any psychological interpretation begins.

It analyzes linguistic form, wording, sentence construction, grammatical signals, explicit references and expression patterns.

The Language Analysis System does not decide what the user feels.

It does not determine why the user cannot sleep.

It does not select a conversation strategy.

It provides reliable linguistic evidence that downstream intelligence modules can interpret.

The primary design objective is:

> Convert raw human language into structured linguistic observations without adding psychological assumptions.

---

# SYSTEM ROLE

The Language Analysis System acts as the linguistic perception layer of Nocta.

Every user message enters this system before it reaches context, mental state, sleep barrier or conversation systems.

Its role is comparable to a sensory layer.

It observes the message.

It identifies the language signals present.

It organizes those signals.

It passes them forward in a standardized format.

The system must preserve the user's original meaning while avoiding premature interpretation.

---

# CORE RESPONSIBILITY

The core responsibility of this module is to answer:

> What is linguistically present in the user's message?

It may identify:

- The language used
- Sentence boundaries
- Sentence type
- Negation
- Temporal references
- Pronouns
- Modal expressions
- Certainty and uncertainty markers
- Intensifiers
- Repetition
- Emotional vocabulary
- Mental-action vocabulary
- Sleep-related vocabulary
- Explicit subjects and objects
- Linguistic ambiguity
- Message completeness

It must not answer:

- What psychological state the user is in
- What mental pattern is operating
- What sleep barrier is active
- What the user needs emotionally
- What Nocta should say next

Those responsibilities belong to downstream modules.

---

# SCOPE

The Language Analysis System processes the text of the user's current message.

Its scope includes:

- Language identification
- Basic sentence segmentation
- Token and phrase-level observation
- Grammatical and semantic signal extraction
- Detection of explicit linguistic features
- Identification of ambiguity and missing information
- Confidence estimation for each extracted signal
- Construction of a standardized output object

The system may use prior conversational messages only when required to resolve direct linguistic references such as:

- "it"
- "that"
- "again"
- "the same thing"
- "her"
- "him"
- "tomorrow"
- "still"

Even when previous messages are used, the module must remain limited to linguistic reference resolution.

It must not perform psychological interpretation.

---

# OUT OF SCOPE

The following operations are explicitly outside the responsibility of the Language Analysis System:

- Mental state classification
- Emotion classification as a final psychological conclusion
- Sleep barrier detection
- Mental pattern detection
- Intent prediction beyond explicit language form
- Therapeutic interpretation
- Clinical diagnosis
- Risk assessment
- Conversation strategy selection
- Response generation
- Audio recommendation
- User-profile personalization
- Long-term memory decisions

The system may detect the presence of emotional words.

It may not conclude that the user is experiencing a specific emotional state solely because those words are present.

Example:

User message:

"I am afraid I will never sleep."

Valid linguistic observation:

- Emotional vocabulary: "afraid"
- Future reference: "will"
- Absolute term: "never"
- Sleep reference: explicit

Invalid psychological conclusion:

- The user has future anxiety.

That conclusion belongs to the Mental State Detection System.

---

# MODULE BOUNDARIES

The Language Analysis System begins when it receives a raw user message.

It ends when it produces a structured linguistic analysis object.

Its boundary is defined by the difference between observation and interpretation.

Observation means identifying what is explicitly present in the language.

Interpretation means deciding what those signals psychologically indicate.

This module performs observation only.

---

## ALLOWED OPERATIONS

The module may:

- Detect that negation is present
- Detect that the user refers to the future
- Detect that a sentence contains uncertainty
- Detect that the user uses the word "worried"
- Detect that the user refers to sleep
- Detect repeated wording
- Detect first-person language
- Detect incomplete or fragmented syntax
- Detect direct questions
- Detect absolute expressions such as "always" or "never"
- Detect comparative wording
- Detect linguistic intensity

---

## PROHIBITED OPERATIONS

The module must not:

- Label the user as anxious
- Decide that rumination is occurring
- Infer abandonment fear
- Decide that loneliness is the primary state
- Determine the optimal response strategy
- Generate reassurance
- Recommend an audio session
- Infer clinical severity
- Diagnose insomnia
- Decide that the user is emotionally dysregulated

---

# POSITION IN THE AI PIPELINE

The Language Analysis System is the first transformation stage after message receipt.

Pipeline:

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

No downstream module should need to repeat basic linguistic analysis unless the Language Analysis System reports uncertainty.

---

# DESIGN PRINCIPLES

The Language Analysis System follows these principles:

## 1. Observation Before Interpretation

The system records linguistic evidence before any psychological meaning is assigned.

## 2. Explicit Evidence First

Explicit words and structures must be prioritized over inferred meaning.

## 3. Minimal Assumption

When language is ambiguous, the system must report ambiguity rather than invent certainty.

## 4. Signal-Level Confidence

Each extracted signal should include a confidence level where appropriate.

## 5. Language Preservation

The original message must remain available alongside the structured analysis.

## 6. Modular Independence

The system must produce output that downstream modules can use without reprocessing the original message.

## 7. Multilingual Readiness

The architecture must support multiple languages even if V1 initially prioritizes English.

## 8. Graceful Degradation

Short, fragmented or unclear messages must still produce a valid analysis object.

## 9. No Psychological Leakage

Psychological labels must never appear in this module's output.

## 10. Deterministic Structure

The same type of linguistic signal must always be represented in the same output field.

---

# PRIMARY SUCCESS CONDITION

The Language Analysis System succeeds when:

- It accurately identifies the linguistic signals present in the message.
- It avoids adding psychological assumptions.
- It produces a complete and valid structured output.
- Downstream modules can use the output without repeating the same analysis.
- Uncertainty is represented explicitly instead of hidden.

---

# END OF PART 1


---

# INTERNAL PROCESSING PIPELINE

The Language Analysis System follows a deterministic processing pipeline.

Every message passes through the same sequence of stages.

Each stage produces structured information that becomes the input of the following stage.

No stage is allowed to skip a previous stage.

The pipeline is designed to maximize consistency, reproducibility and modularity.

---

# PROCESSING FLOW

Raw User Message
↓

Language Identification
↓

Text Normalization
↓

Sentence Segmentation
↓

Token Extraction
↓

Linguistic Feature Detection
↓

Sentence-Level Signal Detection
↓

Confidence Estimation
↓

Structured Language Object

---

# PROCESSING STAGES

## Stage 1 — Language Identification

Objective:

Determine the primary language of the message.

Output:

- Primary language
- Confidence
- Mixed-language detection (if applicable)

---

## Stage 2 — Text Normalization

Objective:

Normalize the text while preserving the user's meaning.

Examples include:

- Standardizing whitespace
- Unicode normalization
- Preserving punctuation that carries meaning
- Preserving capitalization where linguistically relevant

Normalization must never alter the semantic meaning of the message.

---

## Stage 3 — Sentence Segmentation

Objective:

Divide the message into logical sentences or fragments.

The system must support:

- Complete sentences
- Fragmented thoughts
- Lists
- Multi-line input
- Stream-of-consciousness writing

---

## Stage 4 — Token Extraction

Objective:

Identify meaningful linguistic units.

Examples:

- Words
- Numbers
- Dates
- Pronouns
- Negations
- Modal verbs
- Temporal expressions

The tokenizer must preserve token positions for downstream reference.

---

## Stage 5 — Linguistic Feature Detection

Objective:

Extract observable linguistic signals.

Examples include:

- Negation
- Certainty
- Uncertainty
- Temporal references
- Pronouns
- Intensifiers
- Comparisons
- Absolute terms
- Sleep vocabulary
- Mental verbs
- Emotional wording

This stage records observations only.

---

## Stage 6 — Sentence-Level Signal Detection

Objective:

Combine token-level observations into sentence-level linguistic signals.

Examples:

- Statement
- Question
- Request
- Conditional wording
- Sequential events
- Repeated constructions

No psychological interpretation is performed.

---

## Stage 7 — Confidence Estimation

Objective:

Assign a confidence score to each extracted signal.

Confidence reflects linguistic certainty, not psychological certainty.

Signals with insufficient evidence should receive lower confidence values rather than forced classifications.

---

## Stage 8 — Structured Output Generation

Objective:

Package every extracted signal into the standardized Language Analysis Object.

This object becomes the only output consumed by downstream modules.

The original message must remain attached to the output for traceability.

---

# PIPELINE GUARANTEES

The Language Analysis System guarantees that:

- Every message passes through every stage.
- Output structure is deterministic.
- Missing information is represented explicitly.
- Uncertainty is preserved.
- No psychological labels are introduced.
- Original user wording remains available.

---

# END OF PART 2



---

# DETECTION CATEGORIES

The Language Analysis System organizes linguistic observations into standardized detection categories.

These categories define what the module is allowed to identify.

Each detected signal must contain:

- A category
- A signal type
- The source text
- Its location in the message
- A normalized value when applicable
- A confidence score

Detection categories describe language only.

They must not contain psychological diagnoses, mental-state conclusions or response recommendations.

---

# 1. LANGUAGE DETECTION

Purpose:

Identify the primary language used in the message.

The system may detect:

- Primary language
- Secondary language
- Mixed-language usage
- Unknown language
- Language-switching points
- Language detection confidence

Example:

User message:

"I can't sleep, kafam susmuyor."

Valid observations:

- Primary language: English
- Secondary language: Turkish
- Mixed-language message: true
- Language switch detected: true

The system must preserve mixed-language segments rather than translating or deleting them.

---

# 2. SENTENCE AND FRAGMENT DETECTION

Purpose:

Identify the structural units contained in the message.

The system must distinguish between:

- Complete sentences
- Incomplete sentences
- Fragments
- Questions
- Statements
- Commands
- Requests
- Lists
- Repeated fragments
- Multi-line thoughts

Example:

User message:

"Tomorrow. The meeting. Everything."

Valid observations:

- Fragment count: 3
- Complete sentence count: 0
- Punctuation-separated units: 3

The system must not treat fragmented language as invalid input.

---

# 3. NEGATION DETECTION

Purpose:

Identify explicit linguistic negation.

Examples include:

- not
- no
- never
- cannot
- can't
- won't
- don't
- nothing
- nobody
- nowhere

The system must record:

- Negation term
- Negated expression
- Scope of negation
- Token position
- Confidence

Example:

User message:

"I can't stop thinking."

Valid observations:

- Negation term: "can't"
- Negated predicate: "stop thinking"
- Negation present: true

The system must not conclude that the user is overthinking.

---

# 4. TEMPORAL REFERENCE DETECTION

Purpose:

Identify explicit references to time.

Supported temporal categories include:

- Past
- Present
- Future
- Ongoing
- Repeated
- Immediate
- Tonight
- Tomorrow
- Yesterday
- Recently
- Long-term
- Unspecified time

Examples:

- "It happened yesterday."
- "I am still thinking about it."
- "I have a meeting tomorrow."
- "This happens every night."

The system must distinguish grammatical tense from explicit temporal reference.

Example:

"I am worried about tomorrow."

Valid observations:

- Grammatical tense: present
- Explicit temporal reference: future
- Temporal expression: "tomorrow"

---

# 5. PRONOUN AND REFERENCE DETECTION

Purpose:

Identify people, objects or events referenced through pronouns and indirect expressions.

Examples include:

- I
- me
- my
- you
- he
- she
- they
- it
- this
- that
- something
- someone
- the same thing

The system must record whether a reference is:

- Resolved
- Unresolved
- Partially resolved
- Ambiguous

Example:

User message:

"I keep thinking about it."

Valid observation:

- Pronoun: "it"
- Reference status: unresolved
- Resolution confidence: low

The system must not invent what "it" refers to.

---

# 6. CERTAINTY AND UNCERTAINTY DETECTION

Purpose:

Identify how certain or uncertain the user presents a statement.

Certainty markers may include:

- definitely
- certainly
- clearly
- I know
- I am sure
- without doubt

Uncertainty markers may include:

- maybe
- perhaps
- probably
- I think
- I guess
- I don't know
- what if
- possibly

Example:

"Maybe I made the wrong decision."

Valid observations:

- Uncertainty marker: "maybe"
- Statement confidence expressed by user: low
- Proposition: "I made the wrong decision"

This confidence represents the user's linguistic certainty, not system confidence.

---

# 7. MODALITY DETECTION

Purpose:

Identify modal expressions that describe possibility, necessity, ability, permission or obligation.

Modal categories include:

- Possibility
- Probability
- Necessity
- Obligation
- Ability
- Inability
- Permission
- Intention

Common modal terms include:

- can
- could
- may
- might
- must
- should
- would
- need to
- have to

Example:

"I should sleep, but I can't."

Valid observations:

- Obligation modality: "should"
- Inability modality: "can't"
- Explicit contrast: true

---

# 8. INTENSITY DETECTION

Purpose:

Identify linguistic signals that strengthen or weaken an expression.

Intensifiers may include:

- very
- really
- extremely
- completely
- so
- too
- absolutely
- deeply

Downtoners may include:

- slightly
- a little
- somewhat
- kind of
- almost

Example:

"I am completely exhausted."

Valid observations:

- Intensifier: "completely"
- Modified expression: "exhausted"
- Intensity direction: increased

Intensity detection must not be converted directly into clinical severity.

---

# 9. ABSOLUTE LANGUAGE DETECTION

Purpose:

Identify expressions that present an experience as total, permanent or exceptionless.

Examples include:

- always
- never
- everyone
- nobody
- everything
- nothing
- completely
- forever
- every time

Example:

"I always ruin everything."

Valid observations:

- Absolute frequency term: "always"
- Absolute scope term: "everything"

The system must not challenge or reframe the statement.

---

# 10. REPETITION DETECTION

Purpose:

Identify repeated words, phrases or sentence structures.

The system may detect:

- Exact repetition
- Partial repetition
- Repeated keywords
- Repeated sentence openings
- Repeated punctuation
- Repeated concepts expressed with similar wording

Example:

"I can't stop. I can't stop thinking. I can't stop."

Valid observations:

- Repeated phrase: "I can't stop"
- Repetition count: 3
- Repetition type: exact and expanded

Repetition is recorded as a linguistic signal only.

---

# 11. CONTRAST AND CONJUNCTION DETECTION

Purpose:

Identify relationships explicitly expressed between clauses.

Supported relationships include:

- Contrast
- Addition
- Cause
- Result
- Condition
- Sequence
- Alternative
- Concession

Common markers include:

- but
- and
- because
- so
- if
- then
- or
- although
- even though
- yet

Example:

"I am tired, but my mind is awake."

Valid observations:

- Relationship type: contrast
- First clause: "I am tired"
- Second clause: "my mind is awake"
- Connector: "but"

---

# 12. QUESTION DETECTION

Purpose:

Identify direct and indirect questions.

Question categories include:

- Yes-or-no question
- Open question
- Rhetorical question
- Self-directed question
- Clarification request
- Possibility question
- Future-oriented question

Example:

"What if I cannot handle tomorrow?"

Valid observations:

- Question type: possibility question
- Question marker: "what if"
- Future reference: "tomorrow"
- Negation: "cannot"

The system must not assume whether the question is rhetorical unless sufficient linguistic evidence exists.

---

# 13. REQUEST AND COMMAND DETECTION

Purpose:

Identify explicit requests, instructions or commands.

Examples include:

- "Help me sleep."
- "Tell me what to do."
- "Please stay with me."
- "Don't ask me questions."

The system must record:

- Request type
- Requested action
- Politeness marker
- Negated instruction
- Directness level

This module identifies the linguistic request only.

It does not decide whether or how Nocta should comply.

---

# 14. EMOTIONAL VOCABULARY DETECTION

Purpose:

Identify words or phrases that explicitly name or describe emotion.

Examples include:

- afraid
- worried
- sad
- angry
- lonely
- hurt
- ashamed
- overwhelmed
- calm
- relieved

The output must use the label:

Emotional vocabulary detected

It must not use:

User emotion classified

Example:

"I feel afraid."

Valid observations:

- Emotional term: "afraid"
- Expression form: explicit self-description
- Subject: first person

Invalid conclusion:

- Mental state: anxiety

---

# 15. MENTAL-ACTION VOCABULARY DETECTION

Purpose:

Identify language describing cognitive activity.

Examples include:

- think
- remember
- imagine
- analyze
- wonder
- worry
- replay
- understand
- decide
- forget
- focus

Example:

"I keep replaying the conversation."

Valid observations:

- Mental-action term: "replaying"
- Grammatical aspect: ongoing/repeated
- Object: "the conversation"

The system must not classify the mental pattern.

---

# 16. SLEEP-RELATED LANGUAGE DETECTION

Purpose:

Identify explicit or implicit sleep-related expressions.

Explicit examples:

- sleep
- asleep
- insomnia
- bedtime
- wake up
- awake
- tired
- exhausted

Potentially implicit examples:

- "My mind won't switch off."
- "I have been staring at the ceiling."
- "I keep checking the time."

Implicit sleep references must receive lower confidence unless supported by context.

The system must record:

- Sleep term
- Explicit or implicit status
- Linguistic evidence
- Confidence

It must not diagnose insomnia or determine the sleep barrier.

---

# 17. BODY-RELATED LANGUAGE DETECTION

Purpose:

Identify explicit physical or bodily expressions.

Examples include:

- heart racing
- chest tight
- headache
- restless
- tense
- breathing
- shaking
- physically tired

The module records the expression exactly as used.

It must not infer a medical condition or physiological cause.

---

# 18. PERSON AND RELATIONSHIP REFERENCE DETECTION

Purpose:

Identify explicit references to people and relationships.

Examples include:

- partner
- mother
- father
- friend
- boss
- colleague
- ex
- husband
- wife
- child

The module may identify:

- Relationship term
- Named entity
- Pronoun used
- Possessive relationship
- Reference ambiguity

It must not infer the quality or psychological meaning of the relationship.

---

# 19. EVENT AND TOPIC REFERENCE DETECTION

Purpose:

Identify explicit events, situations or topics mentioned by the user.

Examples include:

- meeting
- exam
- argument
- breakup
- work
- money
- health
- decision
- mistake
- conversation

The system records these as linguistic topic references.

It does not decide which topic is psychologically primary.

---

# 20. MESSAGE COMPLETENESS DETECTION

Purpose:

Estimate whether the message contains enough linguistic information for reliable downstream interpretation.

Possible values:

- Complete
- Partially complete
- Fragmentary
- Highly ambiguous
- Empty
- Non-linguistic

Examples of incomplete input:

- "Again."
- "Everything."
- "I don't know."
- "..."
- "Her."

Incomplete messages must still produce a valid output object.

The system should identify what is missing without inventing it.

---

# 21. NON-TEXTUAL AND PARALINGUISTIC SIGNALS

Purpose:

Identify meaning-bearing textual features that are not ordinary words.

Examples include:

- Repeated punctuation
- Ellipses
- Capitalization
- Emojis
- Line breaks
- Repeated letters
- Typographical emphasis

Example:

"I CAN'T DO THIS ANYMORE!!!"

Valid observations:

- Full capitalization detected
- Repeated exclamation marks detected
- Linguistic emphasis: high

These signals must not be translated directly into clinical severity.

---

# 22. TYPOGRAPHICAL NOISE DETECTION

Purpose:

Identify likely spelling errors, keyboard errors or informal shorthand.

The system may detect:

- Probable typo
- Missing punctuation
- Informal contraction
- Slang
- Abbreviation
- Repeated letters
- Phonetic spelling

The system may create a normalized interpretation only when confidence is sufficient.

The original wording must always be preserved.

Example:

"I cant slep."

Possible normalized observations:

- "cant" → "can't"
- "slep" → "sleep"

Normalization confidence must be recorded separately for each correction.

---

# DETECTION OUTPUT RULES

Every detected linguistic signal must include, where applicable:

- `category`
- `type`
- `source_text`
- `normalized_value`
- `start_index`
- `end_index`
- `sentence_index`
- `confidence`
- `resolution_status`
- `notes`

Fields that do not apply must be represented as null or omitted according to the final schema standard.

---

# CONFLICT HANDLING

A single expression may belong to multiple detection categories.

Example:

"I will never sleep."

Possible detections:

- Future reference: "will"
- Absolute language: "never"
- Negation: "never"
- Sleep-related language: "sleep"

The system must preserve all valid signals.

It must not force each expression into only one category.

---

# AMBIGUITY RULE

When a linguistic signal has more than one plausible interpretation:

- Preserve the original text.
- Record each plausible interpretation.
- Assign confidence separately.
- Mark the signal as ambiguous.
- Do not select a final meaning without sufficient evidence.

Example:

"I can't face tomorrow."

Possible linguistic readings:

- Literal inability
- Figurative inability

The Language Analysis System records the ambiguity.

A downstream module determines contextual meaning.

---

# PART 3 SUCCESS CONDITION

Part 3 is implemented correctly when:

- All permitted detection categories are standardized.
- Psychological interpretation remains outside the module.
- Multiple signals can coexist without conflict.
- Ambiguity is represented explicitly.
- Every signal remains traceable to the original message.
- Downstream modules receive consistent linguistic evidence.

---

# END OF PART 3

---

# PART 4 — INPUT & OUTPUT CONTRACT

The Language Analysis System follows the standardized AI Data Contract defined by the Nocta AI Operating System.

Its responsibility is to transform a raw user message into structured linguistic evidence.

It never performs contextual, psychological or behavioral interpretation.

---

# INPUT

Input Type:

UserMessage

Required Fields:

- message_id
- session_id
- timestamp
- language
- raw_text

The module must preserve the original user message exactly as received.

No preprocessing may alter the original text.

---

# OUTPUT

Output Type:

LanguageAnalysisResult

The output contains structured linguistic evidence only.

It may include:

- detected language
- sentence boundaries
- linguistic signals
- negations
- temporal references
- certainty indicators
- emotional vocabulary
- sleep-related vocabulary
- structural observations
- ambiguity markers
- confidence scores

The output must never include:

- psychological interpretation
- mental state
- sleep diagnosis
- conversation strategy
- response generation
- user profiling

These responsibilities belong to downstream AI modules.

---

# DESIGN RULE

The Language Analysis System answers only one question:

"What linguistic evidence exists inside the user's message?"

It never answers:

"What does the message mean?"

Meaning is determined by later modules in the AI pipeline.

---

# PART 4 SUCCESS CONDITION

Part 4 is complete when:

- Input is fully standardized.
- Output is fully standardized.
- Module boundaries remain protected.
- No psychological interpretation exists inside the Language Analysis System.

---

# END OF PART 4


---

# PART 5 — VALIDATION RULES

Every execution of the Language Analysis System must satisfy the following validation rules before its output is passed to downstream modules.

---

# REQUIRED VALIDATIONS

The module must verify that:

- Every required input field is present.
- The original message remains unchanged.
- Every detected signal references the original message.
- Confidence values are within valid limits.
- Every ambiguity is explicitly marked.
- No unsupported interpretation is introduced.
- No psychological conclusions are generated.

---

# OUTPUT VALIDATION

Before returning the result, the module must ensure:

- The output follows the LanguageAnalysisResult contract.
- Required fields are complete.
- No duplicate linguistic signals exist.
- Empty fields are handled consistently.
- Invalid values are rejected.
- Every confidence score is associated with a detected signal.

---

# FAILURE HANDLING

If validation fails:

- Mark the analysis as invalid.
- Preserve the original user message.
- Record the validation failure.
- Do not fabricate missing information.
- Return a structured validation error.

---

# DESIGN PRINCIPLE

Validation protects the integrity of the AI pipeline.

A downstream module must never receive malformed linguistic data.

---

# PART 5 SUCCESS CONDITION

Part 5 is complete when:

- Every output is validated.
- Invalid data is detected consistently.
- Module integrity is preserved.
- Downstream modules can trust every LanguageAnalysisResult.

---

# END OF PART 5


---

# PART 6 — TEST CASES

The following examples verify that the Language Analysis System behaves consistently across different message types.

---

## TEST CASE 01

Input:

"I can't stop thinking."

Expected Detection:

- Language: English
- Negation detected
- Mental vocabulary detected
- Present tense detected

No psychological interpretation.

---

## TEST CASE 02

Input:

"I'm exhausted but my mind won't sleep."

Expected Detection:

- Body-related vocabulary
- Sleep-related vocabulary
- Negation detected
- Contraction detected

No mental state inference.

---

## TEST CASE 03

Input:

"What if tomorrow goes wrong?"

Expected Detection:

- Future reference
- Question detected
- Uncertainty language
- Temporal reference

No anxiety diagnosis.

---

## TEST CASE 04

Input:

"I feel fine."

Expected Detection:

- Emotional vocabulary
- Present tense

No additional interpretation.

---

# PART 6 SUCCESS CONDITION

Part 6 is complete when:

- Every test case produces deterministic linguistic output.
- No psychological conclusions are introduced.
- All outputs conform to the LanguageAnalysisResult contract.
- Every result is reproducible.

---

# END OF PART 6

