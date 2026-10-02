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
        if path == "/app/":
            body = ("<!doctype html><html lang=pl><meta charset=utf-8>"
                    "<meta name=viewport content='width=device-width,initial-scale=1'>"
                    "<title>Pędy — IPA</title><body><h1>Pędy</h1>"
                    "<p><a href='Pedy.ipa' download>Pobierz najnowsze IPA</a></p>"
                    "<p>Po pobraniu otwórz plik w SideStore przy włączonych Wi-Fi i LocalDevVPN.</p>"
                    "<p><a href='build.json'>Informacje o buildzie</a></p></body></html>").encode()
            self.send_response(200)
            self.send_header("Content-Type", "text/html; charset=utf-8")
            self.send_header("Content-Length", str(len(body)))
            self.send_header("Cache-Control", "no-store")
            self.end_headers()
            if not head_only:
                self.wfile.write(body)
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
