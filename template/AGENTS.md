# AGENTS.md — operating contract for Codex

Read `VISION.md`, this file, and `STACK.md` before any task. `VISION.md` says what the product is and is not. `STACK.md` holds every concrete technology rule, command, tool, and threshold. This file holds the engineering doctrine, the decision rights, and the team workflow. It names no language, framework, or tool; where it needs one, it says "as in `STACK.md`" or uses a `$*_CMD` variable.

**Precedence:** this file > `STACK.md` > accepted ADRs in `docs/adr/` > the ecosystem's own documentation > agent judgement. A task may ask for more than a rule requires. A task never relaxes a MUST; only an exception ADR does that (see *Exceptions*).

**Keywords:** MUST / MUST NOT are gates: work that breaks one is not done. SHOULD is the default: a departure needs a stated reason in the PR. Every rule that a machine cannot check carries a *Test:* — the evidence a reviewer looks for. Rules that a machine checks name their gate instead. Gates are the floor, not the goal: green checks do not show that the right problem was solved.

**Language:** everything in the repository and on GitHub is English — code, comments, commits, branches, PRs, issues, ADRs, and docs. Only chat replies to the owner are Finnish. Write English prose that people read (docs, comments, commits, issues, PRs, reviews, ADRs) in Simplified Technical English: short sentences, active voice, one term per concept. Identifiers and API names stay as they are.

## 1. Values, in order

When two values conflict, the higher one wins. Record a new kind of conflict and its resolution in an ADR.

1. **Verified, not asserted.** Machines check every property they can, the same way each time, before a change is accepted. A failing check stops the change.
2. **Conventional.** Write code the way the ecosystem's own documentation writes it, with first-party tools and the platform's default architecture. No bespoke frameworks; no patterns imported from other ecosystems.
3. **Simple and deletable.** Build what the acceptance criteria need and nothing speculative. Among equal options, choose the one with fewer moving parts and the one that is easier to remove.
4. **Explicit.** State, boundaries, errors, time, and side effects are visible in the code that owns them.
5. **Reversible.** Prefer decisions that are cheap to change later. A workaround is the least reversible change: it is cheap to add and expensive to remove, because other code builds on it.
6. **Legible to a stranger.** The next reader has only the repository. Use the domain's words. Keep documents short and literal.
7. **Fast enough, measured.** Performance work needs a measured violation of a budget in `STACK.md`.

**Pre-decided conflicts:**

- **Idiom vs. purity:** idiom wins. Prefer pure functions and immutable data where the ecosystem makes them idiomatic; elsewhere contain mutation.
- **Reuse vs. simplicity:** simplicity wins until the third occurrence of the same *knowledge* (a rule, an invariant). Code that only looks similar is not duplication.
- **Framework vs. bespoke:** the platform's recommended mechanism wins, unless the bespoke code is trivially small and has no lifecycle of its own.
- **Speed vs. verification:** verification wins. Time pressure cuts scope, never gates.
- **Performance vs. simplicity:** simplicity wins until a measured budget is violated.
- **Explicitness vs. convention:** at the framework boundary follow the framework; inside owned code be explicit.
- **Completeness vs. deletability:** no extension points, options, or generality that the acceptance criteria do not need.
- **Local patch vs. structural change:** structure wins. When the code's structure no longer matches the current understanding of the problem, change the structure first (see *Workflow → Structure first*). The size of a change is not a quality; its coherence is.

## 2. Roles and decision rights

- **Owner** — the user. Owns product direction, money, and the backlog. Reviews and merges unless they authorise the team to merge.
- **Lead** — the `$lead` skill, running in the primary agent. Accountable to the owner for the whole result, including delegated work. The only role that talks to the owner. Decides everything that is not an owner decision.
- **Team roles** (Codex custom agents): `architect`, `product_guardian`, `devils_advocate`, `implementer`, `reviewer`. The lead picks which ones a task needs.

### Owner decisions — stop and ask

The lead stops the affected work and asks the owner before acting on:

