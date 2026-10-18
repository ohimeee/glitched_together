"""Give the experience "Use" permission on every asset the game references that buldak0555 owns.

Why (Oct 18): the experience moved into the Night Owl Interactive group (129463626); images uploaded under the
user account then fail to load in it ("experience doesn't have access permission"). Meshes mostly still load,
images (textures, decals, UI) don't.

python tools/assets/grant_permissions.py          scan src/ for asset ids, look up owners, grant (batches of 50)
python tools/assets/grant_permissions.py --dry    only list what would be granted

Needs ROBLOX_API_KEY in .env with the "asset-permissions:write" scope (Creator Hub → Credentials → the key →
add API System "Asset Permissions"), owned by the asset owner (buldak0555).
"""
import json, pathlib, re, sys, time
import requests

ROOT = pathlib.Path(__file__).resolve().parents[2]
UNIVERSE = "10771484072"
OWNER = "buldak0555"


def api_key() -> str:
    for line in (ROOT / ".env").read_text(encoding="utf-8").splitlines():
        if line.startswith("ROBLOX_API_KEY="):
            return line.split("=", 1)[1].strip()
    raise SystemExit("ROBLOX_API_KEY missing in .env")


def scan_ids() -> list[str]:
    ids = set()
    pat = re.compile(r"(?:rbxassetid://|asset/\?id=|\bId\s*=\s*|\b)(\d{9,16})\b")
    for f in list((ROOT / "src").rglob("*.luau")) + list(ROOT.glob("*.project.json")):
        for m in pat.finditer(f.read_text(encoding="utf-8", errors="ignore")):
            ids.add(m.group(1))
    return sorted(ids)


def owner_of(aid: str):
    for _ in range(4):
        r = requests.get(f"https://economy.roblox.com/v2/assets/{aid}/details", timeout=15)
        if r.status_code == 429:
            time.sleep(5)
            continue
        if r.status_code != 200:
            return None, None
        d = r.json()
        return (d.get("Creator") or {}).get("Name"), d.get("AssetTypeId")
    return None, None


def main():
    dry = "--dry" in sys.argv
    ids = scan_ids()
    print(f"{len(ids)} candidate ids in src/")
    mine = []
    for i, aid in enumerate(ids):
        name, typ = owner_of(aid)
        if name == OWNER:
            mine.append(aid)
        if i % 50 == 49:
            print(f"  looked up {i + 1}/{len(ids)}, {len(mine)} owned by {OWNER}")
        time.sleep(0.25)
    print(f"{len(mine)} assets owned by {OWNER}")
    (ROOT / "tools" / "assets" / "owned_ids.json").write_text(json.dumps(mine, indent=0))
    if dry:
        return
    key = api_key()
    ok = 0
    for start in range(0, len(mine), 50):
        batch = mine[start : start + 50]
        body = {
            "subject": {"subjectType": "Universe", "subjectId": UNIVERSE},
            "action": "Use",
            "requests": [{"assetId": a} for a in batch],
        }
        r = requests.patch(
            "https://apis.roblox.com/asset-permissions-api/v1/assets/permissions",
            headers={"x-api-key": key, "Content-Type": "application/json"},
            data=json.dumps(body),
            timeout=30,
        )
        if r.status_code != 200:
            print("batch failed", r.status_code, r.text[:300])
            continue
        res = r.json()
        failed = res.get("errors") or res.get("failedAssets") or []
        ok += len(batch) - len(failed)
        if failed:
            print("  some failed:", json.dumps(failed)[:300])
    print(f"granted Use to universe {UNIVERSE}: {ok}/{len(mine)}")


if __name__ == "__main__":
    main()
