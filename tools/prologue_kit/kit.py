# Prologue kit (exec'd inside Blender through the MCP: exec(open(<this file>).read())).
# Generic pieces modeled at the origin in studs (Blender Z up = Roblox Y up; Blender -Y = Roblox front -Z), each split
# per surface: PK_<Piece>_<Surface>. They are placed by code (src/adventure/server/Services/ArtService/Prologue.luau)
# as skins over invisible holder parts, so the mesh centre is what matters, not the origin.
# Look: It Takes Two's space chapter set read as a theatre stage: aluminium box trusses hold the giant menu panels,
# stage par cans light them, oversized settings-menu props (window, toggle, checkbox, loading bar, gear) float behind.
import bpy
import bmesh
import math
from mathutils import Vector, Matrix

SCENE = "PrologueKit"
COLL = "PrologueKit"


def scene():
    sc = bpy.data.scenes.get(SCENE)
    if not sc:
        sc = bpy.data.scenes.new(SCENE)
    bpy.context.window.scene = sc
    c = bpy.data.collections.get(COLL)
    if not c:
        c = bpy.data.collections.new(COLL)
    if c.name not in sc.collection.children:
        sc.collection.children.link(c)
    return sc, c


def mat(name, rgb, rough=0.5, metal=0.0, emit=0.0):
    m = bpy.data.materials.get(name) or bpy.data.materials.new(name)
    m.use_nodes = True
    lin = [(c / 255) ** 2.2 for c in rgb]
    bsdf = next(n for n in m.node_tree.nodes if n.type == "BSDF_PRINCIPLED")
    bsdf.inputs["Base Color"].default_value = (*lin, 1)
    bsdf.inputs["Roughness"].default_value = rough
    bsdf.inputs["Metallic"].default_value = metal
    if emit > 0:
        bsdf.inputs["Emission Color"].default_value = (*lin, 1)
        bsdf.inputs["Emission Strength"].default_value = emit
    m.diffuse_color = (*lin, 1)
    return m


def remove(name):
    o = bpy.data.objects.get(name)
    if o:
        me = o.data
        bpy.data.objects.remove(o, do_unlink=True)
        if me and me.users == 0:
            bpy.data.meshes.remove(me)


def from_bm(name, bm, material, loc=(0, 0, 0)):
    remove(name)
    me = bpy.data.meshes.new(name)
    bm.normal_update()
    bm.to_mesh(me)
    bm.free()
    o = bpy.data.objects.new(name, me)
    o.location = loc
    scene()[1].objects.link(o)
    me.materials.append(material)
    for p in me.polygons:
        p.use_smooth = True
    return o


def apply_mods(o):
    dg = bpy.context.evaluated_depsgraph_get()
    me = bpy.data.meshes.new_from_object(o.evaluated_get(dg))
    old = o.data
    o.modifiers.clear()
    o.data = me
    if old.users == 0:
        bpy.data.meshes.remove(old)


def bevel(o, width, segments=3, angle=None):
    m = o.modifiers.new("Bevel", "BEVEL")
    m.width = width
    m.segments = segments
    if angle is not None:
        m.limit_method = "ANGLE"
        m.angle_limit = math.radians(angle)
    else:
        m.limit_method = "NONE"
    m.use_clamp_overlap = True
    apply_mods(o)
    ws = o.modifiers.new("WN", "WEIGHTED_NORMAL")
    ws.keep_sharp = True
    apply_mods(o)
    return o


def box(bm, c, s, rot=None):
    res = bmesh.ops.create_cube(bm, size=1.0)
    m = Matrix.Diagonal((s[0], s[1], s[2], 1.0))
    if rot:
        m = rot.to_4x4() @ m
    bmesh.ops.transform(bm, matrix=m, verts=res["verts"])
    bmesh.ops.translate(bm, vec=Vector(c), verts=res["verts"])
    return res["verts"]


def tube(bm, a, b, r, seg=8):
    """Cylinder from point a to point b (Blender space)."""
    a, b = Vector(a), Vector(b)
    d = b - a
    res = bmesh.ops.create_cone(bm, cap_ends=True, segments=seg, radius1=r, radius2=r, depth=d.length)
    rot = d.normalized().to_track_quat("Z", "Y").to_matrix().to_4x4()
    bmesh.ops.transform(bm, matrix=rot, verts=res["verts"])
    bmesh.ops.translate(bm, vec=(a + b) / 2, verts=res["verts"])


