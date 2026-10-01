#!/usr/bin/env python3
"""Generate the per-language README.md and banner.svg files.

Every ``languages/<id>/`` folder gets two generated files:

  * ``banner.svg`` - a self-contained hero banner in the same navy/mint palette
    as the showcase dashboard.  It names the language, its toolchain and the
    skills that implementation exercises, so each folder reads like a project
    card of its own.  No web fonts, no scripts, no external references, so it
    renders on GitHub, in an editor preview and offline.
  * ``README.md`` - what the implementation is, what it needs, and exactly how
    to build and play it.

Display names and categories come from ``tools/generate_dashboard.py`` (the
same metadata the dashboard uses), and the commands below mirror the
``LANGUAGES`` list in ``tests/run_tests.py``.  When that runner can be imported
the script cross-checks tool names, artifacts and source files and warns about
drift instead of failing, so the READMEs can be regenerated on a machine that
does not have every toolchain installed.

Usage::

    python tools/generate_language_readmes.py
"""

from __future__ import annotations

import importlib.util
import sys
import xml.sax.saxutils as sax
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
LANGUAGES_DIR = ROOT / "languages"
RUNNER = ROOT / "tests" / "run_tests.py"

sys.path.insert(0, str(ROOT / "tools"))
from generate_dashboard import discover_languages  # noqa: E402  (needs the path above)

# ---------------------------------------------------------------------------
# Palette: the dark-theme variables declared in index.html (`:root`), which in
# turn mirror the author's portfolio.  The banner is always the dark canvas.
# ---------------------------------------------------------------------------
CANVAS = "#05070c"      # ink-950
PANEL = "#0a0e15"       # ink-900
SLOT = "#0d1219"        # ink-850
LINE = "#1a2230"        # ink-700 hairline
LINE_SOFT = "#26303f"   # ink-600 chip stroke
FG = "#f2f5f3"          # fg-strong
SOFT = "#c3cad3"        # fg-soft
MUTED = "#8a93a0"       # fg-muted
MINT = "#8debc4"        # mint-400 / the accent in dark mode
MINT_EDGE = "#3d7c64"   # dimmed mint for chip borders
MINT_DEEP = "#12291f"   # mint-tinted chip fill

SANS = "Inter, 'Segoe UI', 'Helvetica Neue', Arial, sans-serif"
MONO = "'JetBrains Mono', 'SFMono-Regular', Consolas, 'Liberation Mono', monospace"

BANNER_W = 1200
BANNER_H = 250
BOARD_LEFT = 950
BOARD_TOP = 35
BOARD_STEP = 30
BOARD_RADIUS = 9
CHIP_H = 34
CHIP_PAD = 15
CHIP_GAP = 10
CHIP_TOP = 172
CHIP_TEXT_SIZE = 13
CHIP_LIMIT = BOARD_LEFT - 30


def esc(text: str) -> str:
    """Escape a string for use in XML text or an attribute value."""
    return sax.escape(text, {'"': "&quot;", "'": "&apos;"})


def text_width(text: str, size: float, ratio: float) -> float:
    """Rough width of `text` in px; a mono glyph is ~0.6em, a sans one ~0.55em.

    Only used to lay out chips and to keep the language name clear of the board
    motif, so an estimate is enough - and it keeps the banner independent of any
    font metrics library.
    """
    return len(text) * size * ratio


def chips_for(category: str, skills: list[str], limit: float) -> list[tuple[str, str]]:
    """Pick the chips that fit on one row: the category first, then skills."""
    picked: list[tuple[str, str]] = []
    used = 0.0
    for kind, label in [("category", category)] + [("skill", skill) for skill in skills]:
        width = CHIP_PAD * 2 + text_width(label, CHIP_TEXT_SIZE, 0.62)
        step = width + (CHIP_GAP if picked else 0)
        if used + step > limit:
            break
        used += step
        picked.append((kind, label))
    return picked


def board_motif() -> str:
    """A faint Connect Four board with a mint diagonal - the winning line."""
    win = {(5, 0), (4, 1), (3, 2), (2, 3)}
    parts = []
    for row in range(6):
        for col in range(7):
            cx = BOARD_LEFT + col * BOARD_STEP + BOARD_STEP // 2
            cy = BOARD_TOP + row * BOARD_STEP + BOARD_STEP // 2
            if (row, col) in win:
                fill, stroke, opacity = MINT, MINT, "0.95"
            else:
                fill, stroke, opacity = SLOT, LINE, "1"
            parts.append(
                '    <circle cx="%d" cy="%d" r="%d" fill="%s" stroke="%s" '
                'stroke-width="1.5" opacity="%s"/>'
                % (cx, cy, BOARD_RADIUS, fill, stroke, opacity)
            )
    return "\n".join(parts)


