exec(open(r"C:\Users\User\OneDrive\Desktop\Coding\glitched_together\tools\castle_valley\dnlib.py").read())
random.seed(7)
M = [
    mat("D_Plaster", lin("CFC3A6"), 0.85),
    mat("D_Timber", lin("4A3626"), 0.8),
    mat("D_Slate", lin("4B5266"), 0.6),
    mat("D_Tile", lin("7A4A3A"), 0.7),
    mat("D_Stone", lin("8A8478"), 0.85),
    mat("D_Win", lin("FFB35C"), 0.5, emit=lin("FFB35C"), estr=6.0),
    mat("D_Thatch", lin("8C7650"), 0.95),
]
PL, TI, SL, TL, ST, WI, TH = range(7)

# crossing (from dn_terrain probe)
CX, CY = -54.9, -118.0
ang = math.radians(115.06)
houses = []  # (x, y, rot, sx, sy)


def free(x, y, rad):
    if river_dist(x, y) < 40 + rad or road_dist(x, y) < 14 + rad:
        return False
    for hx, hy, _, sx, sy in houses:
        if math.hypot(hx - x, hy - y) < rad + max(sx, sy) * 0.6 + 6:
            return False
    return True


def road_dir_at(y):
    dx = (road_x(y + 1) - road_x(y - 1)) / 2
    return math.atan2(1, dx)


# houses face the road: walk the road and place on both sides
bm = bmesh.new()
lights = []
for side in (-1, 1):
    y = 30.0
    while y < 520:
        rx = road_x(y)
        a = road_dir_at(y)
        nx, ny = math.cos(a - math.pi / 2) * side, math.sin(a - math.pi / 2) * side
        sx = random.uniform(20, 30); sy = random.uniform(13, 17)
        off = 14 + sy / 2 + random.uniform(2, 6)
        hx, hy = rx + nx * off, y + ny * off
        if free(hx, hy, sx * 0.5):
            houses.append((hx, hy, a, sx, sy))
        y += sx + random.uniform(4, 14)
# a second row / scattered farmsteads
for k in range(160):
    hx = random.uniform(-420, 420); hy = random.uniform(-80, 560)
    sx = random.uniform(18, 28); sy = random.uniform(12, 16)
    if free(hx, hy, sx * 0.6) and road_dist(hx, hy) < 150:
        houses.append((hx, hy, road_dir_at(hy) + random.choice((0, math.pi / 2)), sx, sy))
# south bank hamlet
for k in range(90):
    hx = random.uniform(-500, 300); hy = random.uniform(-520, -230)
    sx = random.uniform(18, 26); sy = random.uniform(12, 15)
    if free(hx, hy, sx * 0.6) and road_dist(hx, hy) < 90:
        houses.append((hx, hy, road_dir_at(hy) + random.choice((0, math.pi / 2)), sx, sy))

