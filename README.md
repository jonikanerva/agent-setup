# Default Agent Stack

## What this repository provides

This repository provides a static agent setup for Claude Code and Codex.

The setup contains:

- Five roles: architect, product guardian, devil's advocate, implementer, and
  reviewer.
- Three workflows: lead, implementation, and code review.
- A technology-neutral operating contract for each tool.
- A product contract template in `VISION.md`.
- An ADR template for decisions, exceptions, and lessons.
- Technology profiles that become a project's `STACK.md`.

## How the team works

The lead is the only role that talks to you. At the start of each task, the
lead agrees the checkpoints with you. For example, the team can stop at the
plan, stop at the pull request, or run to completion and merge. The team merges
only when you allow it for that task.

The team makes its own decisions. The lead stops and asks you only for owner
decisions:

- anything that costs money;
- a new external service or integration;
- a product change listed in `VISION.md → Owner Decisions`;
- an operation that deletes user data or cannot be rolled back;
- a checkpoint that you set for the task.

While the lead waits for your answer, the team continues with the work that
the decision does not affect.

The lead writes acceptance criteria before implementation. The lead chooses the
roles that each task needs. A review in a separate context is mandatory for
every change to code. When the current structure does not fit a change, the
team first refactors the structure in its own pull request.

Machines check what machines can check. Each stack profile lists the gates in
`$VERIFY_CMD`: format, types, lint, complexity, dead code, dependency
direction, secrets, vulnerabilities, commit messages, and tests. The reviewer
judges the rest: the right problem, the simplest solution, the right
structure, test adequacy, and risk. For critical logic the team adds
property-based tests, mutation testing, and a devil's advocate challenge.

Each pull request states what was not verified. Decisions, exceptions, and
lessons go into short ADR files in `docs/adr/`.

## Technical basis

The Claude implementation uses these Claude Code features:

- [Custom subagents](https://code.claude.com/docs/en/sub-agents) define the five
  reusable roles and their tool access. Subagents load the project
  `CLAUDE.md`.
- [Skills](https://code.claude.com/docs/en/skills) define the three reusable
  workflows.
- [Agent Teams](https://code.claude.com/docs/en/agent-teams) are optional. The
  lead can start a team for a task with much parallel work. For other tasks the
  lead uses subagents.

Claude Code marks Agent Teams as experimental. The workflow works without
Agent Teams. Enable Agent Teams when you want the lead to have that option.

The Codex implementation uses these Codex features:

- [Subagents and custom agents](https://learn.chatgpt.com/docs/agent-configuration/subagents)
  provide delegated workers and TOML role definitions.
- [Skills](https://learn.chatgpt.com/docs/build-skills) define the three
  reusable workflows.
- [AGENTS.md](https://learn.chatgpt.com/docs/agent-configuration/agents-md)
  provides the project operating contract.

The two tools use different coordination systems. In Claude, the lead uses
subagents or, when enabled, an Agent Team. The Codex primary agent starts
subagents and collects their results. Both implementations use the same roles,
decision rights, and quality gates.

## Repository layout

```text
template/
  .claude/
    agents/           # Claude role definitions
    skills/           # Claude workflows
    settings.json     # Reference project settings for Claude
  .codex/agents/      # Codex role definitions
  .agents/skills/     # Codex workflows
  .github/
    pull_request_template.md
  docs/adr/TEMPLATE.md  # ADR template
  CLAUDE.md           # Claude project contract
  AGENTS.md           # Codex project contract
  VISION.md           # Product contract template
stacks/
  STACK-TEMPLATE.md
  STACK-TS.md
  STACK-EFFECT.md
  STACK-SWIFT.md
  STACK-PY.md
bin/
  link-global.sh
  check-setup.sh
```

Do not copy the complete `template/` directory into a project. The global link
installs the roles and workflows. Each project needs only `VISION.md`, one
`STACK.md`, the ADR template, the pull request template, and the operating
contract for the selected tool.

## Requirements

Install these tools:

- Claude Code, Codex, or both.
- GitHub CLI (`gh`).
- `jq`.

Use a GitHub repository for the target project. GitHub issues form the backlog.
Issues, commits, pull requests, and review comments form the audit trail.

## Use it

### 1. Create the global links

Run the global link command first. This step is required.
Run all setup commands from the root of this repository.

```sh
bin/link-global.sh
```

The default command installs both tools. You can select one tool:

```sh
bin/link-global.sh --host claude
bin/link-global.sh --host codex
```

The command creates these links:

- Claude roles: `~/.claude/agents/`
- Claude skills: `~/.claude/skills/`
- Codex roles: `~/.codex/agents/`
- Codex skills: `~/.agents/skills/`

The command does not replace a real file or directory. The command can replace
only a symlink. The command does not change Claude or Codex user settings.

Optional: to let the Claude lead start Agent Teams, merge this setting into
your existing `~/.claude/settings.json` file:

```json
{
  "env": {
    "CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS": "1"
  }
}
```

Do not replace other settings in the file. Without this setting, the lead uses
subagents only.

The file `template/.claude/settings.json` contains reference permission rules
and hooks. The link command does not install those settings. Merge the required
rules into your existing settings when you want the same enforcement.

### 2. Add the project files

Set a path for the target project:

```sh
PROJECT_DIR="/path/to/project"
```

Copy the product contract:

```sh
cp template/VISION.md "$PROJECT_DIR/VISION.md"
```

Copy one stack profile. Rename the file to `STACK.md`:

```sh
cp stacks/STACK-TS.md "$PROJECT_DIR/STACK.md"
```

Use `STACK-TEMPLATE.md` when no example matches the project.

Copy the ADR template and the pull request template:

```sh
mkdir -p "$PROJECT_DIR/docs/adr" "$PROJECT_DIR/.github"
cp template/docs/adr/TEMPLATE.md "$PROJECT_DIR/docs/adr/TEMPLATE.md"
cp template/.github/pull_request_template.md "$PROJECT_DIR/.github/"
```

Copy the contract for the selected tool.

For Claude Code:

```sh
cp template/CLAUDE.md "$PROJECT_DIR/CLAUDE.md"
```

For Codex:

```sh
cp template/AGENTS.md "$PROJECT_DIR/AGENTS.md"
```

Copy both contracts when the project uses both hosts.

Edit `VISION.md` and `STACK.md`. Replace every placeholder. Define all six
named commands in `STACK.md` and set up the gates that it lists.

### 3. Start the workflow

For Claude Code, run:

```text
/lead solve issue #1
```

For Codex, run:

```text
$lead solve issue #1
```

You can also give the lead a direct problem description. Say the checkpoints
in the same message when you know them, for example "run to completion and
merge" or "stop at the pull request".

## Updates

The repository is the source of truth for global roles and skills. Run
`git pull` in this repository to update them. Start a new Claude or Codex
session after an update.

Run the link command again after you add or remove a role or skill:

```sh
bin/link-global.sh --host all --prune
```

The `--prune` option also removes links to roles and skills that were renamed
or removed, for example the old `project-manager`, `lead-dev`, `qa-enforcer`,
and `ux-guardian` links.

The copied project contracts do not update automatically. Review contract
changes and copy the new version into each project when required.

## Stack profiles

| Profile | Main use |
| --- | --- |
| `STACK-TS.md` | Strict TypeScript, Node, Hono, React, Vite, and Vitest |
| `STACK-EFFECT.md` | Strict TypeScript with Effect |
| `STACK-SWIFT.md` | Strict Swift, SwiftUI, and Xcode |
| `STACK-PY.md` | Strict Python and Home Assistant custom integrations |
| `STACK-TEMPLATE.md` | A new stack that has no existing profile |

Each profile defines the project shape, runtime, frameworks, commands, gates,
budgets, persistence, dependencies, logging, lifecycle, base units and time,
and reject rules.

## Writing standard

Use [Simplified Technical English](https://en.wikipedia.org/wiki/Simplified_Technical_English)
for new English text that users read. This rule applies to documentation,
commit messages, issues, pull requests, and review comments.

Write short sentences. Use active voice. Use plain and consistent terms. The
rule does not apply to Finnish chat. Do not rewrite compact operating contracts
only to apply this rule.

## Static source of truth

This repository does not use a generator. Git contains every final agent and
skill file. A pull request shows the exact setup that each tool loads.

Claude subagents load the project `CLAUDE.md`, so the Claude roles and skills
refer to the contract and do not repeat it. Codex roles tell the agent to read
`AGENTS.md` first. Claude and Codex use different file formats, so some text
appears in both host trees.

Run the static checks after a change:

```sh
bin/check-setup.sh
```

The check validates both role lists and all workflow files. The check does not
generate or change files.
