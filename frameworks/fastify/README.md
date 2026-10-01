<img src="banner.svg" alt="Fastify - Connect Four banner" width="100%">

# Fastify Implementation

A small Fastify app that plays Connect Four in the browser - a
[framework showcase](../../README.md) alongside the console implementations in
[`languages/`](../../languages). Fastify is a Node.js web framework, so this app
serves server-rendered EJS views instead of the byte-for-byte stdin/stdout
console protocol, and the dashboard shows one representative file from it rather
than a single source file.

## Prerequisites

* **Toolchain:** Node.js 18 or newer
* **Check it is installed:** `node --version`

| Platform | Install command |
| --- | --- |
| Windows | `winget install OpenJS.NodeJS` |
| macOS | `brew install node` |
| Debian/Ubuntu | `apt-get install nodejs` |

## How to run

Everything the app needs is under `frameworks/fastify/`; run it from that
folder:

```sh
cd frameworks/fastify
npm init -y
npm install fastify @fastify/view @fastify/cookie @fastify/session @fastify/formbody ejs
node app.js
```

Then open <http://localhost:3000> and play - the board is a 6x7 grid whose
bottom row is the first to fill, and the first player to line up four `X`s or
`O`s wins.

## How the game is built

* **Board** - `board.js` is plain JavaScript with the 6x7 rules: `drop`,
  `isColumnFull`, `winner` and `lowestEmptyRow`. Every update returns a fresh
  board, and both diagonals are checked from every cell, matching the win
  detection the console implementations use.
* **App** - `app.js` is the Fastify instance: it registers the `@fastify/view`
  (EJS), `@fastify/formbody`, `@fastify/cookie` and `@fastify/session` plugins,
  renders the board on `GET /`, and applies moves on `POST /move` /
  `POST /reset` before redirecting back (post/redirect/get), so a refresh never
  re-plays a move.
* **View** - `views/board.ejs` is an EJS template that renders the board (top
  row first) and the column buttons.

## Skills demonstrated

* Fastify plugins (`@fastify/view`, `@fastify/session`) and routes
* Form-body parsing and session state
* EJS templates and post/redirect/get
* An array-of-arrays board with diagonal win detection

## Where the full app lives

The dashboard shows the application entry point, `app.js`, and links the whole
folder on GitHub. Everything the app needs is under `frameworks/fastify/`:

```
frameworks/fastify/
  app.js
  board.js
  views/board.ejs
```

The showcase dashboard shows this framework's representative file when you
open the **Frameworks** browse mode, addressable at `index.html?lang=fastify`.
