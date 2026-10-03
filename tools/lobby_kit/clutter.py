# Lobby clutter + wall detail (batch 3, Oct 3, 2026). References (It Takes Two Rose's Room, principles only): pennant
# bunting across the ceiling, a hanging planet mobile, wall shelves and cubbies with fabric bins, two-tone walls with
# panelling, toys on the floor, a busy desk. Run after kit.py.
import random

FLOOR, CEIL = -50, 125
RX0, RX1, RZ0, RZ1 = -160, 160, -230, 75
PAINT = mat("PaintedWood", (240, 232, 220), 0.5)
OAK = mat("Oak", (214, 172, 128), 0.55)
PALM = mat("Palette", (255, 255, 255), 0.7)
rnd = random.Random(77)


def finish(o, angle=35):
    mb = bmesh.new()
    mb.from_mesh(o.data)
    bmesh.ops.recalc_face_normals(mb, faces=mb.faces)
    mb.to_mesh(o.data)
    mb.free()
    smooth(o, angle)
    return o


def rod_bm(bm, a, b, r, seg=6, swatch=None):
    """A thin cylinder from Roblox point a to b (strings, dowels)."""
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


def sphere_bm(bm, c, r, swatch, seg=16, rings=10):
    res = bmesh.ops.create_uvsphere(bm, u_segments=seg, v_segments=rings, radius=r)
    vs = res["verts"]
    bmesh.ops.translate(bm, verts=vs, vec=rb(*c))
    tag(bm, faces_of(vs), swatch)
    return vs


# ---------------------------------------------------------------- wainscoting (lower walls)
def build_wainscot():
    bm = bmesh.new()
    top = FLOOR + 44  # chair rail height
    rail = [(0, 0), (1.0, 0), (1.6, 0.6), (1.8, 1.4), (1.4, 2.2), (1.6, 2.8), (0, 3.2)]
    runs = [
        ((RX0, RZ0), (RX0, RZ1), (1, 0, 0), []),
        ((RX1, RZ1), (RX1, RZ0), (-1, 0, 0), []),
        ((RX1, RZ0), (RX0, RZ0), (0, 0, 1), [(54, 126)]),  # door gap (x range)
        ((RX0, RZ1), (RX1, RZ1), (0, 0, -1), []),
    ]
    for (ax, az), (bx, bz), n, gaps in runs:
        a, b = Vector((ax, 0, az)), Vector((bx, 0, bz))
        L = (b - a).length
        t = (b - a).normalized()
        nv = Vector(n)
        # chair rail (split at gaps)
        segs = [(0.0, L)]
        for g0, g1 in gaps:
            # gaps given in x; convert to distance along the run
            d0 = abs(g1 - a.x) if t.x < 0 else abs(g0 - a.x)
            d1 = abs(g0 - a.x) if t.x < 0 else abs(g1 - a.x)
            segs = [(0.0, d0), (d1, L)]
        for s0, s1 in segs:
            p0, p1 = a + t * s0, a + t * s1
            sweep_bm(bm, rail, (p0.x, top - 1.6, p0.z), (p1.x, top - 1.6, p1.z), n)
            # backing board: the painted lower wall the panels sit on
            sweep_bm(bm, [(0, 0), (0.4, 0), (0.4, top - 1.6 - (FLOOR + 6)), (0, top - 1.6 - (FLOOR + 6))],
                     (p0.x, FLOOR + 6, p0.z), (p1.x, FLOOR + 6, p1.z), n)
            # raised panels between the skirting (7.4) and the rail
            span = s1 - s0
            if span < 20:
                continue
            count = max(1, round(span / 30))
            w = span / count
            for k in range(count):
                mid = a + t * (s0 + w * (k + 0.5))
                c = mid + nv * 0.45
                size_along = w - 5
                h = top - 3 - (FLOOR + 10)
                cy = (top - 3 + FLOOR + 10) / 2
                if abs(t.x) > 0.5:
                    sz = (size_along, h, 0.9)
                else:
                    sz = (0.9, h, size_along)
                vs = box_bm(bm, (c.x, cy, c.z), sz)
    o = obj_from_bm("LK_Wainscot_Paint", bm, PAINT)
    finish(o, 30)
    bevel(o, 0.3, 2, 40)
    return o


