# NOCTA LANGUAGE ANALYSIS SYSTEM V1

---

# PURPOSE

The Language Analysis System is the first intelligence layer of the Nocta AI pipeline.

Its responsibility is to transform raw user language into structured linguistic information that can be understood by downstream AI systems.

This module does not interpret psychology.

This module does not generate responses.

Its only responsibility is to accurately analyze how the user expresses their thoughts.

---

# POSITION IN AI PIPELINE

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

Conversation Generation

---

# PRIMARY RESPONSIBILITIES

The Language Analysis System is responsible for:

- Detecting the language used by the user.
- Identifying important linguistic features.
- Extracting sentence-level signals.
- Detecting uncertainty and certainty.
- Identifying emotional wording.
- Detecting temporal references.
- Recognizing negation.
- Preparing structured output for Context Extraction.


# MODULE BOUNDARIES

The Language Analysis System is responsible only for analyzing language.

It does not interpret psychology.

It does not detect emotional states.

It does not classify sleep barriers.

Its responsibility ends after extracting linguistic signals from the user's message.

The extracted information is passed to the Context Extraction System.


---

# INPUT

The input of this module is the user's raw message.

Examples:

"I can't stop thinking."

"I'm worried about tomorrow."

"I miss her."

"My mind won't switch off."

No assumptions are made before analysis begins.

---

# OUTPUT

The output of this module is structured linguistic information.

Examples of extracted information include:

- Language
- Sentence Structure
- Negation
- Temporal References
- Emotional Vocabulary
- Mental Verbs
- Sleep-related Expressions
- Pronouns
- Linguistic Confidence

This output becomes the input for the Context Extraction System.


---

# OUTPUT STRUCTURE

The Language Analysis System produces a structured analysis object.

This object does not contain interpretations.

It only contains linguistic observations.

Example:

Language:
English

Negation:
Present

Temporal Reference:
Future

Mental Verb:
Thinking

Sleep Reference:
Implicit

Emotional Vocabulary:
Present

Sentence Type:
Statement

Confidence:
High

This standardized output allows downstream AI modules to operate independently without reprocessing the user's original message.

