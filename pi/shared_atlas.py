"""Community entries for users of this private LAN/Tailscale server.

Separate database from personal collections and AI quota; no public listener added.
"""
import base64
import hashlib
import io
import json
import os
import sqlite3
import unicodedata
from PIL import Image, ImageOps

DB = os.environ.get('PEDY_ATLAS_DB', '/var/lib/pedy-ai/atlas.sqlite3')

def connection():
    db = sqlite3.connect(DB, timeout=5)
    db.execute('CREATE TABLE IF NOT EXISTS entries (id TEXT PRIMARY KEY, name_key TEXT UNIQUE, payload TEXT NOT NULL)')
    return db

def entries():
    with connection() as db:
        return {'entries': [json.loads(row[0]) for row in db.execute('SELECT payload FROM entries ORDER BY name_key')], 'schemaVersion': 1}

def publish(body):
    if body.get('shareConsent') is not True:
        raise ValueError('Potwierdź prawo do udostępnienia zdjęcia i opisu.')
    name = body.get('name', '')
    requirements = body.get('requirements', '')
    source = body.get('source', '')
    if not all(isinstance(x, str) for x in (name, requirements, source)):
        raise ValueError('Niepoprawny opis gatunku.')
    name, requirements, source = name.strip(), requirements.strip(), source.strip()
    if not 2 <= len(name) <= 120 or not 10 <= len(requirements) <= 4000 or not 3 <= len(source) <= 500:
        raise ValueError('Podaj nazwę, wymagania (10–4000 znaków) i źródło opisu.')
    image = body.get('image', '')
    if not isinstance(image, str) or len(image) > 400000:
        raise ValueError('Zdjęcie jest za duże.')
    cleaned = ''
    if image:
        try:
            raw = base64.b64decode(image, validate=True)
            with Image.open(io.BytesIO(raw)) as im:
                if im.width * im.height > 4000000:
                    raise ValueError('Zdjęcie jest za duże.')
                im = ImageOps.exif_transpose(im).convert('RGB')
                im.thumbnail((320, 320))
                buf = io.BytesIO()
                im.save(buf, format='JPEG', quality=65)
                cleaned = base64.b64encode(buf.getvalue()).decode()
        except Exception as exc:
            raise ValueError('Nie udało się odczytać zdjęcia.') from exc
    key = ' '.join(unicodedata.normalize('NFKC', name).casefold().split())
    entry = {'id': hashlib.sha256(key.encode()).hexdigest(), 'name': name,
             'requirements': requirements, 'source': source, 'image': cleaned,
             'status': 'community_unverified'}
    with connection() as db:
        db.execute('BEGIN IMMEDIATE')
        existing = db.execute('SELECT payload FROM entries WHERE name_key=?', (key,)).fetchone()
        if existing:
            if json.loads(existing[0]) == entry:
                return {'entry': entry, 'message': 'Ten wpis jest już zapisany we wspólnym atlasie.'}
            raise ValueError('Gatunek o tej nazwie już istnieje. Istniejący wpis nie został nadpisany.')
        if db.execute('SELECT COUNT(*) FROM entries').fetchone()[0] >= 100:
            raise ValueError('Atlas osiągnął limit 100 wpisów społeczności. Skontaktuj się z administratorem.')
        db.execute('INSERT INTO entries VALUES (?, ?, ?)', (entry['id'], key, json.dumps(entry, ensure_ascii=False)))
    return {'entry': entry, 'message': 'Zapisano we wspólnym atlasie jako wpis niezweryfikowany.'}
