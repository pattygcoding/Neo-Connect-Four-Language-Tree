#!/usr/bin/env python3
"""Master test runner for the Connect Four Language Tree.

This script runs every language implementation against the same scripted
input files and checks that:

  1. each implementation matches the golden output in ``tests/expected/``, and
  2. all implementations produce byte-for-byte identical output.

Usage::

    python tests/run_tests.py            # run the suite
    python tests/run_tests.py --update   # regenerate the golden output files

Adding a language: append an entry to ``LANGUAGES`` below.  See AGENTS.md
for instructions on installing a toolchain automatically.
"""

from __future__ import annotations

import argparse
import glob
import os
import queue
import shutil
import subprocess
import sys
import threading
import time
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
TEST_DIR = ROOT / "tests"
INPUT_DIR = TEST_DIR / "inputs"
EXPECTED_DIR = TEST_DIR / "expected"
BUILD_DIR = TEST_DIR / "build"


def gnucobol_env() -> dict:
    """Env overrides so GnuCOBOL uses its own bundled MinGW toolchain.

    GnuCOBOL is built against a specific (older) MinGW and its C backend breaks
    when a different ``gcc`` is first on ``PATH``.  Its package ships that
    toolchain, so we point ``PATH`` and the ``COB_*`` variables at it.
    """
    candidates = []
    home = os.environ.get("COB_MAIN_DIR")
    if home:
        candidates.append(Path(home))
    resolved = shutil.which("cobc")
    if resolved:
        candidates.append(Path(resolved).resolve().parent.parent)
    if os.name == "nt":
        candidates.append(Path(r"C:\ProgramData\chocolatey\lib\gnucobol\tools"))
    for tools_dir in candidates:
        if (tools_dir / "bin" / "cobc.exe").exists():
            return {
                "PATH": str(tools_dir / "bin") + os.pathsep + os.environ.get("PATH", ""),
                "COB_CONFIG_DIR": str(tools_dir / "config"),
                "COB_COPY_DIR": str(tools_dir / "copy"),
                "COB_CFLAGS": '-I"%s"' % (tools_dir / "include"),
                "COB_LDFLAGS": '-L"%s"' % (tools_dir / "lib"),
                "COB_LIBRARY_PATH": str(tools_dir / "extras"),
            }
    return {}


DOTNET_ENV = {
    "DOTNET_CLI_TELEMETRY_OPTOUT": "1",
    "DOTNET_SKIP_FIRST_TIME_EXPERIENCE": "1",
    "DOTNET_NOLOGO": "1",
}


def mingw64_env() -> dict:
    """Env overrides so the assembly entry uses the x86-64 MinGW-w64 tools.

    The implementation is win64 assembly, but the ``gcc`` first on ``PATH`` is
    GnuCOBOL's 32-bit one, which cannot assemble or link it, so a MinGW-w64
    prefix is put first (it ships both ``gcc`` and ``as`` for x86-64).
    """
    candidates = []
    resolved = shutil.which("gcc")
    if resolved:
        candidates.append(Path(resolved).resolve().parent)
    if os.name == "nt":
        candidates.append(Path(r"C:\mingw64\bin"))
        candidates.append(Path(r"C:\ProgramData\mingw64\mingw64\bin"))
    for bin_dir in candidates:
        if (bin_dir / "x86_64-w64-mingw32-gcc.exe").exists():
            return {"PATH": str(bin_dir) + os.pathsep + os.environ.get("PATH", "")}
    return {}


def msys2_clang_env() -> dict:
    """Env overrides so the Objective-C entry uses MSYS2's clang + libobjc2.

    Windows ships no Objective-C runtime, so the toolchain here is MSYS2's
    ``clang64`` environment: clang plus the GNUstep libobjc2 runtime.  The
    built program needs the same directory on ``PATH`` at run time to load
    ``libobjc-4.6.dll`` (libobjc2 keeps that compatibility name).
    """
    candidates = []
    resolved = shutil.which("clang")
    if resolved:
        candidates.append(Path(resolved).resolve().parent)
    if os.name == "nt":
        candidates.append(Path(r"C:\msys64\clang64\bin"))
    for bin_dir in candidates:
        if (bin_dir / "clang.exe").exists() and (bin_dir / "libobjc-4.6.dll").exists():
            return {"PATH": str(bin_dir) + os.pathsep + os.environ.get("PATH", "")}
    return {}


_VCVARS_ENV: dict | None = None


def vcvars_env() -> dict:
    """Environment from the Visual Studio developer prompt, cached.

    The Swift toolchain for Windows links against the MSVC/Windows SDK libraries
    and pulls its C headers from the same places, so building needs the
    variables ``vcvars64.bat`` sets (``INCLUDE``, ``LIB``, ...).  Capturing them
    once keeps the registry's ``build`` a plain argv instead of a shell script.
    """
    global _VCVARS_ENV
    if _VCVARS_ENV is not None:
        return _VCVARS_ENV
    _VCVARS_ENV = {}
    if os.name != "nt":
        return _VCVARS_ENV
    scripts = sorted(
        glob.glob(
            r"C:\Program Files*\Microsoft Visual Studio\*\*\VC\Auxiliary\Build\vcvars64.bat"
        )
    )
    if not scripts:
        return _VCVARS_ENV
    result = subprocess.run(
        'call "%s" >nul && set' % scripts[-1],
        shell=True,
        capture_output=True,
        text=True,
    )
    for line in result.stdout.splitlines():
        if "=" in line:
            key, _, value = line.partition("=")
            _VCVARS_ENV[key] = value
    return _VCVARS_ENV


