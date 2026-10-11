"""Receive a mesh JSON {pos, nor, uv, idx} from Studio (POST :34999, EditableMesh dump; HttpEnabled on in Edit only
for the call), write a .glb, upload it as a Model via Open Cloud (ROBLOX_API_KEY in .env). Then InsertService:LoadAsset
(assetId) in Edit gives the MeshPart and its new MeshId. Usage: python tools/mesh/upload.py <Name>  (background first)."""
import json, pathlib, struct, sys, time
from http.server import BaseHTTPRequestHandler, HTTPServer
import requests

ROOT = pathlib.Path(r"C:\Users\User\OneDrive\Desktop\Coding\glitched_together")
OUT = pathlib.Path(__file__).parent
API = "https://apis.roblox.com/assets/v1"
CREATOR = "11657510634"
NAME = sys.argv[1] if len(sys.argv) > 1 else "GT_Mesh"

def key():
    for line in (ROOT / ".env").read_text(encoding="utf-8").splitlines():
        if line.startswith("ROBLOX_API_KEY="):
            return line.split("=", 1)[1].strip()

got = {}
class H(BaseHTTPRequestHandler):
    def do_POST(self):
        n = int(self.headers["Content-Length"])
        got["data"] = json.loads(self.rfile.read(n))
        self.send_response(200); self.end_headers(); self.wfile.write(b"ok")
    def log_message(self, *a): pass

srv = HTTPServer(("127.0.0.1", 34999), H)
while "data" not in got:
    srv.handle_request()
d = got["data"]
pos, nor, uv, idx = d["pos"], d["nor"], d["uv"], d["idx"]
nv = len(pos) // 3

def pad(b):
    return b + b"\x00" * ((4 - len(b) % 4) % 4)
bp = struct.pack(f"<{len(pos)}f", *pos)
bn = struct.pack(f"<{len(nor)}f", *nor)
bu = struct.pack(f"<{len(uv)}f", *uv)
bi = struct.pack(f"<{len(idx)}I", *idx)
blobs = [pad(bp), pad(bn), pad(bu), pad(bi)]
offs, o = [], 0
for b in blobs:
    offs.append(o); o += len(b)
binary = b"".join(blobs)
xs, ys, zs = pos[0::3], pos[1::3], pos[2::3]
gltf = {
    "asset": {"version": "2.0"},
    "scene": 0, "scenes": [{"nodes": [0]}],
    "nodes": [{"mesh": 0, "name": NAME}],
    "meshes": [{"name": NAME, "primitives": [{"attributes": {"POSITION": 0, "NORMAL": 1, "TEXCOORD_0": 2}, "indices": 3}]}],
    "buffers": [{"byteLength": len(binary)}],
    "bufferViews": [
        {"buffer": 0, "byteOffset": offs[0], "byteLength": len(bp), "target": 34962},
        {"buffer": 0, "byteOffset": offs[1], "byteLength": len(bn), "target": 34962},
        {"buffer": 0, "byteOffset": offs[2], "byteLength": len(bu), "target": 34962},
        {"buffer": 0, "byteOffset": offs[3], "byteLength": len(bi), "target": 34963},
    ],
    "accessors": [
        {"bufferView": 0, "componentType": 5126, "count": nv, "type": "VEC3", "min": [min(xs), min(ys), min(zs)], "max": [max(xs), max(ys), max(zs)]},
        {"bufferView": 1, "componentType": 5126, "count": nv, "type": "VEC3"},
        {"bufferView": 2, "componentType": 5126, "count": nv, "type": "VEC2"},
        {"bufferView": 3, "componentType": 5125, "count": len(idx), "type": "SCALAR"},
    ],
}
js = json.dumps(gltf).encode()
js += b" " * ((4 - len(js) % 4) % 4)
glb = struct.pack("<III", 0x46546C67, 2, 12 + 8 + len(js) + 8 + len(binary))
glb += struct.pack("<II", len(js), 0x4E4F534A) + js + struct.pack("<II", len(binary), 0x004E4942) + binary
path = OUT / f"{NAME}.glb"
path.write_bytes(glb)
print("wrote", path, nv, "verts", len(idx) // 3, "tris", flush=True)

k = key()
req = {"assetType": "Model", "displayName": NAME, "description": "Glitched Together held item",
       "creationContext": {"creator": {"userId": CREATOR}}}
r = requests.post(f"{API}/assets", headers={"x-api-key": k}, data={"request": json.dumps(req)},
                  files={"fileContent": (path.name, glb, "model/gltf-binary")}, timeout=120)
print(r.status_code, r.text[:300], flush=True)
op = r.json()
while not op.get("done"):
    time.sleep(2)
    op = requests.get(f"{API}/{op['path']}", headers={"x-api-key": k}, timeout=30).json()
print("RESULT", json.dumps(op)[:600], flush=True)
