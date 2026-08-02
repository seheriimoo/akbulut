# NOCTA MASTER ARCHITECTURE V1

## PURPOSE

This document defines the complete architecture of the Nocta system.

Its purpose is to show how all major engines, libraries and decision systems connect together.

This document serves as the navigation layer for the entire project.

---

# SYSTEM OVERVIEW

USER
↓
CONVERSATION
↓
STATE DETECTION
↓
ROUTING
↓
PLAYBOOK
↓
INSIGHT
↓
RESPONSE
↓
SLEEP PROFILE
↓
AUDIO INTELLIGENCE
↓
SLEEP EXPERIENCE

---

# LAYER 01 — FOUNDATIONS

Purpose:

Defines the philosophy, principles and behavioral rules of Nocta.

Files:

- 01_NOCTA_FOUNDATIONS.md

---

# LAYER 02 — STATE DETECTION

Purpose:

Identify the user's dominant emotional state.

Files:

- NOCTA_CATEGORY_DETECTION_V1_FINAL.md
- NOCTA_MENTAL_STATE_ENGINE_V1.md

---

# LAYER 03 — ROUTING

Purpose:

Route the user toward the correct psychological pattern.

Files:

- NOCTA_ROUTING_ENGINE_V1.md
- NOCTA_INSIGHT_ROUTING_V2_FINAL.md
- NOCTA_STATE_ROUTING_V1.md

---

# LAYER 04 — PLAYBOOKS

Purpose:

Provide conversational guidance for each detected pattern.

Files:

- NOCTA_CONVERSATION_PLAYBOOK_V1.md

---

# LAYER 05 — INSIGHTS

Purpose:

Provide the psychological insight used during reframing.

Files:

- 04_NOCTA_CONTENT_LIBRARY.md
- NOCTA_CORE_INSIGHTS_V1.md

---

# LAYER 06 — RESPONSE SYSTEM

Purpose:

Transform insights into conversational responses.

Files:

- NOCTA_RESPONSE_ENGINE_V3.md
- NOCTA_RESPONSE_ARCHITECTURE_V1.md
- NOCTA_RESPONSE_FORMULA_V1.md

---

# LAYER 07 — EXECUTION

Purpose:

Coordinate the full conversation flow.

Files:

- NOCTA_EXECUTION_ENGINE_V1.md
- NOCTA_DECISION_ENGINE_V1_FINAL.md

---

# LAYER 08 — AUDIO INTELLIGENCE

Purpose:

Select the correct sleep profile and audio experience.

Files:

- NOCTA_AUDIO_INTELLIGENCE_V1.md
- NOCTA_AUDIO_MAPPING_V1.md
- NOCTA_SLEEP_PROFILES_V1.md

---

# NORTH STAR

Nocta does not solve lives.

Nocta helps users carry less into the night.


---

# PRIMARY SYSTEM FILES

The following files represent the current active system.

FOUNDATIONS
→ 01_NOCTA_FOUNDATIONS.md

CONTENT LIBRARY
→ 04_NOCTA_CONTENT_LIBRARY.md

CATEGORY DETECTION
→ NOCTA_CATEGORY_DETECTION_V1_FINAL.md

ROUTING
→ NOCTA_INSIGHT_ROUTING_V2_FINAL.md

PLAYBOOK
→ NOCTA_CONVERSATION_PLAYBOOK_V1.md

RESPONSE ENGINE
→ NOCTA_RESPONSE_ENGINE_V3.md

EXECUTION ENGINE
→ NOCTA_EXECUTION_ENGINE_V1.md

AUDIO INTELLIGENCE
→ NOCTA_AUDIO_INTELLIGENCE_V1.md

MASTER SYSTEM PROMPT
→ NOCTA_MASTER_SYSTEM_PROMPT_V1_FINAL.md

---

# ARCHITECTURE PRINCIPLE

When multiple versions of a system exist,
the newest approved primary file should be treated as the source of truth.

The architecture should avoid duplicate logic across multiple files whenever possible.

