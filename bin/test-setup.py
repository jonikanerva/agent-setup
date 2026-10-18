#!/usr/bin/env python3
"""Run format and linker regression tests in temporary directories only."""

import importlib.util
import json
import os
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile
import unittest

# Do not write __pycache__ into the source bundle when loading the checker.
sys.dont_write_bytecode = True
ROOT = Path(__file__).resolve().parent.parent
SPEC = importlib.util.spec_from_file_location("check_static", ROOT / "bin/check-static.py")
CHECK = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(CHECK)


def destinations(host):
    result = {}
    if host in ("all", "claude"):
        for path in (ROOT / "template/.claude/agents").glob("*.md"):
            result[Path(".claude/agents") / path.name] = path
        for path in (ROOT / "template/.claude/skills").iterdir():
            if path.is_dir():
                result[Path(".claude/skills") / path.name] = path
    if host in ("all", "codex"):
        for path in (ROOT / "template/.codex/agents").glob("*.toml"):
            result[Path(".codex/agents") / path.name] = path
        for path in (ROOT / "template/.agents/skills").iterdir():
            if path.is_dir():
                result[Path(".agents/skills") / path.name] = path
    return result


class LinkerTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix="agent-setup-test-")
        self.addCleanup(self.temp.cleanup)
        self.base = Path(self.temp.name)

    def run_linker(self, destination, host="all", prune=False, repository=ROOT):
        # Leave HOME unchanged. The linker has a dedicated test destination.
        env = os.environ.copy()
        env["AGENT_SETUP_HOME"] = str(destination)
        args = ["bash", str(repository / "bin/link-global.sh"), "--host", host]
        if prune:
            args.append("--prune")
        result = subprocess.run(args, env=env, capture_output=True, text=True, timeout=20)
        self.assertEqual(result.returncode, 0, result.stderr + result.stdout)
        return result

    def test_both_hosts_selection_and_idempotence(self):
        for host in ("all", "claude", "codex"):
            with self.subTest(host=host):
                destination = self.base / host
                expected = destinations(host)
                self.run_linker(destination, host)
                for relative, source in expected.items():
                    link = destination / relative
                    self.assertTrue(link.is_symlink(), str(link))
                    self.assertEqual(link.resolve(), source.resolve())
                self.run_linker(destination, host)
                actual = {path.relative_to(destination): path.resolve()
                          for path in destination.rglob("*") if path.is_symlink()}
                self.assertEqual(actual, {path: source.resolve() for path, source in expected.items()})
                if host == "claude":
                    self.assertFalse((destination / ".codex").exists())
                    self.assertFalse((destination / ".agents").exists())
                if host == "codex":
                    self.assertFalse((destination / ".claude").exists())

    def test_real_files_directories_and_settings_survive(self):
        destination = self.base / "existing"
        for relative, source in destinations("all").items():
            target = destination / relative
            target.parent.mkdir(parents=True, exist_ok=True)
            if source.is_dir():
                target.mkdir()
                (target / "owner-file").write_text("keep directory\n")
            else:
                target.write_text("keep file\n")
        settings = [destination / ".claude/settings.json", destination / ".codex/config.toml"]
        for path in settings:
            path.write_text("keep settings\n")
        self.run_linker(destination, prune=True)
        for relative, source in destinations("all").items():
            target = destination / relative
            self.assertFalse(target.is_symlink())
            preserved = target / "owner-file" if source.is_dir() else target
            self.assertEqual(preserved.read_text(), "keep directory\n" if source.is_dir() else "keep file\n")
        for path in settings:
            self.assertEqual(path.read_text(), "keep settings\n")

    def test_existing_symlinks_can_be_replaced(self):
        destination = self.base / "old-links"
        for relative in destinations("all"):
            target = destination / relative
            target.parent.mkdir(parents=True, exist_ok=True)
            target.symlink_to(self.base / "old-missing-source")
        self.run_linker(destination)
        for relative, source in destinations("all").items():
            self.assertEqual((destination / relative).resolve(), source.resolve())

    def test_prune_removes_only_dead_repository_links(self):
        destination = self.base / "prune"
        self.run_linker(destination)
        directories = {relative.parent for relative in destinations("all")}
        preserved = []
        removed = []
        for relative in directories:
            directory = destination / relative
            dead_owned = directory / "removed-owned"
            dead_owned.symlink_to(ROOT / "template/removed-entry-for-test")
            removed.append(dead_owned)
            for name, target in (
                ("unrelated-dead", self.base / "foreign/missing"),
                ("similar-prefix-dead", Path(str(ROOT) + "-other") / "missing"),
                ("relative-dead", Path("../unrelated-missing")),
                ("live-owned", ROOT / "README.md"),
                ("escaped-dead", ROOT / ".." / "unrelated-missing"),
            ):
                link = directory / name
                link.symlink_to(target)
                preserved.append((link, os.readlink(link)))
            real = directory / "real-file"
            real.write_text("keep real\n")
            preserved.append((real, None))
        self.run_linker(destination, prune=True)
        for link in removed:
            self.assertFalse(link.is_symlink(), str(link))
        for path, target in preserved:
            if target is None:
                self.assertEqual(path.read_text(), "keep real\n")
            else:
                self.assertTrue(path.is_symlink(), str(path))
                self.assertEqual(os.readlink(path), target)

    def test_prune_respects_selected_host(self):
        destination = self.base / "host-prune"
        self.run_linker(destination)
        claude = destination / ".claude/agents/dead-owned"
        codex = destination / ".codex/agents/dead-owned"
        for link in (claude, codex):
            link.symlink_to(ROOT / "template/removed-entry-for-test")
        self.run_linker(destination, "claude", prune=True)
        self.assertFalse(claude.is_symlink())
        self.assertTrue(codex.is_symlink())
        self.run_linker(destination, "codex", prune=True)
        self.assertFalse(codex.is_symlink())

    def test_prune_preserves_escape_through_symlinked_parent(self):
        repository = self.base / "fixture-repo"
        (repository / "bin").mkdir(parents=True)
        shutil.copyfile(ROOT / "bin/link-global.sh", repository / "bin/link-global.sh")
        foreign = self.base / "foreign"
        foreign.mkdir()
        (repository / "escape").symlink_to(foreign, target_is_directory=True)
        destination = self.base / "parent-escape"
        directory = destination / ".claude/agents"
        directory.mkdir(parents=True)
        escaped = directory / "foreign-dead"
        escaped.symlink_to(repository / "escape/missing")
        unknown = directory / "unresolvable-parent"
        unknown.symlink_to(repository / "absent-parent/missing")
        self.run_linker(destination, "claude", prune=True, repository=repository)
        self.assertTrue(escaped.is_symlink())
        self.assertTrue(unknown.is_symlink())


