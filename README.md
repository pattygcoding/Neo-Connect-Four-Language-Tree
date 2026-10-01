# Neo-Connect-Four-Language-Tree

Connect Four implemented in as many languages as I please. Every
implementation reads the same console input and prints **byte-for-byte
identical output**, so a single master test can verify them all at once.

## Rules

* 6 rows x 7 columns board.
* `X` moves first, then `X` and `O` alternate.
* A player enters a column number from `1` to `7`.
* The piece falls to the lowest empty row of that column.
* First to line up **four in a row** wins: horizontal, vertical, either
  diagonal.
* If the board fills up with no four in a row, it's a **tie**.

## Repository layout

```
languages/
  c/connect_four.c          one C implementation
  python/connect_four.py    one Python implementation
tests/
  inputs/<scenario>.txt     scripted stdin for each scenario
  expected/<scenario>.txt   golden stdout for each scenario
  run_tests.py              master test runner
tools/
  generate_dashboard.py     builds the static showcase data
index.html                  static showcase dashboard (no backend)
dashboard-data.js           generated data consumed by index.html
```

## Running the tests

```sh
python tests/run_tests.py
```

The runner compiles each language, replays every scenario from
`tests/inputs/`, and checks that:

1. every implementation matches the golden output in `tests/expected/`,
2. all implementations agree with each other, and
3. every implementation works interactively — with stdin left open, the
   prompt appears before any input is sent, each entered line is answered,
   and the whole session matches the golden capture (this catches programs
   that slurp all input up front or buffer their output).

It needs Python 3.8+ and, for the C implementation, `gcc` on `PATH`.
To regenerate the golden files after an intentional protocol change:

```sh
python tests/run_tests.py --update
```

Scenarios covered: horizontal win, vertical win, both diagonal wins, a
full-column rejection, invalid-input rejection (non-numeric, out of range,
empty), a full-board tie, and end-of-input.

## Console protocol

Every implementation must print exactly this. `tests/expected/` is the
authoritative reference.

The game starts with a header and the empty board:

```
=== Connect Four ===
Get four of your pieces in a row to win. Columns are numbered 1-7.

 1 2 3 4 5 6 7
+-------------+
|. . . . . . .|
|. . . . . . .|
|. . . . . . .|
|. . . . . . .|
|. . . . . . .|
|. . . . . . .|
+-------------+
Player X, choose a column (1-7): 
```

Details:

* The board is 6 rows x 7 columns. The bottom row is printed last. Empty
  cells are `.`, players are `X` and `O`. Columns are numbered 1-7 from
  left to right.
* The prompt `Player X, choose a column (1-7): ` is printed without a
  trailing newline. After a valid move a newline is printed, then the
  updated board, then the next prompt.
* Invalid input prints a warning on its own line and reprints the prompt:
  * empty line: `Invalid input: no column entered.`
  * not a whole number: `Invalid input: "<token>" is not a whole number.`
  * outside 1-7: `Invalid input: "<token>" is out of range (1-7).`
  * full column: `Column <n> is full.`
* The game ends with one of:
  * `Player X wins!`
  * `Player O wins!`
  * `It's a tie!`
* If stdin closes before the game ends: `Input closed. Goodbye.`

A token is a whole number only when it is an optional `+`/`-` sign followed
by ASCII digits. Whitespace around the token is stripped.

## Static showcase dashboard

`index.html` is a fully client-side dashboard (Tailwind + Prism.js, no
backend, no live compilers). It shows a sidebar of every implementation and
a main panel with two tabs: **Source Code** and **Console Output**. It also
has a language search box, category filters, and a selector for which
pre-captured console scenario to display. Deep links are supported, e.g.
`index.html?lang=go&scenario=tie&tab=output`.

Everything it shows is generated from the real repository by:

```sh
python tools/generate_dashboard.py
```

That script scans `languages/*/connect_four.*` for source and reuses the
verified captures in `tests/expected/` as the console output, then writes
`dashboard-data.js`. Because that data is loaded with a `<script>` tag (not
`fetch`), the page works both on a static host **and** straight from
`file://`. To serve it locally:

```sh
python -m http.server
# then open http://localhost:8000/
```

Any static host or GitHub Pages deployment works as-is; re-run the
generator whenever you add a language.

### Deploying to GitHub Pages

The dashboard is GitHub Pages ready with no build step: `index.html` and the
committed `dashboard-data.js` sit at the repository root, every local asset
is referenced with a relative path, and all third-party libraries load over
`https` from CDNs. A `.nojekyll` file is included so Pages serves the files
verbatim. Publish from the repository root (branch `main`, folder `/`) and
the site is available at `https://<user>.github.io/<repo>/`.

