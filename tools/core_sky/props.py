exec(open(r"C:\Users\User\OneDrive\Desktop\Coding\glitched_together\tools\core_sky\corelib.py").read())
random.seed(5)
HAZE = lin("9EA2A9")
PM = [
    mat("C_PencilPaint", lin("595C64"), 0.45),            # 0
    mat("C_PencilWood", lin("C9B28E"), 0.8),              # 1
    mat("C_Lead", lin("2B2C30"), 0.35, metal=0.3),        # 2
    mat("C_Ferrule", lin("B8BBC0"), 0.3, metal=1.0),      # 3
    mat("C_Eraser", lin("B79FA3"), 0.9),                  # 4 dusty rubber
    mat("C_Steel", lin("A9ADB3"), 0.28, metal=1.0),       # 5 ruler / compass steel
    mat("C_Paper", lin("DADCE0"), 0.95),                  # 6
    mat("C_Graphite", lin("2E3035"), 0.5),                # 7
    mat("C_Brass", lin("9C8450"), 0.35, metal=0.85),      # 8
    mat("C_Sleeve", lin("6F7682"), 0.8),                  # 9 eraser sleeve
]
for m in PM:
    add_haze(m, HAZE, start=1200, end=16000)
PAINT, WOODM, LEAD, FERR, ERAS, STEEL, PAPER, GRAPH, BRASS, SLEEVE = range(10)
bm = bmesh.new()
Z = SHEET_Z


def pencil(x, y, ang, L=2600, r=62):
    d = Vector((math.cos(ang), math.sin(ang), 0))
    a = Vector((x, y, Z + r * 0.87)) - d * L / 2
    b = a + d * L
    cyl(bm, a, b, r, seg=6, mi=PAINT)
    cyl(bm, b, b + d * 260, r, seg=6, mi=WOODM, r2=r * 0.28)
    cyl(bm, b + d * 260, b + d * 330, r * 0.28, seg=8, mi=LEAD, r2=0.0)
    cyl(bm, a - d * 120, a, r * 1.04, seg=16, mi=FERR)
    for k in range(3):  # ferrule ridges
        cyl(bm, a - d * (25 + k * 35), a - d * (35 + k * 35), r * 1.09, seg=16, mi=FERR)
    cyl(bm, a - d * 260, a - d * 120, r * 0.98, seg=16, mi=ERAS)


def ruler(x, y, ang, L=3800, W=170):
    box(bm, (x, y, Z + 4), (L, W, 8), rot=ang, mi=STEEL)
    c, s = math.cos(ang), math.sin(ang)
    for k in range(int(L / 25) + 1):
        u = -L / 2 + k * 25
        tl = 70 if k % 5 == 0 else 38
        if k % 10 == 0:
            tl = 100
        v = W / 2 - tl / 2
        box(bm, (x + u * c - v * s, y + u * s + v * c, Z + 8.3), (3, tl, 0.8), rot=ang, mi=GRAPH)


def eraser(x, y, ang):
    box(bm, (x, y, Z + 40), (300, 130, 80), rot=ang, mi=PAPER)
    box(bm, (x + math.cos(ang) * 50, y + math.sin(ang) * 50, Z + 40), (170, 134, 84), rot=ang, mi=SLEEVE)
    for k in range(40):  # eraser crumbs
        rr = random.uniform(180, 500)
        a2 = random.uniform(0, math.tau)
        sz = random.uniform(6, 18)
        box(bm, (x + math.cos(a2) * rr, y + math.sin(a2) * rr, Z + sz * 0.3), (sz * 2.2, sz, sz * 0.7), rot=random.uniform(0, 6), mi=ERAS)


def paper_ball(x, y, r):
    ret = bmesh.ops.create_icosphere(bm, subdivisions=3, radius=r)
    seed = random.uniform(0, 50)
    for v in ret["verts"]:
        n = noise.noise(v.co / r * 2.5 + Vector((seed, 0, 0)))
        v.co = v.co * (1 + n * 0.28) + Vector((x, y, Z + r * 0.8))
    for f in {f for v in ret["verts"] for f in v.link_faces}:
        f.material_index = PAPER
        f.smooth = False


