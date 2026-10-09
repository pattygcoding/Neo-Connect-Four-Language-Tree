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
  generate_dashboard.py     builds the showcase data
  generate-data.mjs         runs that generator with whichever Python is installed
  generate_language_readmes.py  writes each language's README.md + banner.svg
  serve.py                  local preview server (Pages-style 404.html fallback)
src/                        the showcase dashboard (Vue 3 + TypeScript)
  App.vue                   sidebar + detail panel layout
  components/               sidebar, filters, header and the three views
  store/                    generated data, selection, URL router, theme
  styles/app.css            palette tokens + the Tailwind entry point
public/                     static files copied verbatim into the build
  404.html                  GitHub Pages deep-link fallback for /<language-id>
  CNAME, .nojekyll, logo.png, og-image.png
  dashboard-data.js         generated data consumed by index.html (not tracked)
index.html                  Vite entry: head metadata + the app mount point
package.json                npm scripts: start, build, data, preview
vite.config.ts              build config (+ the preview-page copy step)
tailwind.config.js          the design tokens, as the page's own config
tsconfig.json               TypeScript configuration for src/ and vite.config.ts
.github/workflows/deploy.yml   builds dist/ and publishes it to GitHub Pages
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

`src/` is a Vue 3 + TypeScript app built by Vite: a fully client-side dashboard
(no backend, no live compilers) with a sidebar of every implementation and a main
panel whose tabs are **Source Code**, **Console Output** and — for the one
browser-only implementation — **Play**. It also has a language search box,
category filters, and a selector for which pre-captured console scenario to
display. Build and run it with npm:

```sh
npm start          # regenerate the data, then serve the dashboard on :5173
npm run build      # regenerate the data, type-check, and write dist/
npm run preview    # serve the built dist/ straight from Vite
npm run data       # only regenerate public/dashboard-data.js
npm run typecheck  # vue-tsc --noEmit
```

`npm start` and `npm run build` run the generator first, so the Python command
never has to be remembered: `tools/generate-data.mjs` finds `python3`/`python`
and runs `tools/generate_dashboard.py` for you.

Every implementation has its own address, `/<language-id>` — `/ada`, `/c`,
`/objectivec` — and the sidebar entries are real links, so they can be copied,
bookmarked or opened in a new tab. The site root (`/`, or `index.html` without a
`?lang=`) opens the C# implementation, the reference walkthrough; the id lives
in `DEFAULT_LANG_ID` in `src/store/data.ts`, and a fork that ships without C#
falls back to the first language it does have. The console view carries its
scenario, e.g. `/go?tab=output&scenario=tie`. The router in
`src/store/session.ts` keeps the address in step with the selection (including
browser back/forward) using the History API, and falls back to the query-string
shape whenever the browser refuses path writes. `?lang=`, `?tab=` and
`?scenario=` are read on load in both shapes, so older links — and the ones the
`404.html` shim forwards — keep working.

Above the selected implementation the header links to that folder on GitHub,
labelled `View languages/<id> on GitHub` behind a GitHub mark — its target is
`<repository>/tree/<branch>/<source folder>`, built from the
`repository`/`branch` the generator records (the git remote, else
`GITHUB_REPOSITORY`, else the committed default), so it points at the right
project for a clone or a fork while still reading as a label rather than a URL.

The styling follows the author's portfolio site: a near-black navy canvas, a
pale-mint accent, Inter for text and JetBrains Mono for the small uppercase
tracking-wide labels. Those tokens (the Tailwind `ink`/`mint` palette and the
`.micro` label helper) live in `tailwind.config.js` and `src/styles/app.css`:
Tailwind is pinned at 3.4, the same major the page loaded from the Play CDN
before this rewrite, so the stylesheet is now built instead of compiled in the
browser without the design moving.

Everything it shows is generated from the real repository by:

```sh
npm run data                      # or: python tools/generate_dashboard.py
```

