<img src="banner.svg" alt="Gin - Connect Four banner" width="100%">

# Gin Implementation

A small Gin app that plays Connect Four in the browser - a
[framework showcase](../../README.md) alongside the console implementations in
[`languages/`](../../languages). Gin is a web framework, so this app serves HTML
instead of the byte-for-byte stdin/stdout console protocol, and the dashboard
shows one representative file from it rather than a single source file.

## Prerequisites

* **Toolchain:** Go 1.20 or newer
* **Check it is installed:** `go version`

| Platform | Install command |
| --- | --- |
| Windows | `winget install GoLang.Go` |
| macOS | `brew install go` |
| Debian/Ubuntu | `apt-get install golang-go` |

## How to run

Everything the app needs is under `frameworks/gin/`; initialise the module and
pull the two dependencies from that folder:

```sh
cd frameworks/gin
go mod init connectfour
go get github.com/gin-gonic/gin github.com/gin-contrib/sessions
go run .
```

Then open <http://127.0.0.1:8080> and play - the board is a 6x7 grid whose
bottom row is the first to fill, and the first player to line up four `X`s or
`O`s wins.

## How the game is built

* **Board** - `board/board.go` holds the 6x7 board and the rules: `Drop`,
  `IsFull`, `Winner`, `IsOver` and `hasLine`. It marshals to and from JSON so it
  can live in the session, and both diagonals are checked from every cell,
  matching the win detection the console implementations use.
* **App** - `main.go` is the Gin router: `GET /` renders the board and
  `POST /move` / `POST /reset` read and write the game through a cookie-backed
  session and redirect back (post/redirect/get), so a refresh never re-plays a
  move.
* **Template** - `templates/board.html` is an `html/template` that renders the
  board and a row of column buttons; the status line announces whose turn it is
  or who won.

## Skills demonstrated

* Gin routing, handlers and `gin.H` context
* Cookie sessions with `gin-contrib/sessions`
* `html/template` rendering and JSON session state
* An array-of-arrays board with diagonal win detection

## Where the full app lives

The dashboard shows the router entry point, `main.go`, and links the whole
folder on GitHub. Everything the app needs is under `frameworks/gin/`:

```
frameworks/gin/
  board/board.go
  main.go
  templates/board.html
```

The showcase dashboard shows this framework's representative file when you
open the **Frameworks** browse mode, addressable at `index.html?lang=gin`.