def rounded_rect_bm(bm, w, h, depth, r, seg=6, z0=0.0, center=(0, 0)):
    """Extruded rounded rectangle lying in the XZ plane (front faces -Y), w along X, h along Z, depth along Y."""
    pts = []
    cx, cz = center
    for (sx, sz, a0) in ((1, 1, 0), (-1, 1, 90), (-1, -1, 180), (1, -1, 270)):
        ox, oz = cx + sx * (w / 2 - r), cz + sz * (h / 2 - r)
        for k in range(seg + 1):
            a = math.radians(a0 + 90 * k / seg)
            pts.append((ox + math.cos(a) * r, oz + math.sin(a) * r))
    front = [bm.verts.new((x, z0 - depth / 2, z)) for x, z in pts]
    back = [bm.verts.new((x, z0 + depth / 2, z)) for x, z in pts]
    n = len(pts)
    bm.faces.new(list(reversed(front)))
    bm.faces.new(back)
    for i in range(n):
        j = (i + 1) % n
        bm.faces.new((front[i], front[j], back[j], back[i]))


def ring_frame_bm(bm, w, h, depth, r, border, seg=6):
    """A rounded rectangular frame (outline only) in the XZ plane."""
    def loop(ww, hh, rr):
        pts = []
        for (sx, sz, a0) in ((1, 1, 0), (-1, 1, 90), (-1, -1, 180), (1, -1, 270)):
            ox, oz = sx * (ww / 2 - rr), sz * (hh / 2 - rr)
            for k in range(seg + 1):
                a = math.radians(a0 + 90 * k / seg)
                pts.append((ox + math.cos(a) * rr, oz + math.sin(a) * rr))
        return pts
    outer = loop(w, h, r)
    inner = loop(w - 2 * border, h - 2 * border, max(r - border, 0.05))
    n = len(outer)
    of = [bm.verts.new((x, -depth / 2, z)) for x, z in outer]
    ob = [bm.verts.new((x, depth / 2, z)) for x, z in outer]
    inf = [bm.verts.new((x, -depth / 2, z)) for x, z in inner]
    inb = [bm.verts.new((x, depth / 2, z)) for x, z in inner]
    for i in range(n):
        j = (i + 1) % n
        bm.faces.new((of[j], of[i], inf[i], inf[j]))  # front
        bm.faces.new((ob[i], ob[j], inb[j], inb[i]))  # back
        bm.faces.new((of[i], of[j], ob[j], ob[i]))  # outer side
        bm.faces.new((inf[j], inf[i], inb[i], inb[j]))  # inner side


def tris(o):
    return sum(len(p.vertices) - 2 for p in o.data.polygons)


def report():
    out = []
    for o in scene()[1].objects:
        bb = [o.matrix_world @ Vector(c) for c in o.bound_box]
        lo = Vector((min(v.x for v in bb), min(v.y for v in bb), min(v.z for v in bb)))
        hi = Vector((max(v.x for v in bb), max(v.y for v in bb), max(v.z for v in bb)))
        c, s = (lo + hi) / 2, hi - lo
        # Roblox: (x, y, z) = (-bx, bz, by)
        out.append(f"{o.name}: centre R({-c.x:.2f},{c.z:.2f},{c.y:.2f}) size R({s.x:.2f},{s.z:.2f},{s.y:.2f}) tris {tris(o)}")
    return "\n".join(out)


# ---------------------------------------------------------------- materials
ALU = mat("PK_Alu", (196, 200, 210), 0.35, 1.0)
BLACK = mat("PK_Black", (30, 30, 36), 0.45, 0.6)
LENS = mat("PK_Lens", (255, 226, 170), 0.2, 0.0, 4.0)
SLATE = mat("PK_Slate", (46, 54, 112), 0.35)
WHITE = mat("PK_White", (238, 242, 255), 0.3)
PINK = mat("PK_Pink", (255, 95, 162), 0.3, 0.0, 1.5)


# ---------------------------------------------------------------- truss: 3x3 box truss, 12 tall segment
def truss():
    bm = bmesh.new()
    h, a, r = 12.0, 1.35, 0.2
    corners = [(a, a), (-a, a), (-a, -a), (a, -a)]
    for x, y in corners:
        tube(bm, (x, y, -h / 2), (x, y, h / 2), r, 10)
    # rungs at both ends + middle, zig-zag diagonals on each face
    levels = [-h / 2 + 0.25, 0.0, h / 2 - 0.25]
    for z in levels:
        for i in range(4):
            p, q = corners[i], corners[(i + 1) % 4]
            tube(bm, (*p, z), (*q, z), r * 0.6, 6)
    for i in range(4):
        p, q = corners[i], corners[(i + 1) % 4]
        for k in range(2):
            z0, z1 = levels[k], levels[k + 1]
            if (i + k) % 2 == 0:
                tube(bm, (*p, z0), (*q, z1), r * 0.55, 6)
            else:
                tube(bm, (*q, z0), (*p, z1), r * 0.55, 6)
    bmesh.ops.remove_doubles(bm, verts=bm.verts, dist=0.001)
    return from_bm("PK_Truss_Alu", bm, ALU)


