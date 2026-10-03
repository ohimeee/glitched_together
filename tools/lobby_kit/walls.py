# Wall dressing (batch 4, Oct 3, 2026): corkboard with pinned notes on the door wall, a peg rail by the door, a string
# of photos over the cubbies, a paper lantern hanging from the ceiling. Run after kit.py.
import random

FLOOR, CEIL = -50, 125
RX0, RX1, RZ0, RZ1 = -160, 160, -230, 75
OAK = mat("Oak", (214, 172, 128), 0.55)
PALM = mat("Palette", (255, 255, 255), 0.7)
CORK = mat("Cork", (190, 140, 96), 0.9)
PAPER = mat("Paper", (246, 240, 226), 0.8)
rnd = random.Random(31)


def finish(o, angle=35):
    mb = bmesh.new()
    mb.from_mesh(o.data)
    bmesh.ops.recalc_face_normals(mb, faces=mb.faces)
    mb.to_mesh(o.data)
    mb.free()
    smooth(o, angle)
    return o


def rod_bm(bm, a, b, r, seg=6, swatch=None):
    A, B = rb(*a), rb(*b)
    d = B - A
    res = bmesh.ops.create_cone(bm, cap_ends=True, segments=seg, radius1=r, radius2=r, depth=d.length)
    vs = res["verts"]
    q = Vector((0, 0, 1)).rotation_difference(d.normalized())
    bmesh.ops.rotate(bm, verts=vs, cent=(0, 0, 0), matrix=q.to_matrix())
    bmesh.ops.translate(bm, verts=vs, vec=(A + B) / 2)
    if swatch is not None:
        tag(bm, faces_of(vs), swatch)
    return vs


def card_on_wall(bm, c, w, h, tilt, swatch, normal_z=True, t=0.15):
    """A thin card flat on a wall. normal_z: wall faces +Z (door wall) else faces -X (right wall)."""
    if normal_z:
        vs = box_bm(bm, c, (w, h, t))
        axis = "Y"  # Roblox Z -> Blender Y: tilt about the wall normal
    else:
        vs = box_bm(bm, c, (t, h, w))
        axis = "X"
    bmesh.ops.rotate(bm, verts=vs, cent=rb(*c), matrix=Matrix.Rotation(tilt, 3, axis))
    tag(bm, faces_of(vs), swatch)
    return vs


def build_corkboard():
    cx, cy, z = -40, 45, RZ0
    W, H = 64, 44
    parts = []
    for dx, dy, sw, sh in ((0, H / 2, W + 6, 3), (0, -H / 2, W + 6, 3), (-W / 2, 0, 3, H + 6), (W / 2, 0, 3, H + 6)):
        parts.append(rounded_box("tmp_cf", (cx + dx, cy + dy, z + 1.2), (sw, sh, 2.4), 0.6, 2, OAK))
    frame = join("LK_CorkFrame_Oak", parts)
    cork = rounded_box("LK_Cork_Cork", (cx, cy, z + 0.6), (W, H, 1.2), 0.1, 1, CORK)
    # pinned papers + notes + push pins (palette)
    bm = pbm()
    items = [
        (-20, 8, 13, 17, 0.06, "paper"), (-3, 10, 11, 14, -0.1, "noteyellow"), (14, 7, 15, 12, 0.04, "paper"),
        (-18, -11, 10, 10, -0.08, "notepink"), (2, -10, 14, 18, 0.12, "cornflower"), (21, -12, 10, 10, -0.15, "noteyellow"),
    ]
    pins = ["toyred", "toyblue", "toygreen", "toyyellow", "toyred", "toyblue"]
    for (dx, dy, w, h, tilt, col), pin in zip(items, pins):
        card_on_wall(bm, (cx + dx, cy + dy, z + 1.35), w, h, tilt, col)
        res = bmesh.ops.create_uvsphere(bm, u_segments=10, v_segments=6, radius=0.75)
        bmesh.ops.translate(bm, verts=res["verts"], vec=rb(cx + dx, cy + dy + h / 2 - 1.4, z + 2.1))
        tag(bm, faces_of(res["verts"]), pin)
    notes = obj_from_bm("LK_CorkNotes_Pal", bm, PALM)
    finish(notes, 30)
    palette_uv(notes)
    return frame, cork, notes


