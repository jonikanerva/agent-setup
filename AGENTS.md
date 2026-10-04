# AGENTS.md

Guidance for Codex when editing this source bundle.

## Repository and scope

Read README.md first. This repository contains final, static Claude Code and
Codex project guidance. It is not an application. Preserve explicit host
artifacts; do not add a generator, build step, or hidden source format.

The shared doctrine distributed to target projects is template/DOCTRINE.md.
Product intent and concrete
technology are distributed separately as template/VISION.md and stacks/.
The templates describe downstream defaults, not this repository's maintenance
process. Maintain this static bundle with lightweight checks and PRs. Do not
apply the distributed delivery workflow or ADR process to setup maintenance.

## Distribution

bin/link-global.sh links static role and skill files to user discovery paths.
Each target project separately adopts DOCTRINE.md, VISION.md, STACK.md, and its
selected CLAUDE.md or AGENTS.md. Copied contracts never update implicitly.

Never replace a real user file or directory. Replace only symlinks. Prune only
dead links whose target ownership is established inside this repository.
Use AGENT_SETUP_HOME in temporary tests; never test against live user paths.
Global updates must preserve a legacy project's approval and merge rules.

## Cross-host policy

Maintain the same authority and evidence rules in both host trees. Keep native
syntax explicit: Claude Markdown agents and slash skills; Codex TOML agents
and dollar-prefixed skills. In target projects, five specialists remain available, but the lead
chooses the roster. The lead may implement. Material changes require a
reviewer who did not implement them in a separate context.

The three workflows are project-manager, implement, and codereview. Delivery
runs from criteria through implementation and independent review to the
authorised outcome. Missing required evidence blocks acceptance. An owner
reservation of review, testing, or merge always applies.

Shared doctrine and host instructions remain technology-neutral. Concrete
technology and commands belong in STACK.md. Host contracts, agents, and
skills use the five named commands: $FORMAT_CMD, $LINT_CMD, $BUILD_CMD,
$TEST_CMD, $VERIFY_CMD. This source bundle uses the verification contract below
instead of an application VISION.md or STACK.md.

## Records and safeguards

- Use English for repository and GitHub artifacts and Finnish for user chat,
  subject to the owner's explicit language instructions.
- Use ASD-STE100 writing principles: short, active sentences and consistent terms.
- Use feat|fix|chore|docs/<topic> branches. Never commit or push to main.
- Use Conventional Commits with the current host's co-author trailer:
  Co-Authored-By: Codex <noreply@openai.com>.
- Keep coherent commits and use merge commits, never squash.
- Feature-branch force-pushes use --force-with-lease, never bare force.
- Keep setup decisions and history in GitHub PRs and discussions. Do not add
  local ADR, roadmap, backlog, ledger, or changelog files. The distributed
  ADR policy applies to target projects only.
- Do not modify other projects or live user settings without authorisation.
- Never weaken protections, bypass hooks, read secrets, recursively delete
  broad paths, or overwrite another contributor's work.
- Read-only specialists do not edit product or governance files. Review scratch
  files and test artifacts must be isolated.
- Ask before changing product direction, backlog structure, or repository
  settings. Merge only under explicit task authority. If the owner says they
  will review and merge, leave the PR for them.

## Verification

Before committing:
1. Run bin/check-setup.sh (Bash and Python 3.11+).
2. Run python3 bin/test-setup.py. It exercises both hosts in temporary
   AGENT_SETUP_HOME directories and checks malformed artifacts.
3. Inspect git diff --check and the complete diff.
4. Keep README.md accurate. Keep task-specific evaluation records in the PR;
   there is no mandatory agent-team review for setup edits.

These scripts do not generate or rewrite distributed artifacts. They do not
execute application-profile commands or prove model compliance. Keep the two
host distributions consistent and follow the owner's review instructions.

## Decision rights

An approved change authorises feature-branch edits, validation, commits,
pushes, and PR creation. The current task controls worktree, review, merge,
and rollout limits. Do not adopt new downstream permissions for this task
merely because the patch changes a template.
