#!/usr/bin/env python3
"""Check the emitted static formats, not agent behavior or vendor schemas.

Frontmatter uses a small YAML subset: flat string/boolean fields, quoted
strings, and indented folded/literal strings. Reject unsupported syntax.
"""

import json
from pathlib import Path
import re
import shlex
import subprocess
import sys

if sys.version_info < (3, 11):
    sys.exit("check failed: Python 3.11 or newer is required")
import tomllib


ROOT = Path(__file__).resolve().parent.parent
ROLES = ("architect", "devils-advocate", "lead-dev", "qa-enforcer", "ux-guardian")
SKILLS = ("project-manager", "implement", "codereview")
COMMANDS = ("FORMAT_CMD", "LINT_CMD", "BUILD_CMD", "TEST_CMD", "VERIFY_CMD")


def require(condition, message):
    if not condition:
        raise ValueError(message)


def read(root, relative):
    path = root / relative
    require(path.is_file(), f"missing file: {relative}")
    return path.read_text(encoding="utf-8")


def string(value, context):
    require(isinstance(value, str) and bool(value.strip()), f"{context}: expected a nonempty string")


def scalar(value, context):
    if value in ("true", "false"):
        return value == "true"
    if value.startswith('"'):
        parsed = json.loads(value)
        string(parsed, context)
        return parsed
    if value.startswith("'"):
        require(re.fullmatch(r"'(?:[^']|'')*'", value), f"{context}: invalid quoted scalar")
        return value[1:-1].replace("''", "'")
    require(value and not value.startswith(tuple("[{&*!|>@`")), f"{context}: unsupported YAML scalar")
    require(not re.search(r":(?:\s|$)|\s#", value), f"{context}: quote YAML punctuation in this scalar")
    require(value.lower() not in ("null", "~", "yes", "no", "on", "off") and
            not re.fullmatch(r"[-+]?\d+(?:\.\d+)?", value), f"{context}: expected a string or boolean")
    return value


def frontmatter(text, context):
    lines = text.splitlines()
    require(lines and lines[0] == "---", f"{context}: missing frontmatter start")
    try:
        end = lines.index("---", 1)
    except ValueError as error:
        raise ValueError(f"{context}: missing frontmatter end") from error
    fields = {}
    index = 1
    while index < end:
        line = lines[index]
        if not line.strip():
            index += 1
            continue
        match = re.fullmatch(r"([a-z][a-z0-9-]*): (.*)", line)
        require(match is not None, f"{context}:{index + 1}: unsupported YAML field")
        key, value = match.groups()
        require(key not in fields, f"{context}: duplicate metadata field {key}")
        index += 1
        if value in (">", "|", ">-", "|-"):
            parts = []
            while index < end and (not lines[index] or lines[index].startswith("  ")):
                parts.append(lines[index][2:])
                index += 1
            value = (" " if value.startswith(">") else "\n").join(parts)
            string(value, f"{context}: {key}")
        else:
            value = scalar(value, f"{context}: {key}")
        fields[key] = value
    require(bool("\n".join(lines[end + 1:]).strip()), f"{context}: missing instruction body")
    return fields


def metadata(text, context, expected_name, allowed):
    fields = frontmatter(text, context)
    require(not (fields.keys() - allowed), f"{context}: unknown metadata fields {fields.keys() - allowed}")
    require(fields.get("name") == expected_name, f"{context}: name mismatch")
    string(fields.get("description"), f"{context}: description")
    for key, value in fields.items():
        if key in ("user-invocable", "disable-model-invocation", "background"):
            require(isinstance(value, bool), f"{context}: {key} must be boolean")
        else:
            string(value, f"{context}: {key}")
    return fields


def unique_object(pairs):
    result = {}
    for key, value in pairs:
        require(key not in result, f"duplicate JSON field: {key}")
        result[key] = value
    return result


def shell_syntax(command, context):
    result = subprocess.run(["bash", "-n", "-c", command], capture_output=True, text=True)
    require(result.returncode == 0, f"{context}: {result.stderr.strip()}")
    # The emitted hooks wrap another shell program in `bash -c`. Parse that too.
    words = shlex.split(command)
    if len(words) >= 3 and words[:2] == ["bash", "-c"]:
        result = subprocess.run(["bash", "-n", "-c", words[2]], capture_output=True, text=True)
        require(result.returncode == 0, f"{context}: inner script: {result.stderr.strip()}")


def settings(text):
    data = json.loads(text, object_pairs_hook=unique_object)
    require(isinstance(data, dict), "settings: expected an object")
    for key in ("allow", "deny"):
        values = data.get("permissions", {}).get(key)
        require(isinstance(values, list), f"settings: permissions.{key} must be a list")
        for value in values:
            string(value, f"settings: permissions.{key}")
    environment = data.get("env", {})
    require(isinstance(environment, dict), "settings: env must be an object")
    for key, value in environment.items():
        string(value, f"settings: env.{key}")
    hooks = data.get("hooks", {})
    require(isinstance(hooks, dict), "settings: hooks must be an object")
    for event, groups in hooks.items():
        require(isinstance(groups, list), f"settings: {event} must be a list")
        for group in groups:
            require(isinstance(group, dict), f"settings: {event} hook group must be an object")
            string(group.get("matcher"), f"settings: {event} matcher")
            require(isinstance(group.get("hooks"), list), f"settings: {event} hooks must be a list")
            for hook in group["hooks"]:
                require(isinstance(hook, dict) and hook.get("type") == "command",
                        f"settings: {event}: checker supports command hooks only")
                string(hook.get("command"), f"settings: {event} command")
                shell_syntax(hook["command"], f"settings: {event}")


