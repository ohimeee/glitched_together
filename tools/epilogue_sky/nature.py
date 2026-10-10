"""Forests on the smooth ground (round-crown broadleaf + pines, moonlit greens), kept off the voxel plains, the
castle crag top, the lake and the Core's foot; fireflies on the hill. exec after terrain.py."""
rng = random.Random(5)
T_CROWN = mat("E_Crown", lin("2F5A34"), 0.85)
T_CROWN2 = mat("E_Crown2", lin("3E6B3A"), 0.85)
T_PINE = mat("E_Pine", lin("24493A"), 0.85)
T_TRUNK = mat("E_Trunk", lin("4A3626"), 0.9)
T_FLY = mat("E_Firefly", lin("FFE9A0"), 0.5, emit=lin("FFE08A"), estr=25.0, haze=False)

bm = bmesh.new()
count = 0
tries = 0
while count < 4600 and tries < 40000:
    tries += 1
    r = 110 + (rng.random() ** 1.3) * 4420
    a = rng.uniform(0, math.tau)
    x, y = math.sin(a) * r, math.cos(a) * r
    if (Vector((x, y)) - CASTLE).length < 270 or (Vector((x, y)) - LAKE).length < LAKE_R + 90:
        continue
    if (Vector((x, y)) - CORE).length < 680:
        continue
    # clumps: forests where the noise says so, open meadows elsewhere
    if noise.noise(Vector((x / 520, y / 520, 8.0))) < -0.05 and rng.random() < 0.85:
        continue
    z = height(x, y)
    if z > 600:
        continue
    s = rng.uniform(0.8, 1.35) * (1 + r / 6000)
    if rng.random() < 0.45:
        cyl(bm, (x, y, z + 6 * s), 2.5 * s, 2.5 * s, 12 * s, seg=6, side=3, cap=3)
        cyl(bm, (x, y, z + 32 * s), 13 * s, 0.5, 44 * s, seg=8, side=2, cap=2)
    else:
        cyl(bm, (x, y, z + 9 * s), 2.5 * s, 2.5 * s, 18 * s, seg=6, side=3, cap=3)
        res = bmesh.ops.create_icosphere(bm, subdivisions=1, radius=14 * s,
                                         matrix=Matrix.Translation((x, y, z + 28 * s)) @ Matrix.Diagonal((1, 1, 0.85, 1)))
        idx = 0 if rng.random() < 0.6 else 1
        for f in {f for v in res["verts"] for f in v.link_faces}:
            f.material_index = idx
            f.smooth = True
    count += 1
new_obj("ETrees", bm, [T_CROWN, T_CROWN2, T_PINE, T_TRUNK])

# fireflies drifting over the hill slopes
bm = bmesh.new()
for _ in range(260):
    r = rng.uniform(120, 520)
    a = rng.uniform(0, math.tau)
    x, y = math.sin(a) * r, math.cos(a) * r
    z = height(x, y) + rng.uniform(4, 40)
    bmesh.ops.create_icosphere(bm, subdivisions=1, radius=rng.uniform(0.7, 1.3), matrix=Matrix.Translation((x, y, z)))
new_obj("EFireflies", bm, [T_FLY])
