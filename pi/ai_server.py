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
    payload = json.dumps({"model": MODEL, "stream": False, "options": {"temperature": 0.1, "num_predict": 16}, "messages": [message]}).encode()
    req = urllib.request.Request(OLLAMA_URL, data=payload, headers={"Content-Type": "application/json"})
    try:
        with urllib.request.urlopen(req, timeout=10) as response:
            raw = json.load(response)["message"]["content"]
        return raw.strip()
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

def catalog_match(answer):
    text = answer.casefold()
    for species_id, common, latin in CATALOG:
        if species_id.casefold() in text or common.casefold() in text or latin.casefold() in text:
            return {"speciesID": species_id, "commonName": common, "latinName": latin, "confidence": 0.55, "reason": answer[:280]}
    return None

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
                prompt = ("Identify the plant. Choose one: " + catalog + ". "
                          "Reply only with the chosen name or UNKNOWN.")
                try:
                    answer = ollama(prompt, image)
                except RuntimeError:
                    return self.send_json(200, {
                        "candidates": [],
                        "uncertainty": "Lokalny model nie zdążył rozpoznać zdjęcia. Spróbuj ponownie z wyraźnym ujęciem całej rośliny i liścia.",
                        "needsAnotherPhoto": True
                    })
                candidate = catalog_match(answer)
                return self.send_json(200, {
                    "candidates": [candidate] if candidate else [],
                    "uncertainty": "Wynik lokalnego modelu wymaga potwierdzenia użytkownika.",
                    "needsAnotherPhoto": candidate is None
                })
            symptom = str(body.get("symptom", ""))[:200]
            species = str(body.get("speciesName", "nieustalony"))[:120]
            requirements = str(body.get("requirements", "brak dodatkowych danych"))[:1200]
            prompt = ("Plant: " + species + ". Symptom: " + symptom + ". Context: " + requirements + ". "
                      "State one possible observation in at most six words. No treatment advice.")
            try:
                answer = ollama(prompt, image)
            except RuntimeError:
                return self.send_json(200, safe_fallback(symptom))
            return self.send_json(200, {
                "hypotheses": [{"title": "Ocena lokalnego modelu", "likelihood": "nieustalona", "evidence": answer[:600], "safeChecks": ["Sprawdź wilgotność podłoża pod powierzchnią.", "Obejrzyj spody liści i odpływ doniczki."]}],
                "missingInformation": ["Ostatnie podlewanie", "warunki światła", "zbliżenie objawu"],
                "uncertainty": "To wskazówka z lokalnego modelu, nie pewna diagnoza ani zalecenie zabiegu."
            })
        except (ValueError, RuntimeError) as exc:
            self.send_json(400 if isinstance(exc, ValueError) else 503, {"error": str(exc)})
        except Exception:
            self.send_json(500, {"error": "Nie udało się przeanalizować zdjęcia. Spróbuj ponownie."})

if __name__ == "__main__":
    ThreadingHTTPServer(("0.0.0.0", int(os.environ.get("PEDY_AI_PORT", "8788"))), Handler).serve_forever()