def swift_env() -> dict:
    """Env overrides so the Swift entry builds and runs on Windows.

    ``swiftc`` needs ``SDKROOT`` pointing at the Windows.sdk that ships with the
    toolchain, plus the MSVC environment from :func:`vcvars_env` for the C
    headers and link libraries.  The compiled program loads the Swift runtime
    DLLs, so that directory goes on ``PATH`` as well.
    """
    root = Path(os.environ.get("LOCALAPPDATA", "")) / "Programs" / "Swift"
    toolchains = sorted(root.glob("Toolchains/*/usr/bin"))
    runtimes = sorted(root.glob("Runtimes/*/usr/bin"))
    sdks = sorted(root.glob("Platforms/*/Windows.platform/Developer/SDKs/Windows.sdk"))
    if not (toolchains and runtimes and sdks):
        return {}
    env = dict(vcvars_env())
    parts = [str(toolchains[-1]), str(runtimes[-1])]
    if env.get("PATH"):
        parts.append(env["PATH"])
    env["PATH"] = os.pathsep.join(parts)
    env["SDKROOT"] = str(sdks[-1])
    return env


def elm_tool() -> str:
    """Path to the Elm compiler.

    Elm is installed here through Scoop, whose shim is on ``PATH``; the
    explicit candidates cover the same layout when it is not.
    """
    resolved = shutil.which("elm")
    if resolved:
        return resolved
    if os.name == "nt":
        home = os.environ.get("USERPROFILE", "")
        candidates = [
            Path(home) / "scoop" / "shims" / "elm.exe",
            Path(home) / "scoop" / "apps" / "elm" / "current" / "elm.exe",
        ]
        for candidate in candidates:
            if candidate.exists():
                return str(candidate)
    return "elm"


_ELM_HOST = """const path = require('path');
const readline = require('readline');

const compiled = require(path.join(__dirname, 'connect_four.js'));

const app = compiled.Elm.ConnectFour.init();

app.ports.toHost.subscribe(function (text) {
    process.stdout.write(text);
});

const lines = readline.createInterface({ input: process.stdin, crlfDelay: Infinity });

lines.on('line', function (line) {
    app.ports.fromHost.send(line);
});

lines.on('close', function () {
    app.ports.fromHost.send(null);
});

app.ports.quitToHost.subscribe(function () {
    lines.close();
    process.stdout.write('', function () {
        process.exit(0);
    });
});
"""


def _elm_project() -> Path:
    """Project directory for the Elm build, created and populated on demand.

    Elm has no stdin of its own, so a console program is a ``Platform.worker``
    with ports, driven by a small Node host.  Elm also requires a module's file
    name to match its module name, requires the source to live inside the
    project directory, and rejects an ``elm.json`` whose language version does
    not match the compiler.  The runner therefore assembles the project here
    from the one source file in ``languages/elm/`` plus the host template, and
    copies the source in under its module name; nothing in the repository is
    generated or modified.
    """
    project = BUILD_DIR / "elm"
    source_dir = project / "src"
    source_dir.mkdir(parents=True, exist_ok=True)
    version = "0.19.2"
    result = subprocess.run([elm_tool(), "--version"], capture_output=True, text=True)
    if result.returncode == 0 and result.stdout.strip():
        version = result.stdout.strip()
    manifest = (
        "{\n"
        '    "type": "application",\n'
        '    "source-directories": ["src"],\n'
        '    "elm-version": "%s",\n' % version
        + '    "dependencies": {"direct": {"elm/core": "1.0.5", "elm/json": "1.1.4"}, "indirect": {}},\n'
        '    "test-dependencies": {"direct": {}, "indirect": {}}\n'
        "}\n"
    )
    (project / "elm.json").write_text(manifest, encoding="utf-8")
    (project / "host.js").write_text(_ELM_HOST, encoding="utf-8")
    shutil.copyfile(LANG_DIR / "elm" / "connect_four.elm", source_dir / "ConnectFour.elm")
    return project


def fpc_tool() -> str:
    """Path to the Free Pascal compiler.

    ``fpc`` is normally on ``PATH`` (Scoop's shim, for instance, which is how
    it is installed here); the explicit candidates are for the stock installer
    layout, which does not add itself to ``PATH``.
    """
    resolved = shutil.which("fpc")
    if resolved:
        return resolved
    if os.name == "nt":
        home = os.environ.get("USERPROFILE", "")
        candidates = [
            Path(home) / "scoop" / "shims" / "fpc.exe",
            Path(r"C:\FPC\3.2.2\bin\i386-win32\fpc.exe"),
            Path(r"C:\tools\fpc\bin\i386-win32\fpc.exe"),
        ]
        for candidate in candidates:
            if candidate.exists():
                return str(candidate)
    return "fpc"


