"""Upload the move animations (src/shared/Config/MoveAnims.luau) to Roblox with Open Cloud.

1. python tools/anim/upload.py receive    (background: waits for Studio to POST the clips, writes build/anims/*.model.json)
   then run tools/anim/push.luau in Studio (Edit, execute_luau): it POSTs every clip to port 34998.
2. python tools/anim/upload.py upload     builds each clip to .rbxm with Rojo and creates (first time) or updates
   (changed clips only) the Animation asset, then writes the ids into MoveAnims.Ids.

Needs ROBLOX_API_KEY in .env (Assets read+write). Ids + content hashes live in tools/anim/ids.json, so a re-upload
updates the same asset (ids never change).
"""

import hashlib
import json
import pathlib
import re
import subprocess
import sys
import time
from http.server import BaseHTTPRequestHandler, HTTPServer

import requests

ROOT = pathlib.Path(__file__).resolve().parents[2]
OUT = ROOT / "build" / "anims"
IDS = ROOT / "tools" / "anim" / "ids.json"
CONFIG = ROOT / "src" / "shared" / "Config" / "MoveAnims.luau"
PORT = 34998
CREATOR_USER_ID = "11657510634"  # buldak0555, the experience owner
API = "https://apis.roblox.com/assets/v1"


def api_key() -> str:
    for line in (ROOT / ".env").read_text(encoding="utf-8").splitlines():
        if line.startswith("ROBLOX_API_KEY="):
            return line.split("=", 1)[1].strip()
    sys.exit("ROBLOX_API_KEY missing from .env")


def receive() -> None:
    class Handler(BaseHTTPRequestHandler):
        def do_POST(self):
            body = self.rfile.read(int(self.headers["Content-Length"]))
            clips = json.loads(body)
            OUT.mkdir(parents=True, exist_ok=True)
            for name, tree in clips.items():
                tree.pop("name", None)
                (OUT / f"{name}.model.json").write_text(json.dumps(tree, indent=1), encoding="utf-8")
            self.send_response(200)
            self.end_headers()
            self.wfile.write(f"saved {len(clips)}".encode())
            print(f"saved {len(clips)} clips to {OUT}")
            self.server.done = True

        def log_message(self, *args):
            pass

    server = HTTPServer(("127.0.0.1", PORT), Handler)
    server.done = False
    print(f"waiting on 127.0.0.1:{PORT}")
    while not server.done:
        server.handle_request()


def build_rbxm(name: str) -> pathlib.Path:
    project = OUT / f"{name}.project.json"
    project.write_text(json.dumps({"name": name, "tree": {"$path": f"{name}.model.json"}}), encoding="utf-8")
    rbxm = OUT / f"{name}.rbxm"
    subprocess.run(["rojo", "build", str(project), "-o", str(rbxm)], check=True, capture_output=True, cwd=ROOT)
    return rbxm


def wait_operation(key: str, op: dict) -> dict:
    while not op.get("done"):
        time.sleep(1)
        r = requests.get(f"{API}/{op['path']}", headers={"x-api-key": key}, timeout=30)
        r.raise_for_status()
        op = r.json()
    if "error" in op:
        raise RuntimeError(op["error"])
    return op["response"]


def upload_one(key: str, name: str, rbxm: pathlib.Path, asset_id: str | None) -> str:
    files = {"fileContent": (rbxm.name, rbxm.read_bytes(), "model/x-rbxm")}
    if asset_id:
        request = {"assetId": asset_id}
        r = requests.patch(
            f"{API}/assets/{asset_id}",
            headers={"x-api-key": key},
            data={"request": json.dumps(request)},
            files=files,
            timeout=60,
        )
    else:
        request = {
            "assetType": "Animation",
            "displayName": f"GT {name}",
            "description": "Glitched Together move animation",
            "creationContext": {"creator": {"userId": CREATOR_USER_ID}},
        }
        r = requests.post(
            f"{API}/assets",
            headers={"x-api-key": key},
            data={"request": json.dumps(request)},
            files=files,
            timeout=60,
        )
    if not r.ok:
        raise RuntimeError(f"{name}: {r.status_code} {r.text[:300]}")
    response = wait_operation(key, r.json())
    return str(response.get("assetId") or asset_id)


def write_ids(ids: dict) -> None:
    lines = "".join(f'\t{name} = "rbxassetid://{entry["id"]}",\n' for name, entry in sorted(ids.items()))
    src = CONFIG.read_text(encoding="utf-8")
    new = re.sub(
        r"local Ids: \{ \[string\]: string \} = \{.*?\n\}",
        "local Ids: { [string]: string } = {\n" + lines + "}",
        src,
        count=1,
        flags=re.S,
    )
    new = new.replace("local Ids: { [string]: string } = {}", "local Ids: { [string]: string } = {\n" + lines + "}")
    CONFIG.write_text(new, encoding="utf-8", newline="\n")


def upload(only: list[str]) -> None:
    key = api_key()
    ids = json.loads(IDS.read_text(encoding="utf-8")) if IDS.exists() else {}
    for model in sorted(OUT.glob("*.model.json")):
        name = model.name.removesuffix(".model.json")
        if only and name not in only:
            continue
        digest = hashlib.sha1(model.read_bytes()).hexdigest()
        entry = ids.get(name)
        if entry and entry.get("hash") == digest:
            continue
        rbxm = build_rbxm(name)
        asset_id = upload_one(key, name, rbxm, entry and entry["id"])
        ids[name] = {"id": asset_id, "hash": digest}
        IDS.write_text(json.dumps(ids, indent=1, sort_keys=True), encoding="utf-8")
        print(f"{name}: {asset_id}" + (" (updated)" if entry else " (new)"))
    write_ids(ids)
    print(f"{len(ids)} ids in MoveAnims.Ids")


if __name__ == "__main__":
    mode = sys.argv[1] if len(sys.argv) > 1 else ""
    if mode == "receive":
        receive()
    elif mode == "upload":
        upload(sys.argv[2:])
    else:
        sys.exit(__doc__)