# ---------------------------------------------------------------- pennant bunting
def bunting(bm, a, b, sag, n):
    A, B = Vector(a), Vector(b)
    pts = []
    for k in range(n + 1):
        t = k / n
        p = A.lerp(B, t) - Vector((0, math.sin(t * math.pi) * sag, 0))
        pts.append(p)
    for k in range(n):
        rod_bm(bm, tuple(pts[k]), tuple(pts[k + 1]), 0.18, 5, "string")
    colors = ["toyred", "toyyellow", "toyblue", "toygreen", "pink", "ivory", "lilac", "coral"]
    for k in range(n):
        p0, p1 = pts[k], pts[k + 1]
        mid = (p0 + p1) / 2
        tip = mid - Vector((0, 7.5, 0))
        q0 = p0.lerp(p1, 0.12)
        q1 = p0.lerp(p1, 0.88)
        # a thin triangular pennant (front + back faces, with thickness)
        side = (p1 - p0).cross(Vector((0, 1, 0))).normalized() * 0.15
        vs = [bm.verts.new(rb(*(q + s))) for q in (q0, q1, tip) for s in (side, -side)]
        f = [
            (vs[0], vs[2], vs[4]),
            (vs[1], vs[5], vs[3]),
            (vs[0], vs[1], vs[3], vs[2]),
            (vs[2], vs[3], vs[5], vs[4]),
            (vs[4], vs[5], vs[1], vs[0]),
        ]
        faces = [bm.faces.new(x) for x in f]
        tag(bm, faces, colors[k % len(colors)])


def build_bunting():
    bm = pbm()
    y = CEIL - 4
    bunting(bm, (RX0 + 4, y, RZ1 - 10), (RX1 - 4, y, RZ0 + 30), 26, 30)
    bunting(bm, (RX0 + 4, y, RZ0 + 40), (RX1 - 4, y, RZ1 - 30), 22, 28)
    o = obj_from_bm("LK_Bunting_Pal", bm, PALM)
    finish(o, 20)
    palette_uv(o)
    return o


# ---------------------------------------------------------------- planet mobile over the rug
def build_mobile():
    bm = pbm()
    cx, cz = -10, -150
    hook = CEIL
    arm_y = 96
    rod_bm(bm, (cx, hook, cz), (cx, arm_y, cz), 0.2, 5, "string")
    # two crossing dowel arms (natural wood)
    for ang in (0.3, 0.3 + math.pi / 2):
        dx, dz = math.cos(ang) * 30, math.sin(ang) * 30
        rod_bm(bm, (cx - dx, arm_y, cz - dz), (cx + dx, arm_y, cz + dz), 0.7, 8, "rawwood")
    sphere_bm(bm, (cx, arm_y, cz), 1.4, "rawwood", 10, 6)
    planets = [
        (0.3, 30, 18, 6.5, "sun"),
        (0.3 + math.pi, 30, 24, 4.2, "coral"),
        (0.3 + math.pi / 2, 30, 14, 5.0, "cornflower"),
        (0.3 + 3 * math.pi / 2, 30, 26, 3.4, "leaf"),
        (0.3 + math.pi / 4, 0, 30, 3.0, "violet"),
    ]
    for ang, r, drop, size, col in planets:
        px, pz = cx + math.cos(ang) * r, cz + math.sin(ang) * r
        py = arm_y - drop
        rod_bm(bm, (px, arm_y, pz), (px, py + size, pz), 0.12, 4, "string")
        sphere_bm(bm, (px, py, pz), size, col, 20, 12)
        if col == "cornflower":  # a ringed planet
            res = bmesh.ops.create_cone(bm, cap_ends=True, segments=28, radius1=size * 1.9, radius2=size * 1.9, depth=0.25)
            vs = res["verts"]
            bmesh.ops.rotate(bm, verts=vs, cent=(0, 0, 0), matrix=Matrix.Rotation(0.4, 3, "X"))
            bmesh.ops.translate(bm, verts=vs, vec=rb(px, py, pz))
            tag(bm, faces_of(vs), "mustard")
    # a crescent moon on the last string
    o = obj_from_bm("LK_Mobile_Pal", bm, PALM)
    finish(o, 50)
    palette_uv(o)
    return o