def lisp_tool() -> str:
    """Path to SBCL (Steel Bank Common Lisp).

    SBCL is installed here through Scoop; the stock Windows MSI would leave
    ``sbcl.exe`` under ``C:\\Program Files\\Steel Bank Common Lisp`` instead.
    """
    resolved = shutil.which("sbcl")
    if resolved:
        return resolved
    if os.name == "nt":
        home = os.environ.get("USERPROFILE", "")
        candidates = [
            Path(home) / "scoop" / "shims" / "sbcl.exe",
            Path(home) / "scoop" / "apps" / "sbcl" / "current" / "sbcl.exe",
        ]
        stock = Path(r"C:\Program Files\Steel Bank Common Lisp")
        candidates.extend(sorted(stock.glob("sbcl.exe"), reverse=True))
        for candidate in candidates:
            if candidate.exists():
                return str(candidate)
    return "sbcl"


def lisp_env() -> dict:
    """Env overrides so SBCL can find its core file.

    SBCL locates ``sbcl.core`` through ``SBCL_HOME``.  Scoop sets that for new
    shells, but one that was already running when SBCL was installed will not
    have it, so it is supplied here whenever the layout is recognisable.
    """
    tool = lisp_tool()
    if os.name != "nt" or tool == "sbcl":
        return {}
    home = Path(tool).parent
    if (home / "sbcl.core").exists():
        return {"SBCL_HOME": str(home)}
    return {}


def r_tool() -> str:
    """Path to ``Rscript``, R's non-interactive front end.

    R is installed here through Scoop; the stock installer would place
    ``Rscript.exe`` under ``C:\\Program Files\\R\\R-x.y.z\\bin`` instead.
    """
    resolved = shutil.which("Rscript")
    if resolved:
        return resolved
    if os.name == "nt":
        home = os.environ.get("USERPROFILE", "")
        candidates = [
            Path(home) / "scoop" / "shims" / "Rscript.exe",
            Path(home) / "scoop" / "apps" / "r" / "current" / "bin" / "Rscript.exe",
        ]
        candidates.extend(
            sorted(Path(r"C:\Program Files\R").glob("R-*/bin/Rscript.exe"), reverse=True)
        )
        for candidate in candidates:
            if candidate.exists():
                return str(candidate)
    return "Rscript"


def julia_tool() -> str:
    """Path to the Julia interpreter.

    Julia is installed here through Scoop, whose shim is on ``PATH``; the
    explicit candidates cover the same layout when it is not.
    """
    resolved = shutil.which("julia")
    if resolved:
        return resolved
    if os.name == "nt":
        home = os.environ.get("USERPROFILE", "")
        candidates = [
            Path(home) / "scoop" / "shims" / "julia.exe",
            Path(home) / "scoop" / "apps" / "julia" / "current" / "bin" / "julia.exe",
            Path(r"C:\tools\julia\bin\julia.exe"),
        ]
        for candidate in candidates:
            if candidate.exists():
                return str(candidate)
    return "julia"


def v_tool() -> str:
    """Path to the V compiler.

    V ships as a plain zip rather than an installer, so ``v.exe`` is not on
    ``PATH`` here; the unpacked copy under ``C:\\tools\\v`` is used instead.
    """
    resolved = shutil.which("v")
    if resolved:
        return resolved
    if os.name == "nt":
        home = os.environ.get("USERPROFILE", "")
        candidates = [
            Path(r"C:\tools\v\v.exe"),
            Path(r"C:\v\v.exe"),
            Path(home) / "scoop" / "apps" / "v" / "current" / "v.exe",
        ]
        for candidate in candidates:
            if candidate.exists():
                return str(candidate)
    return "v"


def _fpc_output_dir() -> str:
    """Output directory for the Pascal build, created if it does not exist.

    ``fpc`` writes units and the executable to ``-FU``/``-FE`` but will not
    create those directories, and the runner only ever creates files.
    """
    path = BUILD_DIR / "pascal"
    path.mkdir(parents=True, exist_ok=True)
    return str(path)


def _gnat_tools_dir() -> Path | None:
    """Directory holding a GNAT (Ada) toolchain, if one is installed.

    Ada needs a GCC built with the Ada front end, which the Windows compilers
    here do not have; the MSYS2 ``mingw-w64-x86_64-gcc-ada`` package provides
    one under ``C:\\msys64``, and an Alire toolchain would also fit.
    """
    resolved = shutil.which("gnatmake")
    if resolved:
        return Path(resolved).resolve().parent
    if os.name == "nt":
        candidates = [Path(r"C:\msys64\mingw64\bin"), Path(r"C:\GNAT\bin")]
        for candidate in candidates:
            if (candidate / "gnatmake.exe").exists():
                return candidate
    return None


def gnat_tool() -> str:
    """Path to ``gnatmake``, the GNAT build driver."""
    tools = _gnat_tools_dir()
    if tools is None:
        return "gnatmake"
    return str(tools / ("gnatmake.exe" if os.name == "nt" else "gnatmake"))


def gnat_env() -> dict:
    """Env overrides so the Ada entry builds with the MSYS2 GNAT.

    That ``bin`` directory is not on the default ``PATH``, so it goes first.
    The built program links the Ada runtime statically, so running it needs
    nothing extra.
    """
    tools = _gnat_tools_dir()
    if tools is None:
        return {}
    return {"PATH": str(tools) + os.pathsep + os.environ.get("PATH", "")}