def source_files(host):
    """Map each copied file path in a project to its source file."""
    result = {}
    for relative, source in destinations(host).items():
        if source.is_dir():
            for path in source.rglob("*"):
                if path.is_file() and not path.name.startswith("."):
                    result[relative / path.relative_to(source)] = path
        else:
            result[relative] = source
    return result


class CopierTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix="agent-setup-copy-")
        self.addCleanup(self.temp.cleanup)
        self.base = Path(self.temp.name)
        # Isolate Git from the user's configuration, for example commit signing.
        self.env = os.environ.copy()
        self.env.update(GIT_CONFIG_GLOBAL=os.devnull, GIT_CONFIG_NOSYSTEM="1",
                        GIT_AUTHOR_NAME="Test", GIT_AUTHOR_EMAIL="test@example.invalid",
                        GIT_COMMITTER_NAME="Test", GIT_COMMITTER_EMAIL="test@example.invalid")

    def git(self, project, *args):
        subprocess.run(["git", "-C", str(project), *args], env=self.env, check=True,
                       capture_output=True, text=True, timeout=20)

    def project(self, name="project"):
        project = self.base / name
        project.mkdir()
        self.git(project, "init", "-q")
        (project / "README.md").write_text("project\n")
        return project

    def commit(self, project):
        self.git(project, "add", "-A")
        self.git(project, "commit", "-q", "-m", "test")

    def run_copier(self, *args, cwd=None, expect=0):
        command = ["bash", str(ROOT / "bin/copy-project.sh"), *map(str, args)]
        result = subprocess.run(command, env=self.env, cwd=cwd, capture_output=True,
                                text=True, timeout=20)
        self.assertEqual(result.returncode, expect, result.stderr + result.stdout)
        return result

    def copied(self, project):
        return {path.relative_to(project) for path in project.rglob("*")
                if path.is_file() and ".git" not in path.relative_to(project).parts}

    def test_both_hosts_selection_and_idempotence(self):
        for host in ("all", "claude", "codex"):
            with self.subTest(host=host):
                project = self.project(host)
                expected = source_files(host)
                first = self.run_copier("--host", host, project)
                self.assertIn(f"{len(expected)} copied, 0 unchanged", first.stdout)
                self.assertEqual(self.copied(project), set(expected) | {Path("README.md")})
                for relative, source in expected.items():
                    path = project / relative
                    self.assertFalse(path.is_symlink(), str(path))
                    self.assertEqual(path.read_bytes(), source.read_bytes())
                second = self.run_copier("--host", host, project)
                self.assertIn(f"0 copied, {len(expected)} unchanged", second.stdout)

    def test_default_target_is_current_repository(self):
        project = self.project()
        subdirectory = project / "src"
        subdirectory.mkdir()
        self.run_copier(cwd=subdirectory)
        self.assertEqual(self.copied(project), set(source_files("all")) | {Path("README.md")})

    def test_overwrites_committed_copies_and_keeps_other_files(self):
        project = self.project()
        self.run_copier(project)
        role = project / ".claude/agents/architect.md"
        role.write_text("old version\n")
        own_role = project / ".claude/agents/project-own.md"
        own_role.write_text("keep role\n")
        own_skill_file = project / ".claude/skills/implement/notes.md"
        own_skill_file.write_text("keep skill file\n")
        self.commit(project)
        result = self.run_copier(project)
        self.assertEqual(role.read_bytes(), (ROOT / "template/.claude/agents/architect.md").read_bytes())
        self.assertEqual(own_role.read_text(), "keep role\n")
        self.assertEqual(own_skill_file.read_text(), "keep skill file\n")
        self.assertIn("kept (not from agent-setup): .claude/agents/project-own.md", result.stdout)

    def test_uncommitted_changes_require_force(self):
        project = self.project()
        self.run_copier(project)
        self.commit(project)
        role = project / ".codex/agents/lead-dev.toml"
        role.write_text("local edit\n")
        result = self.run_copier(project, expect=1)
        self.assertIn("uncommitted changes", result.stderr)
        self.assertEqual(role.read_text(), "local edit\n")
        self.run_copier("--force", project)
        self.assertEqual(role.read_bytes(), (ROOT / "template/.codex/agents/lead-dev.toml").read_bytes())

    def test_symlinks_are_replaced_without_writing_through(self):
        project = self.project()
        outside_file = self.base / "outside.md"
        outside_file.write_text("outside\n")
        outside_skill = self.base / "outside-skill"
        outside_skill.mkdir()
        (outside_skill / "SKILL.md").write_text("outside skill\n")
        role = project / ".claude/agents/architect.md"
        skill = project / ".agents/skills/codereview"
        role.parent.mkdir(parents=True)
        skill.parent.mkdir(parents=True)
        role.symlink_to(outside_file)
        skill.symlink_to(outside_skill, target_is_directory=True)
        self.run_copier(project)
        self.assertFalse(role.is_symlink())
        self.assertFalse(skill.is_symlink())
        self.assertEqual(role.read_bytes(), (ROOT / "template/.claude/agents/architect.md").read_bytes())
        self.assertEqual(outside_file.read_text(), "outside\n")
        self.assertEqual([path.name for path in outside_skill.iterdir()], ["SKILL.md"])
        self.assertEqual((outside_skill / "SKILL.md").read_text(), "outside skill\n")

    def test_symlinked_parent_directory_is_refused(self):
        for parent in (".claude", ".agents/skills"):
            with self.subTest(parent=parent):
                project = self.project(parent.replace("/", "-"))
                outside = self.base / f"outside-{parent.replace('/', '-')}"
                outside.mkdir()
                (outside / "codereview").symlink_to(self.base / "missing", target_is_directory=True)
                link = project / parent
                link.parent.mkdir(parents=True, exist_ok=True)
                link.symlink_to(outside, target_is_directory=True)
                result = self.run_copier(project, expect=1)
                self.assertIn("refusing to write through a symlink", result.stderr)
                self.assertEqual([path.name for path in outside.iterdir()], ["codereview"])
                self.assertTrue((outside / "codereview").is_symlink())

    def test_invalid_targets_fail(self):
        project = self.project()
        plain = self.base / "plain"
        plain.mkdir()
        (project / "src").mkdir()
        for target in (self.base / "missing", plain, project / "src", ROOT):
            with self.subTest(target=target):
                self.run_copier(target, expect=2)
        self.run_copier("--host", "other", project, expect=2)
        self.run_copier(cwd=plain, expect=2)
        self.assertEqual(self.copied(project), {Path("README.md")})


