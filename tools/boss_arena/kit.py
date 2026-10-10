# Crusher King throne hall kit (exec'd inside Blender through the MCP: exec(open(<this file>).read()), then build()).
# User pick (Oct 10, 2026): "Throne hall island": the unchanged 6x7 fight floor becomes the dais of a ruined voxel
# throne hall on a sky island: broken colonnades with long royal banners down both sides (standing on a lower
# terrace, out of the fight), a half-fallen back wall with a rose window over the king, towers at the back corners,
# an entrance arch + velvet runner on the chase landing, rubble, braziers.
# Same voxel language as tools/pp_trees/trees.py (memory voxel-style-pp): grid voxels, only exposed faces, every face
# a palette swatch picked from material + facing + a per-block jitter (toon shading baked into the colors).
# Atlas: textures/arena_palette.png (make_arena_palette.py). Grid axes = Blender (x, y = depth, z = up); front = -Y
# (= Roblox -z). Output BA_<Piece> meshes, base at z=0, centred in x/y. Placed by ArtService/PixelPlains.luau.
import bpy
import bmesh
import math
import random
from mathutils import Vector

REPO = r"C:\Users\User\OneDrive\Desktop\Coding\glitched_together"
SCENE = "BossArena"
COLL = "BossArenaKit"
N = 8
BASE = {
    "stone": 0, "old": 8, "moss": 16, "ivy": 16, "purple": 24, "gold": 32, "wood": 40, "slate": 44,
    "glitch": 48, "gblack": 49, "cyan": 50, "white": 51, "velvet": 52, "iron": 56, "glass": 60,
}
RAMP = {"stone": 8, "old": 8, "moss": 8, "ivy": 8, "purple": 8, "gold": 8, "wood": 4, "slate": 4, "velvet": 4, "iron": 4}


def scene():
    sc = bpy.data.scenes.get(SCENE) or bpy.data.scenes.new(SCENE)
    bpy.context.window.scene = sc
    c = bpy.data.collections.get(COLL) or bpy.data.collections.new(COLL)
    if c.name not in sc.collection.children:
        sc.collection.children.link(c)
    return sc, c


def material():
    m = bpy.data.materials.get("BA_Palette")
    if m:
        return m
    m = bpy.data.materials.new("BA_Palette")
    m.use_nodes = True
    nt = m.node_tree
    bsdf = next(n for n in nt.nodes if n.type == "BSDF_PRINCIPLED")
    tex = nt.nodes.new("ShaderNodeTexImage")
    tex.image = bpy.data.images.load(REPO + r"\textures\arena_palette.png", check_existing=True)
    tex.interpolation = "Closest"
    nt.links.new(tex.outputs["Color"], bsdf.inputs["Base Color"])
    bsdf.inputs["Roughness"].default_value = 0.75
    return m


class Grid:
    def __init__(self, v):
        self.v = v
        self.cells = {}

    def put(self, i, j, k, kind, over=True):
        if over or (i, j, k) not in self.cells:
            self.cells[(i, j, k)] = kind

    def drop(self, i, j, k):
        self.cells.pop((i, j, k), None)

    def box(self, i0, i1, j0, j1, k0, k1, kind, over=True):
        for i in range(i0, i1 + 1):
            for j in range(j0, j1 + 1):
                for k in range(k0, k1 + 1):
                    self.put(i, j, k, kind, over)

    def surface(self, kinds=None):
        """cells with at least one open face"""
        out = []
        for (i, j, k), kind in self.cells.items():
            if kinds and kind.split(":")[0] not in kinds:
                continue
            for d in ((1, 0, 0), (-1, 0, 0), (0, 1, 0), (0, -1, 0), (0, 0, 1)):
                if (i + d[0], j + d[1], k + d[2]) not in self.cells:
                    out.append(((i, j, k), d))
        return out


DIRS = [((1, 0, 0), "side"), ((-1, 0, 0), "side"), ((0, 1, 0), "side"), ((0, -1, 0), "side"), ((0, 0, 1), "top"), ((0, 0, -1), "bottom")]


