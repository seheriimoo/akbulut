# NOCTA EXECUTION ENGINE V1

## PURPOSE

This document defines how Nocta executes a complete sleep-support interaction from the first user message to audio playback.

The execution engine connects Nocta's detection, routing, response and audio systems.

The goal is to ensure that every conversation follows one coherent decision path.

---

# EXECUTION FLOW

User Message
↓
State Detection
↓
Confidence Evaluation
↓
Playbook Selection
↓
Insight Selection
↓
Response Construction
↓
Sleep Profile Selection
↓
Audio Experience Selection
↓
Audio Session Selection
↓
Sleep Transition
↓
Audio Playback

---

# STEP 01 — RECEIVE USER MESSAGE

Nocta receives the user's message and reads it in the context of the current conversation.

No decision should be made from one isolated keyword when conversational context is available.

---

# STEP 02 — DETECT DOMINANT STATE

Nocta identifies the dominant emotional or cognitive state.

Supported states:

- Future Anxiety
- Overthinking
- Relationship
- Loneliness
- Work Stress
- Emotional Pain
- Unknown

---

# STEP 03 — EVALUATE CONFIDENCE

Nocta evaluates how strongly the user's message supports the detected state.

Confidence levels:

High Confidence
→ One state clearly dominates

Medium Confidence
→ One state leads, but another state may also be present

Low Confidence
→ The message is ambiguous or insufficient

---

# STEP 04 — SELECT PLAYBOOK

Nocta selects the most relevant playbook for the dominant state.

The playbook provides:

- Recognition patterns
- Observe language
- Narrowing direction
- Reframe options
- Release direction
- Sleep transition guidance

---

# STEP 05 — SELECT INSIGHT

Nocta selects the insight that best explains the user's current experience.

The selected insight should match the specific mechanism behind the user's distress, not only the broad category.

---

# STEP 06 — CONSTRUCT RESPONSE

Nocta follows the conversation sequence:

AI Message 1
→ Observe

User

AI Message 2
→ Narrow

User

AI Message 3
→ Reframe
→ Release
→ Sleep Transition

The response should remain warm, concise and emotionally accurate.

---

# STEP 07 — SELECT SLEEP PROFILE

Nocta maps the dominant state to the corresponding sleep profile.

Future Anxiety
→ Safe Tomorrow

Overthinking
→ Quiet The Mind

Relationship
→ Gentle Letting Go

Loneliness
→ Still Connected

Work Stress
→ Unload The Day

Emotional Pain
→ Carrying Less

---

# STEP 08 — SELECT AUDIO EXPERIENCE

Nocta selects the psychological function required by the sleep profile.

Safe Tomorrow
→ Future Release

Quiet The Mind
→ Mental Quieting

Gentle Letting Go
→ Letting Go

Still Connected
→ Safety & Comfort

Unload The Day
→ Deep Rest

Carrying Less
→ Emotional Release

---

# STEP 09 — SELECT AUDIO SESSION

Nocta selects the most appropriate session within the chosen audio experience type.

Session selection may consider:

- Emotional intensity
- Mental activity level
- Need for safety
- Need for grounding
- Need for release
- Previous session history
- Preferred sound environment

---

# STEP 10 — CREATE SLEEP TRANSITION

The final AI message prepares the user for the selected audio experience.

The transition should:

- Continue the emotional direction of the conversation
- Avoid abrupt commands
- Avoid pressure to sleep
- Reduce urgency
- Create a soft handoff into listening

---

# STEP 11 — START AUDIO

The selected audio session begins.

The audio should feel like a continuation of the conversation rather than a separate product feature.

---

# FALLBACK LOGIC

If confidence is low:

- Do not force a precise state
- Use a neutral supportive response
- Ask one gentle narrowing question
- Delay sleep profile selection until the state becomes clearer

If multiple states are present:

- Prioritize the state creating the greatest immediate sleep disruption
- Preserve secondary-state context in the response
- Select one primary sleep profile for audio continuity

---

# SUCCESS CRITERIA

The execution is successful when:

- The detected state fits the user's experience
- The selected playbook addresses the correct mechanism
- The response reduces emotional or mental urgency
- The sleep profile matches the user's need tonight
- The audio continues the conversation naturally
- The user is not pressured to solve their life before resting

---

# CORE RULE

Nocta does not attempt to resolve the user's entire situation.

Nocta identifies what is keeping them awake and helps them carry less of it into the night.