# ---------------------------------------------------------------- wall shelf over the bed, cubby unit
def build_shelves():
    parts = []
    # wall shelf on the bed wall (x = -160), above the headboard
    sy = FLOOR + 125  # above the crayon drawings on that wall
    parts.append(rounded_box("tmp_ws", (RX0 + 6, sy, -165), (12, 2, 70), 0.6, 3, PAINT))
    for z in (-190, -140):
        # S-curve bracket: a block with a rounded underside
        parts.append(rounded_box("tmp_br", (RX0 + 2, sy - 5, z), (4, 8, 1.6), 0.6, 2, PAINT))
    # cubby unit against the right wall, 3 columns x 2 rows of 22-stud cubes
    x0, x1 = RX1 - 26, RX1
    z0 = -104
    cw, ch = 22, 22
    W = cw * 3 + 2 * 4
    for i in range(4):  # verticals
        z = z0 + i * (cw + 2)
        parts.append(rounded_box("tmp_cv", ((x0 + x1) / 2, FLOOR + 1 + (ch * 2 + 6) / 2, z + 1), (26, ch * 2 + 6, 2), 0.5, 2, PAINT))
    for j in range(3):  # horizontals
        y = FLOOR + 1 + j * (ch + 2)
        parts.append(rounded_box("tmp_ch", ((x0 + x1) / 2, y + 1, z0 + W / 2), (26, 2, W), 0.5, 2, PAINT))
    parts.append(rounded_box("tmp_cb", (RX1 - 0.6, FLOOR + 24, z0 + W / 2), (1.2, 48, W), 0.2, 1, PAINT))
    shelves = join("LK_Shelves_Paint", parts)
    # fabric bins in four cubbies (palette cloth), each with a hand-hole on the front
    bm = pbm()
    cols = ["leaf", "pink", "cornflower", "mustard"]
    slots = [(0, 0), (2, 0), (1, 1), (2, 1)]
    for (ci, rj), col in zip(slots, cols):
        zc = z0 + 2 + ci * (cw + 2) + cw / 2
        yb = FLOOR + 3 + rj * (ch + 2)
        vs = box_bm(bm, (x0 + 12, yb + 9, zc), (20, 18, 19))
        tag(bm, faces_of(vs), col)
        # hand-hole plate (a dark inset) on the room-facing side (-X)
        vs = box_bm(bm, (x0 + 1.9, yb + 13.5, zc), (0.3, 3, 7))
        tag(bm, faces_of(vs), "black")
    bins = obj_from_bm("LK_Bins_Pal", bm, PALM)
    finish(bins, 30)
    bevel(bins, 0.8, 3, 30)
    palette_uv(bins)
    return shelves, bins


# ---------------------------------------------------------------- desk clutter (desk top at y 0)
def pencil(bm, base, yaw, L=16, r=0.8, col="pencil"):
    """Hex pencil lying on the desk: paint body, tin ferrule + pink eraser at one end, sharpened wood cone + graphite."""
    x, z = base
    pts = []
    vs_all = []
    y = r * 0.87
    body = bmesh.ops.create_cone(bm, cap_ends=True, segments=6, radius1=r, radius2=r, depth=L)
    vs = body["verts"]
    tag(bm, faces_of(vs), col)
    vs_all += vs
    fer = bmesh.ops.create_cone(bm, cap_ends=True, segments=12, radius1=r * 1.02, radius2=r * 1.02, depth=1.6)
    bmesh.ops.translate(bm, verts=fer["verts"], vec=(0, 0, L / 2 + 0.8))
    tag(bm, faces_of(fer["verts"]), "tin")
    er = bmesh.ops.create_cone(bm, cap_ends=True, segments=12, radius1=r * 0.95, radius2=r * 0.9, depth=1.6)
    bmesh.ops.translate(bm, verts=er["verts"], vec=(0, 0, L / 2 + 2.4))
    tag(bm, faces_of(er["verts"]), "eraser")
    cone = bmesh.ops.create_cone(bm, cap_ends=True, segments=6, radius1=r, radius2=0.25, depth=3.2)
    bmesh.ops.translate(bm, verts=cone["verts"], vec=(0, 0, -L / 2 - 1.6))
    tag(bm, faces_of(cone["verts"]), "rawwood")
    tip = bmesh.ops.create_cone(bm, cap_ends=True, segments=6, radius1=0.27, radius2=0.02, depth=0.8)
    bmesh.ops.translate(bm, verts=tip["verts"], vec=(0, 0, -L / 2 - 3.6))
    tag(bm, faces_of(tip["verts"]), "graphite")
    vs_all += fer["verts"] + er["verts"] + cone["verts"] + tip["verts"]
    # lay it down along Roblox X, turn by yaw, place
    bmesh.ops.rotate(bm, verts=vs_all, cent=(0, 0, 0), matrix=Matrix.Rotation(math.pi / 2, 3, "Y"))
    bmesh.ops.rotate(bm, verts=vs_all, cent=(0, 0, 0), matrix=Matrix.Rotation(yaw, 3, "Z"))
    bmesh.ops.translate(bm, verts=vs_all, vec=rb(x, y, z))


