exec(open(r"C:\Users\User\OneDrive\Desktop\Coding\glitched_together\tools\core_sky\corelib.py").read())
random.seed(3)
HAZE = lin("9EA2A9")
M = [
    mat("C_Primer1", lin("8E9197"), 0.75),   # 0 primer grey
    mat("C_Primer2", lin("A2A5AA"), 0.75),   # 1 lighter primer
    mat("C_Primer3", lin("82858C"), 0.8),    # 2 darker primer
    mat("C_Clay", lin("7E8189"), 0.9),       # 3 underside clay
    mat("C_Foam", lin("CDD0D4"), 0.85),      # 4 foam board
    mat("C_Brass", lin("9C8450"), 0.35, metal=0.85),  # 5 brass stands / wire
    mat("C_Tape", lin("C9BB90"), 0.7),       # 6 masking tape
    mat("C_Graphite", lin("2E3035"), 0.5),   # 7 pencil / wire dark
    mat("C_Wood", lin("8A7A62"), 0.8),       # 8 bare dowel / scaffold wood
]
for m in M:
    add_haze(m, HAZE)
P1, P2, P3, CLAY, FOAM, BRASS, TAPE, GRAPH, WOOD = range(9)


def stand(bm, x, y, z_bottom, r):
    """a brass model stand from the island's underside down to a disk on the drafting sheet"""
    cyl(bm, (x, y, SHEET_Z), (x, y, z_bottom + 2), r, seg=10, mi=BRASS)
    cyl(bm, (x, y, SHEET_Z), (x, y, SHEET_Z + r * 0.8), r * 6, seg=16, mi=BRASS)


def chunk_base(bm, x, y, z, R, tiers=6):
    """deep, jagged clay underside: shrinking, jittered, slightly rotated slabs (a torn-off chunk of an unfinished
    level), the top slab in primer"""
    zz = z
    depth = R * random.uniform(0.7, 1.0)
    for i in range(tiers):
        f = 1 - i / tiers
        s = R * (0.25 + 0.75 * f ** 1.4)
        th = depth / tiers * (0.6 if i == 0 else 1.0)
        for k in range(1 if i == 0 else 2):
            j = 0.0 if i == 0 else 0.18
            box(bm, (x + random.uniform(-j, j) * R, y + random.uniform(-j, j) * R, zz - th / 2),
                (2 * s * random.uniform(0.75, 1.0), 2 * s * random.uniform(0.75, 1.0), th * random.uniform(1.0, 1.25)),
                rot=random.uniform(-0.35, 0.35) if i else 0.0, mi=P3 if i == 0 else CLAY)
        zz -= th
    return zz


def voxel_top(bm, x, y, z, R, cell, hill=1.0, wire_corner=False, wbm=None):
    """stepped voxel terrain (an unpainted Pixel Plains chunk); one corner can be only a wire outline"""
    n = max(3, int(2 * R / cell))
    seed = random.uniform(0, 100)
    for i in range(n):
        for j in range(n):
            cx = x - R + (i + 0.5) * cell
            cy = y - R + (j + 0.5) * cell
            hgt = 1 + int(max(0, noise.noise(Vector((i / 4.0, j / 4.0, seed))) * 4 * hill + 1.5 * hill))
            if wire_corner and i > n * 0.6 and j > n * 0.6:
                if wbm is not None:
                    for k in range(hgt):
                        box(wbm, (cx, cy, z + (k + 0.5) * cell), (cell, cell, cell), mi=0)
                continue
            box(bm, (cx, cy, z + hgt * cell / 2), (cell * 0.98, cell * 0.98, hgt * cell), mi=random.choice((P1, P1, P2, P3)))
            if hgt >= 3 and random.random() < 0.25:  # blockout tree: a grey cone on a stick
                tz = z + hgt * cell
                cyl(bm, (cx, cy, tz), (cx, cy, tz + cell * 0.8), cell * 0.12, seg=6, mi=P3)
                cyl(bm, (cx, cy, tz + cell * 0.6), (cx, cy, tz + cell * 2.4), cell * 0.5, seg=7, mi=P2, r2=0.0)