def _gnat_object_dir() -> str:
    """Object directory for the Ada build, created if it does not exist.

    ``gnatmake -D`` refuses to build into a missing directory, and the runner
    only ever creates files, so the directory is made here.
    """
    path = BUILD_DIR / "ada"
    path.mkdir(parents=True, exist_ok=True)
    return str(path)


def bash_tool() -> str:
    """Path to a bash interpreter.

    Windows ships no bash of its own, and neither Git for Windows nor MSYS2
    puts it on ``PATH`` by default, so the interpreter is referenced by
    absolute path when one of the usual installs is present.  Both accept the
    plain Windows path the registry passes as the script argument.
    """
    resolved = shutil.which("bash")
    if resolved:
        return resolved
    if os.name == "nt":
        candidates = [
            Path(r"C:\Program Files\Git\bin\bash.exe"),
            Path(r"C:\Program Files\Git\usr\bin\bash.exe"),
            Path(r"C:\msys64\usr\bin\bash.exe"),
        ]
        for candidate in candidates:
            if candidate.exists():
                return str(candidate)
    return "bash"


def php_env() -> dict:
    """Env overrides so the PHP entry finds a local PHP build.

    Windows PHP releases are plain archives rather than installers; when
    ``php`` is not already on ``PATH`` the interpreter unpacked under
    ``C:\\tools\\php`` is used instead.
    """
    candidates = []
    resolved = shutil.which("php")
    if resolved:
        candidates.append(Path(resolved).resolve().parent)
    if os.name == "nt":
        candidates.append(Path(r"C:\tools\php"))
    local = os.environ.get("LOCALAPPDATA")
    if local:
        candidates.append(Path(local) / "php")
    for bin_dir in candidates:
        if (bin_dir / "php.exe").exists():
            return {"PATH": str(bin_dir) + os.pathsep + os.environ.get("PATH", "")}
    return {}


# --------------------------------------------------------------------------
# Language registry.  Each entry needs:
#   name     - short identifier, matches languages/<name>/
#   source   - path to the source file
#   build    - argv that compiles/prepares the program, or None
#   artifact - built output path (used to skip rebuilds when up to date)
#   run      - argv that executes the program
# --------------------------------------------------------------------------
LANG_DIR = ROOT / "languages"


def _src(folder: str, filename: str) -> str:
    return str(LANG_DIR / folder / filename)


def _exe(name: str) -> str:
    return str(BUILD_DIR / (name + (".exe" if os.name == "nt" else "")))


