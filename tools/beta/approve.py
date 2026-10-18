"""Approve closed-beta testers (Oct 19): check each Roblox username is in Night Owl Interactive, then give them the
"Beta Tester" role (Config/Beta lets rank >= 10 play). Testers apply in pairs on https://forms.gle/VvvVmpakSBST1FqZ7.

python tools/beta/approve.py user1 user2 ...     check + give the role
python tools/beta/approve.py --check user1 ...   only report (in the community? current role?)

Needs ROBLOX_API_KEY in .env with the Groups API scopes group:read + group:write (Creator Hub → Credentials → the key →
add API System "Groups"), owned by the community owner (buldak0555). Open Cloud v2 groups endpoints are Beta.
"""
import pathlib
import sys

import requests

ROOT = pathlib.Path(__file__).resolve().parents[2]
GROUP = "129463626"
ROLE_NAME = "Beta Tester"
OWNER_ID = 11657510634  # buldak0555: never re-roled
CLOUD = f"https://apis.roblox.com/cloud/v2/groups/{GROUP}"


def api_key() -> str:
    for line in (ROOT / ".env").read_text(encoding="utf-8").splitlines():
        if line.startswith("ROBLOX_API_KEY="):
            return line.split("=", 1)[1].strip()
    raise SystemExit("ROBLOX_API_KEY missing in .env")


H = {"x-api-key": api_key()}


def user_ids(names):
    r = requests.post("https://users.roblox.com/v1/usernames/users",
                      json={"usernames": names, "excludeBannedUsers": True}, timeout=15)
    r.raise_for_status()
    return {u["requestedUsername"].lower(): (u["id"], u["name"]) for u in r.json()["data"]}


def roles():
    out, token = [], ""
    while True:
        params = {"maxPageSize": 20}
        if token:
            params["pageToken"] = token
        r = requests.get(f"{CLOUD}/roles", headers=H, params=params, timeout=15)
        r.raise_for_status()
        j = r.json()
        out += j.get("groupRoles", [])
        token = j.get("nextPageToken") or ""
        if not token:
            return out


def role(path):
    r = requests.get(f"https://apis.roblox.com/cloud/v2/{path}", headers=H, timeout=15)
    return r.json() if r.ok else {}


def membership(uid):
    r = requests.get(f"{CLOUD}/memberships", headers=H, timeout=15,
                     params={"maxPageSize": 1, "filter": f"user == 'users/{uid}'"})
    r.raise_for_status()
    found = r.json().get("groupMemberships", [])
    return found[0] if found else None


def give_role(m, role_path):
    r = requests.patch(f"https://apis.roblox.com/cloud/v2/{m['path']}", headers=H, json={"role": role_path}, timeout=15)
    if r.ok:
        return True, ""
    # newer endpoint (the PATCH may be retired): POST memberships/{id}:assignRole
    r2 = requests.post(f"https://apis.roblox.com/cloud/v2/{m['path']}:assignRole", headers=H,
                       json={"role": role_path}, timeout=15)
    return r2.ok, f"PATCH {r.status_code} {r.text[:120]} / assignRole {r2.status_code} {r2.text[:120]}"


def main():
    args = sys.argv[1:]
    check_only = "--check" in args
    names = [a for a in args if not a.startswith("--")]
    if not names:
        raise SystemExit(__doc__)
    all_roles = roles()
    by_path = {r["path"]: r for r in all_roles}
    tester = next((r for r in all_roles if r["displayName"].lower() == ROLE_NAME.lower()), None)
    if not tester:
        raise SystemExit(f'no "{ROLE_NAME}" role in the community yet (create it, rank 10)')
    ids = user_ids(names)
    for n in names:
        if n.lower() not in ids:
            print(f"{n}: no such Roblox user (check the spelling: username, not display name)")
            continue
        uid, real = ids[n.lower()]
        if uid == OWNER_ID:
            print(f"{real}: the owner, always plays (left alone)")
            continue
        m = membership(uid)
        if not m:
            print(f"{real}: NOT in the community yet: ask them to join first")
            continue
        cur = by_path.get(m["role"]) or role(m["role"])
        if cur.get("rank", 0) >= tester["rank"]:
            print(f"{real}: already {cur.get('displayName')} (can play)")
            continue
        if check_only:
            print(f"{real}: member ({cur.get('displayName')}), ready to approve")
            continue
        ok, err = give_role(m, tester["path"])
        print(f"{real}: {'now ' + ROLE_NAME + ' (can play)' if ok else 'FAILED ' + err}")


if __name__ == "__main__":
    main()