for hx, hy, a, sx, sy in houses:
    z0 = height(hx, hy) - 1.5
    wall = random.uniform(9, 14)
    roofm = random.choice((SL, SL, TL, TL, TH))
    gable(bm, hx, hy, z0, sx, sy, wall, random.uniform(7, 10), a, PL, roofm)
    c, s = math.cos(a), math.sin(a)
    # timber base band
    box(bm, hx, hy, z0, sx + 0.4, sy + 0.4, 2.5, a, ST)
    # chimney
    px = random.uniform(-sx / 3, sx / 3)
    box(bm, hx + px * c - (sy / 4) * s, hy + px * s + (sy / 4) * c, z0 + wall, 2.2, 2.2, 10, a, ST)
    # windows on both long walls (emissive, slightly proud)
    nwin = int(sx // 7)
    for wside in (-1, 1):
        for w in range(nwin):
            if random.random() < 0.35:
                continue
            wx = (w - (nwin - 1) / 2) * 6.5
            wy = wside * (sy / 2 + 0.15)
            box(bm, hx + wx * c - wy * s, hy + wx * s + wy * c, z0 + wall * 0.45, 2.2, 0.4, 2.8, a, WI)
    # warm pool at the door (road side)
    dy = -(sy / 2 + 4)
    lights.append((hx - dy * s, hy + dy * c, z0 + 6))

# chapel with steeple at the village square
chx, chy = road_x(330) + 46, 330
a = road_dir_at(330) + math.pi / 2
z0 = height(chx, chy) - 1.5
gable(bm, chx, chy, z0, 44, 20, 16, 13, a, ST, SL)
c, s = math.cos(a), math.sin(a)
tx, ty = chx + 26 * c, chy + 26 * s
box(bm, tx, ty, z0, 10, 10, 34, a, ST)
cone(bm, tx, ty, z0 + 34, 7.6, 26, seg=4, mi=SL, rot=a + math.pi / 4)
for w in (-12, -4, 4, 12):
    for wside in (-1, 1):
        wy = wside * 10.15
        box(bm, chx + w * c - wy * s, chy + w * s + wy * c, z0 + 5, 2, 0.4, 7, a, WI)
houses.append((chx, chy, a, 60, 22))

# watermill on the north bank with a wheel
mx = 230.0
my = river_y(mx) + 52
ra = math.atan2(river_y(mx + 1) - river_y(mx - 1), 2)
z0 = height(mx, my) - 1.5
gable(bm, mx, my, z0, 30, 18, 14, 9, ra, ST, TH)
wy = -11
wcx, wcy = mx - wy * math.sin(ra), my + wy * math.cos(ra)
# wheel: 12-spoke ring approximated by boxes standing in the water
for k in range(12):
    t = k / 12 * math.tau
    box(bm, wcx + math.cos(ra) * math.cos(t) * 9, wcy + math.sin(ra) * math.cos(t) * 9, -462 + 9 + math.sin(t) * 9, 1.4, 4, 3, ra, TI)
houses.append((mx, my, ra, 30, 18))

new_obj("DnVillage", bm, M)

# bridge: deck along the road through the crossing
bm = bmesh.new()
L = 90
dxv, dyv = math.cos(ang), math.sin(ang)
zb = max(height(CX - dxv * L / 2, CY - dyv * L / 2), height(CX + dxv * L / 2, CY + dyv * L / 2)) + 1.0
box(bm, CX, CY, zb - 3, L, 15, 3, ang, 0)
for side in (-1, 1):
    ox, oy = -dyv * 7 * side, dxv * 7 * side
    box(bm, CX + ox, CY + oy, zb, L, 1.6, 3.2, ang, 0)
for t in (-0.22, 0.0, 0.22):
    box(bm, CX + dxv * L * t, CY + dyv * L * t, -472, 10, 17, zb - 3 + 472, ang, 0)
new_obj("DnBridge", bm, [M[ST]])

# lanterns along the road (posts + glowing heads) + their lights
bm = bmesh.new()
y = -560.0
k = 0
while y < 640:
    x = road_x(y)
    a = road_dir_at(y)
    side = 1 if k % 2 else -1
    lx = x + math.cos(a - math.pi / 2) * 9 * side
    ly = y + math.sin(a - math.pi / 2) * 9 * side
    if river_dist(lx, ly) > 45:
        z0 = height(lx, ly)
        box(bm, lx, ly, z0, 0.8, 0.8, 8, a, 0)
        box(bm, lx, ly, z0 + 8, 1.8, 1.8, 2.0, a, 1)
        lights.append((lx, ly, z0 + 9.5))
    y += 38
    k += 1
new_obj("DnLanterns", bm, [M[TI], M[WI]])
for f in bpy.data.objects["DnLanterns"].data.polygons:
    pass

# point lights (one object per light; Cycles handles hundreds fine)
for o in [o for o in SC.objects if o.name.startswith("DnL_")]:
    bpy.data.objects.remove(o, do_unlink=True)
ld = bpy.data.lights.get("DnWarm") or bpy.data.lights.new("DnWarm", "POINT")
ld.energy = 900
ld.color = (1.0, 0.62, 0.3)
ld.shadow_soft_size = 1.5
for i, (x, y, z) in enumerate(lights):
    o = bpy.data.objects.new(f"DnL_{i}", ld)
    o.location = (x, y, z)
    link(o)

import json
json.dump([[h[0], h[1], max(h[3], h[4])] for h in houses], open(os.path.join(SCR, "houses.json"), "w"))
print("houses", len(houses), "lights", len(lights))