def sheet(bm, c, w, d, yaw, swatch, curl=0.6, t=0.12):
    """A paper sheet / sticky note lying flat with a gently curled corner."""
    grid = bmesh.ops.create_grid(bm, x_segments=6, y_segments=6, size=0.5)
    vs = grid["verts"]
    for v in vs:
        u, w2 = v.co.x + 0.5, v.co.y + 0.5
        lift = curl * max(0, (u + w2 - 1.3)) ** 2 * 3
        v.co = Vector((v.co.x * w, v.co.y * d, lift))
    faces = faces_of(vs)
    ext = bmesh.ops.extrude_face_region(bm, geom=list(faces))
    nv = [g for g in ext["geom"] if isinstance(g, bmesh.types.BMVert)]
    bmesh.ops.translate(bm, verts=nv, vec=(0, 0, t))
    allv = list(set(vs) | set(nv))
    tag(bm, faces_of(allv), swatch)
    bmesh.ops.rotate(bm, verts=allv, cent=(0, 0, 0), matrix=Matrix.Rotation(yaw, 3, "Z"))
    bmesh.ops.translate(bm, verts=allv, vec=rb(c[0], c[1], c[2]))


def build_desk_clutter():
    bm = pbm()
    # an open spiral sketchbook at the back of the desk, two loose pencils, a third by the ring
    cx, cz, yaw = -22, 50, 0.12
    for side in (-1, 1):
        vs = box_bm(bm, (cx + side * 8.2, 0.35, cz), (16, 0.7, 22))
        tag(bm, faces_of(vs), "paper")
        bmesh.ops.rotate(bm, verts=vs, cent=rb(cx, 0, cz), matrix=Matrix.Rotation(yaw + side * 0.04, 3, "Z"))
    vs = box_bm(bm, (cx, 0.12, cz), (34, 0.24, 23.4))
    tag(bm, faces_of(vs), "navy")
    bmesh.ops.rotate(bm, verts=vs, cent=rb(cx, 0, cz), matrix=Matrix.Rotation(yaw, 3, "Z"))
    for k in range(9):  # spiral coils down the gutter
        zz = cz - 10 + k * 2.5
        res = bmesh.ops.create_cone(bm, cap_ends=True, segments=10, radius1=0.9, radius2=0.9, depth=0.35)
        bmesh.ops.rotate(bm, verts=res["verts"], cent=(0, 0, 0), matrix=Matrix.Rotation(math.pi / 2, 3, "X"))
        bmesh.ops.translate(bm, verts=res["verts"], vec=rb(cx, 0.9, zz))
        tag(bm, faces_of(res["verts"]), "steel")
        bmesh.ops.rotate(bm, verts=res["verts"], cent=rb(cx, 0, cz), matrix=Matrix.Rotation(yaw, 3, "Z"))
    pencil(bm, (-2, 58), 1.9, col="pencil")
    pencil(bm, (-40, 38), 0.5, col="toyred")
    pencil(bm, (55, -5), -0.9, col="toyblue")
    # sticky notes in a little scatter, a sheet with a drawing spot (decal goes on in Roblox), an eraser, a ruler
    sheet(bm, (58, 0.02, 18), 9, 9, 0.3, "noteyellow")
    sheet(bm, (66, 0.14, 24), 9, 9, -0.2, "notepink")
    sheet(bm, (50, 0.02, -40), 26, 34, 0.25, "paper", 0.4)
    vs = box_bm(bm, (62, 1.2, -2), (6, 2.4, 3.2))
    tag(bm, faces_of(vs), "eraser")
    bmesh.ops.rotate(bm, verts=vs, cent=rb(62, 0, -2), matrix=Matrix.Rotation(0.5, 3, "Z"))
    vs = box_bm(bm, (-58, 0.3, -52), (46, 0.6, 5))
    tag(bm, faces_of(vs), "rawwood")
    bmesh.ops.rotate(bm, verts=vs, cent=rb(-58, 0, -52), matrix=Matrix.Rotation(-0.15, 3, "Z"))
    # a stack of three comics at the back left
    yy = 0
    for k, col in enumerate(("coral", "cornflower", "sun")):
        vs = box_bm(bm, (-50 + k * 0.6, yy + 0.4, 56 - k * 0.5), (17, 0.8, 24))
        tag(bm, faces_of(vs), col)
        bmesh.ops.rotate(bm, verts=vs, cent=rb(-50, 0, 56), matrix=Matrix.Rotation(0.2 - k * 0.15, 3, "Z"))
        yy += 0.85
    o = obj_from_bm("LK_DeskClutter_Pal", bm, PALM)
    finish(o, 30)
    palette_uv(o)
    return o


