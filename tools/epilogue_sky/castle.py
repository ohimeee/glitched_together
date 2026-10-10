"""Starfall Castle, banners up, on its crag (the -X side, under the moon) + a village of lit cottages at its foot.
exec after terrain.py."""
rng = random.Random(11)
C_STONE = mat("E_CastleStone", lin("A49CB6"), 0.85)
C_ROOF = mat("E_CastleRoof", lin("3D4878"), 0.6)
C_WIN = bpy.data.materials.get("E_Window") or mat("E_Window", lin("FFC067"), 0.5, emit=lin("FFB24F"), estr=12.0, haze=False)
C_BANNER = mat("E_Banner", lin("D8A63A"), 0.7)  # gold banners (owner colors stay off decoration)
C_HOUSE = mat("E_VillageWall", lin("D9C9A8"), 0.85)
C_HROOF = mat("E_VillageRoof", lin("8A4A3A"), 0.8)


def tower(bm, x, y, base, r, h, roof_h):
    cyl(bm, (x, y, base + h / 2), r, r, h)
    cyl(bm, (x, y, base + h + 3), r + 4, r + 4, 6)  # corbel ring
    cyl(bm, (x, y, base + h + 6 + roof_h / 2), r + 5, 0.5, roof_h, side=1, cap=1)
    # a gold pennant on top
    box(bm, (x + 5, y, base + h + 6 + roof_h + 6), (10, 0.8, 6), top=3)
    box(bm, (x, y, base + h + 6 + roof_h + 4), (0.8, 0.8, 12), top=0)
    for k in range(int(h // 22)):
        a = rng.uniform(0, math.tau)
        wx, wy = x + math.cos(a) * (r + 0.7), y + math.sin(a) * (r + 0.7)
        box(bm, (wx, wy, base + 14 + k * 22), (3.5, 3.5, 6), top=2, rot=a)


bm = bmesh.new()
cx, cy = CASTLE.x, CASTLE.y
base = height(cx, cy) - 6
# curtain wall: octagon with merlons
R, n = 150, 8
pts = [(cx + math.cos(k / n * math.tau) * R, cy + math.sin(k / n * math.tau) * R) for k in range(n)]
for k in range(n):
    a, b = Vector(pts[k]), Vector(pts[(k + 1) % n])
    mid, d = (a + b) / 2, (b - a)
    yaw = math.atan2(d.y, d.x)
    zb = min(height(a.x, a.y), height(b.x, b.y), height(mid.x, mid.y)) - 40
    top = base + 50
    box(bm, (mid.x, mid.y, (zb + top) / 2), (d.length, 12, top - zb), top=0, rot=yaw)
    for m in range(int(d.length // 14)):
        p = a + d.normalized() * (7 + m * 14)
        box(bm, (p.x, p.y, top + 4), (7, 13, 8), top=0, rot=yaw)
for (x, y) in pts:
    zb = height(x, y) - 40
    cyl(bm, (x, y, (zb + base) / 2), 22, 22, base - zb)  # tower footings reach the rock
    tower(bm, x, y, base, 20, 85 + rng.uniform(-10, 15), 42)
# the keep: hall + tall centre tower
box(bm, (cx, cy, base + 55), (110, 80, 110), top=0)
box(bm, (cx, cy, base + 118), (110, 80, 16), top=1, side=0)  # roof slab
for sx in (-1, 1):
    for sy in (-1, 1):
        tower(bm, cx + sx * 55, cy + sy * 40, base, 14, 135, 36)
tower(bm, cx, cy, base + 110, 28, 120, 70)
window_quads(bm, (cx, cy, base + 55), (110, 80, 110), 0, 2, rows=3, cols=4, wsz=(5, 9), rng=rng, chance=0.7, z0=0.3)
# banners hanging on the keep's front walls
for k in range(3):
    box(bm, (cx + 56, cy - 25 + k * 25, base + 80), (1.2, 10, 30), top=3)
# built at 1x round the crag top, then scaled up so it reads from the hilltop
bmesh.ops.transform(bm, matrix=Matrix.Translation((cx, cy, base)) @ Matrix.Scale(1.45, 4) @ Matrix.Translation((-cx, -cy, -base)),
                    verts=bm.verts)
new_obj("ECastle", bm, [C_STONE, C_ROOF, C_WIN, C_BANNER])

# village round the crag foot
bv = bmesh.new()
placed = 0
tries = 0
while placed < 70 and tries < 2000:
    tries += 1
    a = rng.uniform(0, math.tau)
    d = rng.uniform(420, 820)
    x, y = cx + math.cos(a) * d, cy + math.sin(a) * d
    if math.hypot(x, y) < 650:
        continue
    z = height(x, y)
    if z > -380:  # stay on the valley floor
        continue
    rot = a + rng.uniform(-0.3, 0.3)
    cottage(bv, x, y, z, rot, rng)
    placed += 1
new_obj("EVillage", bv, [C_HOUSE, C_HROOF, C_WIN])
