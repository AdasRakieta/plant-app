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
    payload = json.dumps({"model": MODEL, "stream": False, "format": "json", "options": {"temperature": 0.1, "num_predict": 96}, "messages": [message]}).encode()
    req = urllib.request.Request(OLLAMA_URL, data=payload, headers={"Content-Type": "application/json"})
    try:
        with urllib.request.urlopen(req, timeout=30) as response:
            raw = json.load(response)["message"]["content"]
        return json.loads(raw)
    except urllib.error.HTTPError as exc:
        raise RuntimeError("Model AI nie jest jeszcze gotowy na serwerze.") from exc
    except (urllib.error.URLError, KeyError, ValueError) as exc:
        raise RuntimeError("Lokalny model AI nie odpowiedział. Spróbuj ponownie za chwilę.") from exc

def safe_fallback(symptom):
    return {
        "hypotheses": [{
            "title": "Potrzebna bezpieczna kontrola ręczna",
            "likelihood": "nieustalona",
            "evidence": "Model lokalny nie zwrócił wyniku na czas; nie zgadujemy przyczyny na podstawie samego objawu: " + symptom + ".",
            "safeChecks": ["Sprawdź wilgotność podłoża pod powierzchnią.", "Obejrzyj spody liści i odpływ doniczki.", "Zrób wyraźne zdjęcie liścia oraz całej rośliny."]
        }],
        "missingInformation": ["Warunki światła", "ostatnie podlewanie", "zbliżenie objawu"],
        "uncertainty": "To bezpieczny wynik zastępczy. Lokalny model nie zdążył z analizą zdjęcia, więc nie proponujemy zabiegu."
    }

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
                catalog = "; ".join(f"{i}:{n}" for i, n, _ in CATALOG)
                prompt = ("Rozpoznaj roślinę. Katalog: " + catalog + ". "
                          "Tylko JSON {candidates:[{speciesID,commonName,latinName,confidence,reason}],uncertainty,needsAnotherPhoto}. "
                          "Maksymalnie 2 kandydaty. Nie zgaduj.")
                try:
                    result = ollama(prompt, image)
                except RuntimeError:
                    return self.send_json(200, {
                        "candidates": [],
                        "uncertainty": "Lokalny model nie zdążył rozpoznać zdjęcia. Spróbuj ponownie z wyraźnym ujęciem całej rośliny i liścia.",
                        "needsAnotherPhoto": True
                    })
                result.setdefault("candidates", [])
                result.setdefault("uncertainty", "Wynik wymaga potwierdzenia użytkownika.")
                result.setdefault("needsAnotherPhoto", not bool(result["candidates"]))
                return self.send_json(200, result)
            symptom = str(body.get("symptom", ""))[:200]
            species = str(body.get("speciesName", "nieustalony"))[:120]
            requirements = str(body.get("requirements", "brak dodatkowych danych"))[:1200]
            prompt = ("Objaw: " + symptom + ". Gatunek: " + species + ". Wymagania: " + requirements + ". "
                      "Tylko bezpieczne kontrole, bez nakazu podlewania lub chemii. "
                      "Tylko JSON {hypotheses:[{title,likelihood,evidence,safeChecks}],missingInformation:[string],uncertainty:string}. Maksymalnie 2 hipotezy.")
            try:
                result = ollama(prompt, image)
            except RuntimeError:
                return self.send_json(200, safe_fallback(symptom))
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
