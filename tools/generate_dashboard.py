#!/usr/bin/env python3
"""Generate the static showcase dashboard.

This script reads the *real* repository contents and writes
``dashboard-data.js`` next to ``index.html``:

  * every implementation in ``languages/<name>/connect_four.<ext>`` becomes
    a sidebar entry (source code included),
  * every framework in ``frameworks/<name>/`` becomes an entry in the
    ``frameworks`` list (the dashboard's "Frameworks" browse mode), using the
    same shape as a language plus the ``folder``/``note``/``linkText`` fields,
  * the verified console captures in ``tests/expected/<scenario>.txt`` become
    the selectable "Console Output" views, and
  * the project URL (the git remote, else ``GITHUB_REPOSITORY``, else a
    default) and branch are recorded so the dashboard can link each
    implementation to its folder on GitHub.

Because the data is emitted as a plain JavaScript object it can be loaded
with a ``<script>`` tag, so the dashboard works both on a static host and
straight from ``file://`` (no fetch/CORS problems).

Usage::

    python tools/generate_dashboard.py
"""

from __future__ import annotations

import datetime
import json
import os
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
LANGUAGES_DIR = ROOT / "languages"
FRAMEWORKS_DIR = ROOT / "frameworks"
EXPECTED_DIR = ROOT / "tests" / "expected"
OUTPUT_FILE = ROOT / "dashboard-data.js"

# Fallbacks for the project link the dashboard shows above each implementation.
DEFAULT_REPOSITORY = "https://github.com/pattygcoding/Neo-Connect-Four-Language-Tree"
DEFAULT_BRANCH = "main"

# ---------------------------------------------------------------------------
# Display metadata per language directory.  Every entry is
# (display name, Prism class, category).  Add new languages here; anything
# missing falls back to a title-cased directory name and generic highlighting.
# ---------------------------------------------------------------------------
LANGUAGE_INFO = {
    "ada": ("Ada", "language-ada", "Systems"),
    "elm": ("Elm", "language-elm", "Web"),
    "bash": ("Bash", "language-bash", "Scripting"),
    "c": ("C", "language-c", "Systems"),
    "assembly": ("Assembly", "language-nasm", "Systems"),
    "clojure": ("Clojure", "language-clojure", "Functional"),
    "cobol": ("COBOL", "language-cobol", "Legacy"),
    "cpp": ("C++", "language-cpp", "Systems"),
    "crystal": ("Crystal", "language-crystal", "Systems"),
    "csharp": ("C#", "language-csharp", "JVM/.NET"),
    "d": ("D", "language-d", "Systems"),
    "dart": ("Dart", "language-dart", "Web"),
    "elixir": ("Elixir", "language-elixir", "Functional"),
    "erlang": ("Erlang", "language-erlang", "Functional"),
    "fortran": ("Fortran", "language-fortran", "Scientific"),
    "fsharp": ("F#", "language-fsharp", "JVM/.NET"),
    "go": ("Go", "language-go", "Systems"),
    "groovy": ("Groovy", "language-groovy", "JVM/.NET"),
    "haskell": ("Haskell", "language-haskell", "Functional"),
    "java": ("Java", "language-java", "JVM/.NET"),
    "javascript": ("JavaScript", "language-javascript", "Web"),
    "julia": ("Julia", "language-julia", "Scientific"),
    "kotlin": ("Kotlin", "language-kotlin", "JVM/.NET"),
    "lisp": ("Lisp", "language-lisp", "Functional"),
    "lua": ("Lua", "language-lua", "Scripting"),
    "matlab": ("MATLAB", "language-matlab", "Scientific"),
    "nim": ("Nim", "language-nim", "Systems"),
    "objectivec": ("Objective-C", "language-objectivec", "Systems"),
    "ocaml": ("OCaml", "language-ocaml", "Functional"),
    "pascal": ("Pascal", "language-pascal", "Legacy"),
    "perl": ("Perl", "language-perl", "Scripting"),
    "php": ("PHP", "language-php", "Web"),
    "powershell": ("PowerShell", "language-powershell", "Scripting"),
    "prolog": ("Prolog", "language-prolog", "Logic"),
    "python": ("Python", "language-python", "Scripting"),
    "r": ("R", "language-r", "Scientific"),
    "ruby": ("Ruby", "language-ruby", "Scripting"),
    "rust": ("Rust", "language-rust", "Systems"),
    "scala": ("Scala", "language-scala", "JVM/.NET"),
    "scheme": ("Scheme", "language-scheme", "Functional"),
    "sql": ("SQL", "language-sql", "Data"),
    "swift": ("Swift", "language-swift", "Systems"),
    "typescript": ("TypeScript", "language-typescript", "Web"),
    "v": ("V", "language-v", "Systems"),
    "vb": ("Visual Basic", "language-vbnet", "JVM/.NET"),
    "zig": ("Zig", "language-zig", "Systems"),
}

