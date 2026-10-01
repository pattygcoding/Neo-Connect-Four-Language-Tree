#!/usr/bin/env python3
"""Generate the static showcase dashboard.

This script reads the *real* repository contents and writes
``dashboard-data.js`` next to ``index.html``:

  * every implementation in ``languages/<name>/connect_four.<ext>`` becomes
    a sidebar entry (source code included), and
  * the verified console captures in ``tests/expected/<scenario>.txt`` become
    the selectable "Console Output" views.

Because the data is emitted as a plain JavaScript object it can be loaded
with a ``<script>`` tag, so the dashboard works both on a static host and
straight from ``file://`` (no fetch/CORS problems).

Usage::

    python tools/generate_dashboard.py
"""

from __future__ import annotations

import datetime
import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
LANGUAGES_DIR = ROOT / "languages"
EXPECTED_DIR = ROOT / "tests" / "expected"
OUTPUT_FILE = ROOT / "dashboard-data.js"

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


def read_text(path: Path) -> str:
    """Read a text file and normalise its line endings to ``\\n``."""
    return path.read_text(encoding="utf-8").replace("\r\n", "\n").replace("\r", "\n")


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
    scenarios, outputs = discover_scenarios()
    return {
        "meta": {
            "generated": datetime.datetime.now(datetime.timezone.utc).strftime(
                "%Y-%m-%d %H:%M UTC"
            ),
            "languageCount": len(languages),
            "scenarioCount": len(scenarios),
        },
        "scenarios": scenarios,
        "outputs": outputs,
        "languages": languages,
    }


def main() -> int:
    payload = build_payload()
    body = json.dumps(payload, indent=2, ensure_ascii=False)
    OUTPUT_FILE.write_text(
        "window.CONNECT_FOUR_DATA = " + body + ";\n", encoding="utf-8"
    )
    print(
        "Wrote %s (%d language(s), %d scenario(s))"
        % (
            OUTPUT_FILE.name,
            payload["meta"]["languageCount"],
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
