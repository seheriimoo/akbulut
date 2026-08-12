# Conversation Quality Lab — Implementation Roadmap (to V1 Launch)

## Status

Operational Roadmap — Not Architecture

Effective Date: 2026-08-07

Conversation Intelligence V1 is **design frozen**.

This document does not create architecture.
It does not create new product doctrine.
It does not redesign HCOS, Constitution, Philosophy, Blueprint, Compiler, Evaluator, Guard, Language Style, or Human Gold.

It defines only the **development workflow** the team follows from now until V1 launch:

1. Golden Night execution
2. Human Gold evaluation
3. Compiler iteration
4. Regression testing
5. Live conversation improvement

---

## Frozen Inputs (Do Not Reopen)

Work only against these existing sources of truth:

| Layer | Source |
|---|---|
| System ownership | HCOS Architecture |
| Law | Conversation Constitution |
| Stance | Conversation Philosophy |
| Stages | Conversation Blueprint |
| Translation | Conversation Compiler (+ Receipt/Naming Intelligence, Language Style binding) |
| Emission gate | UtteranceGuard (incl. Naming Contract V2) |
| Measurement | Conversation Evaluator V1 |
| Benchmark standard | Golden Night Specification V1 |
| Felt quality target | Human Gold Specification V1 |
| Voice | Language Style V1 |
| Seed benchmark | Golden Night 001 |

If a proposed change needs new doctrine, it is out of scope for the Quality Lab.
If it needs HCOS redesign, it is out of scope for the Quality Lab.

---

## Lab Mission

Close the loop:

```
Golden Night → Live compile/speak/guard → Human Gold + Evaluator score
        → Defect triage → Compiler/style binding patch (only)
        → Regression re-run → Promote or reject
```

Outcome required for V1 launch: live nights reliably pass Golden lawfulness and approach Human Gold on naturalness, quiet warmth, and unforced speech—without reopening architecture.

---

## Roles (Lightweight)

| Role | Responsibility in the Lab |
|---|---|
| Lab Runner | Executes Golden Nights on live path; captures transcripts + Guard outcomes |
| Scorer | Applies Evaluator + Human Gold scoring; records dimension vectors |
| Compiler Owner | Proposes binding-only patches from defect clusters |
| Reviewer | Approves/rejects patches against regression gates |
| Launch Owner | Declares V1 conversation-quality readiness |

One person may hold multiple roles. Ownership must still be explicit per change.

---

## Cadence Until V1 Launch

### Weekly Lab Cycle (default)

| Day | Activity |
|---|---|
| Mon | Select/refresh Golden Night set; define the week’s quality hypothesis |
| Tue–Wed | Execute Golden Nights on live Compiler → vendor → Guard |
| Thu | Score (Evaluator + Human Gold); triage defects |
| Fri | Land at most one Compiler/style binding patch; run regression; ship or revert |

### Rules of cadence

1. **One primary defect theme per week** (e.g. Naming naturalness, not five themes).
2. **No architecture discussions in Lab meetings** unless a hard blocker proves a frozen doc is wrong—and even then, escalate outside Lab.
3. **No mid-week stack of unrelated Compiler changes.**

---

## 1. Golden Night Execution

### 1.1 Corpus policy

1. GN-001 is the mandatory regression anchor.
2. Add new Golden Nights only under Golden Night Specification V1.
3. Prefer few excellent nights over many weak ones.
4. Target corpus by V1 launch: **5–8 Golden Nights** covering distinct loads (overthinking, relational residue, diffuse unease, high-readiness compression, etc.).
5. New nights enter as `candidate` → become `golden` only after Evaluator Pass + Human Gold review.

### 1.2 Execution procedure (every run)

For each Golden Night:

1. Run on the **live** path: Compiler → LanguageModelClient/vendor → UtteranceGuard.
2. Use the night’s user turns as lived expression input (no prompt rewriting).
3. Record, per assistant turn:
   - sealed WHAT / Blueprint stage
   - compiled package identity (stage intelligence present? Language Style bound?)
   - model candidate text
   - Guard disposition (ADMIT / REJECT)
   - final emitted text (if any)
