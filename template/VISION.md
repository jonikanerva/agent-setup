# Product Vision

> **Template — replace this entire file before the first task.**
> This file says what the product *is* and what it *is not*. Write it with the
> owner before the team builds anything. Agents read it to stay on course. They
> do not invent needs or features that this file does not support.
>
> Sections marked **REQUIRED** must have real content. Remove an **OPTIONAL**
> section when it does not apply. Replace every `<…>` placeholder. Delete the
> italic guidance when the section is final.
>
> Agents never edit this file unless the owner asks for the edit.

---

## Vision *(REQUIRED)*

*One paragraph. Say what the product changes in the user's life or work.
Describe the experience, not a feature list.*

`<One-paragraph product vision.>`

---

## Goal *(REQUIRED)*

*One or two sentences. Say the one most important thing the product helps a
user do. If two sentences are not enough, the product is not narrow enough.*

`<Goal.>`

---

## Core Principles *(REQUIRED)*

*Four to six principles. Each principle is a constraint on future changes.
Give each one a line that says what it means in practice.*

- **`<Principle 1>`** — `<What this means in practice.>`
- **`<Principle 2>`** — `<What this means in practice.>`
- **`<Principle 3>`** — `<What this means in practice.>`
- **`<Principle 4>`** — `<What this means in practice.>`

---

## Product Shape *(REQUIRED)*

*The minimal user flow, as numbered steps. Optional flows do not go here.*

1. `<Step 1.>`
2. `<Step 2.>`
3. `<Step 3.>`

---

## Non-Goals *(REQUIRED)*

*What the product must not become, and the early signs of drift toward it.
Agents reject a change that crosses these lines, even when it is technically
easy.*

The product must not become:

- `<Non-goal 1.>`
- `<Non-goal 2.>`

Drift signals — do not add:

- `<Drift pattern 1.>`
- `<Drift pattern 2.>`

---

## Decision Filter *(REQUIRED)*

*Yes/no questions. Agents ask them for every change that adds, removes, or
changes product behaviour. A "no" answer stops the change. Keep the list
short. Three to five questions is usual.*

1. `<Question 1>`
2. `<Question 2>`
3. `<Question 3>`

---

## Owner Decisions *(REQUIRED)*

*The product changes that the team must not decide alone. The lead stops the
affected work and asks the owner before it acts. The operating contract also
lists owner decisions that apply to every product (cost, external services,
irreversible data changes). Add the product-specific ones here.*

- Removal of a feature from the Product Shape.
- A change to the Product Shape, the Core Principles, or the Non-Goals.
- `<Product-specific owner decision, e.g. any change to the onboarding flow.>`

---

## Success Definition *(REQUIRED)*

*What it feels like when the product works. First-person sentences. These
guide tone, copy, and completion UX.*

The product succeeds when the user feels:

- `<Success feeling 1.>`
- `<Success feeling 2.>`

---

## Data and Permissions *(REQUIRED)*

*The complete list of data the product keeps or sends, and the permissions it
holds. Agents enforce this list. A new entry is an owner decision.*

**Personal data** — every field that identifies or describes a person:

| Data | Purpose | Where it is kept | Retention |
| ---- | ------- | ---------------- | --------- |
| `<e.g. email address>` | `<e.g. sign-in>` | `<e.g. server database>` | `<e.g. until account deletion>` |

**Other persisted data:** `<list, or "none">`.

**Transmitted off-device or to third parties:** `<list, or "nothing">`.

**Never persisted or transmitted:** `<e.g. location history, message contents>`.

**Telemetry and analytics:** `<"none", or exactly what and why>`.

**Permissions, credentials, and capabilities** the software holds:

| Permission or credential | Why it is needed |
| ------------------------ | ---------------- |
| `<e.g. camera access>` | `<e.g. scan a receipt>` |

---

## Audience and Voice *(OPTIONAL)*

- **Primary audience:** `<who they are and what they care about>`.
- **Tone:** `<calm | playful | technical | warm | terse>` — `<one line>`.

---

## Open Questions *(OPTIONAL)*

*Questions the owner has not decided. Agents do not stop for these. They choose
the most reversible option, record the assumption in the PR, and ask the owner
only when the question falls under Owner Decisions.*

- `<Open question 1.>`
