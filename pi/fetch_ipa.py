#!/usr/bin/env python3
"""Fetch the newest successful main-branch unsigned IPA artifact to a private Pi directory.

Environment: PEDY_REPO=owner/repo, GH_READ_TOKEN=read-only token,
PEDY_SERVE_DIR=/srv/pedy (optional). Never put the token in a URL or log it.
"""

import hashlib
import io
import json
import os
from pathlib import Path
import sys
import tempfile
from urllib.error import HTTPError, URLError
from urllib.parse import quote
from urllib.parse import urlparse
from urllib.request import HTTPRedirectHandler, Request, build_opener
import zipfile


API = "https://api.github.com"
NAME = "pedy-unsigned-ipa"


def request(url: str, token: str) -> bytes:
    class SafeRedirect(HTTPRedirectHandler):
        def redirect_request(self, req, fp, code, msg, headers, newurl):
            if urlparse(newurl).scheme != "https":
                raise ValueError("Refusing a non-HTTPS redirect")
            redirected = super().redirect_request(req, fp, code, msg, headers, newurl)
            if redirected and urlparse(newurl).netloc != urlparse(req.full_url).netloc:
                redirected.remove_header("Authorization")
            return redirected

    req = Request(url, headers={
        "Authorization": f"Bearer {token}",
        "Accept": "application/vnd.github+json",
        "X-GitHub-Api-Version": "2022-11-28",
        "User-Agent": "pedy-pi-artifact-fetcher",
    })
    with build_opener(SafeRedirect).open(req, timeout=40) as response:
        return response.read(500_000_001)


def main() -> int:
    repo = os.getenv("PEDY_REPO", "")
    token = os.getenv("GH_READ_TOKEN", "")
    if len(repo.split("/")) != 2 or not token:
        print("Set PEDY_REPO=owner/repo and GH_READ_TOKEN", file=sys.stderr)
        return 2

    target = Path(os.getenv("PEDY_SERVE_DIR", "/srv/pedy"))
    target.mkdir(parents=True, exist_ok=True)
    url = f"{API}/repos/{quote(repo, safe='/')}/actions/artifacts?name={NAME}&per_page=100"
    listing = json.loads(request(url, token))
    candidates = [
        artifact for artifact in listing.get("artifacts", [])
        if artifact.get("name") == NAME
        and not artifact.get("expired")
        and (artifact.get("workflow_run") or {}).get("head_branch") == "main"
    ]
    if not candidates:
        print("No main-branch IPA artifact is available yet", file=sys.stderr)
        return 1
    latest = None
    for artifact in sorted(candidates, key=lambda a: a.get("created_at", ""), reverse=True):
        run_id = (artifact.get("workflow_run") or {}).get("id")
        if not run_id:
            continue
        run = json.loads(request(f"{API}/repos/{quote(repo, safe='/')}/actions/runs/{run_id}", token))
        if run.get("conclusion") == "success" and run.get("head_branch") == "main":
            latest = artifact
            break
    if latest is None:
        print("No successful main-branch IPA artifact is available yet", file=sys.stderr)
        return 1
    info_file = target / "build.json"
    if (info_file.exists() and (target / "Pedy.ipa").is_file()
            and (target / "Pedy.sha256").is_file()
            and json.loads(info_file.read_text()).get("artifact_id") == latest["id"]):
        print("Already current")
        return 0

    archive = request(latest["archive_download_url"], token)
    if len(archive) > 500_000_000:
        raise ValueError("Artifact is too large")
    with zipfile.ZipFile(io.BytesIO(archive)) as zipped:
        names = [name for name in zipped.namelist() if name.endswith(".ipa")]
        if names != ["Pedy-unsigned.ipa"]:
            raise ValueError("Artifact must contain exactly Pedy-unsigned.ipa")
        ipa = zipped.read(names[0])
    if not zipfile.is_zipfile(io.BytesIO(ipa)):
        raise ValueError("Downloaded IPA is not a ZIP archive")
    with zipfile.ZipFile(io.BytesIO(ipa)) as zipped:
        if "Payload/Pedy.app/Info.plist" not in zipped.namelist():
            raise ValueError("IPA has no Pedy.app payload")

    digest = hashlib.sha256(ipa).hexdigest()
    with tempfile.NamedTemporaryFile(dir=target, prefix=".pedy-", delete=False) as handle:
        handle.write(ipa)
        staged = Path(handle.name)
    staged.chmod(0o644)
    staged.replace(target / "Pedy.ipa")
    info = json.dumps({
        "artifact_id": latest["id"],
        "run_id": run_id,
        "created_at": latest["created_at"],
        "sha256": digest,
        "size_bytes": len(ipa),
    }, indent=2) + "\n"
    (target / "Pedy.sha256").write_text(f"{digest}  Pedy.ipa\n")
    with tempfile.NamedTemporaryFile(mode="w", dir=target, prefix=".build-", delete=False) as handle:
        handle.write(info)
        staged_info = Path(handle.name)
    staged_info.chmod(0o644)
    staged_info.replace(info_file)
    print(f"Updated artifact {latest['id']} SHA256 {digest}")
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except (HTTPError, URLError, OSError, ValueError, KeyError, json.JSONDecodeError) as exc:
        print(f"Fetch failed: {type(exc).__name__}: {exc}", file=sys.stderr)
        raise SystemExit(1)
