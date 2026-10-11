# Hollow Dragon hall kit, "Shattered Cathedral" (user pick, Oct 12, 2026). Exec'd inside Blender through the MCP:
#   exec(open(<this file>).read()); build(); export()
# Pieces (1 unit = 1 stud; Blender x right, y depth, z up; a piece's front looks -Y; base at z = 0, centred in x/y):
#   DH_RoseWall    the gable wall behind the dragon: a 52-wide rose window, two lancets, a pointed doorway to the hidden
#                  room, buttresses with pinnacles; its upper right is torn away where the Glitch ate it
#   DH_GlassBlue / DH_GlassGold / DH_GlassWine   the stained glass, split by colour (none in the eaten wedge)
#   DH_Pillar / DH_PillarBroken / DH_PillarStump  clustered gothic piers (rib springers on the full one)
#   DH_ArchRib     a pointed arcade arch between two piers (24 wide)
#   DH_Banner / DH_BannerTrim  a long hanging banner (velvet) with its gold rod + edging
#   DH_Chunk1..3   broken floor slabs that drift down into the hole
# Surfaces in Roblox come from MaterialVariants (box-projected in studs), so no UVs/textures here. ArtService/
# StarfallCastle.luau places them (dragonHall).
import bpy
import bmesh
import math
import random
from mathutils import Vector, Matrix

REPO = r"C:\Users\User\OneDrive\Desktop\Coding\glitched_together"
OUT = REPO + r"\blender_assets\dragon_hall"
SCENE = "DragonHall"
COLL = "DragonHallKit"
TAU = math.pi * 2

# rose window layout (wall coordinates: x across, z up, centre of the rose)
ROSE_Z = 62
ROSE_R = 26
EATEN = (math.radians(12), math.radians(78))  # the wedge the Glitch tore out (angle from +x, counter-clockwise)


def scene():
    sc = bpy.data.scenes.get(SCENE) or bpy.data.scenes.new(SCENE)
    bpy.context.window.scene = sc
    c = bpy.data.collections.get(COLL) or bpy.data.collections.new(COLL)
    if c.name not in sc.collection.children:
        sc.collection.children.link(c)
    return sc, c


def mat(name, rgb):
    m = bpy.data.materials.get(name) or bpy.data.materials.new(name)
    m.use_nodes = True
    bsdf = next(n for n in m.node_tree.nodes if n.type == "BSDF_PRINCIPLED")
    bsdf.inputs["Base Color"].default_value = (*[(c / 255) ** 2.2 for c in rgb], 1)
    m.diffuse_color = (*[(c / 255) ** 2.2 for c in rgb], 1)
    return m


def new_obj(name, bm, material):
    _, coll = scene()
    old = bpy.data.objects.get(name)
    if old:
        bpy.data.objects.remove(old, do_unlink=True)
    me = bpy.data.meshes.new(name)
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces[:])  # outward everywhere (booleans need it)
    bm.normal_update()
    bm.to_mesh(me)
    bm.free()
    ob = bpy.data.objects.new(name, me)
    coll.objects.link(ob)
    ob.data.materials.append(material)
    return ob


# 2D outline helpers ---------------------------------------------------------------------------------------------
def pointed(w, h, steps=10):
    """Pointed (equilateral) arch outline: springs at height h, width w, base at 0. Counter-clockwise."""
    pts = [(w / 2, 0)]
    for i in range(steps + 1):  # right side: centre (-w/2, h), 0 -> 60 deg
        a = math.radians(60 * i / steps)
        pts.append((-w / 2 + w * math.cos(a), h + w * math.sin(a)))
    for i in range(1, steps + 1):  # left side: centre (w/2, h), 120 -> 180 deg
        a = math.radians(120 + 60 * i / steps)
        pts.append((w / 2 + w * math.cos(a), h + w * math.sin(a)))
    pts.append((-w / 2, 0))
    return pts


def circle(r, n=48, cx=0.0, cz=0.0):
    return [(cx + r * math.cos(TAU * i / n), cz + r * math.sin(TAU * i / n)) for i in range(n)]