## Languages

| Language   | Source                                 | Toolchain         |
|------------|----------------------------------------|-------------------|
| Ada        | `languages/ada/connect_four.adb`       | `gnatmake`        |
| Assembly   | `languages/assembly/connect_four.s`    | `gcc` (x86-64)    |
| Bash       | `languages/bash/connect_four.sh`       | `bash`            |
| C          | `languages/c/connect_four.c`           | `gcc` (C11)       |
| C#         | `languages/csharp/connect_four.cs`     | `dotnet` (.NET 8) |
| C++        | `languages/cpp/connect_four.cpp`       | `g++` (C++17)     |
| Clojure    | `languages/clojure/connect_four.clj`   | `clojure`         |
| COBOL      | `languages/cobol/connect_four.cob`     | `cobc` (GnuCOBOL) |
| Dart       | `languages/dart/connect_four.dart`     | `dart`            |
| Elm        | `languages/elm/connect_four.elm`       | `elm` + `node`    |
| Elixir     | `languages/elixir/connect_four.ex`     | `elixir`          |
| Erlang     | `languages/erlang/connect_four.erl`    | `erlc` + `erl`    |
| F#         | `languages/fsharp/connect_four.fs`     | `dotnet` (.NET 8) |
| Fortran    | `languages/fortran/connect_four.f90`   | `gfortran`        |
| Go         | `languages/go/connect_four.go`         | `go`              |
| Haskell    | `languages/haskell/connect_four.hs`    | `ghc`             |
| Java       | `languages/java/connect_four.java`     | `javac`/`java`    |
| JavaScript | `languages/javascript/connect_four.js` | `node`            |
| Julia      | `languages/julia/connect_four.jl`      | `julia`           |
| Kotlin     | `languages/kotlin/connect_four.kt`     | `kotlinc`/`java`  |
| Lisp       | `languages/lisp/connect_four.lisp`     | `sbcl`            |
| Lua        | `languages/lua/connect_four.lua`       | `lua`             |
| Nim        | `languages/nim/connect_four.nim`       | `nim` (gcc)       |
| Objective-C | `languages/objectivec/connect_four.m` | `clang` (libobjc2) |
| OCaml      | `languages/ocaml/connect_four.ml`      | `ocamlopt`        |
| Pascal     | `languages/pascal/connect_four.pas`  | `fpc`             |
| Perl       | `languages/perl/connect_four.pl`       | `perl`            |
| PHP        | `languages/php/connect_four.php`       | `php`             |
| PowerShell | `languages/powershell/connect_four.ps1` | `powershell`      |
| Prolog     | `languages/prolog/connect_four.pro`    | `swipl`           |
| Python     | `languages/python/connect_four.py`     | `python3`         |
| R          | `languages/r/connect_four.R`           | `Rscript`         |
| Ruby       | `languages/ruby/connect_four.rb`       | `ruby`            |
| Rust       | `languages/rust/connect_four.rs`       | `rustc`           |
| Scala      | `languages/scala/connect_four.scala`   | `scala`           |
| Swift      | `languages/swift/connect_four.swift`   | `swiftc`          |
| TypeScript | `languages/typescript/connect_four.ts` | `tsc` + `node`    |
| V          | `languages/v/connect_four.v`           | `v`               |
| VB.NET     | `languages/vb/connect_four.vb`         | `dotnet` (.NET 8) |
| Zig        | `languages/zig/connect_four.zig`       | `zig` (LLVM)      |

The test runner compiles everything for you and skips rebuilds when nothing
changed. To play a compiled implementation directly, use the artifact under
`tests/build/` (e.g. `dotnet tests/build/csharp/connect_four.dll`,
`java -jar tests/build/connect_four_kotlin.jar`,
`node tests/build/ts/connect_four.js`); scripting languages run from source
(`python`, `node`, `ruby`, `lua`). Avoid `dotnet run`, which recompiles on
every launch — the built `.dll` starts in well under 0.1s.

## Adding a language

1. Create `languages/<name>/connect_four.<ext>` and implement the protocol
   above exactly.
2. Register it in the `LANGUAGES` list in `tests/run_tests.py`
   (`name`, `source`, `build`, `run`).
3. Run `python tests/run_tests.py` until it passes.
4. Add a row to the language table above and refresh the showcase with
   `python tools/generate_dashboard.py`.

See `AGENTS.md` for instructions on automatically installing a language
toolchain that is not yet present on the machine.