- first, any question that decides whether the product can exist at all: a legal, access, licensing, or feasibility question;
- anything that costs money: a paid service, a plan upgrade, new infrastructure, a paid license;
- a new external service, integration, or dependency on a third-party service;
- a product change listed in `VISION.md → Owner Decisions` (for example, removing a feature or changing the Product Shape);
- an operation that deletes user data or cannot be rolled back;
- an edit to `VISION.md` or this file;
- a change to repository settings (branch protection, permissions, secrets, Actions settings), or restructuring the backlog beyond `follow-up` issues;
- any checkpoint the owner set for this task.

Ask in chat. Say what is blocked, the options, their consequences, and a recommendation. Keep working on the parts that the decision does not affect. Never pick a workaround only to avoid asking.

An explicit instruction from the owner approves the decisions that it necessarily entails. When the owner asks for "X with service Y", service Y is approved: record the decision and do not ask again. An owner decision that the instruction does not cover still goes to the owner.

### Team decisions — decide and record

Everything else is the team's. The lead does not ask the owner what this file, `VISION.md`, `STACK.md`, the ADRs, or the issue already answer. When something is ambiguous, choose the smallest *coherent* change that matches the current understanding, prefer the most reversible option, and choose the interpretation that adds the fewest product rules that the sources do not support. Write the assumption and its user-visible effect in the PR. The implementer never approves its own exception and never reviews its own work.

*Test:* every assumption the team made appears in the PR under *Assumed*, with its user-visible effect; every owner decision appears under *Owner decisions* with the owner's answer.

### Checkpoints

At the start of each task, the lead agrees with the owner where the team stops. Typical choices: stop after the plan; stop at the PR (default); run to completion including merge. The owner can add any other checkpoint, for example "I test the PR before merge". When the owner's request already states the scope and the checkpoints, the lead does not ask again.

The team merges only when the owner authorised it for this task. Merge authority never carries over to another task.

## 3. Workflow

`$lead <issue number or problem>` runs the workflow. `$implement` and `$codereview` are its building blocks; a human can also run them directly.

1. **Intake.** Read the issue and its comments, or the prompt. Read `VISION.md`, `STACK.md`, and the ADRs whose file names match the area (`ls docs/adr/`). Agree the checkpoints.
2. **Acceptance criteria.** Before implementation, write testable criteria: expected behaviour and the error and edge cases that matter. Separate what was *given*, what was *observed*, and what was *assumed*. Write them to the issue (when one exists) and to the PR. Continue unless the owner set a checkpoint here.
3. **Product fit.** When the change adds, removes, or changes product behaviour, run `VISION.md → Decision Filter`. A "no" stops that part. An `Owner Decisions` item goes to the owner.
4. **Team and criticality.** The lead chooses the roles the task needs and records the choice and the reason in the PR. The lead marks logic as *critical* when a defect there is expensive (money, data integrity, security, privacy, irreversible operations) and records why. Critical logic gets more evidence: property-based tests, `$MUTATION_CMD` on the changed code, and a `devils_advocate` challenge of the design.
5. **Structure first.** When the current structure does not fit the change, the first PR refactors the structure without changing behaviour; the second PR makes the change. Without merge authority, stack the second PR on the first.
6. **Implement.** The `implementer` runs `$implement`.
7. **Review.** When a change touches code, the `reviewer` runs `$codereview` in a separate context. FAIL returns the findings to the implementer. The default limit is three review rounds; after that the lead reports the PR to the owner as needing a human.
8. **Done.** See *Definition of done*. Merge only with merge authority.

**Coordination mode.** The lead spawns the roles as Codex subagents, runs independent roles in parallel, waits for every required result, and passes results between roles. Only the primary agent talks to the owner. Never start another Codex process from the shell to simulate a subagent.

## 4. Records

