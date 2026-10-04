# Default Agent Stack

## What this repository provides

This repository distributes static project guidance for Claude Code and Codex.
Every file is the final artifact. There is no generator or hidden source format.

- [DOCTRINE.md](template/DOCTRINE.md) defines shared quality principles P1–P9.
- [VISION.md](template/VISION.md) defines product intent and constraints.
- A [stack profile](stacks/STACK-TEMPLATE.md) becomes the project's `STACK.md`.
- [CLAUDE.md](template/CLAUDE.md) and [AGENTS.md](template/AGENTS.md) define
  host coordination, authority adoption, and Git practice.
- Five optional specialist roles and three workflows support delivery.

The primary agent is the lead and owns the complete result. It can implement
directly or delegate. It chooses specialists by risk and uncertainty.
Material behavioural, architectural, security, and data changes require
independent review in a separate context. A fixed team is not required.

## Delivery and authority

A project adopts policy revision 2 by reviewing and copying the shared doctrine
and a matching host contract. A delivery request then authorises technical
decisions, implementation, PR creation, merge, and release within scope.
The owner can reserve planning, testing, review, merge, or deployment for any
task. An analysis-only request never authorises edits.

Escalate additional cost, a new provider or external data transfer, material
lock-in, significant product changes not already requested, irreversible
production-data changes outside an approved policy, and unresolved material
conflicts outside authority. Ordinary library choices and demonstrated,
recoverable migrations remain technical decisions.

The lead records criteria before implementation. It obtains the required
verification and independent review, checks the integrated result, and then
takes the authorised next step. Missing required evidence blocks acceptance.
An owner-only test needed for safe release blocks merge. Prefer automation.

Keep `main` production-ready. Never push directly to it. Use merge commits.
A merge-triggered deployment is a release: verify the deployed version and
required post-release checks. Report unavailable release evidence as pending.
Stop after the assigned task unless a larger work queue was authorised.

## Technical basis