That script scans `languages/*/connect_four.*` and `frameworks/*/` for source and
reuses the verified captures in `tests/expected/` as the console output, then
writes `public/dashboard-data.js`. Because the data is loaded with a `<script>`
tag (not `fetch`) it stays out of the app bundle, needs no CORS, and Vite copies
it into `dist/` unchanged. It is generated, so it is not tracked in git; a
checkout that has not run the generator yet boots and says so instead of failing.

To preview the **built** site the way GitHub Pages serves it:

```sh
npm run build                     # writes dist/
python tools/serve.py             # then open http://localhost:8000/csharp
```

`serve.bat` (Windows) and `./serve.sh` are one-word shortcuts for exactly that
command, so the right server is also the easy one to start.

Use that rather than `python -m http.server`. The dashboard's addresses are
pretty paths (`/csharp`, `/ada`), which are not files, and a bare file server
answers them with its own 404 page — so *refreshing* one of those screens looks
broken locally even though the deployed site is fine. `tools/serve.py` mirrors
GitHub Pages instead: it serves `dist/` and answers an unknown path with the
site's own `404.html` (404 status, shim included), and that shim sends the
browser on to `index.html?lang=<id>`. `npm run preview` serves the same built
files without that fallback, and the dev server rewrites unknown paths to
`index.html` itself, so refreshing a pretty path works under all three.

Any static host serves `dist/` as-is, with no server-side rewrites. One thing
`file://` can no longer do: the app is an ES module bundle, and browsers refuse
to load those from a `file://` document, so open the dev server (or
`tools/serve.py`) instead.

### Deploying to GitHub Pages

The site is a build now, and `.github/workflows/deploy.yml` does all of it. On
every push to `main` it checks out the repository, installs Node 22 and Python,
runs `npm ci` and then `npm run build` — which regenerates the showcase data from
the repository, type-checks the app and writes `dist/` — uploads `dist/` as the
Pages artifact and publishes it. Nothing else to run, and no build output in git:

```powershell
git add -A; git commit -m "Deploy showcase"; git push
```

Watch the run under the repository's **Actions → Deploy showcase to GitHub
Pages**; the update goes live at <https://connectfour.pattygcoding.com/> a minute
or two later. A push that fails to build simply leaves the previous deployment in
place.

Publishing from an artifact needs a one-time setting per repository — Pages
publishing from **GitHub Actions** instead of from a branch:

```sh
gh api -X PUT repos/pattygcoding/Neo-Connect-Four-Language-Tree/pages \
    -f build_type=workflow
```

or **Settings → Pages → Build and deployment → Source: GitHub Actions**. While
the source is still *deploy from a branch*, Pages ignores the artifact and runs
Jekyll over the whole repository instead, so there are two ways for it to look
broken — check this setting first:

* the `deploy-pages` step fails with "Get Pages site failed" (nothing to publish
  to), or
* the workflow goes green and the site still answers with GitHub's generic
  "There isn't a GitHub Pages site here", because the legacy Jekyll build
  *errored* — one unparsable file is enough, and `languages/`/`frameworks/`
  sources do trip it (e.g. "Invalid YAML front matter in
  `frameworks/astro/src/components/ConnectFour.astro`", whose `---` fences read
  as front matter). The failing run is the separate **pages-build-deployment**
  workflow, not this one, which is why a green deploy can still 404.

Everything the artifact needs travels in `public/`, which Vite
copies verbatim into `dist/`: `404.html`, `CNAME`, `.nojekyll`, `logo.png`,
`og-image.png` and the generated `dashboard-data.js`. Third-party libraries
(Prism and the two Google fonts) still load over `https` from CDNs.

The one page that is not a `public/` file is the HTML/CSS implementation: the
Play tab shows `languages/htmlcss/connect_four.html` in an iframe, and
`vite.config.ts` copies that folder to the same path in `dist/`.