def compass(x, y, ang, H=1100):
    hinge = Vector((x, y, Z + H))
    spread = H * 0.42
    d = Vector((math.cos(ang), math.sin(ang), 0))
    p1 = Vector((x, y, Z)) + d * spread
    p2 = Vector((x, y, Z)) - d * spread
    cyl(bm, hinge, p1 + Vector((0, 0, 60)), 16, seg=8, mi=STEEL)
    cyl(bm, p1 + Vector((0, 0, 60)), p1, 4, seg=6, mi=STEEL, r2=0.5)  # needle
    cyl(bm, hinge, p2 + Vector((0, 0, 140)), 16, seg=8, mi=STEEL)
    cyl(bm, p2 + Vector((0, 0, 140)), p2 + Vector((0, 0, 40)), 14, seg=6, mi=WOODM)  # pencil lead holder
    cyl(bm, p2 + Vector((0, 0, 40)), p2, 8, seg=6, mi=LEAD, r2=0.0)
    cyl(bm, hinge - Vector((0, 0, 20)), hinge + Vector((0, 0, 30)), 34, seg=16, mi=BRASS)
    cyl(bm, hinge + Vector((0, 0, 30)), hinge + Vector((0, 0, 140)), 12, seg=10, mi=BRASS)  # handle
    # the circle it drew on the sheet, in pencil
    seg = 96
    for k in range(seg):
        t0, t1 = k / seg * math.tau, (k + 1) / seg * math.tau
        q0 = Vector((x + math.cos(t0) * spread * 2, y + math.sin(t0) * spread * 2, Z + 0.6))
        q1 = Vector((x + math.cos(t1) * spread * 2, y + math.sin(t1) * spread * 2, Z + 0.6))
        mid = (q0 + q1) / 2
        box(bm, mid, ((q1 - q0).length, 5, 0.5), rot=math.atan2(q1.y - q0.y, q1.x - q0.x), mi=GRAPH)
    cyl(bm, Vector((x, y, Z)) + d * spread, Vector((x, y, Z)) - d * spread * 3, 0.1, seg=3, mi=GRAPH)


pencil(1500, 2600, math.radians(20))
pencil(-3200, -1200, math.radians(-65), L=2100)
ruler(-2400, 2900, math.radians(-12))
eraser(2600, -1900, math.radians(30))
for (px, py, pr) in ((-1800, -3200, 260), (3600, 600, 200), (-4600, 1800, 320), (900, -4600, 240)):
    paper_ball(px, py, pr)
compass(-900, -2300, math.radians(40))
o = new_obj("CoreProps", bm, PM)
print("props", len(o.data.polygons))

# --- TODO cards (handwriting, graphite on paper) -------------------------------------------------------------
FONT = bpy.data.fonts.load(r"C:\Windows\Fonts\segoepr.ttf", check_existing=True)
for n in [n for n in bpy.data.objects.keys() if n.startswith("CoreNote")]:
    bpy.data.objects.remove(bpy.data.objects[n], do_unlink=True)