def validate(root):
    for relative in ("README.md", "AGENTS.md", "CLAUDE.md", "template/DOCTRINE.md",
                     "template/VISION.md", "template/.github/pull_request_template.md",
                     "docs/workflow-scenarios.md", "docs/workflow-trial-inputs.md",
                     "stacks/STACK-TEMPLATE.md"):
        require(bool(read(root, relative).strip()), f"empty file: {relative}")
    doctrine = read(root, "template/DOCTRINE.md")
    require(len(re.findall(r"^Policy revision: 2$", doctrine, re.M)) == 1,
            "template/DOCTRINE.md: expected one Policy revision: 2 marker")
    for host in ("CLAUDE", "AGENTS"):
        text = read(root, f"template/{host}.md")
        require(len(re.findall(r"^Policy revision: 2$", text, re.M)) == 1,
                f"template/{host}.md: expected one Policy revision: 2 marker")
        require("DOCTRINE.md" in text, f"template/{host}.md: missing shared doctrine reference")

    settings(read(root, "template/.claude/settings.json"))
    for script in (root / "bin").glob("*.sh"):
        result = subprocess.run(["bash", "-n", str(script)], capture_output=True, text=True)
        require(result.returncode == 0, f"{script.name}: {result.stderr.strip()}")

    # Match the non-hidden entries that link-global.sh can distribute. A role
    # glob can also select a directory, so do not limit it to regular files.
    for host, suffix in ((".claude", ".md"), (".codex", ".toml")):
        relative = f"template/{host}/agents"
        expected = {role + suffix for role in ROLES}
        actual = {path.name for path in (root / relative).glob(f"*{suffix}")
                  if path.exists() and not path.name.startswith(".")}
        require(actual == expected,
                f"{relative}: role set mismatch; missing={sorted(expected - actual)}, "
                f"unexpected={sorted(actual - expected)}")
    for host in (".claude", ".agents"):
        relative = f"template/{host}/skills"
        expected = set(SKILLS)
        actual = {path.name for path in (root / relative).glob("*")
                  if path.is_dir() and not path.name.startswith(".")}
        require(actual == expected,
                f"{relative}: skill set mismatch; missing={sorted(expected - actual)}, "
                f"unexpected={sorted(actual - expected)}")

    for role in ROLES:
        relative = f"template/.claude/agents/{role}.md"
        fields = metadata(read(root, relative), relative, role,
                          {"name", "description", "tools", "disallowed-tools", "model",
                           "skills", "background", "memory"})
        string(fields.get("tools"), f"{relative}: tools")
        relative = f"template/.codex/agents/{role}.toml"
        data = tomllib.loads(read(root, relative))
        allowed = {"name", "description", "sandbox_mode", "developer_instructions",
                   "model", "model_reasoning_effort"}
        require(not (data.keys() - allowed), f"{relative}: unsupported fields {data.keys() - allowed}")
        require(data.get("name") == role.replace("-", "_"), f"{relative}: name mismatch")
        for key in ("description", "developer_instructions"):
            string(data.get(key), f"{relative}: {key}")
        require(data.get("sandbox_mode") in ("read-only", "workspace-write"),
                f"{relative}: unsupported sandbox_mode")
        if role in ("architect", "devils-advocate", "ux-guardian"):
            require(data.get("sandbox_mode") == "read-only", f"{relative}: review role must be read-only")
    for host in (".claude", ".agents"):
        for skill in SKILLS:
            relative = f"template/{host}/skills/{skill}/SKILL.md"
            fields = metadata(read(root, relative), relative, skill,
                              {"name", "description", "allowed-tools", "argument-hint", "context", "agent",
                               "user-invocable", "disable-model-invocation", "model"})
            if "agent" in fields:
                require(fields.get("context") == "fork", f"{relative}: agent requires context: fork")
                agent = fields["agent"]
                require(host == ".claude" and (agent == "general-purpose" or
                        (root / f"template/.claude/agents/{agent}.md").is_file()),
                        f"{relative}: missing agent definition {agent}")
    for profile in sorted((root / "stacks").glob("STACK-*.md")):
        text = profile.read_text(encoding="utf-8")
        for command in COMMANDS:
            rows = re.findall(r"^\|\s*`\$" + command + r"`\s*\|\s*`([^`]+)`", text, re.M)
            require(len(rows) == 1 and bool(rows[0].strip()),
                    f"{profile.name}: expected one nonempty {command} command-table row")


if __name__ == "__main__":
    try:
        validate(ROOT)
    except (ValueError, OSError, TypeError, AttributeError) as error:
        sys.exit(f"check failed: {error}")
