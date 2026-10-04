# Product Vision

> Replace the placeholders before product delivery. This file owns product
> direction, not technology. Keep it specific and short. Remove inapplicable
> optional sections. Read relevant sections for the task.

## Vision

<What the product changes about the user's life or work.>

## Goal

<The principal user or system outcome.>

## Audience and environment

<Who uses it, where it runs, and the conditions that affect success.>
<Material constraints: compatibility, accessibility, privacy, or operating context.>

## Core Principles

<State the few principles that constrain product choices. Give each a practical meaning.>

- <Principle and consequence.>

## Product Shape

<Describe the essential user or system flow.>
<List relevant user-visible or caller-visible states and failure behaviour.>

## Non-Goals & Drift Guardrails

<What the product must not become and the concrete signs of drift.>
<These guide decisions; a major scope change goes to the owner.>

## Decision Filter

<Write the questions needed to assess product fit. There is no fixed count.
Apply relevant questions and record conflicts. Do not silently change the
owner's request to make every answer positive.>

- <Question and the requirement behind it.>

## Success Definition

<Observable outcomes that show the intended need is met.>
<Include important user experience and failure outcomes.>
<Task-specific acceptance criteria belong in the issue or PR; derive them
from this definition and the request before implementation.>

## Persistence and Privacy Posture

<State allowed data, purpose, location, external recipients, and retention.
Cover on-device and server storage. State what must never be collected or sent.
DOCTRINE.md and STACK.md apply this posture to the implementation.>

| Data or capability | Purpose | Storage or recipient | Retention or expiry |
| --- | --- | --- | --- |
| <Data or permission> | <Requirement> | <Location or provider> | <Rule> |

- Forbidden data flows: <List>.
- Telemetry and diagnostics: <None, or exactly what, why, and where>.
- Approved deletion policies: <For example, the established retention rule>.

## Audience & Voice (optional)

<Tone and domain terms for user-facing text.>

## Open Questions (optional)

<Separate material product decisions from delegated technical choices.
The lead resolves ordinary choices within authority. A material goal change
or escalation boundary goes to the owner before dependent work proceeds.>
