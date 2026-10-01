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
  c/README.md               generated: how to build, run and install it
  c/banner.svg              generated: that README's skills banner
  python/connect_four.py    one Python implementation
frameworks/
  rubyonrails/              a multi-file Rails app (shown one file at a time)
tests/
  inputs/<scenario>.txt     scripted stdin for each scenario
  expected/<scenario>.txt   golden stdout for each scenario
  run_tests.py              master test runner
tools/
  generate_dashboard.py     builds the static showcase data
  generate_language_readmes.py  writes each language's README.md + banner.svg
  serve.py                  local preview server (Pages-style 404.html fallback)
index.html                  static showcase dashboard (no backend)
404.html                    GitHub Pages deep-link fallback for /<language-id>
logo.png                    site favicon, used by the dashboard and the 404 shim
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
pre-captured console scenario to display.

Every implementation has its own address, `/<language-id>` — `/ada`, `/c`,
`/objectivec` — and the sidebar entries are real links, so they can be copied,
bookmarked or opened in a new tab. The site root (`/`, or `index.html` without a
`?lang=`) opens the C# implementation, the reference walkthrough; the id lives
in `DEFAULT_LANG_ID` at the top of the script, and a fork that ships without C#
falls back to the first language it does have. The console view carries its
scenario, e.g. `/go?tab=output&scenario=tie`. The page keeps the address in step
with the selection (including browser back/forward) using the History API, and
falls back to the query-string shape when the browser refuses path writes — that
is all `file://` allows, so `index.html?lang=go&tab=output&scenario=tie` still
works there. `?lang=`, `?tab=` and `?scenario=` are read on load in both
shapes, so older links keep working.

Above the selected implementation the header links to that folder on GitHub,
labelled `View languages/<id> on GitHub` behind a GitHub mark — its target is
`<repository>/tree/<branch>/<source folder>`, built from the
`repository`/`branch` the generator records (the git remote, else
`GITHUB_REPOSITORY`, else the committed default), so it points at the right
project for a clone or a fork while still reading as a label rather than a URL.

The styling follows the author's portfolio site: a near-black navy canvas, a
pale-mint accent, Inter for text and JetBrains Mono for the small uppercase
tracking-wide labels. Those tokens (the Tailwind `ink`/`mint` palettes and a
`.micro` label helper) are declared inline in `index.html`, so the page still
needs no build step.

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
python tools/serve.py            # then open http://localhost:8000/
```

Use that rather than `python -m http.server`. The dashboard's addresses are
pretty paths (`/csharp`, `/ada`), which are not files, and a bare file server
answers them with its own 404 page — so *refreshing* one of those screens looks
broken locally even though the deployed site is fine. `tools/serve.py` mirrors
GitHub Pages instead: an unknown path is answered with the site's own
`404.html` (404 status, shim included), and that shim sends the browser on to
`index.html?lang=<id>`. Opening the dashboard straight from `file://` needs no
server at all — it just uses the `?lang=` query shape.

Any static host or GitHub Pages deployment works as-is; re-run the
generator whenever you add a language.

### Deploying to GitHub Pages

The dashboard is GitHub Pages ready with no build step: `index.html` and the
committed `dashboard-data.js` sit at the repository root, every local asset
is referenced with a relative path, and all third-party libraries load over
`https` from CDNs. A `.nojekyll` file is included so Pages serves the files
verbatim. Publish from the repository root (branch `main`, folder `/`).

**Publishing is automatic.** Pages is set to *deploy from a branch* (`main`,
folder `/`) with no build step, so **any push to `main` redeploys the site** —
there is no separate publish or deploy command to run. Commit and push your
changes from PowerShell:

```powershell
git add -A; git commit -m "Deploy showcase"; git push
```

Watch the run under the repository's **Actions → pages build and deployment**;
the update goes live at <https://connectfour.pattygcoding.com/> a minute or two
later. If you changed the showcase, re-run `python tools/generate_dashboard.py`
first so the committed `dashboard-data.js` is current before you push.