def note(i, text, x, y, z, size, yaw, card=True):
    cu = bpy.data.curves.new(f"CoreNoteText{i}", "FONT")
    cu.body = text
    cu.font = FONT
    cu.size = size
    cu.align_x = "CENTER"
    cu.align_y = "CENTER"
    cu.extrude = size * 0.02
    t = bpy.data.objects.new(f"CoreNoteText{i}", cu)
    t.data.materials.append(PM[GRAPH])
    t.rotation_euler = (math.radians(80), 0, yaw)
    t.location = (x, y, z)
    coll().objects.link(t)
    if card:
        bm2 = bmesh.new()
        w = size * (len(text) * 0.62 + 1.2)
        h = size * 2.0
        box(bm2, (0, 0, 0), (w, size * 0.05, h), mi=0)
        c = new_obj(f"CoreNoteCard{i}", bm2, [PM[PAPER]])
        c.rotation_euler = (math.radians(-10), 0, yaw)
        # the card sits just behind the text
        c.location = (x - math.sin(yaw) * size * 0.1, y + math.cos(yaw) * size * 0.1, z)
        # a stick down to whatever it stands on
        bm3 = bmesh.new()
        cyl(bm3, (0, 0, -h / 2 - size * 3), (0, 0, -h / 2), size * 0.06, seg=6, mi=0)
        st = new_obj(f"CoreNoteStick{i}", bm3, [PM[WOODM]])
        st.location = c.location


def facing(x, y):
    return math.atan2(y, x) + math.pi / 2


notes = ["TODO: sky", "TODO: finish level 3!!", "fix later", "Kai: textures?", "Miko: boss goes here"]
sc = scene()
dg = bpy.context.evaluated_depsgraph_get()
isl = bpy.data.objects["CoreIslands"]
placed = 0
for tries in range(400):
    if placed >= len(notes):
        break
    a = random.uniform(0, math.tau)
    r = random.uniform(420, 1500)
    x, y = math.cos(a) * r, math.sin(a) * r
    hit, loc, nrm, idx, obj, _ = sc.ray_cast(dg, Vector((x, y, 2000)), Vector((0, 0, -1)))
    if not hit or obj != isl or nrm.z < 0.9 or loc.z < -600:
        continue
    s_ = random.uniform(24, 40)
    h = s_ * 2.0
    note(placed, notes[placed], loc.x, loc.y, loc.z + s_ * 3 + h / 2, s_, facing(loc.x, loc.y) + math.pi)
    placed += 1
print("notes placed", placed)
# a big pencil note written straight on the sheet
note(99, "LEVEL 3 - DRAFT", 0, 1800, SHEET_Z + 2, 160, 0, card=False)
bpy.data.objects["CoreNoteText99"].rotation_euler = (0, 0, 0)

# --- Glitch tears: magenta rips in the sky, cyan fringe offset (the only strong colors here) ----------------
gm = mat("C_GlitchTear", lin("FF2BD6"), 0.5, emit=lin("FF2BD6"), estr=1.3)
gc = mat("C_GlitchFringe", lin("2BF2FF"), 0.5, emit=lin("2BF2FF"), estr=0.9)
bm = bmesh.new()
for k, (az, el, dist, H) in enumerate(((35, 9, 9000, 1500), (150, 22, 11000, 1900), (255, 5, 8000, 900), (300, 30, 12000, 2200))):
    a = math.radians(az)
    e = math.radians(el)
    centre = Vector((math.cos(a) * math.cos(e), math.sin(a) * math.cos(e), math.sin(e))) * dist
    right = Vector((-math.sin(a), math.cos(a), 0))
    up = Vector((0, 0, 1))
    pts = []
    n = 9
    for i in range(n + 1):
        t = i / n
        w = H * 0.08 * math.sin(t * math.pi) * random.uniform(0.6, 1.4)
        off = random.uniform(-0.12, 0.12) * H
        pts.append((t, off, w))
    for side, mi, shift in ((0, 0, 0.0), (1, 1, H * 0.03)):
        vl, vr = [], []
        for t, off, w in pts:
            base = centre + up * (t - 0.5) * H + right * (off + shift) + (centre.normalized() * (12 if side else 0))
            vl.append(bm.verts.new(base - right * w))
            vr.append(bm.verts.new(base + right * w))
        for i in range(n):
            f = bm.faces.new((vl[i], vr[i], vr[i + 1], vl[i + 1]))
            f.material_index = mi
o = new_obj("CoreGlitchTears", bm, [gm, gc])
o.visible_shadow = False
print("notes + tears ok")