LANGUAGES = [
    {
        "name": "python",
        "source": _src("python", "connect_four.py"),
        "artifact": None,
        "build": None,
        "run": [sys.executable, _src("python", "connect_four.py")],
    },
    {
        "name": "javascript",
        "source": _src("javascript", "connect_four.js"),
        "artifact": None,
        "build": None,
        "run": ["node", _src("javascript", "connect_four.js")],
    },
    {
        "name": "typescript",
        "source": _src("typescript", "connect_four.ts"),
        "artifact": str(BUILD_DIR / "ts" / "connect_four.js"),
        "build": [
            "tsc",
            _src("typescript", "connect_four.ts"),
            "--target", "ES2020",
            "--module", "commonjs",
            "--outDir", str(BUILD_DIR / "ts"),
            "--skipLibCheck",
        ],
        "run": ["node", str(BUILD_DIR / "ts" / "connect_four.js")],
    },
    {
        "name": "dart",
        "source": _src("dart", "connect_four.dart"),
        "artifact": _exe("connect_four_dart"),
        "build": ["dart", "compile", "exe",
                  "-o", _exe("connect_four_dart"),
                  _src("dart", "connect_four.dart")],
        "run": [_exe("connect_four_dart")],
    },
    {
        "name": "powershell",
        "source": _src("powershell", "connect_four.ps1"),
        "artifact": None,
        "build": None,
        "run": ["powershell", "-NoProfile", "-ExecutionPolicy", "Bypass",
                "-File", _src("powershell", "connect_four.ps1")],
    },
    {
        "name": "elm",
        "source": _src("elm", "connect_four.elm"),
        "artifact": str(_elm_project() / "connect_four.js"),
        "build": [elm_tool(), "make", "src/ConnectFour.elm", "--optimize",
                  "--output=connect_four.js"],
        "run": ["node", str(_elm_project() / "host.js")],
        "cwd": str(_elm_project()),
    },
    {
        "name": "lisp",
        "source": _src("lisp", "connect_four.lisp"),
        "artifact": None,
        "build": None,
        "run": [lisp_tool(), "--script", _src("lisp", "connect_four.lisp")],
        "env": lisp_env(),
    },
    {
        "name": "r",
        "source": _src("r", "connect_four.R"),
        "artifact": None,
        "build": None,
        "run": [r_tool(), "--vanilla", _src("r", "connect_four.R")],
    },
    {
        "name": "julia",
        "source": _src("julia", "connect_four.jl"),
        "artifact": None,
        "build": None,
        "run": [julia_tool(), "--startup-file=no", "--color=no",
                _src("julia", "connect_four.jl")],
    },
    {
        "name": "v",
        "source": _src("v", "connect_four.v"),
        "artifact": _exe("connect_four_v"),
        "build": [v_tool(), "-o", _exe("connect_four_v"),
                  _src("v", "connect_four.v")],
        "run": [_exe("connect_four_v")],
    },
    {
        "name": "pascal",
        "source": _src("pascal", "connect_four.pas"),
        "artifact": _exe("pascal/connect_four"),
        "build": [fpc_tool(), "-O2",
                  "-FU" + _fpc_output_dir(),
                  "-FE" + _fpc_output_dir(),
                  _src("pascal", "connect_four.pas")],
        "run": [_exe("pascal/connect_four")],
    },
    {
        "name": "ada",
        "source": _src("ada", "connect_four.adb"),
        "artifact": _exe("connect_four_ada"),
        "build": [gnat_tool(), "-O2", "-D", _gnat_object_dir(),
                  "-o", _exe("connect_four_ada"),
                  _src("ada", "connect_four.adb")],
        "run": [_exe("connect_four_ada")],
        "env": gnat_env(),
    },
    {
        "name": "bash",
        "source": _src("bash", "connect_four.sh"),
        "artifact": None,
        "build": None,
        "run": [bash_tool(), "--noprofile", "--norc",
                _src("bash", "connect_four.sh")],
    },
    {
        "name": "c",
        "source": _src("c", "connect_four.c"),
        "artifact": _exe("connect_four_c"),
        "build": ["gcc", "-std=c11", "-O2",
                  "-o", _exe("connect_four_c"), _src("c", "connect_four.c")],
        "run": [_exe("connect_four_c")],
    },
    {
        "name": "cpp",
        "source": _src("cpp", "connect_four.cpp"),
        "artifact": _exe("connect_four_cpp"),
        "build": ["g++", "-std=c++17", "-O2",
                  "-o", _exe("connect_four_cpp"), _src("cpp", "connect_four.cpp")],
        "run": [_exe("connect_four_cpp")],
    },
    {
        "name": "go",
        "source": _src("go", "connect_four.go"),
        "artifact": _exe("connect_four_go"),
        "build": ["go", "build", "-o", _exe("connect_four_go"), _src("go", "connect_four.go")],
        "run": [_exe("connect_four_go")],
    },
    {
        "name": "assembly",
        "source": _src("assembly", "connect_four.s"),
        "artifact": _exe("connect_four_asm"),
        "build": ["gcc", "-o", _exe("connect_four_asm"),
                  _src("assembly", "connect_four.s")],
        "run": [_exe("connect_four_asm")],
        "env": mingw64_env(),
    },
    {
        "name": "nim",
        "source": _src("nim", "connect_four.nim"),
        "artifact": _exe("connect_four_nim"),
        "build": ["nim", "c", "--hints:off", "--warnings:off", "-d:release",
                  "--nimcache:" + str(BUILD_DIR / "nimcache"),
                  "-o:" + _exe("connect_four_nim"),
                  _src("nim", "connect_four.nim")],
        "run": [_exe("connect_four_nim")],
        "env": mingw64_env(),
    },
    {
        "name": "zig",
        "source": _src("zig", "connect_four.zig"),
        "artifact": _exe("connect_four_zig"),
        "build": ["zig", "build-exe", "-O", "ReleaseFast",
                  "--name", "connect_four_zig", _src("zig", "connect_four.zig")],
        "run": [_exe("connect_four_zig")],
        "cwd": str(BUILD_DIR),
    },
    {
        "name": "objectivec",
        "source": _src("objectivec", "connect_four.m"),
        "artifact": _exe("connect_four_objc"),
        "build": ["clang", "-fobjc-runtime=gnustep-2.0", "-O2",
                  "-o", _exe("connect_four_objc"),
                  _src("objectivec", "connect_four.m"), "-lobjc"],
        "run": [_exe("connect_four_objc")],
        "env": msys2_clang_env(),
    },
    {
        "name": "ocaml",
        "source": _src("ocaml", "connect_four.ml"),
        "artifact": _exe("connect_four_ocaml"),
        "build": ["opam", "exec", "--", "ocamlopt",
                  "-o", _exe("connect_four_ocaml"),
                  _src("ocaml", "connect_four.ml")],
        "run": [_exe("connect_four_ocaml")],
    },
    {
        "name": "fortran",
        "source": _src("fortran", "connect_four.f90"),
        "artifact": _exe("connect_four_fortran"),
        "build": ["gfortran", "-O2", "-o", _exe("connect_four_fortran"),
                  _src("fortran", "connect_four.f90")],
        "run": [_exe("connect_four_fortran")],
        "env": mingw64_env(),
    },
    {
        "name": "php",
        "source": _src("php", "connect_four.php"),
        "artifact": None,
        "build": None,
        "run": ["php", _src("php", "connect_four.php")],
        "env": php_env(),
    },
    {
        "name": "swift",
        "source": _src("swift", "connect_four.swift"),
        "artifact": _exe("connect_four_swift"),
        "build": ["swiftc", "-O", "-o", _exe("connect_four_swift"),
                  _src("swift", "connect_four.swift")],
        "run": [_exe("connect_four_swift")],
        "env": swift_env(),
    },
    {
        "name": "haskell",
        "source": _src("haskell", "connect_four.hs"),
        "artifact": _exe("connect_four_haskell"),
        "build": ["ghc", "-O2",
                  "-outputdir", str(BUILD_DIR / "haskell"),
                  "-o", _exe("connect_four_haskell"),
                  _src("haskell", "connect_four.hs")],
        "run": [_exe("connect_four_haskell")],
    },
    {
        "name": "rust",
        "source": _src("rust", "connect_four.rs"),
        "artifact": _exe("connect_four_rust"),
        "build": ["rustc", "-O", "-o", _exe("connect_four_rust"), _src("rust", "connect_four.rs")],
        "run": [_exe("connect_four_rust")],
    },
    {
        "name": "java",
        "source": _src("java", "connect_four.java"),
        "artifact": str(BUILD_DIR / "java" / "connect_four.class"),
        "build": ["javac", "-d", str(BUILD_DIR / "java"), _src("java", "connect_four.java")],
        "run": ["java", "-cp", str(BUILD_DIR / "java"), "connect_four"],
    },
    {
        "name": "csharp",
        "source": _src("csharp", "connect_four.cs"),
        "artifact": str(BUILD_DIR / "csharp" / "connect_four.dll"),
        "build": ["dotnet", "build", _src("csharp", "ConnectFour.csproj"),
                  "-c", "Release", "-o", str(BUILD_DIR / "csharp"),
                  "--nologo", "-v", "quiet"],
        "run": ["dotnet", str(BUILD_DIR / "csharp" / "connect_four.dll")],
        "env": DOTNET_ENV,
    },
    {
        "name": "vb",
        "source": _src("vb", "connect_four.vb"),
        "artifact": str(BUILD_DIR / "vb" / "connect_four_vb.dll"),
        "build": ["dotnet", "build", _src("vb", "ConnectFour.vbproj"),
                  "-c", "Release", "-o", str(BUILD_DIR / "vb"),
                  "--nologo", "-v", "quiet"],
        "run": ["dotnet", str(BUILD_DIR / "vb" / "connect_four_vb.dll")],
        "env": DOTNET_ENV,
    },
    {
        "name": "fsharp",
        "source": _src("fsharp", "connect_four.fs"),
        "artifact": str(BUILD_DIR / "fsharp" / "connect_four_fs.dll"),
        "build": ["dotnet", "build", _src("fsharp", "ConnectFour.fsproj"),
                  "-c", "Release", "-o", str(BUILD_DIR / "fsharp"),
                  "--nologo", "-v", "quiet"],
        "run": ["dotnet", str(BUILD_DIR / "fsharp" / "connect_four_fs.dll")],
        "env": DOTNET_ENV,
    },
    {
        "name": "kotlin",
        "source": _src("kotlin", "connect_four.kt"),
        "artifact": str(BUILD_DIR / "connect_four_kotlin.jar"),
        "build": ["kotlinc", _src("kotlin", "connect_four.kt"), "-include-runtime",
                  "-d", str(BUILD_DIR / "connect_four_kotlin.jar")],
        "run": ["java", "-jar", str(BUILD_DIR / "connect_four_kotlin.jar")],
    },
    {
        "name": "ruby",
        "source": _src("ruby", "connect_four.rb"),
        "artifact": None,
        "build": None,
        "run": ["ruby", _src("ruby", "connect_four.rb")],
    },
    {
        "name": "lua",
        "source": _src("lua", "connect_four.lua"),
        "artifact": None,
        "build": None,
        "run": ["lua", _src("lua", "connect_four.lua")],
    },
    {
        "name": "elixir",
        "source": _src("elixir", "connect_four.ex"),
        "artifact": None,
        "build": None,
        "run": ["elixir", _src("elixir", "connect_four.ex")],
    },
    {
        "name": "erlang",
        "source": _src("erlang", "connect_four.erl"),
        "artifact": str(BUILD_DIR / "connect_four.beam"),
        "build": ["erlc", "-o", str(BUILD_DIR), _src("erlang", "connect_four.erl")],
        "run": ["erl", "-noshell", "-pa", str(BUILD_DIR),
                "-s", "connect_four", "main", "-s", "init", "stop"],
    },
    {
        "name": "scala",
        "source": _src("scala", "connect_four.scala"),
        "artifact": None,
        "build": None,
        "run": ["scala", _src("scala", "connect_four.scala")],
        "cwd": str(BUILD_DIR),
    },
    {
        "name": "clojure",
        "source": _src("clojure", "connect_four.clj"),
        "artifact": None,
        "build": None,
        "run": ["clojure", "-M", _src("clojure", "connect_four.clj")],
        "cwd": str(BUILD_DIR),
    },
    {
        "name": "perl",
        "source": _src("perl", "connect_four.pl"),
        "artifact": None,
        "build": None,
        "run": ["perl", _src("perl", "connect_four.pl")],
    },
    {
        "name": "prolog",
        "source": _src("prolog", "connect_four.pro"),
        "artifact": None,
        "build": None,
        "run": ["swipl", "-q", "-g", "main", "-t", "halt",
                _src("prolog", "connect_four.pro")],
    },
    {
        "name": "cobol",
        "source": _src("cobol", "connect_four.cob"),
        "artifact": _exe("connect_four_cobol"),
        "build": ["cobc", "-x", "-free", "-o", _exe("connect_four_cobol"),
                  _src("cobol", "connect_four.cob")],
        "run": [_exe("connect_four_cobol")],
        "env": gnucobol_env(),
    },
]