4. Record night terminal state (Rest reached? early fail-closed?).
5. Store run artifact with: night id, app/compiler commit SHA, model id, timestamp.

### 1.3 Execution rules

1. Do not hand-edit model output into the golden corpus during a run.
2. Guard reject = no emission for that turn; do not bypass Guard for scoring convenience.
3. If live path cannot run (auth/vendor), Lab is blocked—do not substitute offline fake speech as Golden evidence.

### 1.4 Deliverable

`runs/GN-xxx/<date>-<sha>/` style artifact (location flexible) containing transcript + metadata. Exact folder tooling may evolve; the required fields above may not.

---

## 2. Human Gold Evaluation

### 2.1 Dual scoring (required)

Every executed Golden Night gets both:

1. **Conversation Evaluator V1** — Pass / Warning / Reject + dimension vector (lawfulness)
2. **Human Gold Specification V1** — score /100 using the Lab’s fixed dimension sheet

Lawfulness and felt quality are never collapsed into one number without showing both.

### 2.2 Human Gold dimension sheet (fixed)

Score each 0–10 (sum ×1 = /100, same sheet as GN-001 reviews):

1. Recognition  
2. Emotional safety  
3. Naturalness  
4. Memorable light  
5. Restward change  
6. Accurate presence  
7. Quiet warmth  
8. Unforced speech  
9. One true recognition  
10. Restward ease  

Also note stage-local notes for Receipt / Naming / Permission / Release / Enough.

### 2.3 Evaluation procedure

1. Score from **emitted** speech only (Guard-admitted). Rejected candidates may be annotated as diagnostics, never as Golden success.
2. Compare to previous run on the same night (delta table).
3. Mark top 1–2 limiting dimensions.
4. Do not invent new scoring dimensions in Lab.

### 2.4 Quality bars (workflow gates)

| Gate | Requirement |
|---|---|
| Corpus admission (`golden`) | Evaluator night Pass + no hard-fail; Human Gold reviewed |
| Compiler patch promote | No Golden Night Evaluator regression; Human Gold total must not fall on GN-001 |
| V1 launch recommend | All Golden nights Evaluator Pass; GN-001 Human Gold ≥ prior baseline and trending up; limiting dimensions documented with owners |

Baseline reference: GN-001 Human Gold **79/100** (post Receipt/Naming Intelligence + Guard Naming V2; pre–Language Style live confirm may be re-measured).

---

## 3. Compiler Iteration

### 3.1 Allowed change surface

Compiler iteration may touch **only**:

- Stage binding wording already owned by Compiler
- Language Style binding text (voice only)
- Receipt / Naming Intelligence compile strings (if defect is stage-local and not doctrinal)
- Tests that lock the intended compile output

### 3.2 Forbidden change surface (in Lab)

- HCOS ownership / pipeline order
- Constitution / Philosophy / Blueprint doctrine
- New canonical product documents
- Guard redesign (except explicit Guard bugfix with separate review)
- Prompt experiments that bypass Compiler
- Utterance rewrite layers

### 3.3 Iteration procedure

1. Start from a **defect cluster** (same dimension failing across ≥2 runs or ≥2 nights).
2. Write a one-sentence hypothesis: “Binding X causes Y; changing Z should lift dimension D.”
3. Patch the smallest Compiler/style surface.
4. Re-run **GN-001 first**, then other goldens.
5. Promote only if regression gates pass.
6. If patch fails twice on the same hypothesis, stop and re-triage—do not expand scope into architecture.

### 3.4 Priority order for iteration (until launch)

1. Naturalness / Unforced speech / Quiet warmth (Language Style adherence in live output)
2. Naming quiet recognition without meta-catchphrase tone
3. Receipt First Stop Moment stability across new goldens
4. Permission / Release / Enough only if Evaluator/Human Gold shows them limiting
5. New stage Intelligences only if Lab evidence shows repeated stage failure—and even then, implement inside Compiler without new architecture docs

---

## 4. Regression Testing

### 4.1 Required suites (every Compiler-affecting PR)

