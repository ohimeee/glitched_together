# Epilogue gold trophies (CLAUDE.md step 5, user pick Oct 12): the six FinishedPiece parts round the pressed SAVE button
# on the hilltop read as random gold blocks. Each becomes a small polished-brass trophy of something the duo built,
# standing on a dark stone plinth:
#   Tower   Starfall Castle round tower (crenellations, cone roof, pennant)
#   Arch    the Prologue stage arch (voussoirs + keystone on two piers)
#   Steps   Pixel Plains voxel pyramid with a ? block on top
#   Orb     Glitched Core orb on a stand, a tilted ring round it
#   Column  a fluted column (base, shaft, capital)
#   Bridge  a little arched stone bridge with posts
# Exec'd inside Blender through the MCP:  exec(open(<this file>).read()); build(); export()
# Reuses the trap kit's helpers (box, cyl, mat, new_obj). 1 unit = 1 stud; front looks -Y (toward the SAVE button);
# origin bottom centre. Objects: EP_Trophy<Name>_Gold, EP_Trophy<Name>_Base.
exec(open(r"C:\Users\User\OneDrive\Desktop\Coding\glitched_together\tools\trap_kit\kit.py").read())

SCENE = "Trophies"
COLL = "Trophies"
OUT = REPO + r"\blender_assets\epilogue_trophies"
SPREAD = 14  # pieces stand apart in the Blender scene; export re-centres each


def torus(bm, R, r, at, rot=None, seg=32, ring=10):
    tmp = bmesh.new()
    for i in range(seg):
        a = i / seg * math.tau
        for j in range(ring):
            b = j / ring * math.tau
            tmp.verts.new(((R + r * math.cos(b)) * math.cos(a), (R + r * math.cos(b)) * math.sin(a), r * math.sin(b)))
    tmp.verts.ensure_lookup_table()
    for i in range(seg):
        for j in range(ring):
            a, b = i, (i + 1) % seg
            c, d = j, (j + 1) % ring
            tmp.faces.new((tmp.verts[a * ring + c], tmp.verts[b * ring + c], tmp.verts[b * ring + d], tmp.verts[a * ring + d]))
    m = Matrix.Translation(Vector(at))
    if rot is not None:
        m = m @ rot
    bmesh.ops.transform(tmp, matrix=m, verts=tmp.verts)
    _merge(bm, tmp)


