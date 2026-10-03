# Lobby kit helpers (exec'd inside Blender through the MCP: exec(open(<this file>).read())).
# Everything is modeled at its real place in the lobby room, in studs, so the Roblox position of each mesh is just
# its bounding-box centre. Roblox (X, Y, Z) <-> Blender (-X, Z, Y). Objects are named LK_<Piece>_<Surface>; the
# surface suffix picks the Roblox material in src/lobby/server/LobbyKit.luau.
import bpy
import bmesh
import math
from mathutils import Vector, Matrix

KIT_COLLECTION = "LobbyKit"


def rb(x, y, z):
    """Roblox position -> Blender position."""
    return Vector((-x, z, y))


def coll():
    c = bpy.data.collections.get(KIT_COLLECTION)
    if not c:
        c = bpy.data.collections.new(KIT_COLLECTION)
        bpy.context.scene.collection.children.link(c)
    return c


def mat(name, rgb, rough=0.6, metal=0.0):
    m = bpy.data.materials.get(name)
    if not m:
        m = bpy.data.materials.new(name)
        m.use_nodes = True
    lin = [(c / 255) ** 2.2 for c in rgb]
    bsdf = next(n for n in m.node_tree.nodes if n.type == "BSDF_PRINCIPLED")
    bsdf.inputs["Base Color"].default_value = (*lin, 1)
    bsdf.inputs["Roughness"].default_value = rough
    bsdf.inputs["Metallic"].default_value = metal
    m.diffuse_color = (*lin, 1)
    return m


def remove(name):
    o = bpy.data.objects.get(name)
    if o:
        me = o.data
        bpy.data.objects.remove(o, do_unlink=True)
        if me and me.users == 0:
            bpy.data.meshes.remove(me)


def obj_from_bm(name, bm, material=None):
    if name.startswith("LK_"):
        remove(name)
    me = bpy.data.meshes.new(name)
    bm.to_mesh(me)
    bm.free()
    o = bpy.data.objects.new(name, me)
    coll().objects.link(o)
    if material:
        me.materials.append(material)
    return o


def apply_mods(o):
    dg = bpy.context.evaluated_depsgraph_get()
    ev = o.evaluated_get(dg)
    me = bpy.data.meshes.new_from_object(ev)
    old = o.data
    o.modifiers.clear()
    o.data = me
    if old.users == 0:
        bpy.data.meshes.remove(old)


def bevel(o, width, segments=3, limit_angle=None, profile=0.5):
    m = o.modifiers.new("Bevel", "BEVEL")
    m.width = width
    m.segments = segments
    m.profile = profile
    if limit_angle is not None:
        m.limit_method = "ANGLE"
        m.angle_limit = math.radians(limit_angle)
    else:
        m.limit_method = "NONE"
    m.use_clamp_overlap = True
    m.harden_normals = False
    apply_mods(o)
    return o


def box_bm(bm, center_rb, size_rb, rot=None):
    """Adds a box (Roblox centre + size) into a bmesh, in Blender space. rot = Matrix (Blender space) about centre."""
    sx, sy, sz = size_rb
    c = rb(*center_rb)
    res = bmesh.ops.create_cube(bm, size=1.0)
    verts = res["verts"]
    m = Matrix.Diagonal((sx, sz, sy, 1.0))
    if rot:
        m = rot.to_4x4() @ m
    bmesh.ops.transform(bm, matrix=m, verts=verts)
    bmesh.ops.translate(bm, vec=c, verts=verts)
    return verts


def rounded_box(name, center_rb, size_rb, radius, segments=3, material=None, rot=None):
    bm = bmesh.new()
    box_bm(bm, center_rb, size_rb, rot)
    o = obj_from_bm(name, bm, material)
    if radius > 0:
        bevel(o, radius, segments)
    return o