# --------------------------------------------------------------------------
# Scenarios.  Each maps to tests/inputs/<name>.txt and
# tests/expected/<name>.txt.  ``expect`` is the result line that must appear.
# --------------------------------------------------------------------------
SCENARIOS = [
    {"name": "horizontal_win", "expect": "Player X wins!"},
    {"name": "vertical_win", "expect": "Player O wins!"},
    {"name": "diagonal_up_win", "expect": "Player X wins!"},
    {"name": "diagonal_down_win", "expect": "Player X wins!"},
    {"name": "full_column", "expect": "Player X wins!"},
    {"name": "invalid_inputs", "expect": "Player X wins!"},
    {"name": "tie", "expect": "It's a tie!"},
    {"name": "eof_during_game", "expect": "Input closed. Goodbye."},
]

TIMEOUT_SECONDS = 20


def normalize(text: str) -> str:
    """Normalise line endings and trailing whitespace for comparison."""
    text = text.replace("\r\n", "\n").replace("\r", "\n")
    return "\n".join(line.rstrip() for line in text.split("\n"))


def language_env(language: dict) -> dict:
    """Environment for a language's build/run, including per-language overrides."""
    env = os.environ.copy()
    env.update(language.get("env") or {})
    return env


def resolve_command(argv: list, env: dict | None = None) -> list:
    """Resolve argv[0] on PATH.

    On Windows some toolchains install ``.cmd``/``.bat`` shims (e.g. ``tsc``,
    ``kotlinc``) that ``CreateProcess`` cannot find by bare name; resolving
    them here keeps the registry portable.  When ``env`` is given its ``PATH``
    is used, so a per-language toolchain can take precedence.
    """
    if not argv:
        return argv
    program = None
    if env is not None:
        program = shutil.which(argv[0], path=env.get("PATH"))
    if not program:
        program = shutil.which(argv[0])
    if program:
        return [program] + list(argv[1:])
    return list(argv)