def prism(bm, outline, y0, y1, offset=(0, 0)):
    """Extrude a 2D (x, z) outline between depths y0..y1 into bm."""
    ox, oz = offset
    bottom = [bm.verts.new((x + ox, y0, z + oz)) for x, z in outline]
    top = [bm.verts.new((x + ox, y1, z + oz)) for x, z in outline]
    bm.faces.new(bottom[::-1])
    bm.faces.new(top)
    n = len(outline)
    for i in range(n):
        j = (i + 1) % n
        bm.faces.new((bottom[i], bottom[j], top[j], top[i]))


def ring(bm, outer, inner, y0, y1):
    """A band between two closed outlines with the same point count (arch ribs, window rings)."""
    n = len(outer)
    fo = [bm.verts.new((x, y0, z)) for x, z in outer]
    fi = [bm.verts.new((x, y0, z)) for x, z in inner]
    bo = [bm.verts.new((x, y1, z)) for x, z in outer]
    bi = [bm.verts.new((x, y1, z)) for x, z in inner]
    for i in range(n):
        j = (i + 1) % n
        bm.faces.new((fo[i], fo[j], fi[j], fi[i]))
        bm.faces.new((bo[j], bo[i], bi[i], bi[j]))
        bm.faces.new((fo[j], fo[i], bo[i], bo[j]))
        bm.faces.new((fi[i], fi[j], bi[j], bi[i]))


def box(bm, cx, cy, cz, sx, sy, sz, rot_y=0.0):
    m = Matrix.Translation((cx, cy, cz)) @ Matrix.Rotation(rot_y, 4, "Y") @ Matrix.Diagonal((sx, sy, sz, 1))
    bmesh.ops.create_cube(bm, size=1, matrix=m)


def cyl(bm, cx, cy, z0, z1, r0, r1=None, seg=12):
    r1 = r0 if r1 is None else r1
    m = Matrix.Translation((cx, cy, (z0 + z1) / 2))
    bmesh.ops.create_cone(bm, cap_ends=True, segments=seg, radius1=r0, radius2=r1, depth=z1 - z0, matrix=m)


def bool_cut(target, cutters):
    for c in cutters:
        mod = target.modifiers.new("cut", "BOOLEAN")
        mod.operation = "DIFFERENCE"
        mod.solver = "EXACT"
        mod.object = c
        bpy.context.view_layer.objects.active = target
        bpy.ops.object.modifier_apply(modifier=mod.name)
        bpy.data.objects.remove(c, do_unlink=True)


_cuts = [0]


def cutter(name, outline, y0, y1, offset=(0, 0)):
    bm = bmesh.new()
    prism(bm, outline, y0, y1, offset)
    _cuts[0] += 1
    return new_obj(f"{name}_{_cuts[0]}", bm, mat("DH_Cut", (255, 0, 255)))


def jagged(cx, cz, r0, r1, a0, a1, seed, n=14):
    """A torn wedge outline (the Glitch's bite): ragged edges, from radius r0 to past the wall edge."""
    rnd = random.Random(seed)
    pts = []
    for i in range(n + 1):
        a = a0 + (a1 - a0) * i / n
        r = r1 + rnd.uniform(-3, 3)
        pts.append((cx + r * math.cos(a), cz + r * math.sin(a)))
    for i in range(n, -1, -1):
        a = a0 + (a1 - a0) * i / n
        r = r0 + rnd.uniform(-2.5, 2.5)
        pts.append((cx + r * math.cos(a), cz + r * math.sin(a)))
    return pts


# Pieces ---------------------------------------------------------------------------------------------------------
STONE = (200, 190, 214)


