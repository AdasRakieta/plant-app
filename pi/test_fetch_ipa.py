import io
import json
import os
from pathlib import Path
import plistlib
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


def valid_ipa() -> bytes:
    info = plistlib.dumps({
        "CFBundleIdentifier": "pl.pedy.app",
        "CFBundleDisplayName": "Pedy",
        "CFBundleShortVersionString": "0.1.0",
        "CFBundleVersion": "42",
    })
    return zipped("Payload/Pedy.app/Info.plist", info)


class FetchIPATests(unittest.TestCase):
    def test_skips_failed_newer_run(self):
        ipa = valid_ipa()
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
        ipa = valid_ipa()
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
            self.assertEqual(json.loads((Path(folder) / "build.json").read_text())["source_format_version"],
                             fetch_ipa.SOURCE_FORMAT_VERSION)
            self.assertIn("Pedy.ipa", (Path(folder) / "Pedy.sha256").read_text())
            source = json.loads((Path(folder) / "source-local.json").read_text())
            self.assertEqual(source["apps"][0]["versions"][0]["buildVersion"], "42")
            self.assertEqual(source["apps"][0]["versions"][0]["downloadURL"],
                             "http://192.168.1.218:8787/app/Pedy.ipa")
            self.assertEqual(fetch_ipa.main(), 0)
            self.assertEqual(request.call_count, 5)

    def test_regenerates_old_source_metadata_once(self):
        ipa = valid_ipa()
        artifact = zipped("Pedy-unsigned.ipa", ipa)
        listing = json.dumps({"artifacts": [{
            "id": 8, "name": fetch_ipa.NAME, "expired": False,
            "workflow_run": {"id": 80, "head_branch": "main"},
            "created_at": "2026-10-02", "archive_download_url": "https://example.invalid/8",
        }]}).encode()
        with tempfile.TemporaryDirectory() as folder, patch.dict(os.environ, {
            "PEDY_REPO": "AdasRakieta/plant-app", "GH_READ_TOKEN": "test-token", "PEDY_SERVE_DIR": folder,
        }), patch.object(fetch_ipa, "request", side_effect=[
            listing, b'{"conclusion":"success","head_branch":"main"}', artifact,
        ]) as request:
            target = Path(folder)
            (target / "Pedy.ipa").write_bytes(ipa)
            (target / "Pedy.sha256").write_text("old  Pedy.ipa\n")
            (target / "source.json").write_text('{"apps":[{"name":"Pędy"}]}')
            (target / "source-local.json").write_text('{"apps":[{"name":"Pędy"}]}')
            (target / "build.json").write_text('{"artifact_id": 8}')

            self.assertEqual(fetch_ipa.main(), 0)

            source = json.loads((target / "source-local.json").read_text())
            self.assertEqual(source["name"], "Pedy")
            self.assertEqual(source["apps"][0]["name"], "Pedy")
            self.assertEqual(request.call_count, 3)

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

    def test_non_ascii_display_name_is_rejected_before_publish(self):
        info = plistlib.dumps({
            "CFBundleIdentifier": "pl.pedy.app",
            "CFBundleDisplayName": "Pędy",
            "CFBundleShortVersionString": "0.1.0",
            "CFBundleVersion": "42",
        })
        artifact = zipped("Pedy-unsigned.ipa", zipped("Payload/Pedy.app/Info.plist", info))
        listing = json.dumps({"artifacts": [{
            "id": 10, "name": fetch_ipa.NAME, "expired": False,
            "workflow_run": {"id": 100, "head_branch": "main"},
            "created_at": "2026-10-03", "archive_download_url": "https://example.invalid/10",
        }]}).encode()
        with tempfile.TemporaryDirectory() as folder, patch.dict(os.environ, {
            "PEDY_REPO": "AdasRakieta/plant-app", "GH_READ_TOKEN": "test-token", "PEDY_SERVE_DIR": folder,
        }), patch.object(fetch_ipa, "request", side_effect=[
            listing, b'{"conclusion":"success","head_branch":"main"}', artifact,
        ]):
            (Path(folder) / "Pedy.ipa").write_bytes(b"old")
            with self.assertRaises(ValueError):
                fetch_ipa.main()
            self.assertEqual((Path(folder) / "Pedy.ipa").read_bytes(), b"old")


if __name__ == "__main__":
    unittest.main()