def lathe_bm(bm, profile, base_rb, segments=24):
    """Turned shape: profile = [(radius, height above base)], bottom to top. Closed with caps."""
    rings = []
    b = rb(*base_rb)
    for r, h in profile:
        ring = []
        for k in range(segments):
            a = k / segments * math.tau
            ring.append(bm.verts.new((b.x + math.cos(a) * r, b.y + math.sin(a) * r, b.z + h)))
        rings.append(ring)
    for i in range(len(rings) - 1):
        for k in range(segments):
            k2 = (k + 1) % segments
            bm.faces.new((rings[i][k], rings[i][k2], rings[i + 1][k2], rings[i + 1][k]))
    bm.faces.new(list(reversed(rings[0])))
    bm.faces.new(rings[-1])


def uv_studs(o, studs_per_unit=1.0):
    """Box-projected UVs measured in studs (1 UV unit = studs_per_unit studs), so tiling materials keep a real scale."""
    me = o.data
    bm = bmesh.new()
    bm.from_mesh(me)
    uv = bm.loops.layers.uv.verify()
    mw = o.matrix_world
    for f in bm.faces:
        n = f.normal
        ax = max(range(3), key=lambda i: abs(n[i]))
        for l in f.loops:
            p = mw @ l.vert.co
            if ax == 0:
                u, v = p.y, p.z
            elif ax == 1:
                u, v = p.x, p.z
            else:
                u, v = p.x, p.y
            l[uv].uv = (u / studs_per_unit, v / studs_per_unit)
    bm.to_mesh(me)
    bm.free()


def smooth(o, angle=40):
    me = o.data
    for p in me.polygons:
        p.use_smooth = True
    try:
        o.modifiers.new("Smooth", "SMOOTH_BY_ANGLE")
        o.modifiers["Smooth"]["Input_1"] = math.radians(angle)
        apply_mods(o)
    except Exception:
        pass


def join(name, objs):
    """Joins objects into one (first keeps the name `name`)."""
    objs = [o for o in objs if o]
    remove(name) if bpy.data.objects.get(name) not in objs else None
    ctx = {"active_object": objs[0], "selected_editable_objects": objs, "selected_objects": objs}
    with bpy.context.temp_override(**ctx):
        bpy.ops.object.join()
    objs[0].name = name
    objs[0].data.name = name
    return objs[0]


def arch_rail(name, x0, x1, y, z, height, thick, arch, material, bulge=0.0, N=24, radius=0.7):
    """A rail along Roblox X from x0 to x1 whose centre line rises by `arch` (sine) and bows toward -Z by `bulge`."""
    bm = bmesh.new()
    rings = []
    for i in range(N + 1):
        t = i / N
        x = x0 + (x1 - x0) * t
        yc = y + math.sin(t * math.pi) * arch
        zc = z - math.sin(t * math.pi) * bulge
        ring = [bm.verts.new(rb(x, yc + dy, zc + dz)) for dy, dz in
                ((-height / 2, -thick / 2), (-height / 2, thick / 2), (height / 2, thick / 2), (height / 2, -thick / 2))]
        rings.append(ring)
    for i in range(N):
        a, b = rings[i], rings[i + 1]
        for k in range(4):
            k2 = (k + 1) % 4
            bm.faces.new((a[k], a[k2], b[k2], b[k]))
    bm.faces.new(list(reversed(rings[0])))
    bm.faces.new(rings[-1])
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    o = obj_from_bm(name, bm, material)
    if radius > 0:
        bevel(o, radius, 2, 30)
    return o


def sweep_bm(bm, profile, a_rb, b_rb, n_rb, base_y=None):
    """Extrudes a 2D moulding profile [(depth out of the wall, height)] along a straight wall run from a to b.
    n_rb = the wall's inward normal (Roblox). Heights add to each end point's y."""
    n = Vector(n_rb)
    rings = []
    for p in (a_rb, b_rb):
        p = Vector(p)
        ring = [bm.verts.new(rb(*(p + n * d + Vector((0, h, 0))))) for d, h in profile]
        rings.append(ring)
    k = len(profile)
    for i in range(k - 1):
        bm.faces.new((rings[0][i], rings[0][i + 1], rings[1][i + 1], rings[1][i]))
    bm.faces.new((rings[0][-1], rings[0][0], rings[1][0], rings[1][-1]))
    bm.faces.new(rings[0])
    bm.faces.new(list(reversed(rings[1])))