# Friendly labels for the scenarios captured under tests/expected/.
SCENARIO_LABELS = {
    "horizontal_win": "Horizontal win",
    "vertical_win": "Vertical win",
    "diagonal_up_win": "Diagonal win (up-right)",
    "diagonal_down_win": "Diagonal win (down-right)",
    "full_column": "Rejected full column",
    "invalid_inputs": "Rejected invalid input",
    "tie": "Full-board tie",
    "eof_during_game": "End of input",
}

DEFAULT_PRISM = "language-clike"

# Framework entries the dashboard lists under its "Frameworks" browse mode
# (Ruby on Rails today; React, NestJS, Next, ... later).  A framework lives in
# ``frameworks/<id>/`` and is described here rather than auto-detected, because
# an app has no single ``connect_four.<ext>`` to discover:
#
#   name      display name shown in the sidebar and header
#   prism     Prism grammar class for syntax highlighting
#   category  the badge and the sidebar's category filter
#   file      the one representative file to show, relative to the framework dir
#   folder    the path linked on GitHub (defaults to ``frameworks/<id>``)
#   note      a sentence for the banner above the code; ``{link}`` marks where
#             the "view the whole project" link is injected (unlike a language,
#             a framework app is many files, so this points at the rest of it)
#   linkText  the anchor text that replaces ``{link}`` in ``note``
# ---------------------------------------------------------------------------
FRAMEWORK_INFO = {
    "rubyonrails": {
        "name": "Ruby on Rails",
        "prism": "language-ruby",
        "category": "Web",
        "file": "app/controllers/games_controller.rb",
        "folder": "frameworks/rubyonrails",
        "note": "This is one representative file from the app. See {link} to "
                "browse the models, views, routes and the rest of the project.",
        "linkText": "the full Rails app on GitHub",
    },
}


def read_text(path: Path) -> str:
    """Read a text file and normalise its line endings to ``\\n``."""
    return path.read_text(encoding="utf-8").replace("\r\n", "\n").replace("\r", "\n")


def git_output(*args: str) -> str:
    """Run a read-only git command in the repository; "" when git is unavailable."""
    try:
        result = subprocess.run(
            ["git", "-C", str(ROOT), *args],
            capture_output=True,
            text=True,
            timeout=10,
            check=False,
        )
    except (OSError, subprocess.SubprocessError):
        return ""
    return result.stdout.strip() if result.returncode == 0 else ""


def repository_url() -> str:
    """The GitHub project the dashboard links to.

    The clone's remote is the truth, then ``GITHUB_REPOSITORY`` (set inside
    Actions), then the committed default.  ``git@``/``ssh://`` remotes are
    normalised to https and a trailing ``.git`` is dropped, so
    ``git@github.com:owner/repo.git`` becomes ``https://github.com/owner/repo``.
    """
    remote = git_output("config", "--get", "remote.origin.url") or os.environ.get(
        "GITHUB_REPOSITORY", ""
    )
    if not remote:
        return DEFAULT_REPOSITORY
    if remote.startswith("git@"):
        host, _, path = remote[len("git@"):].partition(":")
        remote = "https://%s/%s" % (host, path)
    elif remote.startswith("ssh://"):
        remote = "https://" + remote[len("ssh://"):].replace("git@", "", 1)
    if not remote.startswith("http"):
        remote = "https://github.com/" + remote
    if remote.endswith(".git"):
        remote = remote[: -len(".git")]
    return remote.rstrip("/") or DEFAULT_REPOSITORY


def repository_branch() -> str:
    """The branch the dashboard links into: HEAD's name, else Actions', else main.

    A detached HEAD (a CI checkout) reports ``HEAD``, which is not a usable
    ref, so ``GITHUB_REF_NAME`` takes over there.
    """
    branch = git_output("rev-parse", "--abbrev-ref", "HEAD")
    if not branch or branch == "HEAD":
        branch = os.environ.get("GITHUB_REF_NAME", "") or DEFAULT_BRANCH
    return branch


