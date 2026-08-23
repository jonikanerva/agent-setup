# Default Agent Stack

## What this repository provides

This repository provides a static agent setup for Claude Code and Codex.

The setup contains:

- Five roles: architect, UX guardian, devil's advocate, lead developer, and QA
  enforcer.
- Three workflows: project manager, implementation, and code review.
- A technology-neutral operating contract for each tool.
- A product contract template in `VISION.md`.
- Technology profiles that become a project's `STACK.md`.

The project manager uses all five roles for each delivery task. The roles
review product fit, architecture, scope, implementation, and quality. The
project manager shows the pull request only after the code review reports PASS.
The user reviews and merges the pull request.

## Technical basis

The Claude implementation uses these Claude Code features:

- [Agent Teams](https://code.claude.com/docs/en/agent-teams) provide the team
  lead, independent teammates, shared tasks, and direct messages.
- [Custom subagents](https://code.claude.com/docs/en/sub-agents) define the five
  reusable roles and their tool access.
- [Skills](https://code.claude.com/docs/en/skills) define the three reusable
  workflows.

Claude Code marks Agent Teams as experimental. You must enable Agent Teams
before you use the Claude workflow.

The Codex implementation uses these Codex features:

- [Subagents and custom agents](https://learn.chatgpt.com/docs/agent-configuration/subagents)
  provide delegated workers and TOML role definitions.
- [Skills](https://learn.chatgpt.com/docs/build-skills) define the three
  reusable workflows.
- [AGENTS.md](https://learn.chatgpt.com/docs/agent-configuration/agents-md)
  provides the project operating contract.

The two tools use different coordination systems. Claude teammates can share
tasks and send direct messages. The Codex primary agent starts subagents and
collects their results. Both implementations use the same roles, order, and
quality gates.

## Repository layout

```text
template/
  .claude/
    agents/           # Claude role definitions
    skills/           # Claude workflows
    settings.json     # Reference project settings for Claude
  .codex/agents/      # Codex role definitions
  .agents/skills/     # Codex workflows
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
`STACK.md`, and the operating contract for the selected tool.

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

For Claude, merge this setting into your existing
`~/.claude/settings.json` file:

```json
{
  "env": {
    "CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS": "1"
  }
}
```

Do not replace other settings in the file. Claude Agent Teams do not start
without this setting.

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

Edit `VISION.md` and `STACK.md`. Replace every placeholder. Define all named
build and verification commands in `STACK.md`.

### 3. Start the workflow

For Claude Code, run:

```text
/project-manager solve issue #1
```

For Codex, run:

```text
$project-manager solve issue #1
```

You can also give the project manager a direct problem description.

## Updates

The repository is the source of truth for global roles and skills. Run
`git pull` in this repository to update them. Start a new Claude or Codex
session after an update.

Run the link command again after you add or remove a role or skill:

```sh
bin/link-global.sh --host all --prune
```

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

Each profile defines the project shape, runtime, frameworks, commands, budgets,
persistence, dependencies, logging, lifecycle, time rules, and reject rules.

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

Some rules appear in more than one file. The repetition is intentional. Each
agent can run in an isolated context. Claude and Codex also use different file
formats.

Run the static checks after a change:

```sh
bin/check-setup.sh
```

The check validates both role lists and all workflow files. The check does not
generate or change files.