The published site lives at **<https://connectfour.pattygcoding.com/>**. A custom
domain is a *repository setting* here, not a file: an artifact-sourced deployment
ignores a `CNAME` in the artifact ("no CNAME file is created, and any existing
CNAME file is ignored and is not required"), so `public/CNAME` is kept only as
documentation. Set the domain on the site itself — with it unset, the subdomain
answers with that same generic 404 even though the content is live:

```sh
gh api -X PUT repos/pattygcoding/Neo-Connect-Four-Language-Tree/pages \
    -f cname=connectfour.pattygcoding.com
```

or **Settings → Pages → Custom domain**. The DNS side is a single record at the
domain's provider:

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

The dashboard adapts to whatever directory it is served from: `base: "./"` keeps
every asset URL relative, and the app derives the deployment prefix at load
(`APP_DIR` in `src/store/session.ts`) and builds every link, `pushState` and
canonical language address from it, so the same build works at
`https://connectfour.pattygcoding.com/csharp` and at
`https://<user>.github.io/<repo>/csharp` with no configuration.

Pages has no rewrite rules, so the tracked `404.html` stands in for them: it is
served for any path it cannot find (with the address bar untouched) and rebuilds
the request as `index.html?lang=<id>` — `/ada`, `/repo/ada` and a tolerated
`/ada/output` all resolve, and the dashboard then puts the pretty `/ada` path back
into the address bar. Anything else (a typo, a missing file) climbs one directory
per attempt, so a junk link cannot redirect in circles and simply ends up on the
default implementation (C#).

Keep `404.html` — now `public/404.html` — **tracked in git**: it is the only
thing that makes refreshing a pretty path (`/csharp`) work on Pages, and without
it GitHub answers the refresh with its own 404 page. `tools/serve.py` reproduces
that behaviour locally (it serves `dist/`, so run `npm run build` first), which
means a refresh test there means something.

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
| D          | `languages/d/connect_four.d`           | `dmd`             |
| Dart       | `languages/dart/connect_four.dart`     | `dart`            |
| Elm        | `languages/elm/connect_four.elm`       | `elm` + `node`    |
| Elixir     | `languages/elixir/connect_four.ex`     | `elixir`          |
| Erlang     | `languages/erlang/connect_four.erl`    | `erlc` + `erl`    |
| F#         | `languages/fsharp/connect_four.fs`     | `dotnet` (.NET 8) |
| Fortran    | `languages/fortran/connect_four.f90`   | `gfortran`        |
| Go         | `languages/go/connect_four.go`         | `go`              |
| Groovy     | `languages/groovy/connect_four.groovy` | `groovy`          |
| Haskell    | `languages/haskell/connect_four.hs`    | `ghc`             |
| Haxe       | `languages/haxe/connect_four.hx`       | `haxe`            |
| HTML/CSS   | `languages/htmlcss/connect_four.html`  | browser (no build) |
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
| Tiger (Custom) | `languages/tiger/connect_four.tg`  | `tiger` (Go)      |
| TypeScript | `languages/typescript/connect_four.ts` | `tsc` + `node`    |
| V          | `languages/v/connect_four.v`           | `v`               |
| VB.NET     | `languages/vb/connect_four.vb`         | `dotnet` (.NET 8) |
| Zig        | `languages/zig/connect_four.zig`       | `zig` (LLVM)      |

**HTML/CSS is the one language here that is not a console program.** A web page
cannot read stdin or print the golden stdout, so `languages/htmlcss/` is
deliberately left out of the byte-for-byte suite (`tests/run_tests.py`). It is a
single, self-contained page with **red and yellow discs**: open it in any browser,
or use the dashboard's **Play** tab, which runs the page in an iframe so you can
play it right there.

**Tiger (Custom) is a custom programming language written in Go** by Patrick
Goodwin: a dynamically typed, tree-walking interpreter with Python-like
expressions, brace-delimited scopes, f-strings and C-style `cif`/`cfor`. It is a
full console implementation and passes the same byte-for-byte suite as every
other language. Try it in the browser at
[Tiger Language - Patrick Goodwin](https://www.pattygcoding.com/tiger); the
source is at
[pattygcoding/Tiger-Programming-Language](https://github.com/pattygcoding/Tiger-Programming-Language).
The runner uses `tiger` from `PATH`, or else `bin/tiger` in a sibling
`Tiger-Programming-Language` checkout (build it with
`go build -o bin/tiger ./cmd/tiger`).

The test runner compiles everything for you and skips rebuilds when nothing
changed. To play a compiled implementation directly, use the artifact under
`tests/build/` (e.g. `dotnet tests/build/csharp/connect_four.dll`,
`java -jar tests/build/connect_four_kotlin.jar`,
`node tests/build/ts/connect_four.js`); scripting languages run from source
(`python`, `node`, `ruby`, `lua`). Avoid `dotnet run`, which recompiles on
every launch — the built `.dll` starts in well under 0.1s.

## Frameworks

Not every showcase here is a single console program. The `frameworks/` tree
holds a richer, multi-file project built in a real framework; the dashboard
shows **one representative file** from each and links the whole project on
GitHub, with a note above the code explaining just that.

| Framework     | Project                   | Representative file                                           | Run                   |
|---------------|---------------------------|--------------------------------------------------------------|-----------------------|
| .NET MAUI     | `frameworks/maui/`        | `frameworks/maui/MainPage.xaml.cs`                           | `dotnet build -t:Run` |
| AdonisJS      | `frameworks/adonisjs/`    | `frameworks/adonisjs/app/controllers/games_controller.ts`    | `node ace serve`      |
| Alpine.js     | `frameworks/alpinejs/`    | `frameworks/alpinejs/index.html`                             | `npx serve .`         |
| Angular       | `frameworks/angular/`     | `frameworks/angular/src/app/connect-four/connect-four.component.ts` | `ng serve`      |
| ASP.NET Core  | `frameworks/aspnetcore/`  | `frameworks/aspnetcore/Controllers/GameController.cs`        | `dotnet run`          |
| Astro         | `frameworks/astro/`       | `frameworks/astro/src/lib/board.ts`                          | `npm run dev`         |
| Avalonia      | `frameworks/avalonia/`    | `frameworks/avalonia/MainWindow.axaml.cs`                    | `dotnet run`          |
| Axum          | `frameworks/axum/`        | `frameworks/axum/src/main.rs`                                | `cargo run`           |
| Blazor        | `frameworks/blazor/`      | `frameworks/blazor/Components/Pages/ConnectFour.razor`       | `dotnet run`          |
| Bootstrap     | `frameworks/bootstrap/`   | `frameworks/bootstrap/index.html`                            | `npx serve .`         |
| Cassandra     | `frameworks/cassandra/`   | `frameworks/cassandra/schema.cql`                            | `cqlsh -f schema.cql` |
| ClickHouse    | `frameworks/clickhouse/`  | `frameworks/clickhouse/schema.sql`                           | `clickhouse-client < schema.sql` |
| Django        | `frameworks/django/`      | `frameworks/django/game/views.py`                            | `manage.py runserver` |
| DuckDB        | `frameworks/duckdb/`      | `frameworks/duckdb/schema.sql`                               | `duckdb < schema.sql` |
| Echo (Go)     | `frameworks/echo/`        | `frameworks/echo/main.go`                                    | `go run .`            |
| Electron      | `frameworks/electron/`    | `frameworks/electron/main.js`                                | `npm start`           |
| Ember.js      | `frameworks/ember/`       | `frameworks/ember/app/components/connect-four.js`            | `npm start`           |
| Express (Node) | `frameworks/expressjs/`  | `frameworks/expressjs/app.ts`                                | `npm start`           |
| FastAPI       | `frameworks/fastapi/`     | `frameworks/fastapi/app/main.py`                             | `fastapi dev`         |
| Fastify       | `frameworks/fastify/`     | `frameworks/fastify/app.js`                                  | `node app.js`         |
| Fiber         | `frameworks/fiber/`       | `frameworks/fiber/main.go`                                   | `go run .`            |
| Firebird      | `frameworks/firebird/`    | `frameworks/firebird/schema.sql`                             | `isql < schema.sql`   |
| Flask         | `frameworks/flask/`       | `frameworks/flask/app.py`                                    | `flask --app app run` |
| Flutter       | `frameworks/flutter/`     | `frameworks/flutter/lib/connect_four.dart`                   | `flutter run`         |
| Fyne          | `frameworks/fyne/`        | `frameworks/fyne/main.go`                                    | `go run .`            |
| Gin           | `frameworks/gin/`         | `frameworks/gin/main.go`                                     | `go run .`            |
| Gradle        | `frameworks/gradle/`      | `frameworks/gradle/build.gradle.kts`                         | `gradle test`         |
| GraphQL       | `frameworks/graphql/`     | `frameworks/graphql/schema.graphql`                          | `python server.py`    |
| Handlebars    | `frameworks/handlebars/`  | `frameworks/handlebars/templates/board.hbs`                  | `npm start`           |
| HTMX          | `frameworks/htmx/`        | `frameworks/htmx/server.js`                                  | `node server.js`      |
| IBM Db2       | `frameworks/db2/`         | `frameworks/db2/schema.sql`                                  | `db2 -tvf schema.sql` |
| Ionic         | `frameworks/ionic/`       | `frameworks/ionic/src/app/connect-four/connect-four.page.ts` | `ionic serve`         |
| JavaFX        | `frameworks/javafx/`      | `frameworks/javafx/src/main/java/com/example/connectfour/ConnectFourApp.java` | `mvn javafx:run` |
| Jetpack Compose | `frameworks/jetpackcompose/` | `frameworks/jetpackcompose/app/src/main/java/com/example/connectfour/MainActivity.kt` | `gradle installDebug` |
| jQuery        | `frameworks/jquery/`      | `frameworks/jquery/app.js`                                   | `npx serve .`         |
| JSON          | `frameworks/json/`        | `frameworks/json/connect_four.json`                          | `python play.py`      |
| Koa           | `frameworks/koa/`         | `frameworks/koa/app.js`                                      | `npm start`           |
| Ktor          | `frameworks/ktor/`        | `frameworks/ktor/src/main/kotlin/com/example/connectfour/Application.kt` | `gradle run` |
| LangChain     | `frameworks/langchain/`   | `frameworks/langchain/coach.py`                              | `python app.py`       |
| Laravel       | `frameworks/laravel/`     | `frameworks/laravel/app/Http/Controllers/GameController.php` | `php artisan serve`   |
| Lit           | `frameworks/lit/`         | `frameworks/lit/src/connect-four.ts`                         | `npm run dev`         |
| MariaDB       | `frameworks/mariadb/`     | `frameworks/mariadb/schema.sql`                              | `mariadb < schema.sql` |
| Maven         | `frameworks/maven/`       | `frameworks/maven/pom.xml`                                   | `mvn test`            |
| Minimax AI    | `frameworks/minimax/`     | `frameworks/minimax/minimax.py`                              | `python play.py`      |
| MongoDB (NoSQL) | `frameworks/mongodb/`   | `frameworks/mongodb/schema.js`                               | `mongosh --file schema.js` |
| MySQL         | `frameworks/mysql/`       | `frameworks/mysql/schema.sql`                                | `mysql < schema.sql`  |
| NestJS        | `frameworks/nestjs/`      | `frameworks/nestjs/src/game/game.controller.ts`              | `ts-node src/main.ts` |
| Next.js       | `frameworks/nextjs/`      | `frameworks/nextjs/app/page.jsx`                             | `npm run dev`         |
| Nuxt          | `frameworks/nuxt/`        | `frameworks/nuxt/composables/useConnectFour.js`              | `npm run dev`         |
| Ollama        | `frameworks/ollama/`      | `frameworks/ollama/app.py`                                   | `python app.py`       |
| Oracle Database | `frameworks/oracle/`    | `frameworks/oracle/schema.sql`                               | `sqlplus @schema.sql` |
| Oracle PL/SQL | `frameworks/plsql/`       | `frameworks/plsql/packages.sql`                              | `sqlplus @packages.sql` |
| Phoenix       | `frameworks/phoenix/`     | `frameworks/phoenix/lib/connect_four_web/controllers/game_controller.ex` | `mix phx.server` |
| Play Framework | `frameworks/playframework/` | `frameworks/playframework/app/controllers/GameController.scala` | `sbt run`          |
| Playwright    | `frameworks/playwright/`  | `frameworks/playwright/tests/connect-four.spec.ts`           | `npx playwright test` |
| PostgreSQL    | `frameworks/postgresql/`  | `frameworks/postgresql/schema.sql`                           | `psql < schema.sql`   |
| Preact        | `frameworks/preact/`      | `frameworks/preact/src/connect-four.jsx`                     | `npm run dev`         |
| Prisma        | `frameworks/prisma/`      | `frameworks/prisma/src/gameService.ts`                       | `prisma studio`       |
| PySide6 (Qt)  | `frameworks/pyside6/`     | `frameworks/pyside6/main.py`                                 | `python main.py`      |
| Quarkus       | `frameworks/quarkus/`     | `frameworks/quarkus/src/main/java/com/example/connectfour/GameResource.java` | `mvn quarkus:dev` |
| QuestDB       | `frameworks/questdb/`     | `frameworks/questdb/schema.sql`                              | Web Console           |
| Qwik          | `frameworks/qwik/`        | `frameworks/qwik/src/routes/index.tsx`                       | `npm run dev`         |
| React         | `frameworks/react/`       | `frameworks/react/src/ConnectFour.jsx`                       | `npx vite`            |
| React Bootstrap | `frameworks/reactbootstrap/` | `frameworks/reactbootstrap/src/ConnectFour.jsx`          | `npm run dev`         |
| React Native  | `frameworks/reactnative/` | `frameworks/reactnative/src/ConnectFour.jsx`                 | `npx expo start`      |
| Redis         | `frameworks/redis/`       | `frameworks/redis/app.py`                                    | `python app.py`       |
| Redux Toolkit | `frameworks/redux/`       | `frameworks/redux/src/features/game/gameSlice.js`            | `npm run dev`         |
| Remix (React Router) | `frameworks/remix/` | `frameworks/remix/app/routes/home.tsx`                       | `npm run dev`         |
| Ruby on Rails | `frameworks/rubyonrails/` | `frameworks/rubyonrails/app/controllers/games_controller.rb` | `bin/rails server`    |
| Sanic         | `frameworks/sanic/`       | `frameworks/sanic/app.py`                                    | `python app.py`       |
| SCSS          | `frameworks/scss/`        | `frameworks/scss/scss/main.scss`                             | `npm run build`       |
| Selenium      | `frameworks/selenium/`    | `frameworks/selenium/tests/test_connect_four.py`             | `pytest`              |
| SolidJS       | `frameworks/solidjs/`     | `frameworks/solidjs/src/ConnectFour.jsx`                     | `npm run dev`         |
| Spring Boot   | `frameworks/springboot/`  | `frameworks/springboot/src/main/java/com/example/connectfour/GameController.java` | `mvn spring-boot:run` |
| SQLite        | `frameworks/sqlite/`      | `frameworks/sqlite/schema.sql`                               | `sqlite3 < schema.sql` |
| Svelte        | `frameworks/svelte/`      | `frameworks/svelte/src/lib/store.js`                         | `npx vite`            |
| SwiftUI       | `frameworks/swiftui/`     | `frameworks/swiftui/Sources/ConnectFour/ContentView.swift`   | Xcode Run             |
| Symfony       | `frameworks/symfony/`     | `frameworks/symfony/src/Controller/GameController.php`       | `symfony server:start` |
| SurrealDB     | `frameworks/surrealdb/`   | `frameworks/surrealdb/schema.surql`                          | `surreal import`      |
| Tailwind CSS  | `frameworks/tailwindcss/` | `frameworks/tailwindcss/index.html`                          | `npm run build`       |
| TanStack Query | `frameworks/tanstackquery/` | `frameworks/tanstackquery/src/ConnectFour.jsx`             | `npm run server`      |
| Tauri         | `frameworks/tauri/`       | `frameworks/tauri/src-tauri/src/main.rs`                     | `npm run dev`         |
| Tkinter (Python) | `frameworks/tkinter/`  | `frameworks/tkinter/app.py`                                  | `python app.py`       |
| tRPC          | `frameworks/trpc/`        | `frameworks/trpc/server/router.ts`                           | `npm run server`      |
| T-SQL         | `frameworks/tsql/`        | `frameworks/tsql/schema.sql`                                 | `sqlcmd -i schema.sql` |
| Vapor         | `frameworks/vapor/`       | `frameworks/vapor/Sources/App/routes.swift`                  | `swift run`           |
| WPF (C#)      | `frameworks/wpf/`         | `frameworks/wpf/MainWindow.xaml.cs`                          | `dotnet run`          |
| WPF (VB.NET)  | `frameworks/wpfvb/`       | `frameworks/wpfvb/MainWindow.xaml.vb`                        | `dotnet run`          |
| Vue           | `frameworks/vue/`         | `frameworks/vue/src/composables/useConnectFour.js`           | `npx vite`            |
| Vue Bootstrap | `frameworks/vuebootstrap/` | `frameworks/vuebootstrap/src/composables/useConnectFour.js` | `npm run dev`        |

A framework app renders its own UI — HTML, mobile or desktop widgets — rather
than the byte-for-byte console protocol, so frameworks are deliberately
**outside** the golden test suite (`tests/`). Each one carries its own README,
and the dashboard's **Frameworks** browse mode renders it without the
console-capture tab.

Inside that mode the sidebar carries three facets - **Category**, **Stack** and
**Language**. Stack splits the Web tree into Frontend, Backend and Full stack;
Language filters by the programming language a framework is written in, so
picking C# pulls up Blazor, .NET MAUI, ASP.NET Core, Avalonia and WPF together.
Both extra facets appear only in Frameworks mode. Stacks show as short badges
(**FE** / **BE** / **FS**, spelled out in the dropdown) and languages as blue
file-extension tags (`.ts`, `.cs`, `.py`) on each framework's sidebar row, so
Blazor reads "Web · FS · .cs" at a glance.

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
   * `npm run data` (or `python tools/generate_dashboard.py`) for the showcase
     data. CI runs this on every push too, so a forgotten local run only means a
     stale local dev server, never a stale deployment.
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
3. Fill in the two facets the Frameworks filters read:
   * `FRAMEWORK_STACKS` - `Frontend`, `Backend` or `Full stack`, for a **Web**
     framework. The Stack chips list only the values that are present, and a
     framework without one is simply left out of that facet.
   * `FRAMEWORK_LANGUAGES` - the language(s) the app is written in, e.g.
     `["C#"]` or `["JavaScript", "Rust"]`. This is what the Language chips
     filter on, so C# pulls up Blazor, ASP.NET Core and the rest.
4. Add a `frameworks/<name>/README.md` explaining prerequisites, how to run it
   and the skills it demonstrates.
5. Add a banner: a facts entry to `FRAMEWORK_BANNERS` in
   `tools/generate_language_readmes.py`, then run
   `python tools/generate_language_readmes.py`.
6. Run `python tools/generate_dashboard.py` and add a row to the Frameworks
   table above.