def castle_top(bm, x, y, z, R, wbm=None, scaf=None):
    """foam-board castle blockout: curtain walls, square keep, towers; one tower is only a wire armature"""
    wall_h = R * 0.22
    t = R * 0.04
    for sx, sy, w_, d_ in ((0, -0.6, 1.2 * R, t), (0, 0.6, 1.2 * R, t), (-0.6, 0, t, 1.2 * R), (0.6, 0, t, 1.2 * R)):
        box(bm, (x + sx * R, y + sy * R, z + wall_h / 2), (w_, d_, wall_h), mi=FOAM)
    # merlons along the front walls
    for k in range(12):
        u = -0.6 + 1.2 * (k + 0.5) / 12
        for sy in (-0.6, 0.6):
            box(bm, (x + u * R, y + sy * R, z + wall_h + R * 0.025), (R * 0.05, t * 1.4, R * 0.05), mi=FOAM)
    box(bm, (x, y + R * 0.1, z + wall_h * 1.1), (R * 0.5, R * 0.5, wall_h * 2.2), mi=P2)  # keep
    box(bm, (x, y + R * 0.1, z + wall_h * 2.2 + 1), (R * 0.54, R * 0.54, 2), mi=TAPE)  # tape band holding the roof
    towers = [(-0.6, -0.6), (0.6, -0.6), (-0.6, 0.6), (0.6, 0.6)]
    wire_i = random.randrange(4)
    for i, (tx, ty) in enumerate(towers):
        cx, cy = x + tx * R, y + ty * R
        th = wall_h * random.uniform(1.6, 2.1)
        if i == wire_i and wbm is not None:
            cyl(wbm, (cx, cy, z), (cx, cy, z + th), R * 0.12, seg=10, mi=0)
            cyl(wbm, (cx, cy, z + th), (cx, cy, z + th + R * 0.25), R * 0.15, seg=10, mi=0, r2=0.0)
            continue
        cyl(bm, (cx, cy, z), (cx, cy, z + th), R * 0.12, seg=12, mi=FOAM)
        cyl(bm, (cx, cy, z + th), (cx, cy, z + th + R * 0.25), R * 0.15, seg=12, mi=P3, r2=0.0)
        if scaf is not None and i == (wire_i + 2) % 4:
            scaffold(scaf, cx, cy, z, R * 0.32, th * 0.9)


def scaffold(bm, cx, cy, z, size, h):
    """wooden scaffold cage: posts, ledgers every lift, diagonal braces"""
    post = max(0.6, size * 0.02)
    lift = max(6.0, size * 0.25)
    for sx in (-1, 1):
        for sy in (-1, 1):
            box(bm, (cx + sx * size / 2, cy + sy * size / 2, z + h / 2), (post, post, h), mi=0)
    k = 1
    while k * lift < h:
        zz = z + k * lift
        for sx in (-1, 1):
            box(bm, (cx + sx * size / 2, cy, zz), (post, size, post), mi=0)
            box(bm, (cx, cy + sx * size / 2, zz), (size, post, post), mi=0)
        box(bm, (cx, cy - size / 2 - post, zz + post), (size, size * 0.25, post * 0.6), mi=1)  # plank deck
        k += 1
    # braces
    k = 0
    while (k + 1) * lift < h:
        za, zb = z + k * lift, z + (k + 1) * lift
        cyl(bm, (cx - size / 2, cy - size / 2, za), (cx + size / 2, cy - size / 2, zb), post * 0.45, seg=4, mi=0)
        k += 1


