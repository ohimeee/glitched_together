"""Search Roblox's Creator Store audio, keeping only licensed creators (TOOLS.md §3b).

Uses the public toolbox API (no login). Prints id, length, creator, title, first description line.
  python sounds/find_sounds.py "fire whoosh" "sword hit@2"      # "@2" = at most 2 s
  MIN=90 OK=APMOfficial python sounds/find_sounds.py chiptune    # music: at least 90 s, APM only
Default creators: ProSoundEffects, APMOfficial, Roblox, Monstercat. Put picks in src/shared/Config/Sounds.luau.
"""
import sys, json, urllib.request, urllib.parse
import os
OK = set(os.environ.get("OK","ProSoundEffects,APMOfficial,Roblox,Monstercat").split(","))
def search(q, pages=3, maxdur=None, mindur=None):
    tok = None; out = []
    for _ in range(pages):
        p = {"searchCategoryType": "Audio", "query": q, "maxPageSize": 100}
        if tok: p["pageToken"] = tok
        url = "https://apis.roblox.com/toolbox-service/v2/assets:search?" + urllib.parse.urlencode(p)
        try:
            d = json.load(urllib.request.urlopen(url, timeout=20))
        except Exception as e:
            print("ERR", e); break
        for a in d.get("creatorStoreAssets", []):
            c = a["creator"]["name"]
            if c not in OK: continue
            s = a["asset"]; dur = s.get("durationSeconds") or 0
            if maxdur and dur > maxdur: continue
            if mindur and dur < mindur: continue
            desc = (s.get("description") or "").split("\n")[0][:90]
            out.append((s["id"], dur, c[:4], s.get("title","")[:50], desc))
        tok = d.get("nextPageToken")
        if not tok: break
    return out
for q in sys.argv[1:]:
    mx = None
    if "@" in q: q, mx = q.split("@"); mx = float(mx)
    mn = float(os.environ.get("MIN","0")) or None
    r = search(q, maxdur=mx, mindur=mn)
    print(f"== {q} ({len(r)})")
    seen=set()
    for x in r[:40]:
        if len(seen)>=10: break
        if x[3] in seen: continue
        seen.add(x[3]); print(" ", x[0], f"{x[1]}s", x[2], "|", x[3], "|", x[4])