The published site lives at **<https://connectfour.pattygcoding.com/>** — the
`CNAME` file in the repository root names that host, so the `<user>.github.io`
address redirects to it. The DNS side is a single record at the domain's
provider:

```
connectfour   CNAME   pattygcoding.github.io
```

(This is a subdomain, so it does not disturb `www.pattygcoding.com`, which
belongs to the portfolio site and has its own `CNAME`.) Point it at the
hostname the portfolio already uses. If the provider proxies traffic — Cloudflare
does by default — switch that record to **DNS only** (grey cloud); a proxied
record breaks Pages' certificate checks.

Because `www.<domain>` is already claimed by another Pages site, a path of that
domain (`www.pattygcoding.com/connectfour`) is not available to this repository:
GitHub allows one custom domain per site, and a *path* under someone else's
domain can only exist inside that site's own files. A dedicated subdomain keeps
the pretty `/csharp` addresses and the `404.html` fallback intact.

The dashboard adapts to whatever directory it is served from: it derives the
deployment prefix at load (`APP_DIR`) and builds every link, `pushState` and
canonical language address from it, so the same files work at
`https://connectfour.pattygcoding.com/csharp` and at
`https://<user>.github.io/<repo>/csharp` with no configuration.

Pages has no rewrite rules, so the committed `404.html` stands in for them:
it is served for any path it cannot find (with the address bar untouched)
and rebuilds the request as `index.html?lang=<id>` — `/ada`, `/repo/ada` and
a tolerated `/ada/output` all resolve, and the dashboard then puts the pretty
`/ada` path back into the address bar. Anything else (a typo, a missing
file) climbs one directory per attempt, so a junk link cannot redirect in
circles and simply ends up on the default implementation (C#).

Keep `404.html` **tracked in git**: it is the only thing that makes refreshing
a pretty path (`/csharp`) work on Pages, and without it GitHub answers the
refresh with its own 404 page. `tools/serve.py` reproduces that behaviour
locally, so a refresh test there means something.

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
| Groovy     | `languages/groovy/connect_four.groovy` | `groovy`          |
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

## Frameworks

Not every showcase here is a single console program. The `frameworks/` tree
holds a richer, multi-file project built in a real web framework; the dashboard
shows **one representative file** from each and links the whole project on
GitHub, with a note above the code explaining just that.

| Framework     | Project                   | Representative file                                           | Run                   |
|---------------|---------------------------|--------------------------------------------------------------|-----------------------|
| .NET MAUI     | `frameworks/maui/`        | `frameworks/maui/MainPage.xaml.cs`                           | `dotnet build -t:Run` |
| Angular       | `frameworks/angular/`     | `frameworks/angular/src/app/connect-four/connect-four.component.ts` | `ng serve`      |
| ASP.NET Core  | `frameworks/aspnetcore/`  | `frameworks/aspnetcore/Controllers/GameController.cs`        | `dotnet run`          |
| Blazor        | `frameworks/blazor/`      | `frameworks/blazor/Components/Pages/ConnectFour.razor`       | `dotnet run`          |
| Django        | `frameworks/django/`      | `frameworks/django/game/views.py`                            | `manage.py runserver` |
| Express       | `frameworks/expressjs/`   | `frameworks/expressjs/app.js`                                | `node app.js`         |
| FastAPI       | `frameworks/fastapi/`     | `frameworks/fastapi/app/main.py`                             | `fastapi dev`         |
| Fastify       | `frameworks/fastify/`     | `frameworks/fastify/app.js`                                  | `node app.js`         |
| Fiber         | `frameworks/fiber/`       | `frameworks/fiber/main.go`                                   | `go run .`            |
| Flask         | `frameworks/flask/`       | `frameworks/flask/app.py`                                    | `flask --app app run` |
| Flutter       | `frameworks/flutter/`     | `frameworks/flutter/lib/connect_four.dart`                   | `flutter run`         |
| Gin           | `frameworks/gin/`         | `frameworks/gin/main.go`                                     | `go run .`            |
| Laravel       | `frameworks/laravel/`     | `frameworks/laravel/app/Http/Controllers/GameController.php` | `php artisan serve`   |
| NestJS        | `frameworks/nestjs/`      | `frameworks/nestjs/src/game/game.controller.ts`              | `ts-node src/main.ts` |
| Next.js       | `frameworks/nextjs/`      | `frameworks/nextjs/app/page.jsx`                             | `npm run dev`         |
| Nuxt          | `frameworks/nuxt/`        | `frameworks/nuxt/composables/useConnectFour.js`              | `npm run dev`         |
| Phoenix       | `frameworks/phoenix/`     | `frameworks/phoenix/lib/connect_four_web/controllers/game_controller.ex` | `mix phx.server` |
| React         | `frameworks/react/`       | `frameworks/react/src/ConnectFour.jsx`                       | `npx vite`            |
| React Native  | `frameworks/reactnative/` | `frameworks/reactnative/src/ConnectFour.jsx`                 | `npx expo start`      |
| Ruby on Rails | `frameworks/rubyonrails/` | `frameworks/rubyonrails/app/controllers/games_controller.rb` | `bin/rails server`    |
| Spring Boot   | `frameworks/springboot/`  | `frameworks/springboot/src/main/java/com/example/connectfour/GameController.java` | `mvnw spring-boot:run` |
| Svelte        | `frameworks/svelte/`      | `frameworks/svelte/src/lib/store.js`                         | `npx vite`            |
| Symfony       | `frameworks/symfony/`     | `frameworks/symfony/src/Controller/GameController.php`       | `symfony server:start` |
| Vue           | `frameworks/vue/`         | `frameworks/vue/src/composables/useConnectFour.js`           | `npx vite`            |

A framework app serves HTML rather than the byte-for-byte console protocol, so
frameworks are deliberately **outside** the golden test suite (`tests/`). Each
one carries its own README, and the dashboard's **Frameworks** browse mode
renders it without the console-capture tab.

## Language folders

Every `languages/<id>/` folder carries its own generated documentation:

* **`README.md`** — the implementation in one line, its toolchain, how to install
  that toolchain on Windows/macOS/Debian, the exact build and run commands, the
  skills the implementation exercises, and where its verified output comes from.
* **`banner.svg`** — the skills banner at the top of that README: the language
  name, its toolchain and chips for its category and skills, drawn in the
  dashboard's navy/mint palette. It is self-contained (no web fonts, no scripts,
  no network) so it renders on GitHub, in a preview pane and offline.