# --- palette atlas (textures/lobby_palette.png: 8x8 swatches, index = row * 8 + col, see make_lobby_palette.py) ---
PAL = {
    "red": 0, "blue": 1, "green": 2, "mustard": 3, "cream": 4, "plum": 5, "cornflower": 6, "rust": 7,
    "pages": 8, "gold": 9, "navy": 10, "forest": 11, "black": 12, "white": 13, "pink": 14, "leather": 15,
    "toyred": 16, "toyblue": 17, "toyyellow": 18, "toygreen": 19, "ivory": 20, "graphite": 21, "pencil": 22,
    "rawwood": 23, "tin": 24, "eraser": 25, "lilac": 26, "violet": 27, "coral": 28, "leaf": 29, "sun": 30,
    "darkwood": 31, "noteyellow": 32, "notepink": 33, "paper": 34, "cardboard": 35, "chocolate": 36, "lime": 37,
    "steel": 38, "string": 39,
}
BOOK_COLORS = ["red", "blue", "green", "mustard", "cream", "plum", "cornflower", "rust", "navy", "forest", "pink",
               "leather", "chocolate", "lime", "black"]


def pbm():
    """A bmesh for palette meshes: the swatch layer must exist before faces are referenced from Python."""
    bm = bmesh.new()
    bm.faces.layers.int.new("sw")
    return bm


def faces_of(verts):
    fs = set()
    for v in verts:
        fs.update(v.link_faces)
    return fs


def tag(bm, faces, swatch):
    lay = bm.faces.layers.int.get("sw") or bm.faces.layers.int.new("sw")
    idx = PAL[swatch] if isinstance(swatch, str) else swatch
    for f in faces:
        f[lay] = idx


def palette_uv(o, inset=0.12):
    """UV every face into its swatch (face int attribute 'sw'), fitted per face so the swatch detail shows."""
    me = o.data
    bm = bmesh.new()
    bm.from_mesh(me)
    lay = bm.faces.layers.int.get("sw")
    uv = bm.loops.layers.uv.verify()
    for f in bm.faces:
        idx = f[lay] if lay else 0
        r, c = divmod(idx, 8)
        n = f.normal
        ax = max(range(3), key=lambda i: abs(n[i]))
        pts = []
        for l in f.loops:
            p = l.vert.co
            pts.append((p.y, p.z) if ax == 0 else (p.x, p.z) if ax == 1 else (p.x, p.y))
        u0 = min(p[0] for p in pts)
        v0 = min(p[1] for p in pts)
        ext = max(max(p[0] for p in pts) - u0, max(p[1] for p in pts) - v0, 1e-4)
        span = 1 - 2 * inset
        for l, p in zip(f.loops, pts):
            fu = inset + (p[0] - u0) / ext * span
            fv = inset + (p[1] - v0) / ext * span
            l[uv].uv = ((c + fu) / 8, 1 - (r + 1) / 8 + fv / 8)
    bm.to_mesh(me)
    bm.free()


def tris(o):
    return sum(len(p.vertices) - 2 for p in o.data.polygons)


def report():
    out = []
    for o in sorted(coll().objects, key=lambda o: o.name):
        if o.type != "MESH":
            continue
        bb = [o.matrix_world @ Vector(c) for c in o.bound_box]
        lo = Vector((min(v.x for v in bb), min(v.y for v in bb), min(v.z for v in bb)))
        hi = Vector((max(v.x for v in bb), max(v.y for v in bb), max(v.z for v in bb)))
        c = (lo + hi) / 2
        d = hi - lo
        # Roblox centre and size
        out.append(
            f"{o.name}: center=({-c.x:.3f},{c.z:.3f},{c.y:.3f}) size=({d.x:.3f},{d.z:.3f},{d.y:.3f}) tris={tris(o)}"
        )
    return "\n".join(out)