def needs_build(language: dict) -> bool:
    """True when the compiled program is missing or older than its source."""
    if not language.get("build"):
        return False
    artifact = language.get("artifact")
    if artifact:
        artifact_path = Path(artifact)
        source_path = Path(language["source"])
        if (artifact_path.exists()
                and artifact_path.stat().st_mtime >= source_path.stat().st_mtime):
            return False
    return True


def build_language(language: dict) -> None:
    if not needs_build(language):
        return
    BUILD_DIR.mkdir(parents=True, exist_ok=True)
    env = language_env(language)
    result = subprocess.run(
        resolve_command(language["build"], env),
        capture_output=True,
        text=True,
        env=env,
        cwd=language.get("cwd"),
    )
    if result.returncode != 0:
        raise RuntimeError(
            "failed to build %s:\n%s\n%s"
            % (language["name"], result.stdout, result.stderr)
        )


def run_language(language: dict, stdin_bytes: bytes) -> str:
    env = language_env(language)
    result = subprocess.run(
        resolve_command(language["run"], env),
        input=stdin_bytes,
        capture_output=True,
        timeout=TIMEOUT_SECONDS,
        cwd=language.get("cwd"),
        env=env,
    )
    return normalize(result.stdout.decode("utf-8", errors="replace"))


def interactive_check(
    language: dict, scenario: str, timeout: float = 25.0
) -> tuple[bool, str]:
    """Drive a program the way a person at a terminal would.

    stdin is kept OPEN (an open pipe is the portable stand-in for a TTY) and
    the program is fed one line per turn. This proves that:

      * the prompt/board is written before any input arrives (so it is not
        buffered until the program exits),
      * every entered line yields more output, and
      * the whole interactive session matches the golden capture.

    Returns ``(passed, actual_output)``.
    """
    input_path = INPUT_DIR / ("%s.txt" % scenario)
    expected_path = EXPECTED_DIR / ("%s.txt" % scenario)
    stdin_bytes = input_path.read_bytes()
    expected = normalize(expected_path.read_text(encoding="utf-8"))

    lines = stdin_bytes.split(b"\n")
    if lines and lines[-1] == b"":
        lines.pop()

    env = language_env(language)
    process = subprocess.Popen(
        resolve_command(language["run"], env),
        stdin=subprocess.PIPE,
        stdout=subprocess.PIPE,
        stderr=subprocess.DEVNULL,
        cwd=language.get("cwd"),
        env=env,
    )
    chunks: "queue.Queue[bytes | None]" = queue.Queue()

    def reader() -> None:
        try:
            while True:
                data = process.stdout.read1(4096)
                if not data:
                    break
                chunks.put(data)
        except Exception:
            pass
        finally:
            chunks.put(None)

    threading.Thread(target=reader, daemon=True).start()

    buffer = bytearray()
    initial_prompt = b"Player X, choose a column (1-7): "

    def pump(predicate, wait: float) -> bool:
        deadline = time.monotonic() + wait
        while True:
            if predicate():
                return True
            remaining = deadline - time.monotonic()
            if remaining <= 0:
                return predicate()
            try:
                chunk = chunks.get(timeout=remaining)
            except queue.Empty:
                continue
            if chunk is None:
                return predicate()
            buffer.extend(chunk)

    ok = pump(lambda: initial_prompt in bytes(buffer), timeout)
    for line in lines:
        size_before = len(buffer)
        try:
            process.stdin.write(line + b"\n")
            process.stdin.flush()
        except OSError:
            break
        pump(lambda size=size_before: len(buffer) > size, timeout)

    if scenario == "eof_during_game":
        try:
            process.stdin.close()
        except OSError:
            pass

    try:
        process.wait(timeout=timeout)
    except subprocess.TimeoutExpired:
        process.kill()
        process.wait()
        ok = False
    finally:
        try:
            process.stdin.close()
        except OSError:
            pass

    while True:
        try:
            chunk = chunks.get_nowait()
        except queue.Empty:
            break
        if chunk:
            buffer.extend(chunk)

    actual = normalize(bytes(buffer).decode("utf-8", errors="replace"))
    return ok and actual == expected, actual