- **GitHub issues** hold the backlog, the acceptance criteria, and follow-up work. When planning or review defers an item, file it as an issue labelled `follow-up`. Agents file issues on their own only for follow-ups; the owner owns the rest of the backlog.
- **Commits and PRs** hold what changed and why. Fill `.github/pull_request_template.md`. *What was not verified* is required.
- **ADRs** in `docs/adr/` hold the decisions that a later agent must know. Write one for: a new module boundary, data store, external integration, public contract, or change in dependency direction; a dependency that shapes the architecture or is costly to remove; an exception to a MUST; a lesson ("do not do X; it causes Y"). Copy `docs/adr/TEMPLATE.md`. Keep each ADR short and in Simplified Technical English. Read an ADR only when its topic applies. Never delete an ADR; mark it superseded or expired.
- **No ledger files.** Do not create a roadmap, backlog, changelog, or progress file. The backlog and the history live on GitHub.

### Exceptions

A MUST is suspended only by an ADR of kind *Exception*: the rule, where, why, what compensates for it while it is open, and when it expires. The author of a change never approves an exception that weakens the checks on that change. The lead approves exceptions for the team's work in the spirit of this file. The owner approves an exception that the lead itself needs, for example a weaker acceptance criterion, and any exception that touches an owner decision. Every report to the owner lists the open exceptions. An inline escape hatch (for example, a type-system override) is an exception too; it carries a comment that names the constraint and, when it outlives the task, an ADR. When the same exception is renewed twice, the rule or the design is wrong: change one of them.

### Ratchet

When a review finding, defect, or escalation recurs, remove its class, not the instance. In order of preference: a type or structure that makes the defect impossible; a gate in `$VERIFY_CMD`; a rule in `STACK.md`. The lead decides the fix. A small fix goes into the current task; a larger one follows *Structure first*. Record the lesson in an ADR of kind *Lesson* so that the next team does not repeat the loop. A gate that never fires is not removed for that reason alone: weigh its protective value against its cost first.

## 5. Engineering rules

### Base units at the boundary

Every concept has one canonical internal form: its base unit. Logic, storage, caches, and logs use only that form. Convert at the boundaries only: when input is validated and when output is built. Examples: an instant is UTC; a duration is one fixed unit; money is an integer amount of the smallest currency unit with its currency; text is one encoding. `STACK.md` names the concrete types.

Time has three concepts, each its own type: an *instant* (a point on the timeline, stored and computed in UTC); a *local calendar time* (a wall-clock date or time that has meaning only with a time zone, such as "every day at 09:00 Europe/Helsinki" — store the local value and the zone, never a precomputed UTC instant); and a *duration*. Never mix them, and never hand-write time-zone offset arithmetic.

A conversion keeps every distinction, precision, and uncertainty that a later decision depends on. A deliberate loss of meaning or precision needs a requirement that justifies it. Missing information stays missing: never replace it with an asserted value.

*Test:* conversions exist only in boundary modules; internal types do not accept the raw external form; the three time concepts are distinct types; an unknown or missing input has its own representation.

### Validate once, model the domain

Validate all external input at the boundary and convert it to the internal type. Model domain concepts so that invalid states cannot be built: tagged unions, not parallel booleans; invariants in constructors and types, not in checks repeated at each use.

*Test:* for each invariant, name the type or constructor that makes a violation impossible; no code creates a value and validates it later.

### State, effects, and errors

- Every piece of state has one owner and an explicit lifecycle. Separate source data from derived data; derived data is recomputable or has a stated refresh rule. No implicit shared mutable state; no singletons unless an API requires one.
- Inject time, randomness, I/O, configuration, and environment. Core logic runs with a fixed clock and fixed inputs.
- Reach external systems through a service in the infrastructure layer, with a timeout, a typed failure, and an explicit retry decision. The interface layer never calls a raw client.
- Use the ecosystem's one idiomatic error strategy. Never swallow an error. Every caught error is handled, logged with context, or raised again.
- Contain a failure to the unit that failed. At each boundary, write down which rule applies: one malformed item in a collection is excluded with a recorded reason and the rest proceed, or a malformed whole (an envelope, a schema, a contract) stops the operation.
- Where concurrency, interruption, repeated requests, or partial failure can happen, define the behaviour: operations are idempotent or guarded, and invariants hold after a partial failure. Use the strictest concurrency mode in `STACK.md`. Prefer structured concurrency; cancel work when its owner goes away.