def crane(bm, x, y, z, H):
    """tower crane lattice: mast, jib, counter-jib, hook line"""
    s = H * 0.06
    k = 0
    while k * s < H:
        for sx in (-1, 1):
            for sy in (-1, 1):
                pass
        k += 1
    for sx in (-1, 1):
        for sy in (-1, 1):
            cyl(bm, (x + sx * s / 2, y + sy * s / 2, z), (x + sx * s / 2, y + sy * s / 2, z + H), s * 0.06, seg=4, mi=0)
    zz = z
    while zz < H + z - s:
        cyl(bm, (x - s / 2, y - s / 2, zz), (x + s / 2, y - s / 2, zz + s), s * 0.04, seg=4, mi=0)
        cyl(bm, (x + s / 2, y + s / 2, zz), (x - s / 2, y + s / 2, zz + s), s * 0.04, seg=4, mi=0)
        zz += s
    jl = H * 0.8
    box(bm, (x + jl / 2, y, z + H), (jl, s * 0.6, s * 0.5), mi=0)
    box(bm, (x - jl * 0.2, y, z + H), (jl * 0.4, s * 0.6, s * 0.5), mi=0)
    box(bm, (x - jl * 0.35, y, z + H - s * 0.5), (s, s, s), mi=1)  # counterweight
    cyl(bm, (x, y, z + H), (x, y, z + H + s * 2), s * 0.08, seg=4, mi=0)
    cyl(bm, (x + jl * 0.7, y, z + H), (x + jl * 0.7, y, z + H * 0.45), s * 0.03, seg=4, mi=1)  # hook line


bm = bmesh.new()      # solid primer/clay/foam/brass
wbm = bmesh.new()     # wire armatures (wireframe modifier)
sbm = bmesh.new()     # scaffolds + cranes (wood, graphite)
spots = []
for k in range(60):
    for tries in range(40):
        ang = random.uniform(0, math.tau)
        r = random.uniform(650, 7500) if k > 12 else random.uniform(380, 1400)
        x, y = math.cos(ang) * r, math.sin(ang) * r
        # keep the level's own lane (along Roblox +Z = Blender +Y) clear close by
        if abs(x) < 260 and r < 2600:
            continue
        R = (90 + r * 0.05) * random.uniform(0.7, 1.4)
        if all(math.hypot(x - sx, y - sy) > (R + sr) * 1.25 for sx, sy, sr in spots):
            spots.append((x, y, R))
            break
for i, (x, y, R) in enumerate(spots):
    z = random.uniform(-380, 160) * (1 + math.hypot(x, y) / 9000)
    kind = random.random()
    zb = chunk_base(bm, x, y, z, R)
    if kind < 0.5:
        voxel_top(bm, x, y, z, R, cell=R / random.choice((7, 8, 10)), wire_corner=random.random() < 0.4, wbm=wbm)
    elif kind < 0.8:
        castle_top(bm, x, y, z, R, wbm=wbm, scaf=sbm)
    else:
        voxel_top(bm, x, y, z, R, cell=R / 8, hill=0.4)
        crane(sbm, x + R * 0.3, y - R * 0.2, z + R * 0.1, R * 1.4)
    # masking tape strip over an edge, as if the chunk was taped together
    if random.random() < 0.5:
        a = random.uniform(-0.6, 0.6)
        box(bm, (x + R * a, y - R, z - R * 0.04), (R * 0.12, R * 0.05, R * 0.2), mi=TAPE)
    nstands = 1 if R < 200 else 3
    for s in range(nstands):
        ox, oy = (0, 0) if nstands == 1 else (math.cos(s * 2.1) * R * 0.3, math.sin(s * 2.1) * R * 0.3)
        stand(bm, x + ox, y + oy, zb, max(1.6, R * 0.025))

o = new_obj("CoreIslands", bm, M)
w = new_obj("CoreWire", wbm, [M[BRASS]])
mod = w.modifiers.new("wire", "WIREFRAME")
mod.thickness = 1.6
mod.use_even_offset = True
s = new_obj("CoreScaffold", sbm, [M[WOOD], M[GRAPH]])
print("islands", len(spots), len(o.data.polygons), len(w.data.polygons), len(s.data.polygons))