# ---------------------------------------------------------------- stage par can on a yoke, aimed along -Y (front)
def spot():
    bm = bmesh.new()
    # can: lathe-like cone body
    res = bmesh.ops.create_cone(bm, cap_ends=True, segments=20, radius1=1.0, radius2=1.25, depth=2.6)
    rot = Matrix.Rotation(math.radians(90), 4, "X")  # cone axis Z -> -Y
    bmesh.ops.transform(bm, matrix=rot, verts=res["verts"])
    # rim / barn-door ring at the front
    res2 = bmesh.ops.create_cone(bm, cap_ends=True, segments=20, radius1=1.42, radius2=1.42, depth=0.3)
    bmesh.ops.transform(bm, matrix=rot, verts=res2["verts"])
    bmesh.ops.translate(bm, vec=(0, -1.35, 0), verts=res2["verts"])
    # back cap + vents
    res3 = bmesh.ops.create_cone(bm, cap_ends=True, segments=16, radius1=0.7, radius2=0.95, depth=0.5)
    bmesh.ops.transform(bm, matrix=rot, verts=res3["verts"])
    bmesh.ops.translate(bm, vec=(0, 1.45, 0), verts=res3["verts"])
    # yoke: U bracket around the can, clamp on top
    box(bm, (1.45, 0, 0), (0.18, 0.7, 0.7))
    box(bm, (-1.45, 0, 0), (0.18, 0.7, 0.7))
    box(bm, (1.45, 0, 1.0), (0.18, 0.5, 2.0))
    box(bm, (-1.45, 0, 1.0), (0.18, 0.5, 2.0))
    box(bm, (0, 0, 2.0), (3.08, 0.5, 0.2))
    box(bm, (0, 0, 2.45), (0.5, 0.5, 0.7))
    tube(bm, (0, -0.55, 2.95), (0, 0.55, 2.95), 0.32, 12)  # clamp ring on the truss tube
    o = from_bm("PK_Spot_Black", bm, BLACK)
    # lens
    bm = bmesh.new()
    res = bmesh.ops.create_cone(bm, cap_ends=True, segments=20, radius1=1.12, radius2=1.12, depth=0.12)
    bmesh.ops.transform(bm, matrix=Matrix.Rotation(math.radians(90), 4, "X"), verts=res["verts"])
    bmesh.ops.translate(bm, vec=(0, -1.33, 0), verts=res["verts"])
    from_bm("PK_Spot_Lens", bm, LENS)
    return o


# ---------------------------------------------------------------- settings window: 40 x 26, 1.2 deep
def window():
    W, H, D = 40.0, 26.0, 1.2
    bm = bmesh.new()
    rounded_rect_bm(bm, W - 0.6, H - 0.6, D, 2.0, 6)
    from_bm("PK_Window_Slate", bm, SLATE)
    bm = bmesh.new()
    ring_frame_bm(bm, W, H, D + 0.3, 2.2, 0.7, 6)
    from_bm("PK_Window_White", bm, WHITE)
    # title bar band across the top + three dots + close X (pink accent)
    bm = bmesh.new()
    rounded_rect_bm(bm, W - 2.2, 3.4, 0.3, 1.0, 4, z0=-(D / 2 + 0.15), center=(0, H / 2 - 2.6))
    for k in range(3):
        res = bmesh.ops.create_cone(bm, cap_ends=True, segments=16, radius1=0.55, radius2=0.55, depth=0.3)
        bmesh.ops.transform(bm, matrix=Matrix.Rotation(math.radians(90), 4, "X"), verts=res["verts"])
        bmesh.ops.translate(bm, vec=(-W / 2 + 3.2 + k * 1.7, -(D / 2 + 0.45), H / 2 - 2.6), verts=res["verts"])
    from_bm("PK_Window_Pink", bm, PINK)
    bm = bmesh.new()
    for ang in (45, -45):
        box(bm, (W / 2 - 3.0, -(D / 2 + 0.45), H / 2 - 2.6), (2.0, 0.3, 0.42), Matrix.Rotation(math.radians(ang), 3, "Y"))
    # menu rows: three rounded pills inside the window
    for k in range(3):
        rounded_rect_bm(bm, W - 10, 3.0, 0.3, 1.4, 4, z0=-(D / 2 + 0.15), center=(0, 4.5 - k * 5.2))
    from_bm("PK_Window_Rows", bm, WHITE)