def rose_wall():
    W, H, PEAK, T = 124, 96, 132, 6
    # 1. the clean gable slab gets every opening cut first (booleans need a manifold target)
    bm = bmesh.new()
    prism(bm, [(W / 2, 0), (W / 2, H), (0, PEAK), (-W / 2, H), (-W / 2, 0)], -T / 2, T / 2)
    wall = new_obj("DH_RoseWall", bm, mat("DH_Stone", STONE))
    cuts = [
        cutter("c_rose", circle(ROSE_R, 64, 0, ROSE_Z), -20, 20),
        cutter("c_door", pointed(18, 14), -20, 20),
    ]
    for sx in (-1, 1):
        cuts.append(cutter("c_lancet", pointed(10, 30), -20, 20, (sx * 36, 14)))
    # the Glitch's bite: the upper right of the wall is torn away (rose ring, coping, part of the gable)
    cuts.append(cutter("c_eaten", jagged(0, ROSE_Z, ROSE_R - 2, 120, EATEN[0], EATEN[1], 7), -30, 30))
    bool_cut(wall, cuts)

    # 2. dressing joined on afterwards, already broken where the bite is
    bm = bmesh.new()
    for sx in (-1, 1):  # stepped buttresses with pinnacles (the right one snapped off under the bite)
        x = sx * (W / 2 - 3)
        box(bm, x, -5, 30, 9, 10, 60)
        if sx < 0:
            box(bm, x, -4, 75, 7, 8, 30)
            box(bm, x, -3, 98, 5.5, 6, 16)
            cyl(bm, x, -3, 106, 122, 2.6, 0.2, seg=8)
            for dx in (-2.4, 2.4):
                cyl(bm, x + dx, -6.2, 106, 112, 0.9, 0.1, seg=6)
        else:
            box(bm, x - 0.8, -4, 63, 7, 8, 6, rot_y=0.25)
    # moulding ring round the rose, skipping the bite (wedge pieces)
    n = 64
    for i in range(n):
        a0, a1 = TAU * i / n, TAU * (i + 1) / n
        if a1 > EATEN[0] - 0.03 and a0 < EATEN[1] + 0.03:
            continue
        r0, r1 = ROSE_R, ROSE_R + 4.5
        outline = [(r1 * math.cos(a0), ROSE_Z + r1 * math.sin(a0)), (r1 * math.cos(a1), ROSE_Z + r1 * math.sin(a1)),
                   (r0 * math.cos(a1), ROSE_Z + r0 * math.sin(a1)), (r0 * math.cos(a0), ROSE_Z + r0 * math.sin(a0))]
        prism(bm, outline[::-1], -T / 2 - 1.6, -T / 2 + 0.2)
    box(bm, 0, -T / 2 - 0.6, 34, W - 6, 1.6, 1.4)  # string course
    length = math.hypot(W / 2, PEAK - H)
    ang = math.atan2(PEAK - H, W / 2)
    box(bm, -W / 4, 0, (H + PEAK) / 2 + 0.8, length + 2, T + 1.2, 1.6, rot_y=-ang)  # left coping (right one is gone)
    cyl(bm, 0, 0, PEAK - 1, PEAK + 9, 1.8, 0.4, seg=8)  # finial
    deco = new_obj("DH_WallDeco", bm, mat("DH_Stone", STONE))
    join(wall, [deco])

    # tracery inside the openings (same stone): rose = inner ring, 12 spokes, 12 rosettes; lancets = mullion + trefoil
    bm = bmesh.new()
    ring(bm, circle(8.5, 40, 0, ROSE_Z), circle(6.5, 40, 0, ROSE_Z), -1.2, 1.2)
    for i in range(12):
        a = TAU * (i + 0.5) / 12
        if EATEN[0] - 0.05 < a < EATEN[1] + 0.05:
            continue
        mid = (8.5 + ROSE_R) / 2
        ln = ROSE_R - 8.5 + 1
        m = Matrix.Translation((mid * math.cos(a), 0, ROSE_Z + mid * math.sin(a))) @ Matrix.Rotation(-a, 4, "Y")
        bmesh.ops.create_cube(bm, size=1, matrix=m @ Matrix.Diagonal((ln, 2.0, 1.3, 1)))
    for i in range(12):
        a = TAU * i / 12
        if EATEN[0] - 0.1 < a < EATEN[1] + 0.1:
            continue
        cx, cz = 17.5 * math.cos(a), ROSE_Z + 17.5 * math.sin(a)
        ring(bm, circle(4.2, 20, cx, cz), circle(3.2, 20, cx, cz), -1.0, 1.0)
    for sx in (-1, 1):
        box(bm, sx * 36, 0, 22, 1.1, 1.8, 44)
        ring(bm, circle(2.6, 16, sx * 36, 40), circle(1.8, 16, sx * 36, 40), -0.9, 0.9)
    tr = new_obj("DH_Tracery", bm, mat("DH_Stone", STONE))
    join(wall, [tr])
    return wall


