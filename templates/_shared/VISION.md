# Product Vision

> **Template — replace this entire file before running `/start-team`.**
> This document is the single source of truth for what the product *is* and what it is *not*. Every agent reads it on every milestone. Be specific. Be opinionated. Cut everything that does not belong.
>
> Sections marked **REQUIRED** must be filled. Sections marked **OPTIONAL** can be removed if not applicable.
> Replace every `<…>` placeholder. Delete any guidance text in italics once the section is final.

---

## Vision *(REQUIRED)*

*One paragraph. What does this product change about the user's life or work? Frame the experience, not the feature list.*

`<One-paragraph product vision.>`

---

## Goal *(REQUIRED)*

*One or two sentences. The single most important thing this product helps a user do. If you cannot say it in two sentences, the product is not narrow enough yet.*

`<Single-sentence goal.>`

---

## Core Principles *(REQUIRED)*

*4–6 short principles. Each one is a constraint that future feature requests must respect. Pair the principle with a one-line "what this means in practice".*

- **`<Principle 1>`**
  `<What this means in practice.>`

- **`<Principle 2>`**
  `<What this means in practice.>`

- **`<Principle 3>`**
  `<What this means in practice.>`

- **`<Principle 4>`**
  `<What this means in practice.>`

---

## Product Shape *(REQUIRED)*

*The minimal user flow. Numbered steps. No optional flows here — those go elsewhere.*

1. `<Step 1.>`
2. `<Step 2.>`
3. `<Step 3.>`
4. `<…>`

---

## Non-Goals *(REQUIRED)*

*Things the product must not become. Be brutal. Each entry is a feature that will be rejected by `ux-guardian` and `architect` even if technically feasible.*

The product must not become:

- `<Non-goal 1.>`
- `<Non-goal 2.>`
- `<Non-goal 3.>`
- `<…>`

---

## Guardrails for Agents *(REQUIRED)*

*Specific behaviours agents must avoid when proposing UX, copy, or features. These are the early-warning signs of vision drift.*

When making product, UX, or feature decisions:

- Do not `<drift pattern 1>`.
- Do not `<drift pattern 2>`.
- Do not `<drift pattern 3>`.
- Do not `<drift pattern 4>`.

If a feature makes the product feel more like `<adjacent product category 1>`, `<category 2>`, or `<category 3>`, it is the wrong direction.

---

## Decision Filter *(REQUIRED)*

*Exactly four yes/no questions. Every proposed change is evaluated against all four. If any answer is "no", reject the change. The `ux-guardian` agent and the `/implement` skill quote these answers verbatim in PR descriptions.*

A proposed change should only be accepted if it clearly supports the core experience.

Ask:

1. `<Question 1>`
2. `<Question 2>`
3. `<Question 3>`
4. `<Question 4>`

If not, it should not be added.

---

## Success Definition *(REQUIRED)*

*What does it feel like when the product works? First-person sentences. These guide tone of voice, copy, and arrival / completion UX.*

The product succeeds when the user feels:

- `<First-person success feeling 1.>`
- `<First-person success feeling 2.>`
- `<First-person success feeling 3.>`
- `<…>`

---

## Persistence and Privacy Posture *(REQUIRED)*

*State exactly what the product is allowed to persist and transmit. Agents enforce this in `AGENTS.md §6.2` and `§8`.*

- **Persisted on-device:** `<list — be exhaustive>`.
- **Transmitted off-device:** `<list, or "nothing" if fully local>`.
- **Never persisted:** `<list of things explicitly forbidden, e.g. user location history, message contents, biometric data>`.
- **Telemetry / analytics:** `<"none" by default; if any, list exactly what and why>`.

---

## Audience & Voice *(OPTIONAL)*

*Who is this for? How should the product talk to them? Drives microcopy, error states, and onboarding.*

- **Primary audience:** `<who they are, what they care about>`.
- **Tone:** `<calm | playful | technical | warm | terse>` — `<one-line elaboration>`.

---

## Open Questions *(OPTIONAL)*

*Things the human owner is still deciding. Agents do not block on these — they pick the most-conservative interpretation and document the choice in `ROADMAP.md → Strategic decisions` per `AGENTS.md §14.1`.*

- `<Open question 1.>`
- `<Open question 2.>`