| Suite | Purpose |
|---|---|
| Unit: Compiler / Receipt / Naming / Language Style / Guard Naming V2 | Binding & admission contracts |
| Unit: Conversation LLM contract + Engine | Expression ownership intact |
| Golden execution: GN-001 live | End-to-end quality anchor |
| Golden execution: full golden corpus (as it grows) | No silent regressions |

### 4.2 Regression gates (must all pass)

1. No new unit/contract test failures.
2. GN-001 Evaluator disposition does not worsen (Pass stays Pass).
3. GN-001 Human Gold total does not drop.
4. Guard reject rate on goldens does not spike without an explicit, accepted tradeoff note.
5. No Guard bypass introduced.

### 4.3 Failure handling

| Failure | Action |
|---|---|
| Unit fail | Fix or revert before merge |
| GN-001 Human Gold drop | Revert patch by default |
| One secondary golden Warning | Allow only with Reviewer approval + follow-up ticket |
| Any golden Evaluator Reject | Block promote |

### 4.4 Record keeping

Each promote records:

- commit SHA
- nights run
- Evaluator summary
- Human Gold before/after for GN-001
- defect theme addressed

---

## 5. Live Conversation Improvement Workflow

This is how product quality improves without redesigning the system.

### 5.1 Intake sources

1. Golden Lab runs (primary)
2. Internal dogfood nights (secondary)
3. Early user nights (scrubbed; no raw durable transcript into Living Mind Model)

### 5.2 Intake → Lab queue

For each live issue:

1. Tag stage (Receipt/Naming/Permission/Release/Enough) if known
2. Tag Human Gold dimension(s)
3. Tag whether Guard rejected or admitted
4. Accept into Lab only if reproducible or clustered

Single anecdotes do not trigger Compiler changes.

### 5.3 Standard improvement loop

```
Observe live/golden defect
  → Reproduce on a Golden Night (or add candidate night)
  → Score
  → Smallest Compiler/style patch
  → Regression
  → Promote
  → Re-check live sample next cycle
```

### 5.4 Explicit non-goals until V1 launch

1. New architecture documents
2. New cognitive owners
3. Prompt stacks outside Compiler
4. Broad model shopping as a substitute for binding quality
5. Expanding Guard into a rewriter
6. Optimizing for longer engagement

---

## V1 Launch Readiness Checklist

Conversation quality may be recommended for V1 launch when:

1. Design remains frozen (no new architecture created by Lab pressure)
2. Golden corpus ≥5 nights, all Specification-compliant
3. All goldens: Evaluator **Pass** on latest Compiler
4. GN-001 Human Gold ≥ baseline and limiting dimensions ≤2, with owners
5. Language Style visibly improves Naturalness / Quiet warmth / Unforced speech vs pre-style baseline on GN-001
6. Regression suites green on the release candidate SHA
7. Live dogfood week shows no new hard-fail class (solve/hooks/clinical/sleep-command)
8. Launch Owner signs the quality note

If unmet: slip launch quality claim; do not “fix” by rewriting doctrine.

---

## First 30 Days (Concrete)

### Week 1
- Formalize run artifact template
- Re-measure GN-001 with Language Style live (new Human Gold baseline)
- Freeze Lab scoring sheet + roles

### Week 2
- Author Golden Night 002 + 003 as `candidate`, execute, score
- One Compiler/style patch max (likely Naming naturalness / catchphrase)

### Week 3
- Promote candidates that Pass; expand regression set
- Dogfood live nights → Lab queue triage

### Week 4
- Full corpus regression on RC
- Launch readiness review against checklist
- Only if blocked by repeated stage failure: plan next Intelligence **inside Compiler**, still no new architecture

---

## Decision Rule for the Team

When unsure what to do next, choose the action that:

1. Uses an existing Golden Night or creates one under the existing Specification
2. Measures with Evaluator + Human Gold
3. Changes the smallest Compiler/style binding
4. Re-runs regression

If the action requires a new canonical document or HCOS change, **stop**—that is outside the Conversation Quality Lab.
