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


class FormatTests(unittest.TestCase):
    def test_repository_fixtures_reject_invalid_artifacts(self):
        with tempfile.TemporaryDirectory(prefix="agent-setup-format-") as temporary:
            root = Path(temporary)
            for directory in ("template", "stacks", "bin", "docs"):
                shutil.copytree(ROOT / directory, root / directory)
            for filename in ("README.md", "AGENTS.md", "CLAUDE.md"):
                shutil.copyfile(ROOT / filename, root / filename)
            CHECK.validate(root)
            mutations = (
                ("template/.codex/agents/architect.toml", lambda text: text + '\nname = "duplicate"\n', "Cannot overwrite"),
                ("template/.claude/settings.json", lambda text: text + "{", "Extra data"),
                ("template/.agents/skills/implement/SKILL.md", lambda text: text.replace("name: implement", "name: wrong", 1), "name mismatch"),
                ("template/DOCTRINE.md", lambda text: text.replace("Policy revision: 2", "Policy revision: 1", 1), "Policy revision: 2"),
                ("stacks/STACK-TEMPLATE.md", lambda text: text.replace("`$TEST_CMD`", "`$MISSING_CMD`"), "TEST_CMD"),
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
            (root / "template/DOCTRINE.md").unlink()
            with self.assertRaisesRegex(ValueError, "missing file: template/DOCTRINE.md"):
                CHECK.validate(root)

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
