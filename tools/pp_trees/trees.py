# Pixel Plains voxel trees (exec'd inside Blender through the MCP: exec(open(<this file>).read())).
# References (Oct 3, 2026): It Takes Two's Garden / Tree chapters (lush clustered leaf masses, flared roots, moss,
# warm light through gaps) and MagicaVoxel stylized oaks (small voxels, canopy split into clumps with branches
# showing between them, bright yellow-green tops shading to dark undersides). Each tree is generated on a voxel grid,
# only exposed faces are kept, and every face gets a palette swatch from its material, height and facing (tops light,
# undersides dark, voxels under more leaves darker): toon voxel shading baked into the colors.
# Output: PP_Tree_<Kind> / PP_Bush_<n> meshes at the origin, base at z=0, front -Y. Atlas textures/tree_palette.png.
import bpy
import bmesh
import math
import random
from mathutils import Vector

REPO = r"C:\Users\User\OneDrive\Desktop\Coding\glitched_together"
SCENE = "PPTrees"
COLL = "PPTrees"
N = 8
LEAF, PINE, BARK, BIRCH_BARK, BIRCH_LEAF, APPLE, MOSS = 0, 8, 16, 24, 28, 32, 36
YELLOW, PETAL, ROCK = 38, 40, 44
PETALS = {"purple": 0, "blue": 1, "white": 2, "red": 3}


def scene():
    sc = bpy.data.scenes.get(SCENE) or bpy.data.scenes.new(SCENE)
    bpy.context.window.scene = sc
    c = bpy.data.collections.get(COLL) or bpy.data.collections.new(COLL)
    if c.name not in sc.collection.children:
        sc.collection.children.link(c)
    return sc, c


def material():
    m = bpy.data.materials.get("PP_TreePalette")
    if m:
        return m
    m = bpy.data.materials.new("PP_TreePalette")
    m.use_nodes = True
    nt = m.node_tree
    bsdf = next(n for n in nt.nodes if n.type == "BSDF_PRINCIPLED")
    tex = nt.nodes.new("ShaderNodeTexImage")
    tex.image = bpy.data.images.load(REPO + r"\textures\tree_palette.png", check_existing=True)
    tex.interpolation = "Closest"
    nt.links.new(tex.outputs["Color"], bsdf.inputs["Base Color"])
    bsdf.inputs["Roughness"].default_value = 0.7
    return m


# Grid helpers ----------------------------------------------------------------------------------------------------
class Grid:
    def __init__(self, v):
        self.v = v  # voxel size in studs
        self.cells = {}  # (i, j, k) -> kind ("bark", "leaf", "pine", "birch", "bleaf", "apple", "moss", "mark")

    def key(self, p):
        return (round(p[0] / self.v), round(p[1] / self.v), round(p[2] / self.v))

    def put(self, p, kind, over=True):
        k = self.key(p)
        if over or k not in self.cells:
            self.cells[k] = kind

    def ball(self, c, r, kind, rng=None, fluff=0.0, over=False):
        n = int(math.ceil(r / self.v)) + 1
        ci = self.key(c)
        for i in range(-n, n + 1):
            for j in range(-n, n + 1):
                for k in range(-n, n + 1):
                    d = math.sqrt(i * i + j * j + (k * 1.15) ** 2) * self.v
                    edge = r - d
                    if edge < 0:
                        continue
                    if rng and edge < self.v * 1.6 and rng.random() < fluff:
                        continue  # ragged edge: a few voxels missing round the rim
                    key = (ci[0] + i, ci[1] + j, ci[2] + k)
                    if over or key not in self.cells:
                        self.cells[key] = kind

    def tube(self, a, b, r0, r1, kind):
        a, b = Vector(a), Vector(b)
        steps = max(2, int((b - a).length / (self.v * 0.5)))
        for s in range(steps + 1):
            t = s / steps
            p = a.lerp(b, t)
            r = r0 + (r1 - r0) * t
            n = int(math.ceil(r / self.v))
            ci = self.key(p)
            for i in range(-n, n + 1):
                for j in range(-n, n + 1):
                    for k in range(-1, 2):
                        if math.sqrt(i * i + j * j) * self.v <= r + self.v * 0.3:
                            self.cells[(ci[0] + i, ci[1] + j, ci[2] + k)] = kind


# Shading --------------------------------------------------------------------------------------------------------
DIRS = [((1, 0, 0), "side"), ((-1, 0, 0), "side"), ((0, 1, 0), "side"), ((0, -1, 0), "side"), ((0, 0, 1), "top"), ((0, 0, -1), "bottom")]