def join(target, others):
    bpy.ops.object.select_all(action="DESELECT")
    for o in others:
        o.select_set(True)
    target.select_set(True)
    bpy.context.view_layer.objects.active = target
    bpy.ops.object.join()


def bevel(ob, width):
    mod = ob.modifiers.new("bev", "BEVEL")
    mod.width = width
    mod.segments = 1
    mod.limit_method = "ANGLE"
    bpy.context.view_layer.objects.active = ob
    bpy.ops.object.modifier_apply(modifier=mod.name)


def glass():
    """Stained glass, one mesh per colour: centre blue, middle band wine/blue, outer petals gold/blue; lancets
    blue with gold heads. Nothing in the eaten wedge."""
    parts = {"Blue": bmesh.new(), "Gold": bmesh.new(), "Wine": bmesh.new()}
    T = 0.25

    def sector(bm, r0, r1, a0, a1, n=6):
        outline = []
        for i in range(n + 1):
            a = a0 + (a1 - a0) * i / n
            outline.append((r1 * math.cos(a), ROSE_Z + r1 * math.sin(a)))
        for i in range(n, -1, -1):
            a = a0 + (a1 - a0) * i / n
            outline.append((r0 * math.cos(a), ROSE_Z + r0 * math.sin(a)))
        prism(bm, outline, -T, T)

    prism(parts["Blue"], circle(7, 32, 0, ROSE_Z), -T, T)
    for i in range(12):
        a0, a1 = TAU * i / 12, TAU * (i + 1) / 12
        if a1 > EATEN[0] - 0.02 and a0 < EATEN[1] + 0.02:
            continue
        sector(parts["Wine" if i % 2 == 0 else "Blue"], 7.5, 14, a0, a1)
        sector(parts["Gold" if i % 2 == 0 else "Blue"], 14, ROSE_R + 0.5, a0, a1)
    for sx in (-1, 1):
        prism(parts["Blue"], pointed(10, 30), -T, T, (sx * 36, 14))
        prism(parts["Gold"], circle(1.8, 16, sx * 36, 40), -T * 2, T * 2)
    colours = {"Blue": (70, 96, 200), "Gold": (232, 182, 76), "Wine": (140, 47, 90)}
    return [new_obj("DH_Glass" + k, bm, mat("DH_Glass" + k, colours[k])) for k, bm in parts.items()]


def pillar_core(bm, top, ragged=None):
    box(bm, 0, 0, 1.5, 8, 8, 3)  # plinth
    cyl(bm, 0, 0, 3, 4.6, 3.9, 3.3, seg=8)  # base moulding
    rnd = random.Random(ragged or 0)
    jag = (lambda: rnd.uniform(-5, 1.5)) if ragged else (lambda: 0)
    cyl(bm, 0, 0, 4.6, top + jag(), 2.7, seg=8)  # core
    for i in range(4):
        a = TAU * (i + 0.5) / 4
        cyl(bm, 2.6 * math.cos(a), 2.6 * math.sin(a), 4.6, top + jag(), 1.15, seg=10)  # clustered shafts
    for i in range(4):
        a = TAU * i / 4
        cyl(bm, 2.9 * math.cos(a), 2.9 * math.sin(a), 4.6, top + jag(), 0.7, seg=8)