class FormatTests(unittest.TestCase):
    def test_repository_fixtures_reject_invalid_artifacts(self):
        with tempfile.TemporaryDirectory(prefix="agent-setup-format-") as temporary:
            root = Path(temporary)
            for directory in ("template", "stacks", "bin"):
                shutil.copytree(ROOT / directory, root / directory)
            for filename in ("README.md", "AGENTS.md", "CLAUDE.md"):
                shutil.copyfile(ROOT / filename, root / filename)
            CHECK.validate(root)
            mutations = (
                ("template/.codex/agents/architect.toml", lambda text: text + '\nname = "duplicate"\n', "Cannot overwrite"),
                ("template/.claude/settings.json", lambda text: text + "{", "Extra data"),
                ("template/.agents/skills/implement/SKILL.md", lambda text: text.replace("name: implement", "name: wrong", 1), "name mismatch"),
                ("stacks/STACK-TEMPLATE.md", lambda text: text.replace("`$TEST_CMD`", "`$MISSING_CMD`"), "TEST_CMD"),
                ("stacks/STACK-TS.md", lambda text: text.replace("## 15. ", "## ", 1), "sections 0-15"),
                ("README.md", lambda text: text.replace("| `STACK-TS.md` |", "| `STACK-NONE.md` |", 1), "profile table mismatch"),
            )
            for relative, change, error in mutations:
                with self.subTest(relative=relative):
                    path = root / relative
                    original = path.read_text()
                    try:
                        path.write_text(change(original))
                        with self.assertRaisesRegex(ValueError, error):
                            CHECK.validate(root)
                    finally:
                        path.write_text(original)
            extra_entries = (
                ("template/.claude/agents/unexpected.md", False, "role set mismatch"),
                ("template/.codex/agents/unexpected.toml", False, "role set mismatch"),
                ("template/.claude/skills/unexpected", True, "skill set mismatch"),
                ("template/.agents/skills/unexpected", True, "skill set mismatch"),
                ("template/.claude/agents/unexpected.md", True, "role set mismatch"),
                ("template/.codex/agents/unexpected.toml", True, "role set mismatch"),
                ("stacks/stack-unexpected.md", False, "profile names must match"),
                ("stacks/STACK-UNEXPECTED", True, "profile names must match"),
            )
            for relative, directory, error in extra_entries:
                with self.subTest(extra=relative, directory=directory):
                    path = root / relative
                    try:
                        if directory:
                            path.mkdir()
                        else:
                            path.write_text("Unexpected role fixture.\n")
                        with self.assertRaisesRegex(ValueError, error):
                            CHECK.validate(root)
                    finally:
                        if directory:
                            path.rmdir()
                        else:
                            path.unlink()
            CHECK.validate(root)
            for relative in ("template/DOCTRINE.md",):
                with self.subTest(missing=relative):
                    path = root / relative
                    original = path.read_text()
                    try:
                        path.unlink()
                        with self.assertRaisesRegex(ValueError, f"missing file: {relative}"):
                            CHECK.validate(root)
                    finally:
                        path.write_text(original)

    def test_frontmatter_accepts_emitted_scalars(self):
        value = CHECK.frontmatter('---\nname: sample\ndescription: >\n  Line one.\n  Line two.\nuser-invocable: true\n---\nBody.', "fixture")
        self.assertEqual(value["description"], "Line one. Line two.")
        self.assertIs(value["user-invocable"], True)

    def test_frontmatter_rejects_ambiguous_or_incomplete_input(self):
        invalid = (
            "name: sample\n---\nBody.",
            "---\nname: sample\n",
            "---\nname: sample\nname: duplicate\n---\nBody.",
            "---\nname: [sample]\n---\nBody.",
            "---\nname: value: ambiguous\n---\nBody.",
            '---\nname: "unterminated\n---\nBody.',
            "---\nname: sample\n---\n",
        )
        for text in invalid:
            with self.subTest(text=text), self.assertRaises(ValueError):
                CHECK.frontmatter(text, "fixture")

    def test_settings_rejects_bad_json_and_shape(self):
        invalid = ('{', '{"permissions":{},"permissions":{}}',
                   '{"permissions":{"allow":"*","deny":[]}}')
        for text in invalid:
            with self.subTest(text=text), self.assertRaises(ValueError):
                CHECK.settings(text)

    def test_invalid_hook_script_fails_without_execution(self):
        data = {"permissions": {"allow": [], "deny": []}, "hooks": {
            "PreToolUse": [{"matcher": "Bash", "hooks": [{
                "type": "command", "command": "bash -c 'if then'"}]}]}}
        with self.assertRaises(ValueError):
            CHECK.settings(json.dumps(data))


if __name__ == "__main__":
    unittest.main(verbosity=2)
