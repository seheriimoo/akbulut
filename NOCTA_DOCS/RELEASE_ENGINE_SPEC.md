# RELEASE ENGINE SPECIFICATION

## Purpose

ReleaseEngine determines the user's current Release Readiness.

It does not generate responses.

It does not select conversation phases.

It does not decide when to end the conversation.

Its only responsibility is to estimate how ready the user is to release cognitive effort.

---

# Inputs

ReleaseEngine receives:

- ValidatedUnderstanding
- NightSession
- WorkingMindView

ReleaseEngine never reads raw user messages.

ReleaseEngine never writes memory.

---

# Output

ReleaseEngine produces one immutable ReleaseDecision.

ReleaseDecision contains:

- ReleaseReadiness
- Confidence

Nothing else.

---

# Release Readiness States

The five readiness states are:

HOLD

REGULATED

SETTLING

RECEPTIVE

TRANSITION_READY

Readiness represents cognitive readiness.

It does not represent sleep.

---

# State Transition Rules

Allowed progression:

HOLD
↓

REGULATED
↓

SETTLING
↓

RECEPTIVE
↓

TRANSITION_READY

Backward transitions are allowed when new evidence increases activation.

Impossible transitions:

- HOLD → RECEPTIVE
- HOLD → TRANSITION_READY
- REGULATED → TRANSITION_READY

---

# Confidence

Confidence represents the reliability of the readiness estimate.

It is NOT knowledge confidence.

It is NOT memory confidence.

Confidence changes only when new evidence changes certainty.

---

# Responsibilities

ReleaseEngine MUST:

- Estimate Release Readiness
- Estimate confidence
- Remain deterministic
- Produce immutable ReleaseDecision

ReleaseEngine MUST NOT:

- Generate language
- Select conversation phases
- Trigger audio
- Write memory
- Learn user preferences
- Update LivingMindModel

---

# Unit Tests

The implementation should verify:

- Initial HOLD state
- Progression to REGULATED
- Progression to SETTLING
- Progression to RECEPTIVE
- Progression to TRANSITION_READY
- Impossible transitions
- Backward transitions
- Confidence updates
- Immutable ReleaseDecision