Claude uses [custom subagents](https://code.claude.com/docs/en/sub-agents) and
[skills](https://code.claude.com/docs/en/skills). The lead invokes
`/codereview`; its forked context runs `qa-enforcer` directly. This avoids
a second QA wrapper. The lead waits for the result before acceptance.

[Agent Teams](https://code.claude.com/docs/en/agent-teams) are an optional,
experimental choice for work that benefits from teammate coordination.
The default reference settings do not enable them. To use Teams, merge
`CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1` into the `env` object of your existing
Claude settings. Do not replace other settings.

Codex uses [custom agents and subagents](https://learn.chatgpt.com/docs/agent-configuration/subagents),
[skills](https://learn.chatgpt.com/docs/build-skills), and
[AGENTS.md](https://learn.chatgpt.com/docs/agent-configuration/agents-md).
The lead starts an independent `qa_enforcer` to run `$codereview`.

Both hosts implement the same decision boundaries and evidence requirements.
Their tool syntax and orchestration remain explicit and separate.

## Layout

```text
template/
  DOCTRINE.md
  VISION.md
  CLAUDE.md
  AGENTS.md
  .claude/agents/       # Claude specialists
  .claude/skills/       # Claude workflows
  .claude/settings.json # Optional reference controls
  .codex/agents/        # Codex specialists
  .agents/skills/       # Codex workflows
  .github/pull_request_template.md
stacks/                # Concrete example profiles
docs/adr/              # Significant setup decisions
docs/workflow-scenarios.md
bin/                   # Linking and validation; no artifact generation
```

## Requirements

Use Git and the selected agent host. Delivery workflows use a GitHub repository
and the GitHub CLI. The reference Claude hooks require `jq`.

To validate this source bundle, use Bash and Python 3.11 or newer.
Validation uses the Python standard library; no additional package is required.
Example stack commands must be implemented in the target project. The profiles
do not ship a working application or its build scripts.

## Install global roles and workflows

Run from this repository:

```sh
bin/link-global.sh
```

Select one host with `--host claude` or `--host codex`.
The command links:
- Claude roles to `~/.claude/agents/` and skills to `~/.claude/skills/`.
- Codex roles to `~/.codex/agents/` and skills to `~/.agents/skills/`.

The linker replaces only symlinks. It preserves real files and directories.
It does not install user settings or project contracts. The optional
`template/.claude/settings.json` contains reference permissions and hooks;
merge needed controls into existing settings yourself. Native permissions
and repository protections still apply. A policy document cannot bypass them.

## Configure a project

Do not copy the complete `template/` directory. Start with:

```sh
PROJECT_DIR="/path/to/project"
cp template/DOCTRINE.md "$PROJECT_DIR/DOCTRINE.md"
cp template/VISION.md "$PROJECT_DIR/VISION.md"
cp stacks/STACK-TS.md "$PROJECT_DIR/STACK.md"
```

Copy the contract for the selected host, or both when the project uses both:

```sh
cp template/CLAUDE.md "$PROJECT_DIR/CLAUDE.md"
cp template/AGENTS.md "$PROJECT_DIR/AGENTS.md"
```

Review the authority defaults before adoption. Fill product and stack
placeholders. Implement the named verification commands and define applicable
CI, hardware, release, and recovery checks. Record enforcement gaps and
exceptions. Keep the five core command names; add named checks when needed.
Copy the PR template separately if useful.

Use an existing issue or a direct task:

```text
/project-manager solve issue #1
$project-manager solve issue #1
```

Use the first form for Claude and the second for Codex. A clear request starts
autonomous delivery within authority; a new approval ceremony is not required.

## Updating and legacy projects

Global roles and skills remain linked to this repository. Pulling changes
updates them for new sessions. Run the linker again after adding or removing
entries:

```sh
bin/link-global.sh --host all --prune
```

Pruning removes only dead links whose target ownership can be established
inside this repository. It retains links with unresolvable parent paths and
links that escape through parent traversal or a symlinked directory.

Copied project contracts do not update automatically. Revision-2 autonomy
requires both the local host contract and `DOCTRINE.md` to state
`Policy revision: 2`. A newer global skill does not grant merge or release
authority to an old project. Local approval gates and required roles remain.
An incomplete revision-2 adoption stops delivery until the owner approves a
compatible update. Read-only diagnosis is still allowed.

Updating this source bundle does not migrate downstream projects. Review and
adopt their contracts separately. Do not silently copy files or change live
user settings as part of a delivery task.

## Stack profiles

| Profile | Intended use |
| --- | --- |
| `STACK-TS.md` | TypeScript web application and backend |
| `STACK-EFFECT.md` | Effect-based stateless web application |
| `STACK-SWIFT.md` | Native iOS and macOS applications |
| `STACK-PY.md` | Home Assistant custom integrations |
| `STACK-TEMPLATE.md` | A project without a matching example |

Profiles are starting points, not universal product restrictions. Review
versions and fit at adoption. Concrete technology belongs only in `STACK.md`.
Each profile maps applicable doctrine requirements to evidence and defines
release and recovery responsibilities.

## Decisions and writing

Keep backlog and history in GitHub issues, coherent commits, PRs, and reviews.
Do not create roadmap, backlog, ledger, or changelog files. Use `docs/adr/`
only for significant durable decisions. Keep ADRs short and read them as needed.
See [the autonomous delivery decision](docs/adr/0001-autonomous-delivery.md).

Use ASD-STE100 writing principles for English artifacts: short sentences,
active voice, and consistent terms. Domain vocabulary remains unchanged.
This is a writing practice, not a claim of certified STE compliance.

## Verification

Before committing source-bundle changes:

```sh
bin/check-setup.sh
python3 bin/test-setup.py
```

The static check parses emitted TOML and JSON, checks metadata and structural
references, and validates shell syntax. The regression suite tests malformed
artifacts and isolated linking for both hosts, including safe pruning.
Tests use a temporary `AGENT_SETUP_HOME`; they do not alter live links.

Inspect the complete diff and evaluate both host distributions against
[the shared scenarios](docs/workflow-scenarios.md). Record which results came
from code execution, policy inspection, or isolated agent trials. Static tests
do not prove model compliance or vendor-runtime compatibility. Record any
unexecuted host, application, or deployment checks as limitations.
