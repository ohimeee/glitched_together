"""Sky lanterns: the whole kingdom celebrates. Warm paper lanterns rise from the village, the plains cottages and
the Core's foot, thinning out as they climb; a few drift close past the hilltop. exec after terrain.py."""
rng = random.Random(31)
L_PAPER = mat("E_Lantern", lin("FFB25A"), 0.6, emit=lin("FF8A30"), estr=7.0, haze=False)

SOURCES = ((CASTLE, 800, 110), (LAKE, 900, 90), (CORE, 800, 60), (Vector((0.0, 0.0)), 900, 60))
bm = bmesh.new()


def lantern(p, s):
    r = bmesh.ops.create_cone(bm, cap_ends=True, segments=6, radius1=1.8 * s, radius2=2.6 * s, depth=4.2 * s,
                              matrix=Matrix.Translation(p))
    for f in {f for v in r["verts"] for f in v.link_faces}:
        f.material_index = 0


for centre, spread, n in SOURCES:
    for _ in range(n):
        a = rng.uniform(0, math.tau)
        d = spread * math.sqrt(rng.random())
        x, y = centre.x + math.cos(a) * d, centre.y + math.sin(a) * d
        if math.hypot(x, y) < 300 or (Vector((x, y)) - CASTLE).length < 260 or (Vector((x, y)) - CORE).length < 330:
            continue
        g = height(x, y)
        rise = 30 + (rng.random() ** 1.8) * 1100
        lantern(Vector((x, y, g + rise)), rng.uniform(1.1, 1.7) * (1 + math.hypot(x, y) / 2500))
# a handful drifting close past the hill, slightly above eye level
for _ in range(10):
    a = rng.uniform(-1.9, 1.9)
    d = rng.uniform(140, 420)
    lantern(Vector((math.sin(a) * d, math.cos(a) * d, rng.uniform(-30, 70))), rng.uniform(0.6, 0.9))
new_obj("ELanterns", bm, [L_PAPER])
