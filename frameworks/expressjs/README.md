<img src="banner.svg" alt="Express (Node) - Connect Four banner" width="100%">

# Express (Node) Implementation

A small Express app that plays Connect Four in the browser - a
[framework showcase](../../README.md) alongside the console implementations in
[`languages/`](../../languages). Express is a Node.js web framework, so this app
serves server-rendered EJS views instead of the byte-for-byte stdin/stdout
console protocol, and the dashboard shows one representative file from it rather
than a single source file.

## Prerequisites

* **Toolchain:** Node.js 18 or newer + TypeScript (run through `tsx`)
* **Check it is installed:** `node --version`

| Platform | Install command |
| --- | --- |
| Windows | `winget install OpenJS.NodeJS` |
| macOS | `brew install node` |
| Debian/Ubuntu | `apt-get install nodejs` |

## How to run

Everything the app needs is under `frameworks/expressjs/`; run it from that
folder:

```sh
cd frameworks/expressjs
npm install
npm start
```

`npm start` runs `tsx app.ts`; `npm run typecheck` runs `tsc --noEmit`.

Then open <http://localhost:3000> and play - the board is a 6x7 grid whose
bottom row is the first to fill, and the first player to line up four `X`s or
`O`s wins.

## How the game is built

* **Board** - `board.ts` is the 6x7 rules in TypeScript: `drop`, `isColumnFull`,
  `winner` and `lowestEmptyRow`, with exported `Player`/`Cell`/`Board`/`Game`
  types. Every update returns a fresh board, and both diagonals are checked from
  every cell, matching the win detection the console implementations use.
* **App** - `app.ts` is the Express application: `GET /` renders the board and
  `POST /move` / `POST /reset` read and write the game through
  `express-session` and redirect back (post/redirect/get), so a refresh never
  re-plays a move.
* **Session types** - `session.d.ts` augments `express-session`'s `SessionData`
  with the optional `board`, so `req.session.board` is typed everywhere.
* **View** - `views/board.ejs` is an EJS template that renders the board (top
  row first) and the column buttons.

## Skills demonstrated

* Express routing, middleware and `express.urlencoded` in TypeScript
* `express-session` for game state, with a typed session augmentation
* EJS templates and `@types/express` request/response typing
* An array-of-arrays board with diagonal win detection

## Where the full app lives

The dashboard shows the application entry point, `app.ts`, and links the whole
folder on GitHub. Everything the app needs is under `frameworks/expressjs/`:

```
frameworks/expressjs/
  app.ts
  board.ts
  package.json
  session.d.ts
  tsconfig.json
  views/board.ejs
```

The showcase dashboard shows this framework's representative file when you
open the **Frameworks** browse mode, addressable at `index.html?lang=expressjs`.