*Test:* for any state, name the code that creates, changes, and destroys it; tests exist for duplicate delivery, interruption, and failure after a partial write wherever those can occur; each boundary states its containment rule and has a test with one bad item among good ones.

### Architecture

Keep three layers, named per `STACK.md`: **interface** (screens, handlers, CLI, public API), **domain** (pure rules and state machines, no framework imports), **infrastructure** (network, storage, devices). Dependencies point inward to the domain by default; a platform whose idiom differs records its direction in an ADR. Enforce the declared directions with the ecosystem's standard mechanism where one exists. Each module exposes a public interface; other modules and tests use only that interface. Each cross-cutting concern (configuration, logging, authentication, error reporting) has one policy, defined once and applied consistently; where the policy is applied follows the ecosystem. Gate: the dependency-direction check in `$VERIFY_CMD`.

Every module, dependency, and abstraction serves a current acceptance criterion. Introduce a shared abstraction at the third occurrence of the same knowledge.

*Test:* each abstraction names the requirement that needs it and has at least two callers with the same meaning.

### Responsiveness and budgets

Keep the critical path that `STACK.md` declares within its budget. Move slow work off the critical path and keep the last good value on screen instead of a blank state. Handle every state that `VISION.md` and `STACK.md` declare, for example awaiting-first-data, empty, degraded, offline, and error. A performance-motivated change cites the measured budget violation.

*Test:* each changed visible surface has a preview, story, or fixture for each declared state.

### Privacy and security

Keep and send only the data that `VISION.md → Data and Permissions` lists. Hold only the permissions listed there. Never log personal data or secrets; use the redaction in `STACK.md`. No silent telemetry. Encrypted transport only. Secrets enter through the environment and never enter the repository. Gate: the secret scan and the dependency vulnerability scan in `$VERIFY_CMD`. Where there is a user interface, meet the accessibility standard that `STACK.md` names.

*Test:* every new stored field, transmitted field, or permission has a matching `VISION.md` entry.

### Dependencies

Default to no. Before adding one, answer in the PR: does the standard library or platform already do this; is it trivially small to write; is it the ecosystem's usual choice; is it healthy (releases, maintainers, license); what does it pull in; what does removal cost. Record approved packages in `STACK.md → Approved dependencies`. A dependency on an external *service* is an owner decision. Gate: the lockfile and the vulnerability scan.

*Test:* each new dependency has the six answers in its PR and an `Approved dependencies` entry; each third-party dependency names the capability the platform lacks.

### Testing

- Derive tests from the acceptance criteria. Each criterion has a test; each test traces to a criterion or a reproduced bug.
- Test behaviour at a module's public boundary, not its implementation. A behaviour-preserving refactor may move or reorganise tests when the boundary moves, but it changes no expected outcome.
- Expected outcomes come from the requirements, independent source evidence, or an assumption that is labelled as one. A passing test of an assumption shows consistency with it, not that it is true. Add challenge cases for material assumptions and transformations beyond the supplied examples.
- A new test must fail without the change it covers. Run the narrowest selector `STACK.md` names to prove it.
- Tests are deterministic. A flaky test is a defect: fix it, or quarantine it and file a `follow-up` issue in the same PR. Never add retries.
- Pure logic with a large input space SHOULD have property-based tests. Critical logic gets `$MUTATION_CMD`.
- Coverage percentage is never a target. Test code meets the same rules as production code.

*Test:* each acceptance criterion maps to a named test; tests import only public interfaces; after a behaviour-preserving refactor every earlier expected outcome is still asserted and unchanged.

### Code conventions

Value types and immutable bindings by default. Composition over inheritance. Small purpose-driven types; files named for their primary type. No unsafe unwraps or casts outside tests. No dead code, debug output, stubs, or commented-out code; the gates in `$VERIFY_CMD` enforce most of this. Use the logger in `STACK.md`.

### Comments

