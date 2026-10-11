"""Upload Blender exports (.glb / .fbx) as Roblox Model assets via Open Cloud (ROBLOX_API_KEY in .env), no Studio
Import 3D clicks. Prints `RESULT <file> <assetId>` per file. Then in Studio Edit: InsertService:LoadAsset(assetId)
gives a Model whose MeshParts carry the new MeshIds (copy them into the ArtService skin table).
Usage: python tools/mesh/upload_model.py <file.glb> [more files...]"""
import json, pathlib, sys, time
import requests

ROOT = pathlib.Path(r"C:\Users\User\OneDrive\Desktop\Coding\glitched_together")
API = "https://apis.roblox.com/assets/v1"
CREATOR = "11657510634"
TYPES = {".glb": "model/gltf-binary", ".gltf": "model/gltf+json", ".fbx": "model/fbx"}


def key():
    for line in (ROOT / ".env").read_text(encoding="utf-8").splitlines():
        if line.startswith("ROBLOX_API_KEY="):
            return line.split("=", 1)[1].strip()


def upload(path: pathlib.Path, k: str):
    req = {"assetType": "Model", "displayName": path.stem, "description": "Glitched Together environment kit",
           "creationContext": {"creator": {"userId": CREATOR}}}
    r = requests.post(f"{API}/assets", headers={"x-api-key": k}, data={"request": json.dumps(req)},
                      files={"fileContent": (path.name, path.read_bytes(), TYPES[path.suffix.lower()])}, timeout=300)
    if r.status_code >= 300:
        print("FAIL", path.name, r.status_code, r.text[:300], flush=True)
        return
    op = r.json()
    for _ in range(150):
        if op.get("done"):
            break
        time.sleep(2)
        op = requests.get(f"{API}/{op['path']}", headers={"x-api-key": k}, timeout=30).json()
    asset = (op.get("response") or {}).get("assetId")
    print("RESULT", path.name, asset or json.dumps(op)[:400], flush=True)


if __name__ == "__main__":
    k = key()
    for arg in sys.argv[1:]:
        upload(pathlib.Path(arg), k)
