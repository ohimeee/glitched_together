"""The Glitched Core, finished (straight ahead, +Y): the scale-model chunks stacked into one tower on brass rods,
primer-white with gold trim and lit windows, a slow gold ring round it and the SAVE beacon on top (the gold of the
finished level on the Epilogue hilltop). Smaller chunks on brass stands round its foot. exec after terrain.py."""
rng = random.Random(23)
K_PRIMER = mat("E_Primer", lin("E4DDCC"), 0.7)
K_BRASS = mat("E_Brass", lin("C9963E"), 0.35, metal=1.0)
K_WIN = mat("E_CoreWindow", lin("FFE2A0"), 0.5, emit=lin("FFD27A"), estr=10.0, haze=False)
K_GOLD = mat("E_GoldGlow", lin("FFC65C"), 0.4, emit=lin("FFC65C"), estr=18.0, haze=False)
K_RING = mat("E_GoldRing", lin("E8B04E"), 0.3, emit=lin("FFB848"), estr=2.5, metal=1.0, haze=False)

bm = bmesh.new()
cx, cy = CORE.x, CORE.y
z = height(cx, cy) - 10
tiers = ((520, 120), (400, 130), (300, 140), (210, 150), (140, 160))
for k, (w, h) in enumerate(tiers):
    rot = k * 0.18
    box(bm, (cx, cy, z + h / 2), (w, w, h), top=0, rot=rot)
    box(bm, (cx, cy, z + h - 3), (w + 10, w + 10, 8), top=1, rot=rot)  # brass trim band
    window_quads(bm, (cx, cy, z + h / 2), (w, w, h), rot, 2, rows=2, cols=max(3, w // 70), wsz=(9, 14), rng=rng,
                 chance=0.75, z0=0.3)
    z += h
    if k < len(tiers) - 1:
        nw = tiers[k + 1][0]
        for sx in (-1, 1):
            for sy in (-1, 1):  # brass rods carry the next chunk
                p = Matrix.Rotation(rot, 3, "Z") @ Vector((sx * nw * 0.35, sy * nw * 0.35, 0))
                cyl(bm, (cx + p.x, cy + p.y, z + 20), 6, 6, 40, seg=10, side=1, cap=1)
        z += 40
# spire + beacon
cyl(bm, (cx, cy, z + 110), 18, 4, 220, seg=12, side=1, cap=1)
top = z + 240
res = bmesh.ops.create_icosphere(bm, subdivisions=1, radius=34, matrix=Matrix.Translation((cx, cy, top)))
for f in {f for v in res["verts"] for f in v.link_faces}:
    f.material_index = 3
new_obj("ECore", bm, [K_PRIMER, K_BRASS, K_WIN, K_GOLD])

# gold ring round the tower, tilted
bm = bmesh.new()
ring_z = height(cx, cy) + 520
segs = 96
R0, R1, th = 380, 396, 10
vs = []
for i in range(segs):
    a = i / segs * math.tau
    ca, sa = math.cos(a), math.sin(a)
    vs.append([bm.verts.new((ca * rr, sa * rr, dz)) for rr, dz in ((R0, -th), (R1, -th), (R1, th), (R0, th))])
for i in range(segs):
    a, b = vs[i], vs[(i + 1) % segs]
    for k in range(4):
        bm.faces.new((a[k], a[(k + 1) % 4], b[(k + 1) % 4], b[k]))
ring = new_obj("ECoreRing", bm, [K_RING])
ring.location = (cx, cy, ring_z)
ring.rotation_euler = (math.radians(14), math.radians(-8), 0)

# smaller chunks on brass stands round the foot
bm = bmesh.new()
for k in range(7):
    a = k / 7 * math.tau + rng.uniform(-0.3, 0.3)
    d = rng.uniform(420, 620)
    x, y = cx + math.cos(a) * d, cy + math.sin(a) * d
    g = height(x, y)
    stand = rng.uniform(60, 160)
    w = rng.uniform(70, 130)
    cyl(bm, (x, y, g + stand / 2), 7, 7, stand, seg=10, side=1, cap=1)
    box(bm, (x, y, g + stand - 4), (w * 0.5, w * 0.5, 8), top=1)
    box(bm, (x, y, g + stand + w * 0.3), (w, w, w * 0.6), top=0, rot=rng.uniform(0, 1.5))
    window_quads(bm, (x, y, g + stand + w * 0.3), (w, w, w * 0.6), 0, 2, cols=2, wsz=(7, 9), rng=rng, chance=0.5)
new_obj("ECoreChunks", bm, [K_PRIMER, K_BRASS, K_WIN])