# ---------------------------------------------------------------- toggle switch (on), 16 x 8 x 2
def toggle():
    bm = bmesh.new()
    rounded_rect_bm(bm, 16, 8, 2, 3.99, 10)
    from_bm("PK_Toggle_Pink", bm, PINK)
    bm = bmesh.new()
    bmesh.ops.create_uvsphere(bm, u_segments=24, v_segments=14, radius=3.1)
    bmesh.ops.scale(bm, vec=(1, 0.55, 1), verts=bm.verts)
    bmesh.ops.translate(bm, vec=(4.0, -0.9, 0), verts=bm.verts)
    from_bm("PK_Toggle_White", bm, WHITE)


# ---------------------------------------------------------------- checkbox (ticked), 10 x 10 x 1.6
def checkbox():
    bm = bmesh.new()
    ring_frame_bm(bm, 10, 10, 1.6, 2.0, 1.0, 5)
    rounded_rect_bm(bm, 8.4, 8.4, 0.6, 1.2, 4, z0=0.4)
    from_bm("PK_Check_White", bm, WHITE)
    bm = bmesh.new()
    box(bm, (-1.9, -0.9, -0.7), (3.8, 0.9, 1.3), Matrix.Rotation(math.radians(45), 3, "Y"))
    box(bm, (1.2, -0.9, 0.35), (6.6, 0.9, 1.3), Matrix.Rotation(math.radians(-50), 3, "Y"))
    o = from_bm("PK_Check_Pink", bm, PINK)
    bevel(o, 0.25, 2)


# ---------------------------------------------------------------- loading bar 50 x 6 x 2, fill 72%
def loadbar():
    bm = bmesh.new()
    ring_frame_bm(bm, 50, 6, 2, 2.99, 0.8, 8)
    from_bm("PK_Load_White", bm, WHITE)
    bm = bmesh.new()
    fw = (50 - 2.6) * 0.72
    rounded_rect_bm(bm, fw, 4.4, 1.2, 2.19, 8, center=(-(50 - 2.6) / 2 + fw / 2, 0))
    from_bm("PK_Load_Pink", bm, PINK)
    bm = bmesh.new()
    rounded_rect_bm(bm, 49.2, 5.2, 0.6, 2.59, 8, z0=0.5)
    from_bm("PK_Load_Slate", bm, SLATE)


# ---------------------------------------------------------------- settings gear 16 across, 3 thick
def gear():
    bm = bmesh.new()
    teeth, r0, r1, rin = 10, 6.1, 8.0, 2.6
    outer = []
    for k in range(teeth * 4):
        a = k / (teeth * 4) * math.tau
        phase = k % 4
        r = r1 if phase in (1, 2) else r0
        outer.append((math.cos(a) * r, math.sin(a) * r))
    inner = [(math.cos(k / 40 * math.tau) * rin, math.sin(k / 40 * math.tau) * rin) for k in range(40)]
    d = 3.0
    of = [bm.verts.new((x, -d / 2, z)) for x, z in outer]
    ob = [bm.verts.new((x, d / 2, z)) for x, z in outer]
    # bridge outer ring to inner hole via a grid fan: make the face with a hole by triangulating pairs
    inf = [bm.verts.new((x, -d / 2, z)) for x, z in inner]
    inb = [bm.verts.new((x, d / 2, z)) for x, z in inner]
    n = len(outer)
    for i in range(n):
        j = (i + 1) % n
        bm.faces.new((of[i], of[j], ob[j], ob[i]))
        bm.faces.new((inf[j], inf[i], inb[i], inb[j]))
        bm.faces.new((of[j], of[i], inf[i], inf[j]))  # n == 40 == len(inner): same angles, so faces pair up
        bm.faces.new((ob[i], ob[j], inb[j], inb[i]))
    o = from_bm("PK_Gear_White", bm, WHITE)
    bevel(o, 0.3, 2, 40)


def build_all():
    scene()
    truss()
    spot()
    window()
    toggle()
    checkbox()
    loadbar()
    gear()
    # lay them out side by side so a screenshot shows the lot
    xs = {"Truss": -40, "Spot": -32, "Window": 0, "Toggle": 32, "Check": 46, "Load": 0, "Gear": 60}
    zs = {"Load": -22}
    for o in scene()[1].objects:
        piece = o.name.split("_")[1]
        o.location = (xs.get(piece, 0), 0, zs.get(piece, 0))
    return report()
