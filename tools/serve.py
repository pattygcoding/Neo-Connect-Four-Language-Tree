#!/usr/bin/env python3
"""Preview the showcase the way GitHub Pages serves it.

The dashboard gives every implementation a pretty address (`/csharp`, `/ada`,
`/objectivec`), but those are not files.  Pages has no rewrite rules either: it
answers an unknown path with the site's own ``404.html``, and the tiny shim in
that file sends the browser on to ``index.html?lang=<id>``.  That is what makes
*refreshing* one of those screens work on the deployed site.

``python -m http.server`` does not do that - it answers ``/csharp`` with its own
404 page - so a refresh looks broken locally even though production is fine.
This server mirrors Pages instead: unknown paths get ``404.html`` with a 404
status, everything else is served from the repository root, and the shim in the
browser finishes the job.

Usage::

    python tools/serve.py [port]     # then open http://localhost:8000/csharp
"""

from __future__ import annotations

import functools
import http.server
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
FALLBACK = ROOT / "404.html"
DEFAULT_PORT = 8000


class PagesLikeHandler(http.server.SimpleHTTPRequestHandler):
    """Static files from the repository root, with Pages' 404.html fallback."""

    def handle_one_request(self):
        # A browser dropping a keep-alive socket mid-navigation is normal here (it
        # happens on every reload of a pretty path); do not print a traceback for it.
        try:
            super().handle_one_request()
        except (ConnectionResetError, BrokenPipeError):
            self.close_connection = True

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


def main() -> int:
    port = int(sys.argv[1]) if len(sys.argv) > 1 else DEFAULT_PORT
    handler = functools.partial(PagesLikeHandler, directory=str(ROOT))
    with http.server.ThreadingHTTPServer(("", port), handler) as server:
        print("Serving %s" % ROOT)
        print("  http://localhost:%d/            (opens the default implementation)" % port)
        print("  http://localhost:%d/csharp      (404.html fallback, like Pages)" % port)
        try:
            server.serve_forever()
        except KeyboardInterrupt:
            print("stopped")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
