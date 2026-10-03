#!/usr/bin/env python3
"""Private LAN/Tailscale bridge from Pedy to local Ollama vision models.

Images are forwarded in memory to localhost only. They are never written to disk.
"""
import json
import os
import urllib.error
import urllib.request
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer

OLLAMA_URL = os.environ.get("PEDY_OLLAMA_URL", "http://127.0.0.1:11434/api/chat")
MODEL = os.environ.get("PEDY_VISION_MODEL", "llava:7b")
MAX_BODY = 12 * 1024 * 1024
CATALOG = [
    ("monstera", "Monstera", "Monstera deliciosa"), ("fikus-sprężysty", "Fikus sprężysty", "Ficus elastica"),
    ("sansewieria", "Sansewieria", "Dracaena trifasciata"), ("epipremnum", "Epipremnum", "Epipremnum aureum"),
    ("zamiokulkas", "Zamiokulkas", "Zamioculcas zamiifolia"), ("skrzydłokwiat", "Skrzydłokwiat", "Spathiphyllum wallisii"),
    ("zielistka", "Zielistka", "Chlorophytum comosum"), ("pilea", "Pilea", "Pilea peperomioides"),
    ("calathea", "Kalatea", "Goeppertia orbifolia"), ("maranta", "Maranta", "Maranta leuconeura"),
    ("dracena", "Dracena", "Dracaena marginata"), ("aloes", "Aloes", "Aloe vera"),
    ("grubosz", "Grubosz", "Crassula ovata"), ("paprotka", "Paprotka", "Nephrolepis exaltata"),
    ("anturium", "Anturium", "Anthurium andraeanum"), ("hoja", "Hoja", "Hoya carnosa"),
]

def ollama(prompt, image=None):
    message = {"role": "user", "content": prompt}
    if image:
        message["images"] = [image]
    payload = json.dumps({"model": MODEL, "stream": False, "format": "json", "messages": [message]}).encode()
    req = urllib.request.Request(OLLAMA_URL, data=payload, headers={"Content-Type": "application/json"})
    try:
        with urllib.request.urlopen(req, timeout=70) as response:
            raw = json.load(response)["message"]["content"]
        return json.loads(raw)
    except urllib.error.HTTPError as exc:
        raise RuntimeError("Model AI nie jest jeszcze gotowy na serwerze.") from exc
    except (urllib.error.URLError, KeyError, ValueError) as exc:
        raise RuntimeError("Lokalny model AI nie odpowiedział. Spróbuj ponownie za chwilę.") from exc

class Handler(BaseHTTPRequestHandler):
    def log_message(self, format, *args):
        return

    def send_json(self, code, payload):
        data = json.dumps(payload, ensure_ascii=False).encode()
        self.send_response(code)
        self.send_header("Content-Type", "application/json; charset=utf-8")
        self.send_header("Content-Length", str(len(data)))
        self.end_headers()
        self.wfile.write(data)

    def do_GET(self):
        if self.path == "/health":
            self.send_json(200, {"status": "ok", "model": MODEL, "privacy": "images are not retained"})
        else:
            self.send_json(404, {"error": "Nie znaleziono endpointu."})

    def do_POST(self):
        if self.path not in ("/v1/identify", "/v1/diagnose"):
            return self.send_json(404, {"error": "Nie znaleziono endpointu."})
        try:
            length = int(self.headers.get("Content-Length", "0"))
            if not 0 < length <= MAX_BODY:
                raise ValueError("Zdjęcie jest za duże. Wybierz plik do 8 MB.")
            body = json.loads(self.rfile.read(length))
            image = body.get("image")
            if self.path == "/v1/identify":
                if not isinstance(image, str) or len(image) < 100:
                    raise ValueError("Dodaj zdjęcie rośliny do rozpoznania.")
                catalog = "; ".join(f"{i}: {n} ({latin})" for i, n, latin in CATALOG)
                prompt = ("Rozpoznaj domową roślinę na zdjęciu. Wybieraj wyłącznie z katalogu: " + catalog + ". "
                          "Zwróć WYŁĄCZNIE JSON: {candidates:[{speciesID,commonName,latinName,confidence,reason}],"
                          "uncertainty,needsAnotherPhoto}. Daj maksymalnie 3 kandydaty. confidence 0..1. "
                          "Jeśli nie masz pewności, powiedz to; nie zgaduj.")
                result = ollama(prompt, image)
                result.setdefault("candidates", [])
                result.setdefault("uncertainty", "Wynik wymaga potwierdzenia użytkownika.")
                result.setdefault("needsAnotherPhoto", not bool(result["candidates"]))
                return self.send_json(200, result)
            symptom = str(body.get("symptom", ""))[:200]
            species = str(body.get("speciesName", "nieustalony"))[:120]
            requirements = str(body.get("requirements", "brak dodatkowych danych"))[:1200]
            prompt = ("Jesteś ostrożnym asystentem pielęgnacji roślin. Objaw: " + symptom + ". Gatunek: " + species + ". Własne wymagania użytkownika: " + requirements + ". "
                      "Na podstawie zdjęcia, jeśli jest, podaj tylko bezpieczne, odwracalne kontrole; nie dawkuj chemii i nie nakazuj podlewania. "
                      "Zwróć WYŁĄCZNIE JSON: {hypotheses:[{title,likelihood,evidence,safeChecks}],missingInformation:[string],uncertainty:string}. "
                      "likelihood: niska, średnia lub wyższa. Maksymalnie 3 hipotezy.")
            result = ollama(prompt, image)
            result.setdefault("hypotheses", [])
            result.setdefault("missingInformation", ["Sprawdź wilgotność podłoża i spody liści."])
            result.setdefault("uncertainty", "To wskazówki pomocnicze, nie pewna diagnoza.")
            return self.send_json(200, result)
        except (ValueError, RuntimeError) as exc:
            self.send_json(400 if isinstance(exc, ValueError) else 503, {"error": str(exc)})
        except Exception:
            self.send_json(500, {"error": "Nie udało się przeanalizować zdjęcia. Spróbuj ponownie."})

if __name__ == "__main__":
    ThreadingHTTPServer(("0.0.0.0", int(os.environ.get("PEDY_AI_PORT", "8788"))), Handler).serve_forever()