def first_difference(actual: str, expected: str) -> str:
    """Return a short, readable description of the first differing line."""
    actual_lines = actual.split("\n")
    expected_lines = expected.split("\n")
    for index in range(max(len(actual_lines), len(expected_lines))):
        got = actual_lines[index] if index < len(actual_lines) else "<missing>"
        want = expected_lines[index] if index < len(expected_lines) else "<missing>"
        if got != want:
            return "line %d:\n      expected: %r\n      actual:   %r" % (
                index + 1,
                want,
                got,
            )
    return "outputs differ only by length"


def run_suite(update: bool) -> int:
    EXPECTED_DIR.mkdir(parents=True, exist_ok=True)
    BUILD_DIR.mkdir(parents=True, exist_ok=True)
    failures = []

    print("Building implementations...")
    for language in LANGUAGES:
        build_language(language)
        print("  built %s" % language["name"])

    for scenario in SCENARIOS:
        name = scenario["name"]
        input_path = INPUT_DIR / ("%s.txt" % name)
        if not input_path.exists():
            failures.append("%s: missing input file %s" % (name, input_path))
            print("FAIL %s (missing input)" % name)
            continue
        stdin_bytes = input_path.read_bytes()

        outputs = {}
        for language in LANGUAGES:
            outputs[language["name"]] = run_language(language, stdin_bytes)

        # All implementations must agree with each other.
        names = list(outputs)
        reference_name = names[0]
        consistent = True
        for other in names[1:]:
            if outputs[other] != outputs[reference_name]:
                consistent = False
                failures.append(
                    "%s: %s and %s disagree\n    %s"
                    % (
                        name,
                        reference_name,
                        other,
                        first_difference(
                            outputs[other], outputs[reference_name]
                        ),
                    )
                )

        agreed = outputs[reference_name]
        if scenario["expect"] not in agreed:
            consistent = False
            failures.append(
                "%s: output does not contain %r" % (name, scenario["expect"])
            )

        expected_path = EXPECTED_DIR / ("%s.txt" % name)
        if update:
            if consistent:
                golden = agreed if agreed.endswith("\n") else agreed + "\n"
                expected_path.write_text(golden, encoding="utf-8")
                print("WROTE %s" % name)
            else:
                print("FAIL %s (not updating golden file)" % name)
            continue

        if not expected_path.exists():
            failures.append("%s: missing golden file %s" % (name, expected_path))
            print("FAIL %s (missing golden file)" % name)
            continue

        expected = normalize(expected_path.read_text(encoding="utf-8"))
        if agreed != expected:
            consistent = False
            failures.append(
                "%s: output differs from golden file\n    %s"
                % (name, first_difference(agreed, expected))
            )

        if consistent:
            print("PASS %s" % name)
        else:
            print("FAIL %s" % name)

    # Every program must be playable interactively at a terminal: output has
    # to appear before the player types, each line must get a response, and
    # the whole session must still match the golden capture.
    print("Checking interactive terminal I/O (open stdin, output before input)...")
    for scenario_name in ("horizontal_win", "eof_during_game"):
        for language in LANGUAGES:
            passed, _actual = interactive_check(language, scenario_name)
            if passed:
                print("  OK   %-11s %s" % (language["name"], scenario_name))
            else:
                failures.append(
                    "%s: interactive terminal I/O failed for %s"
                    % (language["name"], scenario_name)
                )
                print("  FAIL %-11s %s" % (language["name"], scenario_name))

    print()
    if failures:
        print("%d failure(s):" % len(failures))
        for failure in failures:
            print("  - %s" % failure)
        return 1

    runs = len(SCENARIOS) * len(LANGUAGES)
    print(
        "All %d scenarios passed for %d language(s) (%d runs, identical stdin "
        "to every implementation, plus interactive terminal I/O checks)."
        % (len(SCENARIOS), len(LANGUAGES), runs)
    )
    return 0


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--update",
        action="store_true",
        help="regenerate the golden output files instead of checking them",
    )
    args = parser.parse_args()
    return run_suite(update=args.update)


if __name__ == "__main__":
    sys.exit(main())