def shade(g, key, kind, facing, zmin, zmax, rng):
    i, j, k = key
    h = (k - zmin) / max(1, zmax - zmin)
    if kind in ("leaf", "pine", "bleaf"):
        cover = sum(1 for dk in range(1, 4) if (i, j, k + dk) in g.cells)  # leaves above = in shadow
        s = 0.5 + h * 4.5 + {"top": 2.5, "side": 0.5, "bottom": -2.5}[facing] - cover * 1.0 + rng.uniform(-0.8, 0.8)
        s = max(0, min(7, int(round(s))))
        base = {"leaf": LEAF, "pine": PINE}.get(kind)
        if kind == "bleaf":
            return BIRCH_LEAF + max(0, min(3, s // 2))
        return base + s
    if kind == "bark":
        s = 3 + {"top": 2, "side": 0, "bottom": -2}[facing] + rng.choice((-1, 0, 0, 1)) + (1 if (i + k) % 5 == 0 else 0)
        return BARK + max(0, min(7, s))
    if kind == "birch":
        return BIRCH_BARK + (0 if facing == "top" else rng.choice((0, 0, 1, 2)))
    if kind == "mark":
        return BIRCH_BARK + 3
    if kind == "apple":
        return APPLE + (1 if facing == "top" else 0)
    if kind == "moss":
        return MOSS + (1 if facing == "top" else 0)
    if kind == "yellow":
        return YELLOW + (1 if facing == "top" else 0)
    if kind.startswith("petal_"):
        return PETAL + PETALS[kind[6:]]
    if kind == "rock":
        s = 1 + {"top": 2, "side": 0, "bottom": -1}[facing] + rng.choice((-1, 0, 0, 1))
        return ROCK + max(0, min(3, s))
    if kind == "stem":
        return LEAF + 2
    if kind.startswith("plank"):  # plank0..plank2: three wood tones, lighter on top faces
        tone = int(kind[5:])
        s = 3 + tone * 2 + {"top": 1, "side": 0, "bottom": -2}[facing] + rng.choice((0, 0, 1, -1))
        return BARK + max(0, min(7, s))
    if kind == "frame":
        return BARK + (2 if facing == "top" else 0)
    if kind == "iron":
        return ROCK + (2 if facing == "top" else 0)
    if kind == "roof":
        return BARK + (1 if facing == "top" else 0) + rng.choice((0, 0, 1))
    return 0


def mesh_from(g, name, seed=1):
    rng = random.Random(seed)
    zs = [k[2] for k, kind in g.cells.items() if kind in ("leaf", "pine", "bleaf")] or [k[2] for k in g.cells]
    zmin, zmax = min(zs), max(zs)
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
            # quad corners on the face (voxel spans key +- 0.5)
            c = (i + di * 0.5, j + dj * 0.5, k + dk * 0.5)
            ax = [0, 1, 2]
            n_ax = [di, dj, dk].index(next(x for x in (di, dj, dk) if x != 0))
            a, b = [x for x in ax if x != n_ax]
            corners = []
            for sa, sb in ((-0.5, -0.5), (0.5, -0.5), (0.5, 0.5), (-0.5, 0.5)):
                p = list(c)
                p[a] += sa
                p[b] += sb
                corners.append(tuple(round(x * 2) for x in p))  # half-voxel integer coords
            vs = [vert(tuple(x / 2 for x in p)) for p in corners]
            sgn = (di + dj + dk)
            if (n_ax == 1) ^ (sgn < 0):
                vs.reverse()
            try:
                f = bm.faces.new(vs)
            except ValueError:
                continue
            sw = shade(g, key, kind, facing, zmin, zmax, rng)
            r, col = divmod(sw, N)
            for l, (fu, fv) in zip(f.loops, ((0.1, 0.1), (0.9, 0.1), (0.9, 0.9), (0.1, 0.9))):
                l[uv].uv = ((col + fu) / N, 1 - (r + 1) / N + fv / N)
    bm.normal_update()
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    # Roblox coords -> Blender: grid is (x, z_depth, y_up) already in Blender axes (x, y, z)
    old = bpy.data.objects.get(name)
    if old:
        bpy.data.objects.remove(old, do_unlink=True)
    me = bpy.data.meshes.new(name)
    bm.to_mesh(me)
    bm.free()
    o = bpy.data.objects.new(name, me)
    scene()[1].objects.link(o)
    me.materials.append(material())
    # base at z = 0, centred in x/y
    bb = [Vector(c) for c in o.bound_box]
    lo = Vector((min(p.x for p in bb), min(p.y for p in bb), min(p.z for p in bb)))
    hi = Vector((max(p.x for p in bb), max(p.y for p in bb), max(p.z for p in bb)))
    shift = Vector(((lo.x + hi.x) / 2, (lo.y + hi.y) / 2, lo.z))
    for vv in me.vertices:
        vv.co -= shift
    o["shift"] = tuple(shift)  # grid origin = -shift in the exported mesh (signs need it to line up with the text)
    return o


# Trees ----------------------------------------------------------------------------------------------------------
def roots(g, rng, r, kind="bark"):
    for a in range(5):
        ang = a / 5 * math.tau + rng.uniform(-0.3, 0.3)
        d = Vector((math.cos(ang), math.sin(ang), 0))
        g.tube((0, 0, 1.0), tuple(d * (r * 2.6) + Vector((0, 0, 0.2))), r * 0.55, r * 0.25, kind)
    for a in range(6):  # moss tufts round the foot
        ang = rng.uniform(0, math.tau)
        p = Vector((math.cos(ang), math.sin(ang), 0)) * rng.uniform(r * 0.8, r * 2)
        g.put((p.x, p.y, 0.3), "moss")


def oak(seed, height=11.0, spread=6.0, v=0.5, apples=False, clumps=5):
    rng = random.Random(seed)
    g = Grid(v)
    r = 0.95
    lean = Vector((rng.uniform(-0.5, 0.5), rng.uniform(-0.5, 0.5), 0))
    fork = Vector((0, 0, height * 0.42)) + lean * 0.5  # the trunk forks here into the main limbs
    g.tube((0, 0, 0), fork, r * 1.2, r * 0.9, "bark")
    roots(g, rng, r)
    ends = []
    for b in range(clumps):
        ang = b / clumps * math.tau + rng.uniform(-0.35, 0.35)
        out = Vector((math.cos(ang), math.sin(ang), 0)) * spread * rng.uniform(0.55, 0.8)
        knee = fork + out * 0.45 + Vector((0, 0, rng.uniform(1.2, 2.2)))
        end = fork + out + Vector((0, 0, rng.uniform(3.0, 4.6)))
        g.tube(fork, knee, 0.6, 0.45, "bark")  # crooked limb: two segments
        g.tube(knee, end, 0.45, 0.28, "bark")
        ends.append(end)
    lead = fork + Vector((rng.uniform(-0.6, 0.6), rng.uniform(-0.6, 0.6), height * 0.45))
    g.tube(fork, lead, 0.6, 0.3, "bark")
    ends.append(lead)
    placed = []
    for e in ends:
        cr = rng.uniform(1.9, 2.6)
        c = e + Vector((0, 0, 0.9))
        g.ball(c, cr, "leaf", rng, fluff=0.4)
        g.ball(c + Vector((rng.uniform(-1, 1), rng.uniform(-1, 1), 1.0)), cr * 0.7, "leaf", rng, fluff=0.4)  # lumpy top
        placed.append((c, cr))
    if apples:
        for c, cr in placed:
            for _ in range(6):
                d = Vector((rng.uniform(-1, 1), rng.uniform(-1, 1), rng.uniform(-0.7, 0.3))).normalized()
                g.put(c + d * (cr - 0.35), "apple", over=True)  # set into the leaves, not floating
    return g


def pine(seed, height=13.0, v=0.5):
    rng = random.Random(seed)
    g = Grid(v)
    g.tube((0, 0, 0), (0, 0, height * 0.8), 0.75, 0.3, "bark")
    roots(g, rng, 0.7)
    tiers = 6
    for t in range(tiers):
        z0 = height * 0.18 + t * (height * 0.8) / tiers
        rad = 4.2 * (1 - t / tiers) + 0.8
        thick = 2.4
        n = int(rad / v) + 1
        for i in range(-n, n + 1):
            for j in range(-n, n + 1):
                d = math.sqrt(i * i + j * j) * v
                if d > rad:
                    continue
                h = thick * (1 - d / rad) + 0.5  # drooping skirt: thick at the trunk, thin at the rim
                for k in range(int(h / v)):
                    if d > rad - v * 1.5 and rng.random() < 0.3:
                        continue
                    g.put((i * v, j * v, z0 + k * v - (d / rad) * 0.8), "pine", over=False)
    return g


def birch(seed, height=14.0, v=0.5):
    rng = random.Random(seed)
    g = Grid(v)
    bend = Vector((rng.uniform(-0.8, 0.8), rng.uniform(-0.8, 0.8), 0))
    mid = Vector((0, 0, height * 0.5)) + bend
    top = Vector((0, 0, height * 0.82)) + bend * 0.4
    g.tube((0, 0, 0), mid, 0.6, 0.5, "birch")
    g.tube(mid, top, 0.5, 0.3, "birch")
    for key in list(g.cells):
        if g.cells[key] == "birch" and rng.random() < 0.16:
            g.cells[key] = "mark"  # the black birch dashes
    for b in range(6):
        ang = b * 2.4 + rng.uniform(-0.2, 0.2)  # golden-angle spiral: branches all the way round
        start = mid.lerp(top, b / 5)
        reach = 2.6 - b * 0.25
        end = start + Vector((math.cos(ang), math.sin(ang), 0)) * reach + Vector((0, 0, 1.4))
        g.tube(start, end, 0.3, 0.2, "birch")
        g.ball(end + Vector((0, 0, 0.5)), 1.9 - b * 0.12, "bleaf", rng, fluff=0.4)
    g.ball(top + Vector((0, 0, 1.2)), 1.7, "bleaf", rng, fluff=0.4)
    return g


def bush(seed, v=0.35):
    rng = random.Random(seed)
    g = Grid(v)
    for _ in range(4):
        c = Vector((rng.uniform(-0.6, 0.6), rng.uniform(-0.6, 0.6), rng.uniform(0.9, 1.6)))
        g.ball(c, rng.uniform(0.9, 1.3), "leaf", rng, fluff=0.35)
    if rng.random() < 0.5:
        for _ in range(3):
            d = Vector((rng.uniform(-1, 1), rng.uniform(-1, 1), rng.uniform(0, 0.8))).normalized()
            g.put(Vector((0, 0, 1.3)) + d * 1.4, "apple")  # berries
    return g


def flowers(seed, v=0.25):
    """A small patch: 5-7 flowers on stems in two or three colors, a few grass blades between."""
    rng = random.Random(seed)
    g = Grid(v)
    colors = rng.sample(list(PETALS), 2)
    for n in range(rng.randint(7, 9)):
        x, y = rng.uniform(-1.2, 1.2), rng.uniform(-0.8, 0.8)
        h = rng.uniform(0.8, 1.8)
        for k in range(int(h / v)):
            g.put((x, y, k * v), "stem")
        col = "petal_" + colors[n % 2]
        top = Vector((x, y, h))
        for dx in (-1, 0, 1):
            for dy in (-1, 0, 1):
                if dx or dy:
                    g.put(top + Vector((dx * v, dy * v, 0)), col)  # a full 3x3 bloom round the yellow heart
        g.put(top, "yellow")
        g.put(top + Vector((0, 0, v)), col)
    for _ in range(10):
        x, y = rng.uniform(-1.4, 1.4), rng.uniform(-1.0, 1.0)
        for k in range(rng.randint(1, 3)):
            g.put((x, y, k * v), "leaf", over=False)
    return g


def rock(seed, v=0.5, size=2.2):
    rng = random.Random(seed)
    g = Grid(v)
    for _ in range(3):
        c = Vector((rng.uniform(-0.7, 0.7), rng.uniform(-0.7, 0.7), rng.uniform(0.4, 0.9)))
        g.ball(c, size * rng.uniform(0.45, 0.65), "rock", rng, fluff=0.1)
    for key in list(g.cells):
        if key[2] < 0:
            del g.cells[key]  # flat bottom: sits on the ground
    for key in list(g.cells):
        above = (key[0], key[1], key[2] + 1)
        if above not in g.cells and rng.random() < 0.3:
            g.cells[above] = "moss"  # moss on top
    return g


def tuft(seed, v=0.25):
    rng = random.Random(seed)
    g = Grid(v)
    for _ in range(9):
        x, y = rng.uniform(-0.6, 0.6), rng.uniform(-0.6, 0.6)
        for k in range(rng.randint(2, 5)):
            g.put((x, y, k * v), "leaf")
    return g


def sign_board(seed, w=14.0, h=3.0, v=0.25):
    """Voxel notice board: three staggered planks (ragged ends, three tones), a dark frame batten each side, iron
    corner brackets with nails, and a little shingle roof on top. Text stays on the grey-box part in front of it."""
    rng = random.Random(seed)
    g = Grid(v)
    nx = int(w / v)
    planks = 3
    ph = h / planks
    for i in range(planks):
        z0 = -h / 2 + i * ph
        left = -w / 2 + rng.uniform(-0.3, 0.2)
        right = w / 2 + rng.uniform(-0.2, 0.3)
        tone = "plank" + str(rng.randrange(3))
        x = left
        while x <= right:
            for k in range(int(ph / v) - 1):  # a one-voxel gap between planks
                for d in (0, v):
                    g.put((x, d, z0 + k * v), tone)
            x += v
        if rng.random() < 0.5:  # a knot / chip
            g.cells.pop(g.key((rng.uniform(left + 1, right - 1), 0, z0 + ph - 2 * v)), None)
    for side in (-1, 1):  # frame battens
        x = side * (w / 2 - 0.9)
        for k in range(int((h + 0.5) / v)):
            for dx in (0, v):
                g.put((x + dx, 2 * v, -h / 2 - 0.25 + k * v), "frame")  # behind: the front stays clear for the text
        for zc in (-h / 2 + 0.3, h / 2 - 0.3):  # iron brackets + nail heads
            for dx in (-v, 0, v, 2 * v):
                g.put((x + dx, 3 * v, zc), "iron")
    # roof: a shingle cap stepping out over the board
    for row in range(3):
        z = h / 2 + 0.25 + row * v
        inset = row * 0.35
        x = -w / 2 - 0.5 + inset
        while x <= w / 2 + 0.5 - inset:
            for d in (-2 * v + row * v, -v + row * v, row * v, v + row * v, 2 * v - row * v):
                g.put((x, d, z), "roof")
            x += v
    return g


def sign_post(seed, h=6.0, v=0.25):
    rng = random.Random(seed)
    g = Grid(v)
    for k in range(int(h / v)):
        for i in (-1, 0, 1):
            for j in (-1, 0, 1):
                if abs(i) + abs(j) < 2 or rng.random() < 0.6:
                    g.put((i * v, j * v, k * v), "frame" if k % 7 else "plank0")
    return g


def tris(o):
    return sum(len(p.vertices) - 2 for p in o.data.polygons)


def bbox(o):
    bb = [Vector(c) for c in o.bound_box]
    lo = Vector((min(p.x for p in bb), min(p.y for p in bb), min(p.z for p in bb)))
    hi = Vector((max(p.x for p in bb), max(p.y for p in bb), max(p.z for p in bb)))
    return hi - lo


def build():
    scene()
    made = [
        mesh_from(oak(3), "PP_Tree_Oak", 3),
        mesh_from(oak(11, height=9.0, spread=4.8, apples=True, clumps=4), "PP_Tree_Apple", 11),
        mesh_from(pine(5), "PP_Tree_Pine", 5),
        mesh_from(birch(7), "PP_Tree_Birch", 7),
        mesh_from(bush(1), "PP_Bush_1", 1),
        mesh_from(bush(4), "PP_Bush_2", 4),
        mesh_from(flowers(21), "PP_Flowers_1", 21),
        mesh_from(flowers(22), "PP_Flowers_2", 22),
        mesh_from(flowers(23), "PP_Flowers_3", 23),
        mesh_from(rock(31), "PP_Rock_1", 31),
        mesh_from(rock(32, size=3.0), "PP_Rock_2", 32),
        mesh_from(tuft(41), "PP_Tuft", 41),
    ]
    out = []
    x = 0
    for o in made:
        d = bbox(o)
        o.location = (x, 0, 0)
        x += d.x + 4
        # Roblox size: (Blender x, z, y)
        out.append(f"{o.name}: roblox size=({d.x:.2f},{d.z:.2f},{d.y:.2f}) tris={tris(o)}")
    return "\n".join(out)


def export():
    sc, c = scene()
    objs = [o for o in c.objects if o.name.startswith("PP_")]
    saved = {o.name: o.location.copy() for o in objs}
    for o in objs:
        o.location = (0, 0, 0)
    bpy.ops.object.select_all(action="DESELECT")
    for o in objs:
        o.select_set(True)
    bpy.context.view_layer.objects.active = objs[0]
    bpy.ops.export_scene.fbx(
        filepath=REPO + r"\blender_assets\PPTrees.fbx",
        use_selection=True,
        object_types={"MESH"},
        apply_unit_scale=True,
        bake_space_transform=True,
        path_mode="COPY",
        embed_textures=True,
    )
    for o in objs:
        o.location = saved[o.name]
    bpy.data.libraries.write(REPO + r"\blender_assets\PPTrees.blend", set(objs), fake_user=True)
    return f"exported {len(objs)}"
