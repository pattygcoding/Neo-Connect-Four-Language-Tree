#!/usr/bin/env python3
"""Preview the built showcase the way GitHub Pages serves it.

The dashboard is a built site (``npm run build`` writes ``dist/``), and its
addresses are pretty paths (`/csharp`, `/ada`, `/objectivec`) that are not files.
Pages has no rewrite rules either: it answers an unknown path with the site's own
``404.html``, and the tiny shim in that file sends the browser on to
``index.html?lang=<id>``.  That is what makes *refreshing* one of those screens
work on the deployed site.

``python -m http.server`` does not do that - it answers ``/csharp`` with its own
404 page - so a refresh looks broken locally even though production is fine.
This server mirrors Pages instead: unknown paths get ``404.html`` with a 404
status, everything else is served from ``dist/``, and the shim in the browser
finishes the job.  Before the first build it falls back to serving the repository
itself, which the dashboard's own static files are enough for.

Usage::

    npm run build                    # once, so dist/ exists
    python tools/serve.py [port]     # then open http://localhost:8000/csharp
"""

from __future__ import annotations

import functools
import http.server
import socket
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
DIST = ROOT / "dist"
# The deployed artifact when it has been built, else the sources (the dashboard
# then shows its "no data" state until `npm run data` has run).
SERVE_ROOT = DIST if DIST.is_dir() else ROOT
FALLBACK = SERVE_ROOT / "404.html"
DEFAULT_PORT = 8000


class PagesLikeHandler(http.server.SimpleHTTPRequestHandler):
    """Static files from the built site, with Pages' 404.html fallback."""

    def handle_one_request(self):
        # A browser dropping a keep-alive socket mid-navigation is normal here (it
        # happens on every reload of a pretty path); do not print a traceback for it.
        try:
            super().handle_one_request()
        except (ConnectionResetError, BrokenPipeError):
            self.close_connection = True

    def end_headers(self):
        # Without this the browser heuristically caches the built files and keeps
        # showing a stale build after `npm run build` rewrites them.
        self.send_header("Cache-Control", "no-cache")
        super().end_headers()

    def send_error(self, code, message=None, explain=None):
        if code == 404 and FALLBACK.is_file():
            body = FALLBACK.read_bytes()
            self.send_response(404)
            self.send_header("Content-Type", "text/html; charset=utf-8")
            self.send_header("Content-Length", str(len(body)))
            self.end_headers()
            if self.command != "HEAD":
                self.wfile.write(body)
            return
        super().send_error(code, message, explain)


class PagesLikeServer(http.server.ThreadingHTTPServer):
    """A server that refuses to silently *share* a port another server holds.

    Python's default ``allow_reuse_address`` maps to Windows' ``SO_REUSEADDR``,
    which lets a second process bind an address that is already listening - so a
    stray ``python -m http.server`` would keep answering while this one believes
    it started, and refreshing a pretty path would still show that server's 404.
    Reuse-address elsewhere and exclusive-address on Windows make a busy port
    fail loudly instead, which ``main`` turns into a clear message.
    """

    allow_reuse_address = sys.platform != "win32"

    def server_bind(self):
        if sys.platform == "win32":
            self.socket.setsockopt(socket.SOL_SOCKET, socket.SO_EXCLUSIVEADDRUSE, 1)
        super().server_bind()


def main() -> int:
    port = int(sys.argv[1]) if len(sys.argv) > 1 else DEFAULT_PORT
    handler = functools.partial(PagesLikeHandler, directory=str(SERVE_ROOT))
    try:
        server = PagesLikeServer(("", port), handler)
    except OSError as error:
        # The usual cause is a *different* static server already holding the port -
        # most often `python -m http.server`, whose own 404 page is exactly what
        # makes refreshing a pretty path look broken.  Say so instead of dumping a
        # traceback, because the browser would otherwise still be talking to that
        # server while this one never started.
        print("error: cannot start on port %d (%s)" % (port, error), file=sys.stderr)
        print("Something else is already listening there - most likely a stray", file=sys.stderr)
        print("'python -m http.server'. Stop it, or pick another port:", file=sys.stderr)
        print("    python tools/serve.py 8080", file=sys.stderr)
        return 1
    with server:
        print("Serving %s" % SERVE_ROOT)
        if SERVE_ROOT is ROOT:
            print("  (no dist/ yet - run `npm run build` to serve the real thing)")
        print("  http://localhost:%d/            (opens the default implementation)" % port)
        print("  http://localhost:%d/csharp      (404.html fallback, like Pages)" % port)
        try:
            server.serve_forever()
        except KeyboardInterrupt:
            print("stopped")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
