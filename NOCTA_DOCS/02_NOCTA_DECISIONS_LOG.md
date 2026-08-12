# 🌙 NOCTA DECISIONS LOG

## DECISION 001

Date: 2026-06-27

Topic:
Core Value

Decision:
Nocta'nın temel değeri, kişinin yaşadığı uyku engelini anlamak ve ona uygun duygusal, zihinsel ve işitsel bir uykuya geçiş deneyimi sunmaktır.

Reason:
Bu tanım AI sohbet deneyimini, zihinsel ve duygusal katmanı ve ses deneyimini tek çatı altında birleştirir.


---

## DECISION 002

Date: 2026-06-27

Topic:
Knowledge Management System

Decision:
Nocta için Foundations, Decisions Log, Roadmap, Content Library ve Ideas Parking Lot dosyalarından oluşan kalıcı bilgi yönetim sistemi kurulmuştur.

Reason:
Kararların, içeriklerin ve ürün bilgisinin sohbetler içinde kaybolmasını önlemek.


---

## DECISION 003

Date: 2026-06-27

Topic:
Understanding Is An Outcome

Decision:
Nocta için "anlaşılmak" temel değer değil, sunulan deneyimin doğal sonucudur. Nocta'nın görevi kullanıcının yaşadığı uyku engelini anlamak ve ona uygun bir deneyim sunmaktır.

Reason:
Farklı kullanıcılar farklı uyku engelleriyle gelir. İlişki sorunları, aşırı düşünme, yalnızlık, hastalık veya stres gibi farklı durumlarda ihtiyaç duyulan deneyim değişebilir. Anlaşılmış hissetmek ise bu deneyimin ortak sonucudur.


---

## DECISION 004

Date: 2026-07-05

Topic:
Foundations Freeze

Decision:
NOCTA Foundations V1 has been frozen.

Future development should focus on:

- Reframe Library
- Conversation Testing
- Audio Integration

No new philosophy, framework or methodology documents should be created unless a major contradiction is discovered.

Reason:
The foundational psychology, principles and conversation philosophy of Nocta are sufficiently defined. Additional framework creation is likely to produce diminishing returns. The highest value work now is content creation, testing and refinement.


---

## DECISION 005

Date: 2026-07-06

Topic:
Core Psychology Map

Decision:

Nocta's core psychology system will be organized around eight primary categories:

1. Overthinking
2. Future Anxiety
3. Relationship Pain
4. Loneliness
5. Emotional Pain
6. Work Stress
7. Self-Worth
8. Life Direction

All future insight libraries, conversation libraries, trigger detection systems, AI responses and audio experiences should originate from one of these eight categories.

Reason:

Analysis of the primary reasons people struggle to sleep suggests that six categories alone are insufficient.

Self-Worth and Life Direction represent distinct psychological states that cannot be reliably reduced to Overthinking, Emotional Pain or Work Stress.

Creating dedicated categories improves emotional accuracy, content organization and AI detection quality.


## DECISION 005 — Gold Standard Conversations Before More Content

Date:
2026-07-13

Decision:

Before expanding the content library further, Nocta will build a collection of Gold Standard Conversations.

Reason:

The current limitation is not category coverage.

The current limitation is conversation quality.

Execution Engine and Conversation Engine are now defined.

The next priority is creating complete end-to-end conversations that demonstrate:

- Observe
- Narrow
- Reframe
- Release
- Sleep Transition

These conversations will become the reference standard for future Nocta responses.

Status:
APPROVED


---

## DECISION 004 — Sleep Barrier Template Locked

Status: Approved

Decision:

The Sleep Barrier Template V1 has been approved and locked as the official schema for all Sleep Barrier definitions.

Reason:

Using a single standardized template ensures consistency across all barrier definitions and simplifies integration with the AI Brain, Conversation Engine, Routing Engine, Validation Engine and future Soundscape Engine.

Impact:

- All future Sleep Barrier definitions must follow this template.
- Changes to the template require a new version (V2) rather than modifying the locked version.
- The locked template serves as the canonical reference for V1.


---

# DECISION XXX — Conversation Memory V1

Status: APPROVED

Conversation Memory is not Vendor chat history.

Conversation Memory is not WorkingMind.

Conversation Memory is temporary night-scoped shaping context.

Ownership:

- CognitiveOrchestrator owns the temporary grounding buffer.
- PromptArchitecture admits shaping only.
- ConversationCompiler materializes admitted grounding.
- VendorProvider transports compiled instructions only.

V1 Scope:

- current user utterance
- up to two previous user utterances
- prior assistant utterances excluded

Conversation Memory never becomes durable memory.

Conversation Memory is discarded at NightSession completion.


---

# DECISION XXX — Amendment 001 Approved

Status: FROZEN

Approved Contract:

HCOS Principle 3 + Memory Storage Clarification

Summary:

HCOS permits temporary runtime conversation grounding during an active NightSession.

Temporary grounding:

- remains governed by HCOS principles
- is volatile runtime memory only
- never becomes durable memory
- is discarded at NightSession completion
- never reaches LivingMindModel
- never reaches MemoryEngine
- never becomes vendor-maintained conversation history

Conversation Memory scope remains owned by the Conversation Memory Contract.


---

# DECISION XXX — Amendment 003 Approved

Status: FROZEN

Approved Contract:

ConversationCompiler Shaping Contract

Summary:

ConversationCompiler remains a deterministic translation component.

Compiler owns no cognition.

Compiler owns no authority.

Compiler owns no memory.

Compiler may consume shaping only from the sealed LlmInvocationPackage.

Field-specific shaping modes:

- understanding → presence-only
- workingMind → presence-only
- conversationGrounding → deterministic materialization

Compiler must never:

- infer
- invent
- reopen cognition
- change WHAT
- narrate analysis
- write memory
- generate user-facing speech

Unknown shaping fields cause fail-closed compilation.

Cognitive authority remains upstream.

ConversationGrounding is the sole canonical user-grounding shaping field.


---

# DECISION XXX — Amendment 002 Approved

Status: FROZEN

Approved Contract:

LlmInvocationPackage Conversation Grounding

Summary:

LlmInvocationPackage is the sole canonical handoff into the LLM expression plane.

Conversation Grounding is an optional shaping field.

Ownership:

- CognitiveOrchestrator owns the temporary grounding buffer lifecycle.
- PromptArchitecture admits or rejects Conversation Grounding.
- PromptArchitecture is the sole writer of the package field.
- ConversationCompiler may read the admitted field only for deterministic materialization according to the frozen Compiler contract.
- LanguageModelClient carries the sealed package.
- VendorProvider transports compiled instructions only.

Conversation Grounding:

- is optional
- has zero cognitive authority
- never changes WHAT
- never changes ReleaseDecision
- never changes ExitDecision
- never changes ConversationPolicy
- never becomes durable memory

After package emission, the Conversation Grounding field is immutable.