Both are written by:

```sh
python tools/generate_language_readmes.py
```

which takes display names and categories from `tools/generate_dashboard.py` and
the build/run commands from `tests/run_tests.py`, so the documented commands
cannot drift from the suite without a warning. Re-run it after adding a language
or changing how one is built, rather than editing the generated files.

## Adding a language

1. Create `languages/<name>/connect_four.<ext>` and implement the protocol
   above exactly.
2. Register it in the `LANGUAGES` list in `tests/run_tests.py`
   (`name`, `source`, `build`, `run`).
3. Run `python tests/run_tests.py` until it passes.
4. Add a row to the language table above, then refresh the generated files:
   * `python tools/generate_dashboard.py` for the showcase data,
   * `python tools/generate_language_readmes.py` for the folder's README and
     banner (add a display entry to `LANGUAGE_INFO` in the dashboard generator
     and a facts entry to `INFO` in the README generator).

See `AGENTS.md` for instructions on automatically installing a language
toolchain that is not yet present on the machine.

## Adding a framework

A framework lives under `frameworks/<name>/` instead of `languages/<name>/`
because an app is many files, not one `connect_four.<ext>`:

1. Create `frameworks/<name>/` with the real project files (model, controller,
   view, routes, and so on).
2. Add an entry to `FRAMEWORK_INFO` in `tools/generate_dashboard.py`: the
   display name, Prism class, category, the one representative `file` to show,
   the `folder` to link on GitHub, and the `note`/`linkText` banner above the
   code (put a `{link}` placeholder where the "view the whole project" link
   goes).
3. Add a `frameworks/<name>/README.md` explaining prerequisites, how to run it
   and the skills it demonstrates.
4. Run `python tools/generate_dashboard.py` and add a row to the Frameworks
   table above.