def pillar(name, height, broken=False, springers=False, seed=1):
    bm = bmesh.new()
    top = height - (0 if broken else 6)
    pillar_core(bm, top, seed if broken else None)
    if broken:  # a fallen drum leaning at the foot
        m = Matrix.Translation((4.5, 3.5, 1.6)) @ Matrix.Rotation(math.pi / 2, 4, "X") @ Matrix.Rotation(0.4, 4, "Z")
        bmesh.ops.create_cone(bm, cap_ends=True, segments=10, radius1=2.5, radius2=2.5, depth=4, matrix=m)
    else:
        cyl(bm, 0, 0, top, top + 3, 3.4, 4.6, seg=8)  # capital
        box(bm, 0, 0, top + 3.8, 9.5, 9.5, 1.6)  # abacus
        if springers:
            # rib stubs springing toward the hall (+x) and along the arcade (+-y)
            for d in ((1, 0), (0, 1), (0, -1)):
                for k in range(5):
                    t = (k + 0.5) / 5
                    x, y = d[0] * (2 + t * 9), d[1] * (2 + t * 9)
                    z = top + 4.5 + math.sin(t * math.pi / 2.4) * 7
                    box(bm, x, y, z, 2.2 if d[0] == 0 else 3.2, 3.2 if d[0] == 0 else 2.2, 2.0)
    ob = new_obj(name, bm, mat("DH_Stone", STONE))
    return ob


def arch_rib():
    W, H, D = 24, 4, 3
    outer = pointed(W + 2.4, H, steps=14)[1:-1]
    inner = pointed(W - 2.4, H, steps=14)[1:-1]
    bm = bmesh.new()
    # band between the two arcs (closed by the springers)
    pts_o = outer
    pts_i = inner
    n = len(pts_o)
    fo = [bm.verts.new((x, -D / 2, z)) for x, z in pts_o]
    fi = [bm.verts.new((x, -D / 2, z)) for x, z in pts_i]
    bo = [bm.verts.new((x, D / 2, z)) for x, z in pts_o]
    bi = [bm.verts.new((x, D / 2, z)) for x, z in pts_i]
    for i in range(n - 1):
        j = i + 1
        bm.faces.new((fo[i], fo[j], fi[j], fi[i]))
        bm.faces.new((bo[j], bo[i], bi[i], bi[j]))
        bm.faces.new((fo[j], fo[i], bo[i], bo[j]))
        bm.faces.new((fi[i], fi[j], bi[j], bi[i]))
    for i in (0, n - 1):
        bm.faces.new((fo[i], fi[i], bi[i], bo[i]) if i == 0 else (fo[i], bo[i], bi[i], fi[i]))
    ob = new_obj("DH_ArchRib", bm, mat("DH_Stone", STONE))
    bevel(ob, 0.1)
    return ob


def banner():
    W, L = 6, 26
    bm = bmesh.new()
    cols, rows = 7, 16
    grid = []
    for r in range(rows + 1):
        z = -L * r / rows
        row = []
        for c in range(cols + 1):
            x = -W / 2 + W * c / cols
            zz = z
            if r == rows:  # swallowtail
                zz = z + 3 * (1 - abs(x) / (W / 2)) - 0.0
            y = 0.35 * math.sin(c / cols * TAU * 1.5) * (0.3 + r / rows)
            row.append(bm.verts.new((x, y, zz + L)))
        grid.append(row)
    for r in range(rows):
        for c in range(cols):
            bm.faces.new((grid[r][c], grid[r][c + 1], grid[r + 1][c + 1], grid[r + 1][c]))
    bmesh.ops.solidify(bm, geom=bm.faces[:], thickness=0.2)
    cloth = new_obj("DH_Banner", bm, mat("DH_Velvet", (140, 47, 90)))
    bm = bmesh.new()
    m = Matrix.Translation((0, 0, L + 0.4)) @ Matrix.Rotation(math.pi / 2, 4, "Y")
    bmesh.ops.create_cone(bm, cap_ends=True, segments=10, radius1=0.35, radius2=0.35, depth=W + 1.6, matrix=m)
    for sx in (-1, 1):
        bmesh.ops.create_uvsphere(bm, u_segments=10, v_segments=6, radius=0.6,
                                  matrix=Matrix.Translation((sx * (W / 2 + 0.9), 0, L + 0.4)))
    # gold trim: a stripe band near the top and a star emblem plate
    box(bm, 0, -0.3, L - 3, W - 0.4, 0.15, 0.6)
    star = []
    for i in range(10):
        a = math.pi / 2 + TAU * i / 10
        r = 1.6 if i % 2 == 0 else 0.7
        star.append((r * math.cos(a), L - 9 + r * math.sin(a)))
    prism(bm, star, -0.42, -0.3)
    trim = new_obj("DH_BannerTrim", bm, mat("DH_Gold", (232, 182, 76)))
    return [cloth, trim]