def build_peg_rail():
    """Shaker peg rail right of the door (the hoodie hangs on the middle peg)."""
    z = RZ0
    parts = [rounded_box("tmp_rail", (144, 45, z + 0.9), (26, 4, 1.8), 0.6, 3, OAK)]
    bm = bmesh.new()
    for x in (134, 144, 154):
        lathe_bm(bm, [(0.01, 0), (1.0, 0), (0.8, 1.2), (0.7, 3.0), (1.2, 3.6), (1.1, 4.2), (0.01, 4.4)], (0, 0, 0), 12)
    pegs = obj_from_bm("tmp_pegs", bm, OAK)
    me = pegs.data
    mb = bmesh.new()
    mb.from_mesh(me)
    allv = list(mb.verts)
    n = len(allv) // 3
    for i, x in enumerate((134, 144, 154)):
        vs = allv[i * n:(i + 1) * n]
        bmesh.ops.rotate(mb, verts=vs, cent=(0, 0, 0), matrix=Matrix.Rotation(-math.pi / 2 - 0.15, 3, "X"))
        bmesh.ops.translate(mb, verts=vs, vec=rb(x, 45, z + 1.8))
    mb.to_mesh(me)
    mb.free()
    smooth(pegs, 50)
    parts.append(pegs)
    return join("LK_PegRail_Oak", parts)


def build_photo_string():
    """A string of photos clipped on twine over the cubbies (right wall, x = 160)."""
    bm = pbm()
    x = RX1 - 0.8
    a, b = (x, 60, -102), (x, 60, -36)
    N = 12
    pts = []
    for k in range(N + 1):
        t = k / N
        pts.append(Vector(a).lerp(Vector(b), t) - Vector((0, math.sin(t * math.pi) * 6, 0)))
    for k in range(N):
        rod_bm(bm, tuple(pts[k]), tuple(pts[k + 1]), 0.15, 4, "string")
    photos = ["coral", "cornflower", "leaf", "sun", "lilac"]
    for i, col in enumerate(photos):
        t = (i + 0.5) / len(photos)
        p = Vector(a).lerp(Vector(b), t) - Vector((0, math.sin(t * math.pi) * 6, 0))
        tilt = rnd.uniform(-0.12, 0.12)
        c = (x - 0.2, p.y - 6.5, p.z)
        card_on_wall(bm, c, 10, 12, tilt, "white", normal_z=False, t=0.12)
        card_on_wall(bm, (x - 0.3, p.y - 5.6, p.z), 8, 8, tilt, col, normal_z=False, t=0.06)
        vs = box_bm(bm, (x - 0.5, p.y - 0.4, p.z), (0.6, 2.4, 1.0))  # wooden peg clip
        tag(bm, faces_of(vs), "rawwood")
    o = obj_from_bm("LK_Photos_Pal", bm, PALM)
    finish(o, 30)
    palette_uv(o)
    return o


def build_lantern():
    """A ribbed rice-paper globe lantern hanging over the middle of the room (a faint warm light inside, in game)."""
    cx, cy, cz, r = 46, 98, -112, 11
    bm = bmesh.new()
    prof = []
    N = 36
    for i in range(N + 1):
        a = -math.pi / 2 + i / N * math.pi
        rib = 0.35 if i % 3 == 0 else 0.0
        prof.append((max(0.01, math.cos(a) * (r + rib)), r + math.sin(a) * r))
    lathe_bm(bm, prof, (cx, cy - r, cz), 28)
    o = obj_from_bm("LK_Lantern_Paper", bm, PAPER)
    smooth(o, 60)
    bm = bmesh.new()
    rod_bm(bm, (cx, CEIL, cz), (cx, cy + r - 0.5, cz), 0.25, 6)
    lathe_bm(bm, [(0.01, 0), (3.0, 0), (3.0, 0.6), (0.01, 0.6)], (cx, CEIL - 0.6, cz), 16)  # ceiling rose
    cord = obj_from_bm("LK_LanternCord_Oak", bm, OAK)
    return o, cord


cf, ck, cn = build_corkboard()
peg = build_peg_rail()
ph = build_photo_string()
lan, cord = build_lantern()
print("\n".join(l for l in report().splitlines() if any(k in l for k in ("Cork", "Peg", "Photos", "Lantern"))))
