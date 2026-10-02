import io
import json
import os
from pathlib import Path
import tempfile
import unittest
from unittest.mock import patch
import zipfile

import fetch_ipa


def zipped(name: str, data: bytes) -> bytes:
    output = io.BytesIO()
    with zipfile.ZipFile(output, "w") as archive:
        archive.writestr(name, data)
    return output.getvalue()


class FetchIPATests(unittest.TestCase):
    def test_skips_failed_newer_run(self):
        ipa = zipped("Payload/Pedy.app/Info.plist", b"plist")
        artifact = zipped("Pedy-unsigned.ipa", ipa)
        listing = json.dumps({"artifacts": [
            {"id": 10, "name": fetch_ipa.NAME, "expired": False,
             "workflow_run": {"id": 100, "head_branch": "main"},
             "created_at": "2026-10-03", "archive_download_url": "https://example.invalid/10"},
            {"id": 8, "name": fetch_ipa.NAME, "expired": False,
             "workflow_run": {"id": 80, "head_branch": "main"},
             "created_at": "2026-10-02", "archive_download_url": "https://example.invalid/8"},
        ]}).encode()
        with tempfile.TemporaryDirectory() as folder, patch.dict(os.environ, {
            "PEDY_REPO": "AdasRakieta/plant-app", "GH_READ_TOKEN": "test-token", "PEDY_SERVE_DIR": folder,
        }), patch.object(fetch_ipa, "request", side_effect=[
            listing,
            b'{"conclusion":"failure","head_branch":"main"}',
            b'{"conclusion":"success","head_branch":"main"}',
            artifact,
        ]) as request:
            self.assertEqual(fetch_ipa.main(), 0)
            self.assertEqual(json.loads((Path(folder) / "build.json").read_text())["artifact_id"], 8)
            self.assertEqual(request.call_count, 4)

    def test_downloads_only_latest_main_artifact_and_keeps_existing_on_repeat(self):
        ipa = zipped("Payload/Pedy.app/Info.plist", b"plist")
        artifact = zipped("Pedy-unsigned.ipa", ipa)
        listing = json.dumps({"artifacts": [
            {"id": 7, "name": fetch_ipa.NAME, "expired": False,
             "workflow_run": {"id": 70, "head_branch": "feature"}, "created_at": "2026-10-03", "archive_download_url": "https://example.invalid/7"},
            {"id": 8, "name": fetch_ipa.NAME, "expired": False,
             "workflow_run": {"id": 80, "head_branch": "main"}, "created_at": "2026-10-02", "archive_download_url": "https://example.invalid/8"},
        ]}).encode()
        with tempfile.TemporaryDirectory() as folder, patch.dict(os.environ, {
            "PEDY_REPO": "AdasRakieta/plant-app", "GH_READ_TOKEN": "test-token", "PEDY_SERVE_DIR": folder,
        }), patch.object(fetch_ipa, "request", side_effect=[listing, b'{"conclusion":"success","head_branch":"main"}', artifact, listing, b'{"conclusion":"success","head_branch":"main"}']) as request:
            self.assertEqual(fetch_ipa.main(), 0)
            self.assertEqual((Path(folder) / "Pedy.ipa").read_bytes(), ipa)
            self.assertEqual(json.loads((Path(folder) / "build.json").read_text())["artifact_id"], 8)
            self.assertIn("Pedy.ipa", (Path(folder) / "Pedy.sha256").read_text())
            self.assertEqual(fetch_ipa.main(), 0)
            self.assertEqual(request.call_count, 5)

    def test_invalid_payload_does_not_replace_existing_file(self):
        bad = zipped("Pedy-unsigned.ipa", b"not an ipa")
        listing = json.dumps({"artifacts": [{
            "id": 9, "name": fetch_ipa.NAME, "expired": False,
            "workflow_run": {"id": 90, "head_branch": "main"}, "created_at": "2026-10-03",
            "archive_download_url": "https://example.invalid/9",
        }]}).encode()
        with tempfile.TemporaryDirectory() as folder, patch.dict(os.environ, {
            "PEDY_REPO": "AdasRakieta/plant-app", "GH_READ_TOKEN": "test-token", "PEDY_SERVE_DIR": folder,
        }), patch.object(fetch_ipa, "request", side_effect=[listing, b'{"conclusion":"success","head_branch":"main"}', bad]):
            (Path(folder) / "Pedy.ipa").write_bytes(b"old")
            with self.assertRaises(ValueError):
                fetch_ipa.main()
            self.assertEqual((Path(folder) / "Pedy.ipa").read_bytes(), b"old")


if __name__ == "__main__":
    unittest.main()