def chunk(i):
    rnd = random.Random(40 + i)
    bm = bmesh.new()
    sx, sy = rnd.uniform(7, 10), rnd.uniform(5, 8)
    outline = []
    for k in range(9):
        a = TAU * k / 9
        r = 1 + rnd.uniform(-0.18, 0.12)
        outline.append((sx / 2 * r * math.cos(a), sy / 2 * r * math.sin(a)))
    # top slab (flagstone) + a tapering rock underside
    top = [bm.verts.new((x, y, 3.0)) for x, y in outline]
    mid = [bm.verts.new((x, y, 1.8)) for x, y in outline]
    low = [bm.verts.new((x * 0.55 + rnd.uniform(-0.5, 0.5), y * 0.55 + rnd.uniform(-0.5, 0.5), 0.4)) for x, y in outline]
    tip = bm.verts.new((rnd.uniform(-1, 1), rnd.uniform(-1, 1), -1.6))
    bm.faces.new(top)
    n = len(outline)
    for k in range(n):
        j = (k + 1) % n
        bm.faces.new((top[j], top[k], mid[k], mid[j]))
        bm.faces.new((mid[j], mid[k], low[k], low[j]))
        bm.faces.new((low[j], low[k], tip))
    bmesh.ops.translate(bm, verts=bm.verts[:], vec=(0, 0, 1.6))
    ob = new_obj(f"DH_Chunk{i}", bm, mat("DH_Stone", STONE))
    bevel(ob, 0.12)
    return ob


PIECES = []


def build():
    global PIECES
    random.seed(3)
    PIECES = [rose_wall(), *glass(), pillar("DH_Pillar", 58, springers=True), pillar("DH_PillarBroken", 38, True, seed=5),
              pillar("DH_PillarStump", 14, True, seed=9), arch_rib(), *banner(), chunk(1), chunk(2), chunk(3)]
    # offsets of the glass / trim from their parent's box centre, in Roblox axes (x, z up, -y): ArtService needs them
    def centre(ob):
        cs = [ob.matrix_world @ Vector(c) for c in ob.bound_box]
        return sum(cs, Vector()) / 8
    offsets = {}
    for child, parent in (("DH_GlassBlue", "DH_RoseWall"), ("DH_GlassGold", "DH_RoseWall"),
                          ("DH_GlassWine", "DH_RoseWall"), ("DH_BannerTrim", "DH_Banner")):
        d = centre(bpy.data.objects[child]) - centre(bpy.data.objects[parent])
        offsets[child] = (round(d.x, 3), round(d.z, 3), round(-d.y, 3))
    print("OFFSETS", offsets)
    for ob in PIECES:
        bpy.context.view_layer.objects.active = ob
        bpy.ops.object.select_all(action="DESELECT")
        ob.select_set(True)
        bpy.ops.object.origin_set(type="ORIGIN_GEOMETRY", center="BOUNDS")
        bpy.ops.object.transform_apply(location=False, rotation=True, scale=True)
    # lay the pieces out side by side for a look
    x = 0
    for ob in PIECES:
        w = ob.dimensions.x
        ob.location = (x + w / 2, 0, ob.dimensions.z / 2)
        x += w + 6
    return {ob.name: (round(ob.dimensions.x, 2), round(ob.dimensions.y, 2), round(ob.dimensions.z, 2),
                      len(ob.data.polygons)) for ob in PIECES}


def export():
    import os
    os.makedirs(OUT, exist_ok=True)
    done = {}
    for ob in PIECES:
        loc = ob.location.copy()
        ob.location = (0, 0, 0)
        for o in bpy.context.view_layer.objects:  # only this piece (a stale selection leaked the default Cube in)
            o.select_set(o == ob)
        bpy.context.view_layer.objects.active = ob
        path = f"{OUT}\\{ob.name}.glb"
        bpy.ops.export_scene.gltf(filepath=path, use_selection=True, export_format="GLB", export_materials="NONE",
                                  export_apply=True, use_active_scene=True)
        ob.location = loc
        done[ob.name] = path
    return done