def sphere(bm, r, at, seg=32):
    tmp = bmesh.new()
    bmesh.ops.create_uvsphere(tmp, u_segments=seg, v_segments=seg // 2, radius=r)
    bmesh.ops.transform(tmp, matrix=Matrix.Translation(Vector(at)), verts=tmp.verts)
    _merge(bm, tmp)


def smooth(ob, angle=35):
    for f in ob.data.polygons:
        f.use_smooth = True
    m = ob.modifiers.new("split", "EDGE_SPLIT")
    m.split_angle = math.radians(angle)


def place(ob, i):
    ob.location.x = (i - 2.5) * SPREAD
    smooth(ob)


def plinth(bm, w, d, h=0.5):
    box(bm, (w, d, h * 0.7), (0, 0, h * 0.35), bevel=0.05)
    box(bm, (w - 0.3, d - 0.3, h * 0.3), (0, 0, h * 0.85), bevel=0.04)


def tower(gold, stone, i):
    bm = bmesh.new()
    cyl(bm, 1.85, 0.35, (0, 0, 0.175), seg=8)
    cyl(bm, 1.65, 0.2, (0, 0, 0.45), seg=8)
    place(new_obj("EP_TrophyTower_Base", bm, stone), i)
    bm = bmesh.new()
    cyl(bm, 1.45, 0.35, (0, 0, 0.73), seg=32)  # foot band
    cyl(bm, 1.3, 6.5, (0, 0, 0.55 + 3.25), seg=32, r2=1.2)  # tapering shaft
    for z in (2.6, 4.8):
        cyl(bm, 1.32, 0.16, (0, 0, z), seg=32)  # string courses
    cyl(bm, 1.7, 0.5, (0, 0, 7.25), seg=32, r2=1.45)  # corbel ring
    for k in range(8):  # merlons
        a = k / 8 * math.tau
        box(bm, (0.62, 0.42, 0.7), (1.5 * math.sin(a), 1.5 * math.cos(a), 7.85), RZ(-a), bevel=0.05)
    cyl(bm, 1.25, 2.0, (0, 0, 8.6), seg=32, r2=0.05)  # cone roof
    rod(bm, (0, 0, 9.4), (0, 0, 10.0), 0.05)
    box(bm, (0.04, 0.5, 0.3), (0, 0.25, 9.8), bevel=0.01)  # pennant
    box(bm, (0.9, 0.3, 1.5), (0, -1.25, 1.45), bevel=0.08)  # door frame
    cyl(bm, 0.45, 0.3, (0, -1.25, 2.2), RX(math.pi / 2), seg=16)  # round door head
    for z, a in ((3.7, 0.0), (5.6, 0.0), (5.6, 1.6), (5.6, -1.6), (3.7, 2.4), (3.7, -2.4)):  # window slits
        x, y = 1.22 * math.sin(a), -1.22 * math.cos(a)
        box(bm, (0.32, 0.22, 0.75), (x, y, z), RZ(-a), bevel=0.04)
    place(new_obj("EP_TrophyTower_Gold", bm, gold), i)


def arch(gold, stone, i):
    bm = bmesh.new()
    plinth(bm, 7.4, 2.6)
    place(new_obj("EP_TrophyArch_Base", bm, stone), i)
    bm = bmesh.new()
    for s in (-1, 1):
        box(bm, (1.3, 1.5, 0.35), (s * 2.25, 0, 0.68), bevel=0.05)  # pier foot
        box(bm, (1.1, 1.3, 2.25), (s * 2.25, 0, 0.5 + 0.35 + 1.12), bevel=0.06)  # pier
        box(bm, (1.4, 1.6, 0.3), (s * 2.25, 0, 3.15), bevel=0.05)  # impost
    n = 9
    for k in range(n):  # voussoirs on a half circle round (0, 3.3)
        a = math.pi * (k + 0.5) / n - math.pi / 2
        big = k == n // 2
        r = 2.25
        box(
            bm,
            (0.66 if big else 0.58, 1.4 if big else 1.25, 1.35 if big else 1.1),
            (r * math.sin(a), 0, 3.3 + r * math.cos(a)),
            RY(a),
            bevel=0.05,
        )
    place(new_obj("EP_TrophyArch_Gold", bm, gold), i)


def steps(gold, stone, i):
    bm = bmesh.new()
    plinth(bm, 6.8, 6.8)
    place(new_obj("EP_TrophySteps_Base", bm, stone), i)
    bm = bmesh.new()
    V = 0.98  # voxel with a hairline gap
    for layer, n in enumerate((6, 4, 2)):
        for ix in range(n):
            for iy in range(n):
                x, y = ix - (n - 1) / 2, iy - (n - 1) / 2
                if layer == 0 and abs(x) < 2 and abs(y) < 2:
                    continue  # hidden under the next layer
                box(bm, (V, V, V), (x, y, 0.5 + layer + 0.5), bevel=0.06)
    box(bm, (1.1, 1.1, 1.1), (0, 0, 3.5 + 0.6), bevel=0.08)  # ? block
    q = [(-0.15, 0.22), (0.0, 0.3), (0.15, 0.22), (0.17, 0.08), (0.04, -0.04), (0.0, -0.14)]
    for f in (-1, 1):  # raised "?" on the front and back faces
        for x, z in q:
            box(bm, (0.12, 0.06, 0.12), (x, f * 0.57, 4.1 + z), bevel=0.0)
        box(bm, (0.12, 0.06, 0.12), (0, f * 0.57, 4.1 - 0.32), bevel=0.0)
    place(new_obj("EP_TrophySteps_Gold", bm, gold), i)


def orb(gold, stone, i):
    bm = bmesh.new()
    cyl(bm, 1.6, 0.35, (0, 0, 0.175), seg=32)
    cyl(bm, 1.4, 0.15, (0, 0, 0.425), seg=32)
    place(new_obj("EP_TrophyOrb_Base", bm, stone), i)
    bm = bmesh.new()
    cyl(bm, 1.0, 0.2, (0, 0, 0.6), seg=32, r2=0.8)
    cyl(bm, 0.22, 1.6, (0, 0, 1.5), seg=16, r2=0.16)  # stem
    torus(bm, 0.3, 0.1, (0, 0, 1.4))  # knot
    cyl(bm, 0.25, 0.4, (0, 0, 2.45), seg=24, r2=0.75)  # cup
    for k in range(3):  # three claws holding the orb
        a = k / 3 * math.tau
        rod(bm, (0.6 * math.cos(a), 0.6 * math.sin(a), 2.6), (1.05 * math.cos(a), 1.05 * math.sin(a), 3.4), 0.08)
    sphere(bm, 1.15, (0, 0, 3.75))
    torus(bm, 1.75, 0.07, (0, 0, 3.75), RX(math.radians(70)) @ RY(math.radians(18)), seg=48, ring=8)
    place(new_obj("EP_TrophyOrb_Gold", bm, gold), i)


def column(gold, stone, i):
    bm = bmesh.new()
    plinth(bm, 2.6, 2.6)
    place(new_obj("EP_TrophyColumn_Base", bm, stone), i)
    bm = bmesh.new()
    box(bm, (2.1, 2.1, 0.3), (0, 0, 0.65), bevel=0.04)  # plinth block
    torus(bm, 0.78, 0.14, (0, 0, 0.92))
    torus(bm, 0.72, 0.1, (0, 0, 1.12))
    # fluted shaft: 20 sides, every other one pushed in
    tmp = bmesh.new()
    sides, h0, h1 = 20, 1.1, 7.9
    rings = []
    for z, rad in ((h0, 0.7), (h1, 0.6)):
        ring = []
        for k in range(sides * 2):
            a = k / (sides * 2) * math.tau
            rr = rad * (0.9 if k % 2 else 1.0)
            ring.append(tmp.verts.new((rr * math.cos(a), rr * math.sin(a), z)))
        rings.append(ring)
    n = sides * 2
    for k in range(n):
        tmp.faces.new((rings[0][k], rings[0][(k + 1) % n], rings[1][(k + 1) % n], rings[1][k]))
    _merge(bm, tmp)
    torus(bm, 0.62, 0.09, (0, 0, 7.95))
    cyl(bm, 0.65, 0.35, (0, 0, 8.15), seg=32, r2=0.95)  # echinus
    box(bm, (2.1, 2.1, 0.3), (0, 0, 8.45), bevel=0.04)  # abacus
    place(new_obj("EP_TrophyColumn_Gold", bm, gold), i)


def bridge(gold, stone, i):
    bm = bmesh.new()
    plinth(bm, 10.4, 3.0, 0.4)
    place(new_obj("EP_TrophyBridge_Base", bm, stone), i)
    bm = bmesh.new()
    L, rise, n = 9.6, 0.7, 16  # deck: n blocks on a gentle hump
    for k in range(n):
        t = (k + 0.5) / n
        x = (t - 0.5) * L
        z = 0.4 + 0.6 + rise * math.sin(t * math.pi)
        slope = math.atan(rise * math.pi / L * math.cos(t * math.pi))
        box(bm, (L / n - 0.04, 2.2, 0.4), (x, 0, z), RY(-slope), bevel=0.03)
        if k % 3 == 0 or k == n - 1:
            for s in (-1, 1):  # railing posts + a rail between them
                box(bm, (0.2, 0.2, 0.7), (x, s * 1.0, z + 0.5), bevel=0.03)
    for s in (-1, 1):
        pts = [((t / 10 - 0.5) * L, 0.4 + 0.6 + rise * math.sin(t / 10 * math.pi) + 0.85) for t in range(11)]
        for (xa, za), (xb, zb) in zip(pts, pts[1:]):
            rod(bm, (xa, s * 1.0, za), (xb, s * 1.0, zb), 0.07)
    for s in (-1, 1):  # end piers
        box(bm, (0.9, 2.4, 0.7), (s * (L / 2 - 0.45), 0, 0.75), bevel=0.05)
    place(new_obj("EP_TrophyBridge_Gold", bm, gold), i)


def build():
    sc, coll = scene()
    for ob in list(coll.objects):
        bpy.data.objects.remove(ob, do_unlink=True)
    gold = mat("EP_TrophyGold", (255, 196, 92), 1.0, 0.25)
    stone = mat("EP_TrophyStone", (58, 56, 62), 0.0, 0.55)
    for k, f in enumerate((tower, arch, steps, orb, column, bridge)):
        f(gold, stone, k)


def export():
    import os

    os.makedirs(OUT, exist_ok=True)
    # per trophy: Roblox design box (the base + gold together), each mesh's size + centre offset from the box centre
    groups = {}
    for ob in bpy.data.collections[COLL].objects:
        groups.setdefault(ob.name.rsplit("_", 1)[0], []).append(ob)
    for name, obs in groups.items():
        pts = [ob.matrix_world @ Vector(b) for ob in obs for b in ob.bound_box]
        lo = Vector((min(p.x for p in pts), min(p.y for p in pts), min(p.z for p in pts)))
        hi = Vector((max(p.x for p in pts), max(p.y for p in pts), max(p.z for p in pts)))
        mid = (lo + hi) / 2
        print("DESIGN", name, (round(hi.x - lo.x, 3), round(hi.z - lo.z, 3), round(hi.y - lo.y, 3)))
        for ob in obs:
            bpy.ops.object.select_all(action="DESELECT")
            ob.select_set(True)
            bpy.context.view_layer.objects.active = ob
            keep = ob.location.x
            ob.location.x -= obs[0].location.x - 0  # export each piece centred on its own trophy
            bpy.ops.export_scene.gltf(
                filepath=os.path.join(OUT, ob.name + ".glb"),
                use_selection=True,
                use_active_scene=True,
                export_format="GLB",
                export_materials="NONE",
                export_apply=True,
            )
            ob.location.x = keep
            b = [ob.matrix_world @ Vector(c) for c in ob.bound_box]
            c = sum(b, Vector()) / 8
            sz = (max(p.x for p in b) - min(p.x for p in b), max(p.z for p in b) - min(p.z for p in b),
                  max(p.y for p in b) - min(p.y for p in b))
            # Roblox: +X = -Blender X, Y = Blender Z, Z = Blender Y (glTF import turns 180 about Y)
            off = (-(c.x - mid.x), c.z - mid.z, c.y - mid.y)
            print("MESH", ob.name, "size", tuple(round(s, 3) for s in sz), "offset", tuple(round(o, 3) for o in off))