# ---------------------------------------------------------------- floor: wooden train track loop, beach ball
def build_floor_toys():
    bm = pbm()
    cx, cz, rx, rz = 82, -160, 28, 26  # clear of the rug (thicker) and the shelf ladder
    N = 64
    pts = []
    for k in range(N):
        a = k / N * math.tau
        pts.append(Vector((cx + math.cos(a) * rx, 0, cz + math.sin(a) * rz)))
    # track bed: a flat wooden strip with two grooves (rails proud = simplified as two raised strips)
    for k in range(N):
        p0, p1 = pts[k], pts[(k + 1) % N]
        mid = (p0 + p1) / 2
        t = (p1 - p0).normalized()
        n = Vector((-t.z, 0, t.x))
        L = (p1 - p0).length + 0.3
        ang = math.atan2(t.z, t.x)
        for off, w, h, col in ((0, 7, 1.0, "rawwood"), (-2.1, 0.9, 1.5, "darkwood"), (2.1, 0.9, 1.5, "darkwood")):
            c = mid + n * off
            vs = box_bm(bm, (c.x, FLOOR + h / 2, c.z), (L, h, w))
            tag(bm, faces_of(vs), col)
            bmesh.ops.rotate(bm, verts=vs, cent=rb(c.x, 0, c.z), matrix=Matrix.Rotation(-ang, 3, "Z"))
    # beach ball by the door
    sphere_bm(bm, (-40, FLOOR + 7, -218), 7, "toyred", 24, 14)
    o = obj_from_bm("LK_FloorToys_Pal", bm, PALM)
    finish(o, 40)
    palette_uv(o)
    # stripe the ball: recolor faces by longitude band
    me = o.data
    mb = bmesh.new()
    mb.from_mesh(me)
    lay = mb.faces.layers.int.get("sw")
    uv = mb.loops.layers.uv.verify()
    ball = rb(-40, FLOOR + 7, -218)
    stripes = [PAL["toyred"], PAL["ivory"], PAL["toyblue"], PAL["ivory"], PAL["toyyellow"], PAL["ivory"]]
    for f in mb.faces:
        c = f.calc_center_median()
        if (c - ball).length < 7.5:
            ang = math.atan2(c.y - ball.y, c.x - ball.x) % math.tau
            f[lay] = stripes[int(ang / math.tau * 6) % 6]
    mb.to_mesh(me)
    mb.free()
    palette_uv(o)
    return o


wain = build_wainscot()
bunt = build_bunting()
mob = build_mobile()
shelves, bins = build_shelves()
clutter = build_desk_clutter()
toys = build_floor_toys()
print(report())
