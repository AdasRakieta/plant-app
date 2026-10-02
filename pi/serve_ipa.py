#!/usr/bin/env python3
"""Small LAN file server exposing only the Pedy download under /app/."""

from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path
import os


ROOT = Path(os.environ.get("PEDY_SERVE_DIR", "/srv/pedy"))
PORT = int(os.environ.get("PEDY_LAN_PORT", "8787"))
FILES = {
    "/app/Pedy.ipa": ("Pedy.ipa", "application/octet-stream"),
    "/app/build.json": ("build.json", "application/json; charset=utf-8"),
    "/app/Pedy.sha256": ("Pedy.sha256", "text/plain; charset=utf-8"),
    "/app/source.json": ("source.json", "application/json; charset=utf-8"),
    "/app/source-local.json": ("source-local.json", "application/json; charset=utf-8"),
    "/app/icon.png": ("icon.png", "image/png"),
    "/app/": ("index.html", "text/html; charset=utf-8"),
    "/app/index.html": ("index.html", "text/html; charset=utf-8"),
}


class Handler(BaseHTTPRequestHandler):
    def do_HEAD(self):
        self.respond(head_only=True)

    def do_GET(self):
        self.respond(head_only=False)

    def respond(self, head_only: bool):
        path = self.path.split("?", 1)[0]
        if path == "/app":
            self.send_response(308)
            self.send_header("Location", "/app/")
            self.end_headers()
            return
        if path not in FILES:
            self.send_error(404)
            return
        filename, content_type = FILES[path]
        file = ROOT / filename
        try:
            size = file.stat().st_size
            if not file.is_file():
                raise FileNotFoundError
            self.send_response(200)
            self.send_header("Content-Type", content_type)
            self.send_header("Content-Length", str(size))
            if filename == "Pedy.ipa":
                self.send_header("Content-Disposition", f'attachment; filename="{filename}"')
            self.send_header("Cache-Control", "no-store")
            self.end_headers()
            if not head_only:
                with file.open("rb") as source:
                    while chunk := source.read(1024 * 1024):
                        self.wfile.write(chunk)
        except FileNotFoundError:
            self.send_error(404, "IPA is not available yet")


if __name__ == "__main__":
    ThreadingHTTPServer(("0.0.0.0", PORT), Handler).serve_forever()