def jitter(i, j, k, seed):
    # stable per-block noise: blocks are 2 voxels long in a running bond (alternate courses offset by one)
    off = k % 2
    h = hash(((i + off) // 2, (j + off) // 2, k, seed)) % 7
    return (-1, 0, 0, 0, 0, 1, 1)[h]


def shade(g, key, kind, facing, rng, seed):
    i, j, k = key
    name, _, extra = kind.partition(":")
    base = BASE[name]
    ramp = RAMP.get(name, 1)
    if ramp == 1:
        return base
    f = {"top": 2, "side": 0, "bottom": -2}[facing]
    if name in ("stone", "old"):
        s = 4 + f + jitter(i, j, k, seed)
        if k * g.v < 4:
            s -= 1  # grime at the foot
        if any((i, j, k + d) in g.cells for d in (1, 2)) and facing != "top":
            s -= 0  # (kept simple: sides under an overhang read fine)
        return base + max(0, min(7, s))
    if name in ("moss", "ivy"):
        s = (5 if facing == "top" else 3 if facing == "side" else 1) + rng.choice((-1, 0, 0, 1))
        return base + max(0, min(7, s))
    if name in ("purple", "gold"):
        s = (int(extra) if extra else 4) + f // 2 + rng.choice((0, 0, 0, 1))
        return base + max(0, min(7, s))
    s = (int(extra) if extra else ramp // 2) + (1 if facing == "top" else -1 if facing == "bottom" else 0)
    return base + max(0, min(ramp - 1, s))


def mesh_from(g, name, seed=1):
    rng = random.Random(seed)
    bm = bmesh.new()
    uv = bm.loops.layers.uv.verify()
    vcache = {}
    v = g.v

    def vert(p):
        vv = vcache.get(p)
        if vv is None:
            vv = bm.verts.new((p[0] * v, p[1] * v, p[2] * v))
            vcache[p] = vv
        return vv

    for key, kind in g.cells.items():
        i, j, k = key
        for (di, dj, dk), facing in DIRS:
            if (i + di, j + dj, k + dk) in g.cells:
                continue
            c = (i + di * 0.5, j + dj * 0.5, k + dk * 0.5)
            n_ax = [di, dj, dk].index(next(x for x in (di, dj, dk) if x != 0))
            a, b = [x for x in (0, 1, 2) if x != n_ax]
            corners = []
            for sa, sb in ((-0.5, -0.5), (0.5, -0.5), (0.5, 0.5), (-0.5, 0.5)):
                p = list(c)
                p[a] += sa
                p[b] += sb
                corners.append(tuple(round(x * 2) for x in p))
            vs = [vert(tuple(x / 2 for x in p)) for p in corners]
            if (n_ax == 1) ^ ((di + dj + dk) < 0):
                vs.reverse()
            try:
                f = bm.faces.new(vs)
            except ValueError:
                continue
            sw = shade(g, key, kind, facing, rng, seed)
            r, col = divmod(sw, N)
            for l, (fu, fv) in zip(f.loops, ((0.1, 0.1), (0.9, 0.1), (0.9, 0.9), (0.1, 0.9))):
                l[uv].uv = ((col + fu) / N, 1 - (r + 1) / N + fv / N)
    bm.normal_update()
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    old = bpy.data.objects.get(name)
    if old:
        bpy.data.objects.remove(old, do_unlink=True)
    me = bpy.data.meshes.new(name)
    bm.to_mesh(me)
    bm.free()
    o = bpy.data.objects.new(name, me)
    scene()[1].objects.link(o)
    me.materials.append(material())
    bb = [Vector(c) for c in o.bound_box]
    lo = Vector((min(p.x for p in bb), min(p.y for p in bb), min(p.z for p in bb)))
    hi = Vector((max(p.x for p in bb), max(p.y for p in bb), max(p.z for p in bb)))
    shift = Vector(((lo.x + hi.x) / 2, (lo.y + hi.y) / 2, lo.z))
    for vv in me.vertices:
        vv.co -= shift
    return o


# Weathering ------------------------------------------------------------------------------------------------------
def chip(g, rng, p=0.05, kinds=("stone", "old")):
    """knock a few voxels off exposed corners and edges"""
    for (i, j, k), d in g.surface(kinds):
        if rng.random() < p * 0.25:
            open_faces = sum(1 for dd in ((1, 0, 0), (-1, 0, 0), (0, 1, 0), (0, -1, 0)) if (i + dd[0], j + dd[1], k) not in g.cells)
            if open_faces >= 2 and k > 1:
                g.drop(i, j, k)


def moss_tops(g, rng, p=0.5):
    for (i, j, k), d in g.surface(("stone", "old")):
        if d == (0, 0, 1) and rng.random() < p:
            g.put(i, j, k + 1, "moss", over=False)


def ivy(g, rng, start, length, out, span=None):
    """a vine climbing a face: start (i, j, k) just outside the surface, out = the face normal (di, dj); span =
    (lo, hi) keeps its sideways wander on the face"""
    i, j, k = start
    for _ in range(length):
        g.put(i, j, k, "ivy", over=False)
        if rng.random() < 0.35:  # leaves either side
            g.put(i + (out[1] != 0) * rng.choice((-1, 1)), j + (out[0] != 0) * rng.choice((-1, 1)), k, "ivy", over=False)
        k += 1
        if rng.random() < 0.25:
            step = rng.choice((-1, 1))
            if out[0] != 0:
                j = max(span[0], min(span[1], j + step)) if span else j + step
            else:
                i = max(span[0], min(span[1], i + step)) if span else i + step


# Pieces ----------------------------------------------------------------------------------------------------------
def pillar(seed, height=74, broken_at=None):
    """v=1: square plinth, a chamfered fluted shaft with banding, a capital + abacus with a gold band"""
    rng = random.Random(seed)
    g = Grid(1.0)
    g.box(-5, 4, -5, 4, 0, 2, "old")
    g.box(-4, 3, -4, 3, 3, 3, "old")
    top_shaft = height - 9
    for k in range(4, top_shaft):
        band = k % 16 == 0
        for i in range(-3, 3):
            for j in range(-3, 3):
                edge_i, edge_j = i in (-3, 2), j in (-3, 2)
                if edge_i and edge_j and not band:
                    continue  # chamfered corners
                if not band and ((edge_i and j % 2 == 0) or (edge_j and i % 2 == 0)):
                    # flutes: the groove sits one voxel in
                    continue
                g.put(i, j, k, "stone")
        if band:
            for i in range(-4, 4):
                for j in range(-4, 4):
                    if i in (-4, 3) or j in (-4, 3):
                        g.put(i, j, k, "old")
    # capital: flares out in steps, a gold band, the abacus slab
    g.box(-4, 3, -4, 3, top_shaft, top_shaft + 1, "stone")
    g.box(-5, 4, -5, 4, top_shaft + 2, top_shaft + 3, "stone")
    for i in range(-5, 5):
        for j in range(-5, 5):
            if i in (-5, 4) or j in (-5, 4):
                g.put(i, j, top_shaft + 3, "gold:5")
    g.box(-6, 5, -6, 5, top_shaft + 4, height - 1, "stone")
    if broken_at:
        # snapped: everything above a jagged line is gone, a few fallen-in blocks on top
        for key in list(g.cells):
            i, j, k = key
            cut = broken_at + int(3 * math.sin(i * 0.9 + seed) + 2 * math.cos(j * 1.3 + seed)) + rng.choice((0, 0, 1, -1))
            if k > cut:
                del g.cells[key]
    chip(g, rng, 0.08)
    moss_tops(g, rng, 0.55)
    for _ in range(rng.randint(1, 3)):  # ivy up from the plinth
        side = rng.choice(((1, 0), (-1, 0), (0, 1), (0, -1)))
        # just outside the shaft (it spans -3..2): flush on the stone, never hanging in the air
        if side[0]:
            start = (3 if side[0] > 0 else -4, rng.choice((-2, 0)), 4)
        else:
            start = (rng.choice((-2, 0)), 3 if side[1] > 0 else -4, 4)
        ivy(g, rng, start, rng.randint(6, max(7, (broken_at or height) - 12)), side, (-2, 1))
    for i in range(-6, 6):  # moss skirt round the foot
        for j in range(-6, 6):
            if (abs(i + 0.5) > 5 or abs(j + 0.5) > 5) and rng.random() < 0.5:
                g.put(i, j, 0, "moss", over=False)
    return g


def lintel(seed, length=28):
    """v=1: the beam laid across two pillar tops (x = along the colonnade), dentils under, gold inlay"""
    rng = random.Random(seed)
    g = Grid(1.0)
    n = length // 2
    g.box(-n, n - 1, -3, 2, 2, 4, "stone")
    g.box(-n, n - 1, -3, 2, 5, 5, "old")
    for i in range(-n + 1, n - 1, 2):  # dentils on both long faces
        g.put(i, -4, 3, "stone")
        g.put(i, 3, 3, "stone")
    for i in range(-n + 3, n - 3):
        if i % 4 != 0:
            g.put(i, -4, 4, "gold:4")
            g.put(i, 3, 4, "gold:4")
    g.box(-n + 5, n - 6, -2, 1, 0, 1, "stone")  # soffit: the beam's belly
    chip(g, rng, 0.12)
    moss_tops(g, rng, 0.45)
    for _ in range(4):  # ivy hanging off it
        i = rng.randint(-n + 2, n - 3)
        side = rng.choice((-4, 3))
        for k in range(5, 5 - rng.randint(3, 8), -1):
            g.put(i, side, k, "ivy", over=False)
    return g


CROWN = [
    "..G..G..G..",
    "..G..G..G..",
    ".GGG.G.GGG.",
    ".GGGGGGGGG.",
    ".GRGGBGGRG.",
    ".GGGGGGGGG.",
    "..GGGGGGG..",
]


def banner(seed, torn=False):
    """v=0.5: a long royal-purple banner on a gold rod held by two iron arms (+Y = back toward the pillar): gold
    border and centre stripe, a pixel crown, swallowtail end; torn = holes and a Glitch patch eating the bottom"""
    rng = random.Random(seed)
    g = Grid(0.5)
    W, H = 18, 60  # 9 x 30 studs
    for i in range(-W // 2, W // 2):
        for k in range(0, H):
            # swallowtail: a V cut out of the last 8 rows
            x = i + W // 2
            if k < 8 and abs(x - (W - 1) / 2) < (8 - k) * 0.9:
                continue
            wave = round(math.sin((i + 9) * 0.45 + k * 0.05) * 0.8)  # soft folds across the width
            light = 4 + wave * 2  # fold crests lighter, troughs darker
            border = x in (0, W - 1) or k in (8, H - 4) or (k < 8 and x in (0, W - 1))
            stripe = x in (8, 9) and k < 30
            kind = "gold:5" if border or stripe else f"purple:{light}"
            g.put(i, wave, k, kind)
    # the crown up near the top (rows written top to bottom)
    for r, row in enumerate(CROWN):
        for c, ch in enumerate(row):
            if ch == ".":
                continue
            kind = {"G": "gold:6", "R": "velvet:2", "B": "glass:0"}[ch]
            i = c - 6 + 0
            k = H - 14 - r
            wave = round(math.sin((i + 9) * 0.45 + k * 0.05) * 0.8)
            g.put(i, wave - 1, k, kind)  # proud of the cloth: stitched on
    if torn:
        for _ in range(9):
            ci, ck = rng.randint(-8, 8), rng.randint(9, 26)
            for key in list(g.cells):
                if (key[0] - ci) ** 2 + (key[2] - ck) ** 2 < rng.uniform(1, 4):
                    del g.cells[key]
        for key in list(g.cells):  # the Glitch: static where the cloth used to end
            i, j, k = key
            if k < 20 + int(3 * math.sin(i * 0.8)) and i > -3:
                g.cells[key] = rng.choice(("glitch", "glitch", "gblack", "cyan"))
    # rod: a gold bar across the top with knobs; two iron arms back to the pillar face
    top = H + 1
    for i in range(-W // 2 - 2, W // 2 + 2):
        g.put(i, 0, top, "gold:4")
    for e in (-W // 2 - 3, W // 2 + 2):
        g.box(e, e, -1, 1, top - 1, top + 1, "gold:6")
    for i in (-W // 2 + 2, W // 2 - 3):
        for j in range(0, 5):
            g.put(i, j, top + 1, "iron")
        g.put(i, 4, top, "iron")
        g.put(i, 4, top + 2, "iron")
    return g


def back_wall(seed):
    """v=2: the throne hall's back wall, 84 x 132 x 4: a plinth course, buttresses, two tall lancet windows, a rose
    window over the king's head, crenellations; the right third collapsed in a diagonal break with ivy pouring
    down the face"""
    rng = random.Random(seed)
    g = Grid(2.0)
    W, H = 42, 66  # cells
    rose_c, rose_r = (0, 56), 6.6  # cell centre (i, k), radius in cells (13 studs)

    def top_at(i):
        x = i + W // 2
        if x > 28:  # the collapse: steps down to the right
            return int(H - 6 - (x - 28) * 1.6 + rng.choice((0, 1, -1)))
        return H

    for i in range(-W // 2, W // 2):
        th = top_at(i)
        for k in range(0, th):
            # windows
            di, dk = i - rose_c[0], k - rose_c[1]
            d = math.sqrt(di * di + dk * dk)
            if d < rose_r:
                ring = d > rose_r - 1.2
                hub = d < 1.6
                ang = math.atan2(dk, di)
                spoke = abs(math.sin(ang * 4)) < 0.22 and d > 1.5
                if ring or hub or spoke:
                    g.put(i, 0, k, "gold:5" if ring else "stone")
                    g.put(i, 1, k, "stone")
                continue
            lancet = False
            for cx in (-14, 13):
                if cx - 2 <= i <= cx + 1 and 22 <= k < 44:
                    if k < 40 or abs(i - cx + 0.5) < (44 - k) * 0.6:
                        lancet = True
            if lancet:
                continue
            kind = "old" if k < 4 else "stone"
            g.put(i, 0, k, kind)
            g.put(i, 1, k, kind)
        # crenellations on the intact top
        if th == H and i % 3 != 0:
            g.put(i, 0, H, "stone")
            g.put(i, 1, H, "stone")
    # rose window frame moulding standing proud
    for a in range(0, 360, 4):
        r = rose_r + 0.4
        g.put(round(rose_c[0] + math.cos(math.radians(a)) * r), -1, round(rose_c[1] + math.sin(math.radians(a)) * r), "old", over=False)
    # buttresses + a string course
    for bi in (-21, -8, 7):
        for k in range(0, (top_at(bi) if bi < 7 else 30)):
            depth = 2 if k < 40 else 1
            for j in range(-depth, 0):
                g.put(bi, j, k, "old" if k < 4 else "stone")
                g.put(bi + 1, j, k, "old" if k < 4 else "stone")
    for i in range(-W // 2, W // 2):
        if top_at(i) > 46:
            g.put(i, -1, 46, "old", over=False)
    chip(g, rng, 0.06)
    moss_tops(g, rng, 0.6)
    # ivy curtains spilling from the top over the face
    for _ in range(9):
        i = rng.randint(-W // 2, W // 2 - 1)
        k = top_at(i) - 1
        for _ in range(rng.randint(8, 30)):
            if (i, 0, k) in g.cells or (i, 1, k) in g.cells:
                g.put(i, -1, k, "ivy", over=False)
            k -= 1
            if rng.random() < 0.3:
                i += rng.choice((-1, 1))
    # rubble at the foot of the collapse
    for _ in range(40):
        i = rng.randint(6, 20)
        g.put(i, rng.randint(-4, -1), rng.choice((0, 0, 0, 1)), rng.choice(("stone", "stone", "old")), over=False)
    return g


def tower(seed, broken=False):
    """v=2: a round tower, radius 10 / 120 tall, a corbelled walk near the top, arrow slits, a plum slate cone with
    a gold finial and a royal pennant; broken = no roof, a jagged ring, ivy"""
    rng = random.Random(seed)
    g = Grid(2.0)
    R = 5.2
    body = 60
    for k in range(0, body):
        rr = R + (1 if body - 6 <= k < body - 4 else 0) + (1 if body - 4 <= k else 0)  # corbels, then the walk
        n = int(rr) + 1
        for i in range(-n, n + 1):
            for j in range(-n, n + 1):
                d = math.sqrt(i * i + j * j)
                if d > rr:
                    continue
                if k >= body - 1 and d < rr - 1:
                    continue  # the walk's floor is one cell down: a parapet ring stands round it
                if k == body - 1 and (round(math.degrees(math.atan2(j, i))) // 30) % 2 == 0:
                    continue  # merlons
                ang = math.atan2(j, i)
                slit = d > rr - 1 and (k % 14 in (5, 6, 7)) and abs(math.sin(ang * 2 + k * 0.1)) < 0.12
                g.put(i, j, k, "iron" if slit else ("old" if k < 3 else "stone"))
    if broken:
        for key in list(g.cells):
            i, j, k = key
            cut = 44 + int(5 * math.sin(math.atan2(j, i) * 2 + seed) + 3 * math.cos(math.atan2(j, i) * 5)) + rng.choice((0, 1))
            if k > cut:
                del g.cells[key]
    else:
        roof = 15
        for k in range(roof):
            rr = (R + 0.6) * (1 - k / roof)
            n = int(rr) + 1
            for i in range(-n, n + 1):
                for j in range(-n, n + 1):
                    if math.sqrt(i * i + j * j) <= rr:
                        g.put(i, j, body - 2 + k, "slate:" + str(1 + (k % 2)))
        top = body - 2 + roof
        for k in range(top, top + 4):
            g.put(0, 0, k, "gold:6")
        for k in range(2):  # pennant
            for i in range(1, 5 - k * 2):
                g.put(i, 0, top + 2 + k, "purple:5")
    chip(g, rng, 0.07)
    moss_tops(g, rng, 0.6)
    for _ in range(3 if broken else 2):
        a = rng.uniform(0, math.tau)
        d = (math.cos(a), math.sin(a))
        start = (round(d[0] * (R + 1)), round(d[1] * (R + 1)), 1)
        ivy(g, rng, start, rng.randint(14, 36), (1 if abs(d[0]) > abs(d[1]) else 0, 1 if abs(d[1]) >= abs(d[0]) else 0))
    return g


def gate(seed):
    """v=1: the entrance arch on the chase landing: two 4x4 posts 30 tall, a round arch (inner width 22), a gold
    crown keystone, a little crenellated top"""
    rng = random.Random(seed)
    g = Grid(1.0)
    inner = 11  # half inner width
    spring = 19  # arch springs at this height
    for side in (-1, 1):
        x0 = inner if side > 0 else -inner - 4
        g.box(x0 - 1, x0 + 4, -3, 2, 0, 2, "old")  # post plinths
        g.box(x0, x0 + 3, -2, 1, 3, spring + 12, "stone")
    for i in range(-inner - 4, inner + 4):
        for k in range(spring, spring + 15):
            x = i + 0.5
            dk = k - spring + 0.5
            d = math.sqrt(x * x + dk * dk)
            if d < inner:
                continue
            if d < inner + 1.2 and k < spring + 13:
                g.box(i, i, -3, 2, k, k, "old")  # the arch ring, proud of the wall
            elif k < spring + 13:
                g.box(i, i, -2, 1, k, k, "stone")
    for i in range(-inner - 4, inner + 4):
        if i % 3 != 0:
            g.box(i, i, -2, 1, spring + 13, spring + 14, "stone")
    # the crown stands ON the arch (hung inside the opening it hid the king from the chase landing, Oct 10 shot)
    for r, row in enumerate(CROWN):
        for c, ch in enumerate(row):
            if ch != ".":
                g.box(c - 6, c - 6, -1, 0, spring + 15 + len(CROWN) - 1 - r, spring + 15 + len(CROWN) - 1 - r, {"G": "gold:6", "R": "velvet:2", "B": "glass:0"}[ch])
    g.box(-1, 0, -3, -3, spring + 10, spring + 12, "gold:4")  # the keystone, flush with the arch ring
    chip(g, rng, 0.06)
    moss_tops(g, rng, 0.5)
    for side in (-1, 1):
        ivy(g, rng, (side * (inner + 4) if side > 0 else -inner - 5, 0, 3), rng.randint(12, 24), (side, 0))
    return g


def carpet(seed, w=8, length=20):
    """v=0.5: a velvet runner with gold edges and a frayed far end"""
    rng = random.Random(seed)
    g = Grid(0.5)
    nw, nl = int(w / 0.5), int(length / 0.5)
    for i in range(-nw // 2, nw // 2):
        for j in range(-nl // 2, nl // 2):
            if j >= nl // 2 - 2 and rng.random() < 0.4:
                continue  # frayed
            edge = i in (-nw // 2, nw // 2 - 1)
            inner = i in (-nw // 2 + 2, nw // 2 - 3)
            kind = "gold:5" if edge or (inner and j % 4 != 0) else ("velvet:2" if (i + j) % 7 else "velvet:1")
            g.put(i, j, 0, kind)
    return g


def rubble(seed):
    """v=1: a fallen column drum and broken blocks"""
    rng = random.Random(seed)
    g = Grid(1.0)
    L = rng.randint(7, 10)
    for j in range(-L // 2, L // 2):  # drum lying along Y
        for i in range(-3, 3):
            for k in range(0, 6):
                if (i + 0.5) ** 2 + (k - 2.5) ** 2 <= 9.5:
                    g.put(i, j, k, "stone")
    for _ in range(8):
        i, j = rng.randint(-6, 6), rng.randint(-6, 6)
        s = rng.randint(1, 2)
        g.box(i, i + s, j, j + s, 0, rng.randint(0, s), rng.choice(("stone", "old")), over=False)
    chip(g, rng, 0.1)
    moss_tops(g, rng, 0.5)
    return g


def brazier(seed):
    """v=0.5: an iron bowl on a stone pedestal, glowing coals (the flames are particles in Roblox)"""
    rng = random.Random(seed)
    g = Grid(0.5)
    g.box(-3, 2, -3, 2, 0, 1, "old")
    g.box(-2, 1, -2, 1, 2, 7, "stone")
    for k in range(8, 12):
        r = 2.5 + (k - 8) * 0.7
        n = int(r) + 1
        for i in range(-n, n):
            for j in range(-n, n):
                d = math.sqrt((i + 0.5) ** 2 + (j + 0.5) ** 2)
                if d <= r and (d > r - 1.2 or k == 8):
                    g.put(i, j, k, "iron" if k < 11 else "gold:4")
    for i in range(-4, 4):
        for j in range(-4, 4):
            if (i + 0.5) ** 2 + (j + 0.5) ** 2 < 10:
                g.put(i, j, 10, rng.choice(("gold:7", "gold:6", "glass:0")), over=False)  # embers
    return g


PIECES = {
    # name: (builder, seed)
    "BA_Pillar": (lambda: pillar(1), 1),
    "BA_PillarBroken": (lambda: pillar(2, broken_at=46), 2),
    "BA_PillarStump": (lambda: pillar(3, broken_at=22), 3),
    "BA_Lintel": (lambda: lintel(4), 4),
    "BA_Banner": (lambda: banner(5), 5),
    "BA_BannerTorn": (lambda: banner(6, torn=True), 6),
    "BA_BackWall": (lambda: back_wall(7), 7),
    "BA_Tower": (lambda: tower(8), 8),
    "BA_TowerBroken": (lambda: tower(9, broken=True), 9),
    "BA_Gate": (lambda: gate(10), 10),
    "BA_Carpet": (lambda: carpet(11), 11),
    "BA_Rubble1": (lambda: rubble(12), 12),
    "BA_Rubble2": (lambda: rubble(13), 13),
    "BA_Brazier": (lambda: brazier(14), 14),
}


def tris(o):
    return sum(len(p.vertices) - 2 for p in o.data.polygons)


def bbox(o):
    bb = [Vector(c) for c in o.bound_box]
    lo = Vector((min(p.x for p in bb), min(p.y for p in bb), min(p.z for p in bb)))
    hi = Vector((max(p.x for p in bb), max(p.y for p in bb), max(p.z for p in bb)))
    return hi - lo


def build(only=None):
    scene()
    out = []
    x = 0
    for name, (make, seed) in PIECES.items():
        if only and name not in only:
            continue
        o = mesh_from(make(), name, seed)
        d = bbox(o)
        o.location = (x + d.x / 2, 0, 0)
        x += d.x + 6
        out.append(f"{name}: roblox size=({d.x:.2f},{d.z:.2f},{d.y:.2f}) tris={tris(o)}")
    return "\n".join(out)


def export():
    sc, c = scene()
    objs = [o for o in c.objects if o.name.startswith("BA_")]
    saved = {o.name: o.location.copy() for o in objs}
    for o in objs:
        o.location = (0, 0, 0)
    bpy.ops.object.select_all(action="DESELECT")
    for o in objs:
        o.select_set(True)
    bpy.context.view_layer.objects.active = objs[0]
    bpy.ops.export_scene.fbx(
        filepath=REPO + r"\blender_assets\BossArena.fbx",
        use_selection=True,
        object_types={"MESH"},
        apply_unit_scale=True,
        bake_space_transform=True,
        path_mode="COPY",
        embed_textures=True,
    )
    for o in objs:
        o.location = saved[o.name]
    bpy.data.libraries.write(REPO + r"\blender_assets\BossArena.blend", set(objs), fake_user=True)
    return f"exported {len(objs)}"