def is_source_text(path: Path) -> bool:
    """True when ``path`` decodes as UTF-8 text.

    A language directory can hold compile artefacts beside its source (OCaml's
    ``ocamlopt`` writes ``connect_four.cmi``/``.cmx``/``.o`` next to
    ``connect_four.ml``), and those sort before the source.  Only the source is
    text, so binaries are skipped here.
    """
    try:
        path.read_text(encoding="utf-8")
    except (UnicodeDecodeError, OSError):
        return False
    return True


def discover_languages() -> list[dict]:
    """Find every languages/<name>/connect_four.<ext> implementation."""
    found = []
    if not LANGUAGES_DIR.is_dir():
        return found
    for directory in sorted(LANGUAGES_DIR.iterdir()):
        if not directory.is_dir():
            continue
        matches = sorted(directory.glob("connect_four.*"))
        sources = [path for path in matches if is_source_text(path)]
        if not sources:
            continue
        source = sources[0]
        key = directory.name.lower()
        name, prism, category = LANGUAGE_INFO.get(
            key, (directory.name.replace("_", " ").title(), DEFAULT_PRISM, "Other")
        )
        found.append(
            {
                "id": key,
                "name": name,
                "category": category,
                "prism": prism,
                "file": source.relative_to(ROOT).as_posix(),
                "code": read_text(source),
            }
        )
    found.sort(key=lambda item: item["name"].lower())
    return found


def discover_frameworks() -> list[dict]:
    """Build the framework entries from ``frameworks/<id>/`` and ``FRAMEWORK_INFO``.

    A framework app is many files, so unlike a language there is nothing to
    glob; the metadata pins the one representative file to show and the folder
    to link on GitHub.  A directory missing its metadata, or missing that file,
    is skipped rather than guessed at.
    """
    found = []
    if not FRAMEWORKS_DIR.is_dir():
        return found
    for directory in sorted(FRAMEWORKS_DIR.iterdir()):
        if not directory.is_dir():
            continue
        key = directory.name.lower()
        meta = FRAMEWORK_INFO.get(key)
        if meta is None:
            continue
        highlight = directory / meta["file"]
        if not is_source_text(highlight):
            continue
        found.append(
            {
                "id": key,
                "name": meta["name"],
                "category": meta["category"],
                "prism": meta["prism"],
                "file": highlight.relative_to(ROOT).as_posix(),
                "folder": meta.get("folder", "frameworks/%s" % key),
                "note": meta.get("note", ""),
                "linkText": meta.get("linkText", ""),
                "code": read_text(highlight),
            }
        )
    found.sort(key=lambda item: item["name"].lower())
    return found


def discover_scenarios() -> tuple[list[dict], dict[str, str]]:
    """Return (scenario list, {scenario id -> console output})."""
    scenarios = []
    outputs = {}
    if not EXPECTED_DIR.is_dir():
        return scenarios, outputs
    for path in sorted(EXPECTED_DIR.glob("*.txt")):
        scenario_id = path.stem
        labels = SCENARIO_LABELS
        scenarios.append(
            {
                "id": scenario_id,
                "label": labels.get(scenario_id, scenario_id.replace("_", " ").title()),
            }
        )
        outputs[scenario_id] = read_text(path)
    return scenarios, outputs


def build_payload() -> dict:
    languages = discover_languages()
    frameworks = discover_frameworks()
    scenarios, outputs = discover_scenarios()
    return {
        "meta": {
            "updated": datetime.datetime.now(datetime.timezone.utc).strftime(
                "%Y-%m-%d %H:%M UTC"
            ),
            "languageCount": len(languages),
            "frameworkCount": len(frameworks),
            "scenarioCount": len(scenarios),
            # The dashboard shows "<repository>/tree/<branch>/languages/<id>" above
            # each implementation, so the project it lives in travels with the data.
            "repository": repository_url(),
            "branch": repository_branch(),
        },
        "scenarios": scenarios,
        "outputs": outputs,
        "languages": languages,
        "frameworks": frameworks,
    }


def main() -> int:
    payload = build_payload()
    body = json.dumps(payload, indent=2, ensure_ascii=False)
    OUTPUT_FILE.write_text(
        "window.CONNECT_FOUR_DATA = " + body + ";\n", encoding="utf-8"
    )
    print(
        "Wrote %s (%d language(s), %d framework(s), %d scenario(s))"
        % (
            OUTPUT_FILE.name,
            payload["meta"]["languageCount"],
            payload["meta"]["frameworkCount"],
            payload["meta"]["scenarioCount"],
        )
    )
    if payload["meta"]["languageCount"] == 0:
        print(
            "warning: no implementations found under languages/",
            file=sys.stderr,
        )
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
