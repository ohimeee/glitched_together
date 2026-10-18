"""Read the testers' bug reports (Util/BugReports → DataStore "BugReports") through Open Cloud.

python tools/beta/bugs.py          new reports since the last run (remembered in tools/beta/seen_bugs.txt)
python tools/beta/bugs.py --all    every report

Needs ROBLOX_API_KEY in .env with the Data Stores scopes (universe-datastores.objects:list + :read) for universe
10771484072. Reports from Studio playtests land in the same store (keys sort by time).
"""
import json
import pathlib
import sys
import time

import requests

ROOT = pathlib.Path(__file__).resolve().parents[2]
UNIVERSE = "10771484072"
BASE = f"https://apis.roblox.com/datastores/v1/universes/{UNIVERSE}/standard-datastores/datastore"
SEEN = pathlib.Path(__file__).with_name("seen_bugs.txt")


def api_key() -> str:
    for line in (ROOT / ".env").read_text(encoding="utf-8").splitlines():
        if line.startswith("ROBLOX_API_KEY="):
            return line.split("=", 1)[1].strip()
    raise SystemExit("ROBLOX_API_KEY missing in .env")


H = {"x-api-key": api_key()}


def keys():
    out, cursor = [], ""
    while True:
        params = {"datastoreName": "BugReports", "limit": 100}
        if cursor:
            params["cursor"] = cursor
        r = requests.get(f"{BASE}/entries", headers=H, params=params, timeout=20)
        if r.status_code in (401, 403):
            raise SystemExit(f"API key can't read data stores ({r.status_code}): add the Data Stores scopes. {r.text[:200]}")
        r.raise_for_status()
        j = r.json()
        out += [k["key"] for k in j.get("keys", [])]
        cursor = j.get("nextPageCursor") or ""
        if not cursor:
            return out


def entry(key):
    r = requests.get(f"{BASE}/entries/entry", headers=H, params={"datastoreName": "BugReports", "entryKey": key}, timeout=20)
    r.raise_for_status()
    return r.json()


def main():
    seen = set(SEEN.read_text().split()) if SEEN.exists() else set()
    show_all = "--all" in sys.argv
    todo = sorted(k for k in keys() if show_all or k not in seen)
    if not todo:
        print("no new bug reports")
        return
    for k in todo:
        e = entry(k)
        when = time.strftime("%b %d %H:%M", time.localtime(e.get("time", 0)))
        where = f"{e.get('place')} {e.get('world') or ''} cp {e.get('checkpoint', '-')} @ {e.get('pos')}"
        print(f"[{when}] {e.get('user')} ({e.get('device')}, v{e.get('placeVersion')}) {where}")
        print(f"    {e.get('text')}")
        if e.get("others"):
            print(f"    with: {', '.join(e['others'])}")
        for err in e.get("errors") or []:
            print(f"    error: {err}")
        seen.add(k)
    SEEN.write_text("\n".join(sorted(seen)))
    print(f"{len(todo)} report(s)")


if __name__ == "__main__":
    main()