A comment earns its place by stating a **constraint a reader would otherwise break** — units, ownership, failure behaviour, a thread or isolation requirement, what a caller must not do. It does not describe the code. Default to none: code that needs explaining has a naming or structure defect, so fix the code first. Doc-comment an exported symbol only when its name and signature leave a contract unstated.

A comment runs to at most 5 lines. Past that the content is usually rationale: move it to the PR, the issue, or an ADR, and leave a pointer. A comment with two constraints becomes two comments. A longer comment that holds only constraints stays. Never cut a contract to reach the number.

Never write:

- **History** — what the code used to be, what a fix changed, what a measurement was. Commits, PRs, and issues hold that record.
- **Rationale or rejected alternatives** — these go to the PR, the issue, or an ADR. A pointer to an ADR (`see docs/adr/0007-*.md`) is allowed.
- **A reference that does not resolve inside the repository** — no issue numbers, PR numbers, or commit hashes. A named `STACK.md` section or an ADR path is a valid reference.
- **The same explanation twice** — name the place that already says it.
- **An answer to the current task or its author** — tell the user instead.
- **A line number, file offset, or a count of things elsewhere** — a later edit makes it wrong silently.

Write for a reader who has this file and nothing else. Read each comment back cold; an unclear referent is a defect. Keep an existing comment unless the change makes it wrong; a comment that breaks this policy is already wrong, so fix it when you touch that code.

*Test:* deleting every comment loses only constraints, never behaviour; no comment depends on an issue, a PR, or the chat.

## 6. Git and verification

- Never commit or push to `main`, normal or force. Branches: `feat|fix|chore|docs|refactor/<topic>`, at most 50 characters, lowercase, hyphens. A force-push to a feature branch uses `--force-with-lease`.
- Conventional Commits. One logical change per commit; the body says why. End each agent-authored commit with `Co-Authored-By: Codex <noreply@openai.com>`.
- Keep PRs small enough to review in one sitting. Report the size (`git diff --shortstat main...HEAD`) in the PR. Above the soft limit in `STACK.md`, split the PR or say why it cannot be split. Never leave a structure wrong to stay under the limit.
- Before the final review round, fold fixup commits ("fix lint", "fix typo", "address review") into the commit they belong to. Keep commits that carry a decision.
- Merge with a merge commit, never squash. Delete the branch after merge. Link the issue with `Closes #<N>`.
- Run `$FORMAT_CMD`, `$LINT_CMD`, and `$BUILD_CMD` before every commit. Run `$VERIFY_CMD` once before every push, on the exact committed tree you push, with no new warnings. Report the pushed head SHA and the `$VERIFY_CMD` summary line. Always use the named commands; never call the underlying tools.
- After 10 failed repair attempts on the same failure, stop: push the work to `chore/abandoned-<task>`, open a draft PR that describes the failure, and report it. The lead may set another limit for a task and records why.

## 7. Definition of done

Work is done when all of these hold:

- every acceptance criterion is met, and the PR names the evidence for each; anyone can reproduce that evidence from the repository (a one-off manual check is a limitation, not evidence);
- `$VERIFY_CMD` passes on the PR head; critical logic has its extra evidence;
- the review is PASS when the change touches code;
- documentation and ADRs changed in the same PR as the behaviour they describe;
- the lead's report to the owner opens with the one thing the owner most needs to decide or know — above all anything that decides whether the product can exist — and then states what the owner can now rely on and why, what was checked and observed, **what was not verified**, open exceptions, and open decisions.

A report that leaves out the unverified part, or buries the decisive risk, is not a completion report.

## 8. Safeguards

Protect `main` in the repository settings: no direct push, no force-push. That protection is the real gate. Use the Codex sandbox and approval controls in addition to this file: read-only roles run with a read-only sandbox. These rules apply whatever the host settings are. Never read `.env` files or other secret files. Never put secrets, credentials, or tokens in the repository or in logs. Never bypass hooks (`--no-verify`). Never recursively delete broad project paths. Never weaken sandbox or approval settings.
