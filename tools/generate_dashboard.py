#!/usr/bin/env python3
"""Generate the static showcase dashboard.

This script reads the *real* repository contents and writes
``public/dashboard-data.js`` - the file the dashboard loads with a ``<script>``
tag, so ``npm run build`` copies it into the published site untouched:

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
# The Vue app loads this with a classic <script> tag, so it has to sit beside the
# built ``index.html``.  Vite copies ``public/`` verbatim into ``dist/``, which is
# also what the dev server serves at the site root - hence ``public/`` and not the
# repository root.  It is generated, never hand-edited, and not tracked in git.
OUTPUT_FILE = ROOT / "public" / "dashboard-data.js"

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
    "csharp": ("C#", "language-csharp", ".NET"),
    "d": ("D", "language-d", "Systems"),
    "dart": ("Dart", "language-dart", "Web"),
    "elixir": ("Elixir", "language-elixir", "Functional"),
    "erlang": ("Erlang", "language-erlang", "Functional"),
    "fortran": ("Fortran", "language-fortran", "Scientific"),
    "fsharp": ("F#", "language-fsharp", ".NET"),
    "go": ("Go", "language-go", "Systems"),
    "groovy": ("Groovy", "language-groovy", "JVM"),
    "haskell": ("Haskell", "language-haskell", "Functional"),
    "haxe": ("Haxe", "language-haxe", "Systems"),
    "htmlcss": ("HTML/CSS", "language-markup", "Web"),
    "java": ("Java", "language-java", "JVM"),
    "javascript": ("JavaScript", "language-javascript", "Web"),
    "julia": ("Julia", "language-julia", "Scientific"),
    "kotlin": ("Kotlin", "language-kotlin", "JVM"),
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
    "scala": ("Scala", "language-scala", "JVM"),
    "scheme": ("Scheme", "language-scheme", "Functional"),
    "sql": ("SQL", "language-sql", "Data"),
    "swift": ("Swift", "language-swift", "Systems"),
    "tiger": ("Tiger (Custom)", "language-javascript", "Custom"),
    "typescript": ("TypeScript", "language-typescript", "Web"),
    "v": ("V", "language-v", "Systems"),
    "vb": ("Visual Basic", "language-vbnet", ".NET"),
    "zig": ("Zig", "language-zig", "Systems"),
}

# Languages that are not console programs at all.  HTML/CSS lives in
# ``languages/`` like the others, but a browser page cannot read stdin or print
# the golden stdout, so it is deliberately **not** in ``tests/run_tests.py`` and
# the dashboard gives it no console capture.  Instead it shows the file plus a
# live, playable preview (``preview``, loaded in an iframe).  Keys are directory
# names; ``folder`` defaults to ``languages/<id>``.
INTERACTIVE_LANGUAGES = {
    "htmlcss": {
        "note": "HTML/CSS is not a console program, so it is not part of the "
                "byte-for-byte suite. This one page holds the markup, the styles "
                "and a little JavaScript - open the Play tab to drop red and "
                "yellow discs. See {link} to read the file on GitHub.",
        "linkText": "the HTML/CSS implementation on GitHub",
        "preview": "languages/htmlcss/connect_four.html",
    },
}

# Console languages that still carry a banner above their code.  ``note`` may use
# ``{name}`` placeholders that the dashboard turns into anchors from ``noteLinks``.
LANGUAGE_NOTES = {
    "tiger": {
        "note": "Tiger is a custom programming language written in Go by Patrick "
                "Goodwin: a dynamically typed, tree-walking interpreter with "
                "Python-like expressions, brace-delimited scopes, f-strings and "
                "C-style cfor/cif. It passes the same byte-for-byte suite as every "
                "other language here. Try it in the {demo}, or read the source at "
                "{repo}.",
        "noteLinks": {
            "demo": {
                "text": "Tiger Language demo",
                "href": "https://www.pattygcoding.com/tiger",
            },
            "repo": {
                "text": "pattygcoding/Tiger-Programming-Language",
                "href": "https://github.com/pattygcoding/Tiger-Programming-Language",
            },
        },
    },
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
# (.NET MAUI, Ruby on Rails, Django, Express, FastAPI, Fastify, Fiber, Flask, Flutter, Gin, Laravel, NestJS, Next.js, Nuxt, Phoenix, React, React Native, Angular, Vue, Svelte, Symfony, Spring Boot, Blazor, ASP.NET Core, and more).  A framework lives in
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
    "maui": {
        "name": ".NET MAUI",
        "prism": "language-csharp",
        "category": "Mobile",
        "file": "MainPage.xaml.cs",
        "folder": "frameworks/maui",
        "note": "This is one representative file from the app - the page code-behind "
                "(Prism has no XAML grammar, so MainPage.xaml is not shown here). "
                "See {link} to browse the XAML view, board logic and the rest of "
                "the project.",
        "linkText": "the full .NET MAUI app on GitHub",
    },
    "angular": {
        "name": "Angular",
        "prism": "language-typescript",
        "category": "Web",
        "file": "src/app/connect-four/connect-four.component.ts",
        "folder": "frameworks/angular",
        "note": "This is one representative file from the app. See {link} to "
                "browse the board logic, template and the rest of the project.",
        "linkText": "the full Angular app on GitHub",
    },
    "aspnetcore": {
        "name": "ASP.NET Core",
        "prism": "language-csharp",
        "category": "Web",
        "file": "Controllers/GameController.cs",
        "folder": "frameworks/aspnetcore",
        "note": "This is one representative file from the app. See {link} to "
                "browse the board model, Razor view, host setup and the rest of the project.",
        "linkText": "the full ASP.NET Core app on GitHub",
    },
    "blazor": {
        "name": "Blazor",
        "prism": "language-cshtml",
        "category": "Web",
        "file": "Components/Pages/ConnectFour.razor",
        "folder": "frameworks/blazor",
        "note": "This is one representative file from the app. See {link} to "
                "browse the board logic and the rest of the project.",
        "linkText": "the full Blazor app on GitHub",
    },
    "django": {
        "name": "Django",
        "prism": "language-python",
        "category": "Web",
        "file": "game/views.py",
        "folder": "frameworks/django",
        "note": "This is one representative file from the app. See {link} to "
                "browse the board, forms, URLs, templates and the rest of the project.",
        "linkText": "the full Django app on GitHub",
    },
    "expressjs": {
        "name": "Express (Node)",
        "prism": "language-typescript",
        "category": "Web",
        "file": "app.ts",
        "folder": "frameworks/expressjs",
        "note": "This is one representative file from the app. See {link} to "
                "browse the board logic, EJS view and the rest of the project.",
        "linkText": "the full Express (Node) app on GitHub",
    },
    "fastapi": {
        "name": "FastAPI",
        "prism": "language-python",
        "category": "Web",
        "file": "app/main.py",
        "folder": "frameworks/fastapi",
        "note": "This is one representative file from the app. See {link} to "
                "browse the board, schemas, templates and the rest of the project.",
        "linkText": "the full FastAPI app on GitHub",
    },
    "fastify": {
        "name": "Fastify",
        "prism": "language-javascript",
        "category": "Web",
        "file": "app.js",
        "folder": "frameworks/fastify",
        "note": "This is one representative file from the app. See {link} to "
                "browse the board logic, EJS view and the rest of the project.",
        "linkText": "the full Fastify app on GitHub",
    },
    "fiber": {
        "name": "Fiber",
        "prism": "language-go",
        "category": "Web",
        "file": "main.go",
        "folder": "frameworks/fiber",
        "note": "This is one representative file from the app. See {link} to "
                "browse the board, templates and the rest of the project.",
        "linkText": "the full Fiber app on GitHub",
    },
    "flask": {
        "name": "Flask",
        "prism": "language-python",
        "category": "Web",
        "file": "app.py",
        "folder": "frameworks/flask",
        "note": "This is one representative file from the app. See {link} to "
                "browse the board, template and the rest of the project.",
        "linkText": "the full Flask app on GitHub",
    },
    "flutter": {
        "name": "Flutter",
        "prism": "language-dart",
        "category": "Mobile",
        "file": "lib/connect_four.dart",
        "folder": "frameworks/flutter",
        "note": "This is one representative file from the app. See {link} to "
                "browse the app entry, board logic and the rest of the project.",
        "linkText": "the full Flutter app on GitHub",
    },
    "fyne": {
        "name": "Fyne",
        "prism": "language-go",
        "category": "Desktop",
        "file": "main.go",
        "folder": "frameworks/fyne",
        "note": "This is one representative file from the app - Fyne is a "
                "cross-platform desktop GUI toolkit, so it opens a native "
                "window instead of serving HTML (Prism has no Fyne grammar, so "
                "this is plain Go). See {link} to browse the board logic and "
                "the rest of the project.",
        "linkText": "the full Fyne app on GitHub",
    },
    "gin": {
        "name": "Gin",
        "prism": "language-go",
        "category": "Web",
        "file": "main.go",
        "folder": "frameworks/gin",
        "note": "This is one representative file from the app. See {link} to "
                "browse the board, templates and the rest of the project.",
        "linkText": "the full Gin app on GitHub",
    },
    "graphql": {
        "name": "GraphQL",
        "prism": "language-graphql",
        "category": "API",
        "file": "schema.graphql",
        "folder": "frameworks/graphql",
        "note": "This is the representative file - a GraphQL schema (a Board type "
                "with Query and Mutation operations), with a Python resolver "
                "server and example operations beside it. See {link} to browse "
                "the resolvers and the rest of the example.",
        "linkText": "the full GraphQL example on GitHub",
    },
    "json": {
        "name": "JSON",
        "prism": "language-json",
        "category": "Data",
        "file": "connect_four.json",
        "folder": "frameworks/json",
        "note": "This is the representative file - a data-first Connect Four whose "
                "board and scripted moves live in JSON, played by a small Python "
                "loader. See {link} to browse the loader and the rest of the "
                "example.",
        "linkText": "the JSON example on GitHub",
    },
    "laravel": {
        "name": "Laravel",
        "prism": "language-php",
        "category": "Web",
        "file": "app/Http/Controllers/GameController.php",
        "folder": "frameworks/laravel",
        "note": "This is one representative file from the app. See {link} to "
                "browse the board, routes, Blade view and the rest of the project.",
        "linkText": "the full Laravel app on GitHub",
    },
    "minimax": {
        "name": "Minimax AI",
        "prism": "language-python",
        "category": "AI",
        "file": "minimax.py",
        "folder": "frameworks/minimax",
        "note": "This is the representative file - a minimax search with alpha-beta "
                "pruning that plays Connect Four, with the board rules and a "
                "self-play driver beside it. See {link} to browse the board, the "
                "player and the rest of the example.",
        "linkText": "the full Minimax AI app on GitHub",
    },
    "mongodb": {
        "name": "MongoDB (NoSQL)",
        "prism": "language-javascript",
        "category": "Database",
        "file": "schema.js",
        "folder": "frameworks/mongodb",
        "note": "This is the representative file - a MongoDB collection whose moves "
                "are embedded in each game document, validated with a $jsonSchema, "
                "with a seed game and aggregation pipelines beside it. See {link} to "
                "browse the seed data, the queries and the rest of the example.",
        "linkText": "the MongoDB example on GitHub",
    },
    "mysql": {
        "name": "MySQL",
        "prism": "language-sql",
        "category": "Database",
        "file": "schema.sql",
        "folder": "frameworks/mysql",
        "note": "This is the representative file - a Connect Four schema (a games "
                "table, a moves table and a board view) with a seed game and "
                "window-function queries beside it. See {link} to browse the seed "
                "data, the queries and the rest of the example.",
        "linkText": "the MySQL example on GitHub",
    },
    "nestjs": {
        "name": "NestJS",
        "prism": "language-typescript",
        "category": "Web",
        "file": "src/game/game.controller.ts",
        "folder": "frameworks/nestjs",
        "note": "This is one representative file from the app (a JSON REST API, so "
                "there is no HTML view). See {link} to browse the service, board "
                "logic, modules and the rest of the project.",
        "linkText": "the full NestJS app on GitHub",
    },
    "nextjs": {
        "name": "Next.js",
        "prism": "language-jsx",
        "category": "Web",
        "file": "app/page.jsx",
        "folder": "frameworks/nextjs",
        "note": "This is one representative file from the app. See {link} to "
                "browse the layout, board logic and the rest of the project.",
        "linkText": "the full Next.js app on GitHub",
    },
    "nuxt": {
        "name": "Nuxt",
        "prism": "language-javascript",
        "category": "Web",
        "file": "composables/useConnectFour.js",
        "folder": "frameworks/nuxt",
        "note": "This is one representative file from the app - the composable "
                "(Prism has no Vue grammar, so the .vue files are not shown "
                "here). See {link} to browse the page, board logic and the rest "
                "of the project.",
        "linkText": "the full Nuxt app on GitHub",
    },
    "phoenix": {
        "name": "Phoenix",
        "prism": "language-elixir",
        "category": "Web",
        "file": "lib/connect_four_web/controllers/game_controller.ex",
        "folder": "frameworks/phoenix",
        "note": "This is one representative file from the app. See {link} to "
                "browse the game engine, router, HEEx template and the rest of the project.",
        "linkText": "the full Phoenix app on GitHub",
    },
    "react": {
        "name": "React",
        "prism": "language-jsx",
        "category": "Web",
        "file": "src/ConnectFour.jsx",
        "folder": "frameworks/react",
        "note": "This is one representative file from the app. See {link} to "
                "browse the board logic, entry point and the rest of the project.",
        "linkText": "the full React app on GitHub",
    },
    "reactnative": {
        "name": "React Native",
        "prism": "language-jsx",
        "category": "Mobile",
        "file": "src/ConnectFour.jsx",
        "folder": "frameworks/reactnative",
        "note": "This is one representative file from the app. See {link} to "
                "browse the app entry, board logic and the rest of the project.",
        "linkText": "the full React Native app on GitHub",
    },
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
    "springboot": {
        "name": "Spring Boot",
        "prism": "language-java",
        "category": "Web",
        "file": "src/main/java/com/example/connectfour/GameController.java",
        "folder": "frameworks/springboot",
        "note": "This is one representative file from the app. See {link} to "
                "browse the board, application entry point, Thymeleaf template "
                "and the rest of the project.",
        "linkText": "the full Spring Boot app on GitHub",
    },
    "svelte": {
        "name": "Svelte",
        "prism": "language-javascript",
        "category": "Web",
        "file": "src/lib/store.js",
        "folder": "frameworks/svelte",
        "note": "This is one representative file from the app - the Svelte stores "
                "(Prism has no Svelte grammar, so the .svelte file is not shown "
                "here). See {link} to browse the component, board logic and the "
                "rest of the project.",
        "linkText": "the full Svelte app on GitHub",
    },
    "symfony": {
        "name": "Symfony",
        "prism": "language-php",
        "category": "Web",
        "file": "src/Controller/GameController.php",
        "folder": "frameworks/symfony",
        "note": "This is one representative file from the app. See {link} to "
                "browse the board, Twig template, routes and the rest of the project.",
        "linkText": "the full Symfony app on GitHub",
    },
    "tkinter": {
        "name": "Tkinter (Python)",
        "prism": "language-python",
        "category": "Desktop",
        "file": "app.py",
        "folder": "frameworks/tkinter",
        "note": "This is the representative file - a Tkinter window that draws the "
                "board on a Canvas and drops red and yellow discs, with the game "
                "rules beside it. See {link} to browse the board and the rest of "
                "the example.",
        "linkText": "the full Tkinter app on GitHub",
    },
    "wpf": {
        "name": "WPF (C#)",
        "prism": "language-csharp",
        "category": "Desktop",
        "file": "MainWindow.xaml.cs",
        "folder": "frameworks/wpf",
        "note": "This is the representative file - the code-behind of a WPF window "
                "(Prism has no XAML grammar, so MainWindow.xaml is not shown here). "
                "See {link} to browse the XAML view, board logic and the rest of "
                "the project.",
        "linkText": "the full WPF (C#) app on GitHub",
    },
    "wpfvb": {
        "name": "WPF (VB.NET)",
        "prism": "language-vbnet",
        "category": "Desktop",
        "file": "MainWindow.xaml.vb",
        "folder": "frameworks/wpfvb",
        "note": "This is the representative file - the VB.NET code-behind of a WPF "
                "window (Prism has no XAML grammar, so MainWindow.xaml is not shown "
                "here). See {link} to browse the XAML view, board logic and the "
                "rest of the project.",
        "linkText": "the full WPF (VB.NET) app on GitHub",
    },
    "vue": {
        "name": "Vue",
        "prism": "language-javascript",
        "category": "Web",
        "file": "src/composables/useConnectFour.js",
        "folder": "frameworks/vue",
        "note": "This is one representative file from the app - the Composition API "
                "composable (Prism has no Vue grammar, so the .vue file is not shown "
                "here). See {link} to browse the single-file component, board logic "
                "and the rest of the project.",
        "linkText": "the full Vue app on GitHub",
    },
    "adonisjs": {
        "name": "AdonisJS",
        "prism": "language-typescript",
        "category": "Web",
        "file": "app/controllers/games_controller.ts",
        "folder": "frameworks/adonisjs",
        "note": "This is one representative file from the app. See {link} to "
                "browse the board service, routes, Edge view and the rest of the project.",
        "linkText": "the full AdonisJS app on GitHub",
    },
    "alpinejs": {
        "name": "Alpine.js",
        "prism": "language-markup",
        "category": "Web",
        "file": "index.html",
        "folder": "frameworks/alpinejs",
        "note": "This is one representative file from the app. See {link} to "
                "browse the Alpine component and the rest of the project.",
        "linkText": "the full Alpine.js app on GitHub",
    },
    "astro": {
        "name": "Astro",
        "prism": "language-typescript",
        "category": "Web",
        "file": "src/lib/board.ts",
        "folder": "frameworks/astro",
        "note": "This is one representative file from the app - the typed board "
                "module (Prism has no Astro grammar, so the .astro files are not "
                "shown here). See {link} to browse the component, page and the rest "
                "of the project.",
        "linkText": "the full Astro app on GitHub",
    },
    "avalonia": {
        "name": "Avalonia",
        "prism": "language-csharp",
        "category": "Desktop",
        "file": "MainWindow.axaml.cs",
        "folder": "frameworks/avalonia",
        "note": "This is one representative file from the app - the code-behind "
                "(Prism has no AXAML grammar, so MainWindow.axaml is not shown "
                "here). See {link} to browse the XAML view, board logic and the rest "
                "of the project.",
        "linkText": "the full Avalonia app on GitHub",
    },
    "axum": {
        "name": "Axum",
        "prism": "language-rust",
        "category": "Web",
        "file": "src/main.rs",
        "folder": "frameworks/axum",
        "note": "This is one representative file from the app. See {link} to "
                "browse the board, MiniJinja template and the rest of the project.",
        "linkText": "the full Axum app on GitHub",
    },
    "echo": {
        "name": "Echo (Go)",
        "prism": "language-go",
        "category": "Web",
        "file": "main.go",
        "folder": "frameworks/echo",
        "note": "This is one representative file from the app. See {link} to "
                "browse the board package, template and the rest of the project.",
        "linkText": "the full Echo app on GitHub",
    },
    "electron": {
        "name": "Electron",
        "prism": "language-javascript",
        "category": "Desktop",
        "file": "main.js",
        "folder": "frameworks/electron",
        "note": "This is one representative file from the app - the main process. "
                "See {link} to browse the preload script, renderer and the rest of "
                "the project.",
        "linkText": "the full Electron app on GitHub",
    },
    "htmx": {
        "name": "HTMX",
        "prism": "language-javascript",
        "category": "Web",
        "file": "server.js",
        "folder": "frameworks/htmx",
        "note": "This is one representative file from the app - the server that "
                "returns htmx fragments. See {link} to browse the board and the rest "
                "of the project.",
        "linkText": "the full htmx app on GitHub",
    },
    "ionic": {
        "name": "Ionic",
        "prism": "language-typescript",
        "category": "Mobile",
        "file": "src/app/connect-four/connect-four.page.ts",
        "folder": "frameworks/ionic",
        "note": "This is one representative file from the app. See {link} to "
                "browse the template, board logic and the rest of the project.",
        "linkText": "the full Ionic app on GitHub",
    },
    "javafx": {
        "name": "JavaFX",
        "prism": "language-java",
        "category": "Desktop",
        "file": "src/main/java/com/example/connectfour/ConnectFourApp.java",
        "folder": "frameworks/javafx",
        "note": "This is one representative file from the app. See {link} to "
                "browse the board and the rest of the project.",
        "linkText": "the full JavaFX app on GitHub",
    },
    "jetpackcompose": {
        "name": "Jetpack Compose",
        "prism": "language-kotlin",
        "category": "Mobile",
        "file": "app/src/main/java/com/example/connectfour/MainActivity.kt",
        "folder": "frameworks/jetpackcompose",
        "note": "This is one representative file from the app. See {link} to "
                "browse the ViewModel, board, Gradle build and the rest of the project.",
        "linkText": "the full Jetpack Compose app on GitHub",
    },
    "koa": {
        "name": "Koa",
        "prism": "language-javascript",
        "category": "Web",
        "file": "app.js",
        "folder": "frameworks/koa",
        "note": "This is one representative file from the app. See {link} to "
                "browse the board module and the rest of the project.",
        "linkText": "the full Koa app on GitHub",
    },
    "ktor": {
        "name": "Ktor",
        "prism": "language-kotlin",
        "category": "Web",
        "file": "src/main/kotlin/com/example/connectfour/Application.kt",
        "folder": "frameworks/ktor",
        "note": "This is one representative file from the app. See {link} to "
                "browse the board, Gradle build and the rest of the project.",
        "linkText": "the full Ktor app on GitHub",
    },
    "langchain": {
        "name": "LangChain",
        "prism": "language-python",
        "category": "AI",
        "file": "coach.py",
        "folder": "frameworks/langchain",
        "note": "This is one representative file from the app - the LCEL chain. "
                "See {link} to browse the board, Flask app and the rest of the project.",
        "linkText": "the full LangChain app on GitHub",
    },
    "ollama": {
        "name": "Ollama",
        "prism": "language-python",
        "category": "AI",
        "file": "app.py",
        "folder": "frameworks/ollama",
        "note": "This is one representative file from the app - the game loop that "
                "asks a local model for a move. See {link} to browse the board and the "
                "rest of the project.",
        "linkText": "the full Ollama app on GitHub",
    },
    "playframework": {
        "name": "Play Framework",
        "prism": "language-scala",
        "category": "Web",
        "file": "app/controllers/GameController.scala",
        "folder": "frameworks/playframework",
        "note": "This is one representative file from the app. See {link} to "
                "browse the board model, Twirl template, routes and the rest of the project.",
        "linkText": "the full Play Framework app on GitHub",
    },
    "playwright": {
        "name": "Playwright",
        "prism": "language-typescript",
        "category": "Data",
        "file": "tests/connect-four.spec.ts",
        "folder": "frameworks/playwright",
        "note": "This is one representative file from the test suite. See {link} "
                "to browse the config, helpers and the rest of the project.",
        "linkText": "the full Playwright suite on GitHub",
    },
    "postgresql": {
        "name": "PostgreSQL",
        "prism": "language-sql",
        "category": "Database",
        "file": "schema.sql",
        "folder": "frameworks/postgresql",
        "note": "This is the representative file - the schema, window-function "
                "board view and the `winner`/`drop_disc` functions. See {link} to "
                "browse the seed data and the rest of the project.",
        "linkText": "the full PostgreSQL example on GitHub",
    },
    "prisma": {
        "name": "Prisma",
        "prism": "language-typescript",
        "category": "Data",
        "file": "src/gameService.ts",
        "folder": "frameworks/prisma",
        "note": "This is one representative file from the app. See {link} to "
                "browse the schema, board logic and the rest of the project.",
        "linkText": "the full Prisma example on GitHub",
    },
    "pyside6": {
        "name": "PySide6 (Qt)",
        "prism": "language-python",
        "category": "Desktop",
        "file": "main.py",
        "folder": "frameworks/pyside6",
        "note": "This is one representative file from the app. See {link} to "
                "browse the board model and the rest of the project.",
        "linkText": "the full PySide6 app on GitHub",
    },
    "qwik": {
        "name": "Qwik",
        "prism": "language-tsx",
        "category": "Web",
        "file": "src/routes/index.tsx",
        "folder": "frameworks/qwik",
        "note": "This is one representative file from the app. See {link} to "
                "browse the typed board module and the rest of the project.",
        "linkText": "the full Qwik app on GitHub",
    },
    "quarkus": {
        "name": "Quarkus",
        "prism": "language-java",
        "category": "Web",
        "file": "src/main/java/com/example/connectfour/GameResource.java",
        "folder": "frameworks/quarkus",
        "note": "This is one representative file from the app. See {link} to "
                "browse the board, Qute template, Maven build and the rest of the project.",
        "linkText": "the full Quarkus app on GitHub",
    },
    "redis": {
        "name": "Redis",
        "prism": "language-python",
        "category": "Database",
        "file": "app.py",
        "folder": "frameworks/redis",
        "note": "This is one representative file from the app. See {link} to "
                "browse the board, template and the rest of the project.",
        "linkText": "the full Redis example on GitHub",
    },
    "redux": {
        "name": "Redux Toolkit",
        "prism": "language-javascript",
        "category": "Data",
        "file": "src/features/game/gameSlice.js",
        "folder": "frameworks/redux",
        "note": "This is one representative file from the app - the state slice. "
                "See {link} to browse the store, components and the rest of the project.",
        "linkText": "the full Redux Toolkit app on GitHub",
    },
    "remix": {
        "name": "Remix (React Router)",
        "prism": "language-tsx",
        "category": "Web",
        "file": "app/routes/home.tsx",
        "folder": "frameworks/remix",
        "note": "This is one representative file from the app. See {link} to "
                "browse the board, session storage, root layout and the rest of the project.",
        "linkText": "the full React Router app on GitHub",
    },
    "sanic": {
        "name": "Sanic",
        "prism": "language-python",
        "category": "Web",
        "file": "app.py",
        "folder": "frameworks/sanic",
        "note": "This is one representative file from the app. See {link} to "
                "browse the board, template and the rest of the project.",
        "linkText": "the full Sanic app on GitHub",
    },
    "solidjs": {
        "name": "SolidJS",
        "prism": "language-jsx",
        "category": "Web",
        "file": "src/ConnectFour.jsx",
        "folder": "frameworks/solidjs",
        "note": "This is one representative file from the app. See {link} to "
                "browse the board logic, entry point and the rest of the project.",
        "linkText": "the full SolidJS app on GitHub",
    },
    "swiftui": {
        "name": "SwiftUI",
        "prism": "language-swift",
        "category": "Mobile",
        "file": "Sources/ConnectFour/ContentView.swift",
        "folder": "frameworks/swiftui",
        "note": "This is one representative file from the app. See {link} to "
                "browse the board, app entry point and the rest of the project.",
        "linkText": "the full SwiftUI app on GitHub",
    },
    "tailwindcss": {
        "name": "Tailwind CSS",
        "prism": "language-markup",
        "category": "Web",
        "file": "index.html",
        "folder": "frameworks/tailwindcss",
        "note": "This is one representative file from the app. See {link} to "
                "browse the theme config, stylesheet, game script and the rest of "
                "the project.",
        "linkText": "the full Tailwind CSS page on GitHub",
    },
    "tanstackquery": {
        "name": "TanStack Query",
        "prism": "language-jsx",
        "category": "Data",
        "file": "src/ConnectFour.jsx",
        "folder": "frameworks/tanstackquery",
        "note": "This is one representative file from the app. See {link} to "
                "browse the API client, server and the rest of the project.",
        "linkText": "the full TanStack Query app on GitHub",
    },
    "tauri": {
        "name": "Tauri",
        "prism": "language-rust",
        "category": "Desktop",
        "file": "src-tauri/src/main.rs",
        "folder": "frameworks/tauri",
        "note": "This is one representative file from the app - the Rust entry "
                "point and its commands. See {link} to browse the board, frontend "
                "and the rest of the project.",
        "linkText": "the full Tauri app on GitHub",
    },
    "trpc": {
        "name": "tRPC",
        "prism": "language-typescript",
        "category": "API",
        "file": "server/router.ts",
        "folder": "frameworks/trpc",
        "note": "This is one representative file from the app - the typed router. "
                "See {link} to browse the board, server, client and the rest of the project.",
        "linkText": "the full tRPC app on GitHub",
    },
    "vapor": {
        "name": "Vapor",
        "prism": "language-swift",
        "category": "Web",
        "file": "Sources/App/routes.swift",
        "folder": "frameworks/vapor",
        "note": "This is one representative file from the app. See {link} to "
                "browse the board, configure step, boot file and the rest of the project.",
        "linkText": "the full Vapor app on GitHub",
    },
    "tsql": {
        "name": "T-SQL",
        "prism": "language-tsql",
        "category": "Database",
        "file": "schema.sql",
        "folder": "frameworks/tsql",
        "note": "This is the representative file - the tables, the `dbo.Cells` "
                "window-function view and the constraints. See {link} to browse the "
                "`fn_Winner`/`DropDisc` procedures, seed data and the rest of the project.",
        "linkText": "the full T-SQL example on GitHub",
    },
    "jquery": {
        "name": "jQuery",
        "prism": "language-javascript",
        "category": "Web",
        "file": "app.js",
        "folder": "frameworks/jquery",
        "note": "This is one representative file from the app. See {link} to "
                "browse the markup, stylesheet and the rest of the project.",
        "linkText": "the full jQuery app on GitHub",
    },
    "scss": {
        "name": "SCSS",
        "prism": "language-scss",
        "category": "Web",
        "file": "scss/main.scss",
        "folder": "frameworks/scss",
        "note": "This is one representative file from the app - the entry "
                "stylesheet (the `_variables`/`_board` partials and the plain "
                "JavaScript next to it). See {link} to browse the rest of the project.",
        "linkText": "the full SCSS project on GitHub",
    },
    "ember": {
        "name": "Ember.js",
        "prism": "language-javascript",
        "category": "Web",
        "file": "app/components/connect-four.js",
        "folder": "frameworks/ember",
        "note": "This is one representative file from the app. See {link} to "
                "browse the template, board util, app entry and the rest of the project.",
        "linkText": "the full Ember.js app on GitHub",
    },
    "lit": {
        "name": "Lit",
        "prism": "language-typescript",
        "category": "Web",
        "file": "src/connect-four.ts",
        "folder": "frameworks/lit",
        "note": "This is one representative file from the app. See {link} to "
                "browse the typed board module and the rest of the project.",
        "linkText": "the full Lit app on GitHub",
    },
    "handlebars": {
        "name": "Handlebars",
        "prism": "language-handlebars",
        "category": "Web",
        "file": "templates/board.hbs",
        "folder": "frameworks/handlebars",
        "note": "This is one representative file from the app. See {link} to "
                "browse the partial, renderer, server and the rest of the project.",
        "linkText": "the full Handlebars app on GitHub",
    },
    "cassandra": {
        "name": "Cassandra",
        "prism": "language-cql",
        "category": "Database",
        "file": "schema.cql",
        "folder": "frameworks/cassandra",
        "note": "This is the representative file - the keyspace and the query-driven "
                "tables (lists of discs, timeuuid clustering), plus a materialized "
                "view and a secondary index. See {link} to browse the queries, seed "
                "data and the rest of the project.",
        "linkText": "the full Apache Cassandra example on GitHub",
    },
    "oracle": {
        "name": "Oracle Database",
        "prism": "language-plsql",
        "category": "Database",
        "file": "schema.sql",
        "folder": "frameworks/oracle",
        "note": "This is the representative file - the tables, constraints, index and "
                "the `cells` window-function view. See {link} to browse the `INSERT "
                "ALL` seed and the PL/SQL package sibling.",
        "linkText": "the full Oracle Database example on GitHub",
    },
    "plsql": {
        "name": "Oracle PL/SQL",
        "prism": "language-plsql",
        "category": "Database",
        "file": "packages.sql",
        "folder": "frameworks/plsql",
        "note": "This is the representative file - the `connect_four_pkg` package "
                "spec and body. See {link} to browse the Oracle tables it runs on.",
        "linkText": "the full Oracle PL/SQL example on GitHub",
    },
    "sqlite": {
        "name": "SQLite",
        "prism": "language-sql",
        "category": "Database",
        "file": "schema.sql",
        "folder": "frameworks/sqlite",
        "note": "This is the representative file - the STRICT tables, constraints "
                "and the `cells` window-function view. See {link} to browse the "
                "recursive-CTE queries and the rest of the project.",
        "linkText": "the full SQLite example on GitHub",
    },
    "mariadb": {
        "name": "MariaDB",
        "prism": "language-sql",
        "category": "Database",
        "file": "schema.sql",
        "folder": "frameworks/mariadb",
        "note": "This is the representative file - the sequence default, tables, "
                "constraints and the `cells` view. See {link} to browse the "
                "window-function queries and the rest of the project.",
        "linkText": "the full MariaDB example on GitHub",
    },
    "db2": {
        "name": "IBM Db2",
        "prism": "language-sql",
        "category": "Database",
        "file": "schema.sql",
        "folder": "frameworks/db2",
        "note": "This is the representative file - the identity-column tables, "
                "constraints and the `cells` view. See {link} to browse the "
                "LISTAGG queries and the rest of the project.",
        "linkText": "the full IBM Db2 example on GitHub",
    },
    "questdb": {
        "name": "QuestDB",
        "prism": "language-sql",
        "category": "Database",
        "file": "schema.sql",
        "folder": "frameworks/questdb",
        "note": "This is the representative file - the designated-timestamp, "
                "`PARTITION BY` time-series tables with `SYMBOL` columns. See {link} "
                "to browse the LATEST ON / SAMPLE BY / ASOF JOIN queries.",
        "linkText": "the full QuestDB example on GitHub",
    },
    "duckdb": {
        "name": "DuckDB",
        "prism": "language-sql",
        "category": "Database",
        "file": "schema.sql",
        "folder": "frameworks/duckdb",
        "note": "This is the representative file - the sequence default, tables, "
                "constraints and the `cells` view. See {link} to browse the `range()`, "
                "`PIVOT` and window-function queries.",
        "linkText": "the full DuckDB example on GitHub",
    },
    "surrealdb": {
        "name": "SurrealDB",
        "prism": "language-sql",
        "category": "Database",
        "file": "schema.surql",
        "folder": "frameworks/surrealdb",
        "note": "This is the representative file - the SCHEMAFULL table and field "
                "definitions with ASSERT rules and a record link. See {link} to browse "
                "the SurrealQL queries and the rest of the project.",
        "linkText": "the full SurrealDB example on GitHub",
    },
    "firebird": {
        "name": "Firebird",
        "prism": "language-sql",
        "category": "Database",
        "file": "schema.sql",
        "folder": "frameworks/firebird",
        "note": "This is the representative file - the identity-column tables, "
                "constraints and the `cells` view. See {link} to browse the PSQL "
                "procedures and the rest of the project.",
        "linkText": "the full Firebird example on GitHub",
    },
    "clickhouse": {
        "name": "ClickHouse",
        "prism": "language-sql",
        "category": "Database",
        "file": "schema.sql",
        "folder": "frameworks/clickhouse",
        "note": "This is the representative file - the MergeTree tables and the "
                "SummingMergeTree materialized view. See {link} to browse the "
                "argMax / groupArray / ANY LEFT JOIN queries.",
        "linkText": "the full ClickHouse example on GitHub",
    },
    "preact": {
        "name": "Preact",
        "prism": "language-jsx",
        "category": "Web",
        "file": "src/connect-four.jsx",
        "folder": "frameworks/preact",
        "note": "This is one representative file from the app. See {link} to "
                "browse the board logic, entry point and the rest of the project.",
        "linkText": "the full Preact app on GitHub",
    },
    "bootstrap": {
        "name": "Bootstrap",
        "prism": "language-markup",
        "category": "Web",
        "file": "index.html",
        "folder": "frameworks/bootstrap",
        "note": "This is one representative file from the app. See {link} to "
                "browse the game script and the rest of the project.",
        "linkText": "the full Bootstrap page on GitHub",
    },
    "reactbootstrap": {
        "name": "React Bootstrap",
        "prism": "language-jsx",
        "category": "Web",
        "file": "src/ConnectFour.jsx",
        "folder": "frameworks/reactbootstrap",
        "note": "This is one representative file from the app. See {link} to "
                "browse the board logic, entry point and the rest of the project.",
        "linkText": "the full React Bootstrap app on GitHub",
    },
    "vuebootstrap": {
        "name": "Vue Bootstrap",
        "prism": "language-javascript",
        "category": "Web",
        "file": "src/composables/useConnectFour.js",
        "folder": "frameworks/vuebootstrap",
        "note": "This is one representative file from the app - the Composition API "
                "composable (Prism has no Vue grammar, so App.vue is not shown "
                "here). See {link} to browse the single-file component, board logic "
                "and the rest of the project.",
        "linkText": "the full Vue Bootstrap app on GitHub",
    },
    "selenium": {
        "name": "Selenium",
        "prism": "language-python",
        "category": "Data",
        "file": "tests/test_connect_four.py",
        "folder": "frameworks/selenium",
        "note": "This is one representative file from the test suite. See {link} "
                "to browse the Page Object, the driver fixtures and the rest of the project.",
        "linkText": "the full Selenium suite on GitHub",
    },
    "gradle": {
        "name": "Gradle",
        "prism": "language-kotlin",
        "category": "Build",
        "file": "build.gradle.kts",
        "folder": "frameworks/gradle",
        "note": "This is the representative file - the Kotlin-DSL build script with "
                "the JUnit BOM, Java toolchain and test task. See {link} to browse the "
                "Java board, the tests and the Maven twin.",
        "linkText": "the full Gradle project on GitHub",
    },
    "maven": {
        "name": "Maven",
        "prism": "language-markup",
        "category": "Build",
        "file": "pom.xml",
        "folder": "frameworks/maven",
        "note": "This is the representative file - the POM with its coordinates, "
                "test-scoped JUnit 5 dependency and compiler/surefire/exec/jar "
                "plugins. See {link} to browse the Java board, the tests and the "
                "Gradle twin.",
        "linkText": "the full Maven project on GitHub",
    },
}

# ---------------------------------------------------------------------------
# Extra facets the dashboard's Frameworks filters read.
#
#   FRAMEWORK_STACKS     the Web sub-classification: Frontend, Backend or
#                        Full stack.  Only Web frameworks carry one, so the
#                        Stack facet is meaningful for the web tree alone.
#   FRAMEWORK_LANGUAGES  the programming language(s) each framework is written
#                        in (display names).  This is what lets the dashboard's
#                        Language facet pull up, say, every C# or Java
#                        framework regardless of its category.
# ---------------------------------------------------------------------------
FRAMEWORK_STACKS = {
    "adonisjs": "Backend",
    "alpinejs": "Frontend",
    "angular": "Frontend",
    "aspnetcore": "Backend",
    "astro": "Frontend",
    "axum": "Backend",
    "blazor": "Full stack",
    "bootstrap": "Frontend",
    "django": "Full stack",
    "echo": "Backend",
    "ember": "Frontend",
    "expressjs": "Backend",
    "fastapi": "Backend",
    "fastify": "Backend",
    "fiber": "Backend",
    "flask": "Backend",
    "gin": "Backend",
    "handlebars": "Frontend",
    "htmx": "Frontend",
    "jquery": "Frontend",
    "koa": "Backend",
    "ktor": "Backend",
    "laravel": "Full stack",
    "lit": "Frontend",
    "nestjs": "Backend",
    "nextjs": "Full stack",
    "nuxt": "Full stack",
    "phoenix": "Full stack",
    "playframework": "Full stack",
    "preact": "Frontend",
    "qwik": "Frontend",
    "quarkus": "Backend",
    "react": "Frontend",
    "reactbootstrap": "Frontend",
    "remix": "Full stack",
    "rubyonrails": "Full stack",
    "sanic": "Backend",
    "scss": "Frontend",
    "solidjs": "Frontend",
    "springboot": "Backend",
    "svelte": "Frontend",
    "symfony": "Full stack",
    "tailwindcss": "Frontend",
    "vapor": "Backend",
    "vue": "Frontend",
    "vuebootstrap": "Frontend",
}

FRAMEWORK_LANGUAGES = {
    "adonisjs": ["TypeScript"],
    "alpinejs": ["JavaScript"],
    "angular": ["TypeScript"],
    "aspnetcore": ["C#"],
    "astro": ["TypeScript"],
    "avalonia": ["C#"],
    "axum": ["Rust"],
    "blazor": ["C#"],
    "bootstrap": ["CSS", "JavaScript"],
    "cassandra": ["CQL"],
    "clickhouse": ["SQL"],
    "db2": ["SQL"],
    "django": ["Python"],
    "duckdb": ["SQL"],
    "echo": ["Go"],
    "electron": ["JavaScript"],
    "ember": ["JavaScript"],
    "expressjs": ["TypeScript"],
    "fastapi": ["Python"],
    "fastify": ["JavaScript"],
    "fiber": ["Go"],
    "firebird": ["SQL"],
    "flask": ["Python"],
    "flutter": ["Dart"],
    "fyne": ["Go"],
    "gin": ["Go"],
    "graphql": ["Python"],
    "handlebars": ["JavaScript"],
    "htmx": ["JavaScript"],
    "ionic": ["TypeScript"],
    "javafx": ["Java"],
    "jetpackcompose": ["Kotlin"],
    "jquery": ["JavaScript"],
    "json": ["JSON"],
    "koa": ["JavaScript"],
    "ktor": ["Kotlin"],
    "langchain": ["Python"],
    "laravel": ["PHP"],
    "lit": ["TypeScript"],
    "mariadb": ["SQL"],
    "maui": ["C#"],
    "minimax": ["Python"],
    "mongodb": ["JavaScript"],
    "mysql": ["SQL"],
    "nestjs": ["TypeScript"],
    "nextjs": ["JavaScript"],
    "nuxt": ["JavaScript"],
    "ollama": ["Python"],
    "oracle": ["SQL"],
    "phoenix": ["Elixir"],
    "playframework": ["Scala"],
    "playwright": ["TypeScript"],
    "plsql": ["PL/SQL"],
    "postgresql": ["SQL"],
    "preact": ["JavaScript"],
    "prisma": ["TypeScript"],
    "pyside6": ["Python"],
    "qwik": ["TypeScript"],
    "quarkus": ["Java"],
    "questdb": ["SQL"],
    "react": ["JavaScript"],
    "reactbootstrap": ["JavaScript"],
    "reactnative": ["JavaScript"],
    "redis": ["Python"],
    "redux": ["JavaScript"],
    "remix": ["TypeScript"],
    "rubyonrails": ["Ruby"],
    "sanic": ["Python"],
    "scss": ["CSS"],
    "selenium": ["Python"],
    "solidjs": ["JavaScript"],
    "springboot": ["Java"],
    "sqlite": ["SQL"],
    "surrealdb": ["SurrealQL"],
    "svelte": ["JavaScript"],
    "swiftui": ["Swift"],
    "symfony": ["PHP"],
    "tailwindcss": ["CSS", "JavaScript"],
    "tanstackquery": ["JavaScript"],
    "tauri": ["JavaScript", "Rust"],
    "tkinter": ["Python"],
    "trpc": ["TypeScript"],
    "tsql": ["SQL"],
    "vapor": ["Swift"],
    "vue": ["JavaScript"],
    "vuebootstrap": ["JavaScript"],
    "wpf": ["C#"],
    "wpfvb": ["VB.NET"],
    "maven": ["XML", "Java"],
    "gradle": ["Kotlin", "Java"],
}

# The short file-extension tag the dashboard shows for a language, so a
# framework's language chips (and the Language filter) read ".ts", ".cs", ...
# rather than a name.  Keys match the names used in FRAMEWORK_LANGUAGES.
LANGUAGE_EXTENSIONS = {
    "C#": ".cs",
    "CQL": ".cql",
    "CSS": ".css",
    "Dart": ".dart",
    "Elixir": ".ex",
    "Go": ".go",
    "JSON": ".json",
    "Java": ".java",
    "JavaScript": ".js",
    "Kotlin": ".kt",
    "PHP": ".php",
    "PL/SQL": ".plsql",
    "Python": ".py",
    "Ruby": ".rb",
    "Rust": ".rs",
    "SQL": ".sql",
    "Scala": ".scala",
    "SurrealQL": ".surql",
    "Swift": ".swift",
    "TypeScript": ".ts",
    "VB.NET": ".vb",
    "XML": ".xml",
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
        entry = {
            "id": key,
            "name": name,
            "category": category,
            "prism": prism,
            "file": source.relative_to(ROOT).as_posix(),
            "code": read_text(source),
        }
        interactive = INTERACTIVE_LANGUAGES.get(key)
        if interactive:
            entry["folder"] = interactive.get("folder", "languages/%s" % key)
            entry["note"] = interactive.get("note", "")
            entry["linkText"] = interactive.get("linkText", "")
            entry["preview"] = interactive.get("preview", entry["file"])
            entry["interactive"] = True
        noted = LANGUAGE_NOTES.get(key)
        if noted:
            entry["note"] = noted["note"]
            entry["noteLinks"] = noted.get("noteLinks", {})
        found.append(entry)
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
                "stack": FRAMEWORK_STACKS.get(key, ""),
                "languages": FRAMEWORK_LANGUAGES.get(key, []),
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
        "languageExtensions": LANGUAGE_EXTENSIONS,
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