def chip_row(category: str, skills: list[str]) -> str:
    """The category chip followed by as many skill chips as fit neatly."""
    parts = []
    x = 56.0
    for kind, label in chips_for(category, skills, CHIP_LIMIT - 56):
        width = CHIP_PAD * 2 + text_width(label, CHIP_TEXT_SIZE, 0.62)
        fill, stroke, colour = (
            (MINT_DEEP, MINT_EDGE, MINT) if kind == "category" else (PANEL, LINE_SOFT, SOFT)
        )
        parts.append(
            '    <rect x="%.0f" y="%d" width="%.0f" height="%d" rx="%d" fill="%s" '
            'stroke="%s" stroke-width="1"/>'
            % (x, CHIP_TOP, width, CHIP_H, CHIP_H // 2, fill, stroke)
        )
        parts.append(
            '    <text x="%.0f" y="%d" font-family="%s" font-size="%d" fill="%s">%s</text>'
            % (x + CHIP_PAD, CHIP_TOP + 22, MONO, CHIP_TEXT_SIZE, colour, esc(label))
        )
        x += width + CHIP_GAP
    return "\n".join(parts)


def banner_svg(name: str, toolchain: str, category: str, skills: list[str]) -> str:
    """Render the hero banner: label, language name, toolchain and skill chips."""
    return "\n".join(
        [
            '<svg xmlns="http://www.w3.org/2000/svg" width="%d" height="%d" '
            'viewBox="0 0 %d %d" role="img" aria-label="%s - Connect Four">'
            % (BANNER_W, BANNER_H, BANNER_W, BANNER_H, esc(name)),
            "    <title>%s - Connect Four</title>" % esc(name),
            '    <rect width="%d" height="%d" rx="18" fill="%s"/>' % (BANNER_W, BANNER_H, CANVAS),
            '    <rect x="0.5" y="0.5" width="%d" height="%d" rx="17.5" fill="none" '
            'stroke="%s" stroke-width="1"/>' % (BANNER_W - 1, BANNER_H - 1, LINE),
            board_motif(),
            '    <text x="56" y="54" font-family="%s" font-size="13" letter-spacing="2.5" '
            'fill="%s">CONNECT FOUR &#183; LANGUAGE TREE</text>' % (MONO, MINT),
            '    <text x="56" y="110" font-family="%s" font-size="46" font-weight="700" '
            'fill="%s">%s</text>' % (SANS, FG, esc(name)),
            '    <rect x="56" y="126" width="56" height="3" rx="1.5" fill="%s"/>' % MINT,
            '    <text x="56" y="152" font-family="%s" font-size="14" fill="%s">%s</text>'
            % (MONO, MUTED, esc(toolchain)),
            chip_row(category, skills),
            "</svg>",
            "",
        ]
    )


def exe_note(run: list[str]) -> str:
    """The Windows note for languages whose artifact is a native binary."""
    artifact = run[0] if run else ""
    if artifact.startswith("./"):
        artifact = artifact[2:]
    return (
        "On Windows the built program is `%s.exe`; on other platforms the `.exe` "
        "suffix is dropped." % artifact
    )


def bullet_list(items: list[str]) -> list[str]:
    """Markdown bullets, or nothing at all when there is nothing to list."""
    return ["* %s" % item for item in items] if items else []


def readme_md(lang: dict, info: dict, total: int) -> str:
    """Render one language's README from its curated facts and the runner data."""
    name = lang["name"]
    source = lang["file"]
    folder = "languages/%s" % lang["id"]
    build = list(info.get("build") or [])
    run = list(info.get("run") or [])
    notes = list(info.get("notes") or [])
    if info.get("binary") and run:
        notes.insert(0, exe_note(run))
    if info.get("solo_file", True):
        files = "`%s` is the only file this implementation needs." % source
    else:
        files = "Everything this implementation needs lives in `%s/`." % folder

    lines = [
        '<img src="banner.svg" alt="%s - Connect Four banner" width="100%%">' % esc(name),
        "",
        "# %s Implementation" % name,
        "",
        "%s - one of %d implementations of the same console protocol in the" % (info["tagline"], total),
        "[Neo-Connect-Four-Language-Tree](../../README.md) repository. Every",
        "implementation reads the same stdin and prints byte-for-byte identical",
        "output, so a single master test verifies them all at once.",
        "",
        "## Prerequisites",
        "",
        "* **Toolchain:** %s" % info["toolchain"],
        "* **Check it is installed:** `%s`" % info["detect"],
        "",
        "| Platform | Install command |",
        "| --- | --- |",
    ]
    lines += [
        "| %s | `%s` |" % (platform, command)
        for platform, command in info["install"].items()
    ]
    lines += [
        "",
        "## How to run",
        "",
        "Build this implementation and replay every scenario (from the repository",
        "root):",
        "",
        "```sh",
        "python tests/run_tests.py",
        "```",
    ]
    if build or run:
        verb = "Build and play it on its own" if build else "Play it on its own"
        lines += ["", "%s:" % verb, "", "```sh"] + build + run + ["```"]
    if notes:
        lines += ["", "### Notes", ""] + bullet_list(notes)
    lines += ["", "## Skills demonstrated", ""] + bullet_list(info["skills"])
    lines += [
        "",
        "## Verified output",
        "",
        "The runner replays the eight scripted sessions in",
        "[`tests/inputs/`](../../tests/inputs) and compares stdout with the goldens in",
        "[`tests/expected/`](../../tests/expected) byte for byte. It then checks that",
        "the prompt appears before each read while stdin is still open, which is what",
        "separates an interactive program from one that swallows its input up front.",
        files,
        "",
        "## Protocol",
        "",
        "[`README.md`](../../README.md#console-protocol) documents the console",
        "protocol exactly, and [`tests/run_tests.py`](../../tests/run_tests.py) holds",
        "the build and run commands the suite uses for every language. The showcase",
        "dashboard shows this implementation at `index.html?lang=%s`." % lang["id"],
        "",
        "This README and its banner are generated by",
        "[`tools/generate_language_readmes.py`](../../tools/generate_language_readmes.py),",
        "which reads the runner's own metadata - so re-run that script rather than",
        "editing them by hand.",
        "",
    ]
    return "\n".join(lines)


# ---------------------------------------------------------------------------
# Per-language facts.
#
#   tagline    one clause describing how the implementation is written
#   toolchain  what it is built with (banner + prerequisites)
#   detect     a command that tells you whether the toolchain is present
#   install    one install command per platform
#   build/run  the portable commands the README documents, run from the
#              repository root (the `.exe` suffix is added by the note that
#              `binary: True` generates)
#   skills     the chips on the banner and the list in the README
#   notes      the wrinkles worth knowing before you run it
#
# These mirror the `LANGUAGES` list in tests/run_tests.py; main() warns when a
# tool name, artifact or source file no longer matches the runner.
# ---------------------------------------------------------------------------
INFO = {
    "ada": {
        "tagline": "Strong typing, unbounded-string line input and checked numeric conversion",
        "toolchain": "gnatmake (GNAT, Ada 2012 or newer)",
        "detect": "gnatmake --version",
        "install": {
            "Windows": "pacman -S mingw-w64-x86_64-gcc-ada (MSYS2)",
            "macOS": "brew install gnat",
            "Debian/Ubuntu": "apt-get install gnat",
        },
        "build": ["gnatmake -O2 -D tests/build/ada -o tests/build/connect_four_ada languages/ada/connect_four.adb"],
        "run": ["./tests/build/connect_four_ada"],
        "binary": True,
        "skills": ["Strong typing", "Unbounded_IO line input", "Checked, saturating parse"],
        "notes": [
            "GNAT comes from MSYS2's `mingw-w64-x86_64-gcc-ada` package, which installs into `C:\\msys64\\mingw64\\bin` - not on the default `PATH`. The runner adds it, and creates `tests/build/ada` because `gnatmake -D` will not create that directory itself.",
            "Input goes through `Ada.Text_IO.Unbounded_IO`, so a line can be any length and the CR of a CRLF pair is dropped; each prompt is flushed before the read, because Ada buffers `Standard_Output` when it is not a terminal.",
        ],
    },
    "assembly": {
        "tagline": "Win64 x86-64 assembly in GNU `as` syntax, on the Microsoft x64 ABI",
        "toolchain": "gcc (the x86-64 MinGW-w64 one, which assembles and links in one step)",
        "detect": "gcc --version",
        "install": {
            "Windows": "winget install BrechtSanders.WinLibs.POSIX.UCRT (or MSYS2: pacman -S mingw-w64-ucrt-x86_64-gcc)",
            "macOS": "xcode-select --install",
            "Debian/Ubuntu": "apt-get install build-essential",
        },
        "build": ["gcc -o tests/build/connect_four_asm languages/assembly/connect_four.s"],
        "run": ["./tests/build/connect_four_asm"],
        "binary": True,
        "skills": ["x86-64 assembly", "Microsoft x64 ABI", "Shadow space + stack alignment"],
        "notes": [
            "Use the x86-64 MinGW-w64 `gcc`, not the 32-bit one GnuCOBOL ships; the runner selects that toolchain with `mingw64_env()`. Every call reserves 32 bytes of shadow space and keeps `rsp` 16-byte aligned.",
        ],
    },
    "bash": {
        "tagline": "Pure bash: builtins only, a flat array board and command substitution for the pure helpers",
        "toolchain": "bash 4 or newer",
        "detect": "bash --version",
        "install": {
            "Windows": "Git for Windows or MSYS2 (neither puts `bash` on `PATH`)",
            "macOS": "brew install bash",
            "Debian/Ubuntu": "apt-get install bash",
        },
        "build": [],
        "run": ["bash --noprofile --norc languages/bash/connect_four.sh"],
        "skills": ["Bash builtins", "Flat global board array", "Saturating $(( )) arithmetic"],
        "notes": [
            "Windows ships no bash and neither Git for Windows nor MSYS2 adds it to `PATH`, so the runner looks for `C:\\Program Files\\Git\\bin\\bash.exe`, then its `usr\\bin`, then `C:\\msys64\\usr\\bin\\bash.exe`.",
            "Bash functions cannot return strings and capturing a prompt-printing function would swallow its output, so `ask_column` prints through and hands its answer back in the global `$CHOSEN_COLUMN`; only the pure helpers are captured with `$(...)`.",
        ],
    },
    "c": {
        "tagline": "Straight C11 with direct stdio output",
        "toolchain": "gcc (C11; any C11 compiler will do)",
        "detect": "gcc --version",
        "install": {
            "Windows": "winget install BrechtSanders.WinLibs.POSIX.UCRT (or MSYS2: pacman -S mingw-w64-ucrt-x86_64-gcc)",
            "macOS": "xcode-select --install",
            "Debian/Ubuntu": "apt-get install build-essential",
        },
        "build": ["gcc -std=c11 -O2 -o tests/build/connect_four_c languages/c/connect_four.c"],
        "run": ["./tests/build/connect_four_c"],
        "binary": True,
        "skills": ["C11", "stdio + ctype.h", "Row-major char board"],
        "notes": [],
    },
    "clojure": {
        "tagline": "Clojure with immutable vectors for the board and recursion for the game loop",
        "toolchain": "clojure (the official CLI, which needs a JVM)",
        "detect": "clojure --version",
        "install": {
            "Windows": "scoop install clojure",
            "macOS": "brew install clojure",
            "Debian/Ubuntu": "apt-get install clojure",
        },
        "build": [],
        "run": ["clojure -M languages/clojure/connect_four.clj"],
        "skills": ["Immutable vectors", "clojure.string", "Recursive game loop"],
        "notes": [
            "The runner starts it from `tests/build` so the CLI's dependency caches (`.cpcache`) land there instead of the repository root.",
        ],
    },
    "cobol": {
        "tagline": "A COBOL-85 style program built from picture clauses, fixed-length fields and its own trim",
        "toolchain": "cobc (GnuCOBOL 3 or newer, with a C compiler underneath)",
        "detect": "cobc --version",
        "install": {
            "Windows": "choco install gnucobol",
            "macOS": "brew install gnu-cobol",
            "Debian/Ubuntu": "apt-get install gnucobol",
        },
        "build": ["cobc -x -free -o tests/build/connect_four_cobol languages/cobol/connect_four.cob"],
        "run": ["./tests/build/connect_four_cobol"],
        "binary": True,
        "skills": ["PIC X picture clauses", "OCCURS fixed arrays", "Hand-rolled string trim"],
        "notes": [
            "The Windows package ships its own, older MinGW. That toolchain's `bin` has to come first on `PATH` (with `COB_CONFIG_DIR`, `COB_CFLAGS`, `COB_LDFLAGS` and `COB_LIBRARY_PATH` set) or GnuCOBOL's C backend fails against a different `gcc`; the runner does all of that in `gnucobol_env()`.",
        ],
    },
    "cpp": {
        "tagline": "C++17 with std::string rendering and plain index loops",
        "toolchain": "g++ (C++17; any C++17 compiler will do)",
        "detect": "g++ --version",
        "install": {
            "Windows": "winget install BrechtSanders.WinLibs.POSIX.UCRT (or MSYS2: pacman -S mingw-w64-ucrt-x86_64-gcc)",
            "macOS": "xcode-select --install",
            "Debian/Ubuntu": "apt-get install build-essential",
        },
        "build": ["g++ -std=c++17 -O2 -o tests/build/connect_four_cpp languages/cpp/connect_four.cpp"],
        "run": ["./tests/build/connect_four_cpp"],
        "binary": True,
        "skills": ["C++17 constexpr", "std::string + iostream", "Precomputed border and labels"],
        "notes": [],
    },
    "csharp": {
        "tagline": ".NET 8 console app with StreamReader line input",
        "toolchain": "dotnet (.NET 8 SDK)",
        "detect": "dotnet --version",
        "install": {
            "Windows": "winget install Microsoft.DotNet.SDK.8",
            "macOS": "brew install dotnet-sdk",
            "Debian/Ubuntu": "apt-get install dotnet-sdk-8.0",
        },
        "build": ["dotnet build languages/csharp/ConnectFour.csproj -c Release -o tests/build/csharp --nologo -v quiet"],
        "run": ["dotnet tests/build/csharp/connect_four.dll"],
        "solo_file": False,
        "skills": [".NET 8", "StreamReader + Console.Out", "StringBuilder rendering"],
        "notes": [
            "`ConnectFour.csproj` next to the source is the project file; the runner sets `DOTNET_NOLOGO` and the telemetry opt-outs so the build log stays quiet.",
            "Avoid `dotnet run`, which recompiles on every launch - the built `.dll` starts in well under 0.1s.",
        ],
    },
    "dart": {
        "tagline": "Dart 3, AOT-compiled into a standalone executable",
        "toolchain": "dart (SDK 3 or newer)",
        "detect": "dart --version",
        "install": {
            "Windows": "choco install dart-sdk (or scoop install dart)",
            "macOS": "brew install dart",
            "Debian/Ubuntu": "apt-get install dart",
        },
        "build": ["dart compile exe -o tests/build/connect_four_dart languages/dart/connect_four.dart"],
        "run": ["./tests/build/connect_four_dart"],
        "binary": True,
        "skills": ["dart:io stdin", "Nested List<String> board", "AOT compilation"],
        "notes": [
            "The suite runs an AOT binary rather than `dart run`, which would re-resolve the package on every launch. `readLineSync()` strips a trailing CR and returns `null` at end of input.",
        ],
    },
    "elixir": {
        "tagline": "Elixir with module attributes and a tail-recursive game loop",
        "toolchain": "elixir (1.15 or newer, with Erlang/OTP)",
        "detect": "elixir --version",
        "install": {
            "Windows": "choco install elixir (or scoop install elixir)",
            "macOS": "brew install elixir",
            "Debian/Ubuntu": "apt-get install elixir",
        },
        "build": [],
        "run": ["elixir languages/elixir/connect_four.ex"],
        "skills": ["Module attributes", "IO.write", "Tail-recursive loop"],
        "notes": [],
    },
    "elm": {
        "tagline": "Elm as a Platform.worker, driven by a small JavaScript host over ports",
        "toolchain": "elm 0.19 + node (Elm cannot read stdin on its own)",
        "detect": "elm --version && node --version",
        "install": {
            "Windows": "scoop install elm, plus winget install OpenJS.NodeJS",
            "macOS": "brew install elm node",
            "Debian/Ubuntu": "apt-get install elm nodejs",
        },
        "build": ["cd tests/build/elm", "elm make src/ConnectFour.elm --optimize --output=connect_four.js"],
        "run": ["node host.js"],
        "solo_file": False,
        "skills": ["Platform.worker + ports", "Generated JS host bridge", "Maybe for EOF"],
        "notes": [
            "A console Elm program has to be a `Platform.worker` with ports, so the runner's `_elm_project()` assembles a throwaway project in `tests/build/elm/` first: it writes `elm.json` and `host.js` and copies the module in as `src/ConnectFour.elm`. Run the suite once and the commands above work.",
            "`--optimize` is not only for speed - it also suppresses the runtime's dev-mode notice, which would otherwise land on stderr and break the byte-for-byte comparison.",
        ],
    },
    "erlang": {
        "tagline": "Erlang with pattern-matched lists and an OTP-style main/0 entry point",
        "toolchain": "erlc + erl (Erlang/OTP 26 or newer)",
        "detect": "erl -noshell -eval \"halt().\"",
        "install": {
            "Windows": "winget install Erlang.ErlangOTP",
            "macOS": "brew install erlang",
            "Debian/Ubuntu": "apt-get install erlang",
        },
        "build": ["erlc -o tests/build languages/erlang/connect_four.erl"],
        "run": ["erl -noshell -pa tests/build -s connect_four main -s init stop"],
        "skills": ["erlc + -s main", "io:format", "Pattern-matched lists"],
        "notes": [],
    },
    "fortran": {
        "tagline": "Fortran with a character board and a hand-written whitespace trim",
        "toolchain": "gfortran (Fortran 2008 or newer)",
        "detect": "gfortran --version",
        "install": {
            "Windows": "winget install BrechtSanders.WinLibs.POSIX.UCRT (or MSYS2: pacman -S mingw-w64-ucrt-x86_64-gcc-fortran)",
            "macOS": "brew install gcc",
            "Debian/Ubuntu": "apt-get install gfortran",
        },
        "build": ["gfortran -O2 -o tests/build/connect_four_fortran languages/fortran/connect_four.f90"],
        "run": ["./tests/build/connect_four_fortran"],
        "binary": True,
        "skills": ["character(len=1) board", "implicit none", "Hand-written trim"],
        "notes": [
            "It needs the x86-64 MinGW-w64 toolchain, which the runner selects with `mingw64_env()` - GnuCOBOL's 32-bit MinGW will not do.",
            "The token is trimmed by a hand-written function covering the same whitespace set as C's `isspace`, rather than `adjustl`/`trim` alone, because the program works wholly on fixed-length `character` values.",
        ],
    },
    "fsharp": {
        "tagline": "F# with array-based state, StringBuilder rendering and pattern matching",
        "toolchain": "dotnet (.NET 8 SDK)",
        "detect": "dotnet --version",
        "install": {
            "Windows": "winget install Microsoft.DotNet.SDK.8",
            "macOS": "brew install dotnet-sdk",
            "Debian/Ubuntu": "apt-get install dotnet-sdk-8.0",
        },
        "build": ["dotnet build languages/fsharp/ConnectFour.fsproj -c Release -o tests/build/fsharp --nologo -v quiet"],
        "run": ["dotnet tests/build/fsharp/connect_four_fs.dll"],
        "solo_file": False,
        "skills": ["F# arrays + StringBuilder", ".NET console I/O", "Pattern matching"],
        "notes": [
            "`ConnectFour.fsproj` next to the source is the project file; the generated `.dll` starts far faster than `dotnet run`, which recompiles first.",
        ],
    },
    "go": {
        "tagline": "Go with a bufio.Scanner and strconv for the whole line protocol",
        "toolchain": "go (1.21 or newer)",
        "detect": "go version",
        "install": {
            "Windows": "winget install GoLang.Go",
            "macOS": "brew install go",
            "Debian/Ubuntu": "apt-get install golang-go",
        },
        "build": ["go build -o tests/build/connect_four_go languages/go/connect_four.go"],
        "run": ["./tests/build/connect_four_go"],
        "binary": True,
        "skills": ["bufio.Scanner", "strconv.ParseInt", "strings.TrimSpace"],
        "notes": [],
    },
    "haskell": {
        "tagline": "Haskell with a pure board renderer and a small IO loop",
        "toolchain": "ghc (9.4 or newer; only the base package is used)",
        "detect": "ghc --version",
        "install": {
            "Windows": "choco install ghc (or scoop install ghc)",
            "macOS": "brew install ghc",
            "Debian/Ubuntu": "apt-get install ghc",
        },
        "build": ["ghc -O2 -outputdir tests/build/haskell -o tests/build/connect_four_haskell languages/haskell/connect_four.hs"],
        "run": ["./tests/build/connect_four_haskell"],
        "binary": True,
        "skills": ["NoBuffering stdout", "isEOFError for EOF", "Pure render, thin IO loop"],
        "notes": [
            "`-outputdir tests/build/haskell` keeps the `.hi` and `.o` files out of the source directory, and because only `base` is used there is no cabal or stack project to set up.",
            "`stdout` is switched to `NoBuffering` so every prompt is visible before the read; end of input is detected with `isEOFError` from the caught `getLine`.",
        ],
    },
    "java": {
        "tagline": "Java with a BufferedReader and static, precomputed board text",
        "toolchain": "JDK 17 or newer (javac + java)",
        "detect": "java -version",
        "install": {
            "Windows": "winget install Microsoft.OpenJDK.21",
            "macOS": "brew install openjdk",
            "Debian/Ubuntu": "apt-get install default-jdk",
        },
        "build": ["javac -d tests/build/java languages/java/connect_four.java"],
        "run": ["java -cp tests/build/java connect_four"],
        "skills": ["BufferedReader/InputStreamReader", "System.out.flush", "Static final helpers"],
        "notes": [],
    },
    "javascript": {
        "tagline": "Node.js with the readline module reading line by line",
        "toolchain": "node 18 or newer",
        "detect": "node --version",
        "install": {
            "Windows": "winget install OpenJS.NodeJS",
            "macOS": "brew install node",
            "Debian/Ubuntu": "apt-get install nodejs",
        },
        "build": [],
        "run": ["node languages/javascript/connect_four.js"],
        "skills": ["readline on process.stdin", "String.repeat rendering", "Input 'close' handling"],
        "notes": [],
    },
    "julia": {
        "tagline": "Julia with a Matrix{Char} board and 1-based indexing straight from the input",
        "toolchain": "julia 1.9 or newer",
        "detect": "julia --version",
        "install": {
            "Windows": "scoop install julia",
            "macOS": "brew install julia",
            "Debian/Ubuntu": "apt-get install julia",
        },
        "build": [],
        "run": ["julia --startup-file=no --color=no languages/julia/connect_four.jl"],
        "skills": ["Matrix{Char} board", "1-based indexing", "flush(stdout) prompts"],
        "notes": [
            "`--startup-file=no --color=no` keeps startup fast and stderr clean.",
            "`print` needs an explicit `flush(stdout)` before each read, and end of input is detected with `eof(stdin)` *before* calling `readline()` - that function returns `\"\"` both at EOF and for an empty line.",
        ],
    },
    "kotlin": {
        "tagline": "Kotlin/JVM compiled into a self-contained runnable jar",
        "toolchain": "kotlinc plus a JVM (JDK 17 or newer)",
        "detect": "kotlinc -version",
        "install": {
            "Windows": "scoop install kotlin",
            "macOS": "brew install kotlin",
            "Debian/Ubuntu": "apt-get install kotlin",
        },
        "build": ["kotlinc languages/kotlin/connect_four.kt -include-runtime -d tests/build/connect_four_kotlin.jar"],
        "run": ["java -jar tests/build/connect_four_kotlin.jar"],
        "skills": ["Kotlin/JVM + java.io", "StringBuilder rendering", "charArrayOf players"],
        "notes": [],
    },
    "lisp": {
        "tagline": "Common Lisp run as a SBCL script, with a character bag for trimming",
        "toolchain": "sbcl (SBCL 2.2 or newer)",
        "detect": "sbcl --version",
        "install": {
            "Windows": "scoop install sbcl",
            "macOS": "brew install sbcl",
            "Debian/Ubuntu": "apt-get install sbcl",
        },
        "build": [],
        "run": ["sbcl --script languages/lisp/connect_four.lisp"],
        "skills": ["SBCL --script, no REPL noise", "code-char whitespace bag", "nil eof-value for read-line"],
        "notes": [
            "Scoop's SBCL needs `SBCL_HOME` to find `sbcl.core`; the runner supplies it in `lisp_env()`.",
            "`read-line` is called with an explicit `nil` eof value and keeps the CR of a CRLF pair, so the trim covers the same six characters C's `isspace` does.",
        ],
    },
    "lua": {
        "tagline": "Plain Lua 5.4 with a nested table board",
        "toolchain": "lua 5.4 (5.3 also works)",
        "detect": "lua -v",
        "install": {
            "Windows": "winget install DEVCOM.Lua",
            "macOS": "brew install lua",
            "Debian/Ubuntu": "apt-get install lua5.4",
        },
        "build": [],
        "run": ["lua languages/lua/connect_four.lua"],
        "skills": ["Nested table board", "string.rep + table.concat", "Explicit stdout flush"],
        "notes": [],
    },
    "nim": {
        "tagline": "Nim compiled through its C backend, with checked arithmetic",
        "toolchain": "nim (2.0 or newer) plus a C compiler for its backend",
        "detect": "nim --version",
        "install": {
            "Windows": "choco install nim (or scoop install nim)",
            "macOS": "brew install nim",
            "Debian/Ubuntu": "apt-get install nim",
        },
        "build": ["nim c --hints:off --warnings:off -d:release --nimcache:tests/build/nimcache -o:tests/build/connect_four_nim languages/nim/connect_four.nim"],
        "run": ["./tests/build/connect_four_nim"],
        "binary": True,
        "skills": ["std/strutils", "Nim C backend", "Checked arithmetic"],
        "notes": [
            "Nim compiles through a C compiler, so it needs the same x86-64 MinGW-w64 `gcc` the C implementation uses; the runner selects it with `mingw64_env()`.",
            "`--nimcache:tests/build/nimcache` keeps Nim's generated C out of the source directory.",
        ],
    },
    "objectivec": {
        "tagline": "Objective-C messaging a small root class on the GNUstep runtime",
        "toolchain": "clang with the GNUstep libobjc2 runtime and its headers",
        "detect": "clang --version",
        "install": {
            "Windows": "pacman -S mingw-w64-clang-x86_64-clang mingw-w64-clang-x86_64-libobjc2 (MSYS2 clang64)",
            "macOS": "xcode-select --install",
            "Debian/Ubuntu": "apt-get install clang libobjc2-dev",
        },
        "build": ["clang -fobjc-runtime=gnustep-2.0 -O2 -o tests/build/connect_four_objc languages/objectivec/connect_four.m -lobjc"],
        "run": ["./tests/build/connect_four_objc"],
        "binary": True,
        "skills": ["GNUstep libobjc2", "objc/message.h", "Root class with an isa ivar"],
        "notes": [
            "On Windows this uses MSYS2's clang64 environment, because Windows has no first-party Objective-C runtime. That `bin` directory has to be on `PATH` for the build *and* the run, since libobjc2 ships as `libobjc-4.6.dll`; the runner handles it with `msys2_clang_env()`.",
            "A root class must declare the `isa` ivar and carry `__attribute__((objc_root_class))`; without the ivar, clang computes an instance size that leaves out the isa pointer and every message send returns nil.",
        ],
    },
    "ocaml": {
        "tagline": "OCaml with array-of-array state and a recursive column scan",
        "toolchain": "OCaml 5 (ocamlopt), usually through opam",
        "detect": "ocamlopt -version",
        "install": {
            "Windows": "winget install OCaml.opam, then opam init and opam switch create",
            "macOS": "brew install opam",
            "Debian/Ubuntu": "apt-get install opam",
        },
        "build": ["opam exec -- ocamlopt -o tests/build/connect_four_ocaml languages/ocaml/connect_four.ml"],
        "run": ["./tests/build/connect_four_ocaml"],
        "binary": True,
        "skills": ["Array.init board", "Recursive scan helpers", "opam exec for the switch"],
        "notes": [
            "`opam exec -- ocamlopt` works without sourcing the switch environment first, because an opam switch is self-contained.",
            "`ocamlopt` has no output directory option and drops `connect_four.cmi`/`.cmx`/`.o` next to the source - those extensions are in `.gitignore`.",
        ],
    },
    "pascal": {
        "tagline": "Free Pascal in OBJFPC mode, with explicit short-circuit-free trim loops",
        "toolchain": "fpc (Free Pascal 3.2.2 or newer)",
        "detect": "fpc -iV",
        "install": {
            "Windows": "scoop install freepascal",
            "macOS": "brew install fpc",
            "Debian/Ubuntu": "apt-get install fpc",
        },
        "build": ["fpc -O2 -FUtests/build/pascal -FEtests/build/pascal languages/pascal/connect_four.pas"],
        "run": ["./tests/build/pascal/connect_four"],
        "binary": True,
        "skills": ["{$MODE OBJFPC}", "Complete-evaluation-safe loops", "Flush(Output) prompts"],
        "notes": [
            "Scoop's Free Pascal is the i386 build, which is fine - the 32-bit executable runs on x64 Windows.",
            "`fpc` will not create its `-FU`/`-FE` directories, so the runner makes `tests/build/pascal` first; without that the compiler stops with an error rather than creating the path.",
            "`and then` is not available in OBJFPC mode and `and` evaluates both sides, so the trim loops break out explicitly instead of indexing past the end of an empty string.",
        ],
    },
    "perl": {
        "tagline": "Perl 5 with autoflush enabled and hand-rolled trims",
        "toolchain": "perl 5.30 or newer (core modules only)",
        "detect": "perl -v",
        "install": {
            "Windows": "winget install StrawberryPerl.StrawberryPerl (or scoop install perl)",
            "macOS": "brew install perl",
            "Debian/Ubuntu": "apt-get install perl",
        },
        "build": [],
        "run": ["perl languages/perl/connect_four.pl"],
        "skills": ["Perl 5 core only", "$|=1 autoflush", "Sub-based board state"],
        "notes": [],
    },
    "php": {
        "tagline": "PHP 8 reading STDIN with fgets and flushing after every prompt",
        "toolchain": "php 8 (the CLI, no extensions beyond the default build)",
        "detect": "php --version",
        "install": {
            "Windows": "winget install PHP.PHP.8.3 (or unpack the official zip)",
            "macOS": "brew install php",
            "Debian/Ubuntu": "apt-get install php-cli",
        },
        "build": [],
        "run": ["php languages/php/connect_four.php"],
        "skills": ["PHP 8 CLI", "fgets(STDIN)", "Explicit flush after prompts"],
        "notes": [
            "The blank-cell constant is called `EMPTY_CELL`, because `EMPTY` is a reserved construct in PHP (`empty()`).",
            "The Windows binaries are plain archives or an install package; the runner's `php_env()` only prepends a PHP directory to `PATH` when one is not already there.",
        ],
    },
    "powershell": {
        "tagline": "Windows PowerShell with a flat 42-cell array board",
        "toolchain": "Windows PowerShell 5.1 (built in) or PowerShell 7+",
        "detect": "powershell -Command '$PSVersionTable.PSVersion'",
        "install": {
            "Windows": "built in with Windows; choco install powershell-core for PowerShell 7",
            "macOS": "brew install --cask powershell",
            "Debian/Ubuntu": "apt-get install powershell",
        },
        "build": [],
        "run": ["powershell -NoProfile -ExecutionPolicy Bypass -File languages/powershell/connect_four.ps1"],
        "skills": ["Flat 42-cell board array", "-ceq/-cne string compares", "[long]::MaxValue saturating parse"],
        "notes": [
            "The board is a flat 42-cell array, which sidesteps PowerShell's array unrolling when a function returns a nested array.",
            "Variable names are case-insensitive, so a loop-local `$row`/`$column` inside a function whose parameters are `-Row`/`-Column` is the *same* variable and overwrites the parameter; the locals are named `$targetRow`/`$targetColumn` instead. `-eq`/`-ne` are case-insensitive for strings too, so the board comparisons use `-ceq`/`-cne`.",
            "Output goes through `[Console]::Out.Write` rather than `Write-Output`/`Write-Host`, so the newline-free prompt reaches the pipe before the read.",
        ],
    },
    "prolog": {
        "tagline": "SWI-Prolog with a list-of-lists board and maplist helpers",
        "toolchain": "swipl (SWI-Prolog 9)",
        "detect": "swipl --version",
        "install": {
            "Windows": "winget install SWI-Prolog.SWI-Prolog",
            "macOS": "brew install swi-prolog",
            "Debian/Ubuntu": "apt-get install swi-prolog",
        },
        "build": [],
        "run": ["swipl -q -g main -t halt languages/prolog/connect_four.pro"],
        "skills": ["List-of-lists board", "maplist + length constraints", "-g main -t halt entry point"],
        "notes": [
            "The Windows installer does not always put `swipl` on `PATH`; append its `bin` directory (for example `C:\\Program Files\\swipl\\bin`) to the user `PATH` if it is missing.",
        ],
    },
    "python": {
        "tagline": "Python 3 with sys.stdin read line by line",
        "toolchain": "python 3.8 or newer (standard library only)",
        "detect": "python3 --version (on Windows: python --version)",
        "install": {
            "Windows": "winget install Python.Python.3.12",
            "macOS": "brew install python",
            "Debian/Ubuntu": "apt-get install python3",
        },
        "build": [],
        "run": ["python languages/python/connect_four.py"],
        "skills": ["Python 3 stdlib", "sys.stdin.readline()", "Explicit flush after prompts"],
        "notes": [
            "On macOS and Linux the interpreter is normally `python3`, on Windows `python` (or the `py` launcher); the suite simply reuses the interpreter that is running it.",
        ],
    },
    "r": {
        "tagline": "R with a 1-based matrix board and a single stdin connection",
        "toolchain": "Rscript (R 4.2 or newer)",
        "detect": "Rscript --version",
        "install": {
            "Windows": "scoop install r",
            "macOS": "brew install r",
            "Debian/Ubuntu": "apt-get install r-base",
        },
        "build": [],
        "run": ["Rscript --vanilla languages/r/connect_four.R"],
        "skills": ["matrix() board, 1-based", "One stdin connection", "[[:space:]] trim"],
        "notes": [
            "Reading stdin incrementally in a script needs a connection opened once at the top (`input_stream <- file(\"stdin\", \"r\")`) and then `readLines(input_stream, n = 1)`; `readLines(\"stdin\", n = 1)`, `scan(\"stdin\", ...)` and `stdin()` each reopen the pseudo-file and report EOF on the second call, while `readline()` does not read piped stdin under `Rscript` at all.",
            "`--vanilla` keeps site and user profiles, and any saved workspace, out of the run; `character(0)` is the end-of-input signal, which is how EOF is told apart from an empty line.",
        ],
    },
    "ruby": {
        "tagline": "Ruby with nested arrays, sync'd stdout and a small method set",
        "toolchain": "ruby 3.0 or newer",
        "detect": "ruby --version",
        "install": {
            "Windows": "winget install RubyInstallerTeam.Ruby.3.3",
            "macOS": "brew install ruby",
            "Debian/Ubuntu": "apt-get install ruby",
        },
        "build": [],
        "run": ["ruby languages/ruby/connect_four.rb"],
        "skills": ["Array of arrays board", "$stdout.sync for prompts", "Frozen string constants"],
        "notes": [],
    },
    "rust": {
        "tagline": "Rust with no external crates, using std::io::BufRead",
        "toolchain": "rustc (a recent stable toolchain; cargo is not needed)",
        "detect": "rustc --version",
        "install": {
            "Windows": "winget install Rustlang.Rustup",
            "macOS": "brew install rust",
            "Debian/Ubuntu": "apt-get install rustc",
        },
        "build": ["rustc -O -o tests/build/connect_four_rust languages/rust/connect_four.rs"],
        "run": ["./tests/build/connect_four_rust"],
        "binary": True,
        "skills": ["std::io::BufRead", "Saturating i64 parse", "No external crates"],
        "notes": [],
    },
    "scala": {
        "tagline": "Scala 3 run straight from source by the Scala CLI",
        "toolchain": "scala (the Scala CLI, which needs a JVM)",
        "detect": "scala -version",
        "install": {
            "Windows": "scoop install scala",
            "macOS": "brew install scala",
            "Debian/Ubuntu": "apt-get install scala",
        },
        "build": [],
        "run": ["scala languages/scala/connect_four.scala"],
        "skills": ["scala.io.StdIn", "Console.flush prompts", "Array-based board"],
        "notes": [
            "The runner starts it from `tests/build`, so the CLI's `.scala-build` and `.bsp` directories land there instead of the repository root (both are git-ignored, so running it from the root is harmless too).",
        ],
    },
    "swift": {
        "tagline": "Swift on Windows, using the ucrt module for C-style stdin/stdout",
        "toolchain": "swiftc (Swift toolchain for Windows 6.x, or Xcode's on macOS)",
        "detect": "swiftc --version",
        "install": {
            "Windows": "winget install Swift.Toolchain (needs Visual Studio 2022 and a current Windows SDK)",
            "macOS": "xcode-select --install",
            "Debian/Ubuntu": "the swift.org toolchain for your distribution",
        },
        "build": ["swiftc -O -o tests/build/connect_four_swift languages/swift/connect_four.swift"],
        "run": ["./tests/build/connect_four_swift"],
        "binary": True,
        "skills": ["Swift on Windows", "ucrt stdin/stdout", "Character/Array board"],
        "notes": [
            "`swiftc` needs three things the runner's `swift_env()` supplies on Windows: `SDKROOT` pointing at the toolchain's own `Windows.sdk`, the MSVC environment captured from `vcvars64.bat` (for C headers and link libraries), and the Swift runtime directory on `PATH` when the built program runs.",
            "The Swift 6.4 SDK module maps expect a current Windows SDK; on an older one the build fails on a missing C header until Visual Studio 2022 Build Tools with the C++ workload is installed.",
        ],
    },
    "typescript": {
        "tagline": "TypeScript compiled by tsc to CommonJS and run on node",
        "toolchain": "tsc (TypeScript 5) plus node 18+",
        "detect": "tsc --version",
        "install": {
            "Windows": "npm install -g typescript (with winget install OpenJS.NodeJS)",
            "macOS": "brew install typescript (or npm install -g typescript)",
            "Debian/Ubuntu": "apt-get install node-typescript nodejs",
        },
        "build": ["tsc languages/typescript/connect_four.ts --target ES2020 --module commonjs --outDir tests/build/ts --skipLibCheck"],
        "run": ["node tests/build/ts/connect_four.js"],
        "skills": ["tsc (ES2020, CommonJS)", "readline module", "Types on a CommonJS script"],
        "notes": [
            "The compiler output goes to `tests/build/ts`, so no `.js` file appears next to the `.ts` source.",
        ],
    },
    "v": {
        "tagline": "V with os.input_opt, which distinguishes an empty line from end of input",
        "toolchain": "v (the official compiler; it bundles tcc as its C backend)",
        "detect": "v version",
        "install": {
            "Windows": "the official v_windows.zip, unpacked to C:\\tools\\v",
            "macOS": "brew install v",
            "Debian/Ubuntu": "the distro package, or build from source",
        },
        "build": ["v -o tests/build/connect_four_v languages/v/connect_four.v"],
        "run": ["./tests/build/connect_four_v"],
        "binary": True,
        "skills": ["os.input_opt", "tcc backend", "Byte-wise digit test"],
        "notes": [
            "`os.input_opt(prompt)` is exactly the primitive this needs: it prints the prompt verbatim, flushes immediately, strips a trailing `\\r\\n`, and returns `none` at end of input versus `''` for an empty line.",
            "The release asset is `v_windows.zip` (not `v_win.zip`) and it nests everything one level down; it bundles `tcc`, so no external C compiler is required.",
        ],
    },
    "vb": {
        "tagline": "VB.NET console app with Const/ReadOnly module state",
        "toolchain": "dotnet (.NET 8 SDK)",
        "detect": "dotnet --version",
        "install": {
            "Windows": "winget install Microsoft.DotNet.SDK.8",
            "macOS": "brew install dotnet-sdk",
            "Debian/Ubuntu": "apt-get install dotnet-sdk-8.0",
        },
        "build": ["dotnet build languages/vb/ConnectFour.vbproj -c Release -o tests/build/vb --nologo -v quiet"],
        "run": ["dotnet tests/build/vb/connect_four_vb.dll"],
        "solo_file": False,
        "skills": ["VB.NET Module/Const style", "Console.ReadLine", "Shared helper functions"],
        "notes": [
            "`ConnectFour.vbproj` next to the source is the project file, and it compiles with the same .NET SDK as the C# and F# entries.",
        ],
    },
    "zig": {
        "tagline": "Zig with a flat []u8 board and direct stdout writes",
        "toolchain": "zig 0.13 or newer (it brings its own LLVM backend)",
        "detect": "zig version",
        "install": {
            "Windows": "choco install zig",
            "macOS": "brew install zig",
            "Debian/Ubuntu": "apt-get install zig (newer releases)",
        },
        "build": ["cd tests/build", "zig build-exe -O ReleaseFast --name connect_four_zig ../../languages/zig/connect_four.zig"],
        "run": ["./connect_four_zig"],
        "binary": True,
        "skills": ["Flat [42]u8 board", "std.io writers", "ReleaseFast + own LLVM backend"],
        "notes": [
            "`zig build-exe` writes the `--name` verbatim and rejects a `.exe` in `-femit-bin`, so the runner builds with `cwd=tests/build` and `--name connect_four_zig` to land `connect_four_zig.exe` where it expects it - the commands above do the same by starting with `cd tests/build`.",
        ],
    },
}


def write_text(path: Path, text: str) -> None:
    """Write UTF-8 with LF endings; Python would otherwise use os.linesep."""
    with open(path, "w", encoding="utf-8", newline="\n") as handle:
        handle.write(text)


def runner_languages() -> dict:
    """The runner's own metadata, or {} when it cannot be imported.

    Only used to report drift. Regenerating the READMEs must not require every
    toolchain to be installed, and importing the runner probes for tools that
    may legitimately be missing on the machine doing the writing.
    """
    spec = importlib.util.spec_from_file_location("cf_run_tests", RUNNER)
    if spec is None or spec.loader is None:
        return {}
    module = importlib.util.module_from_spec(spec)
    try:
        spec.loader.exec_module(module)
    except Exception as error:
        print("note: tests/run_tests.py could not be imported (%s)" % error)
        return {}
    return {language["name"]: language for language in module.LANGUAGES}


def drift_warnings(lang: dict, info: dict, runner: dict) -> list[str]:
    """Report anything the runner does that the curated entry does not mention."""
    entry = runner.get(lang["id"])
    if entry is None:
        return ["%s: no entry in tests/run_tests.py" % lang["id"]]
    commands = " ".join(info.get("build") or []) + " " + " ".join(info.get("run") or [])
    argv = list(entry.get("build") or []) + list(entry.get("run") or [])
    problems = []
    for item in argv:
        normalised = item.replace("\\", "/")
        if "/" not in normalised:
            continue
        name = normalised.rsplit("/", 1)[-1]
        if name.lower().endswith(".exe"):
            name = name[: -len(".exe")]
        if name not in commands:
            problems.append("%s: %s is not mentioned in the README commands" % (lang["id"], name))
    if argv:
        tool = argv[0].replace("\\", "/").rsplit("/", 1)[-1]
        if tool.lower().endswith(".exe"):
            tool = tool[: -len(".exe")]
        haystack = (commands + " " + info["toolchain"] + " " + info["detect"]).lower()
        if tool.lower() not in haystack:
            problems.append("%s: tool %r is not mentioned" % (lang["id"], tool))
    return problems


def main() -> int:
    languages = discover_languages()
    runner = runner_languages()
    ids = {language["id"] for language in languages}
    written = 0
    warnings = []
    for lang in languages:
        info = INFO.get(lang["id"])
        if info is None:
            warnings.append("%s: no INFO entry, skipped" % lang["id"])
            continue
        folder = LANGUAGES_DIR / lang["id"]
        write_text(
            folder / "banner.svg",
            banner_svg(lang["name"], info["toolchain"], lang["category"], info["skills"]),
        )
        write_text(folder / "README.md", readme_md(lang, info, len(languages)))
        written += 1
        if runner:
            warnings += drift_warnings(lang, info, runner)
    for name in sorted(set(INFO) - ids):
        warnings.append("%s: INFO entry has no languages/ folder" % name)
    print("Wrote README.md and banner.svg for %d language(s)." % written)
    for warning in warnings:
        print("warning: %s" % warning)
    return 0 if written else 1


if __name__ == "__main__":
    raise SystemExit(main())


