"""Epilogue sky helpers (Blender scene EpilogueSky, collection EpiSet). Run the parts in order through Blender MCP
execute_blender_code:  exec(open(r"<repo>/tools/epilogue_sky/build.py").read())
Coordinates: Blender (x, y, z) = Roblox (-x, z, y). The camera sits on the Epilogue hilltop at z = 0; the level walks
toward +Y (Roblox +Z = the Bk face). +X = Roblox -X (the Pixel Plains grove side), -X = the castle corner side.
"""
import bpy, bmesh, math, random
from mathutils import Vector, Matrix, noise

REPO = r"C:\Users\User\OneDrive\Desktop\Coding\glitched_together"
exec(open(REPO + r"\tools\blender_sky.py").read())

SC = bpy.data.scenes.get("EpilogueSky") or bpy.data.scenes.new("EpilogueSky")
bpy.context.window.scene = SC
HAZE = None  # set in build.py

# landmarks (Blender coords)
CASTLE = Vector((-1550.0, 1150.0))
CORE = Vector((180.0, 3300.0))
LAKE = Vector((1300.0, 2000.0))
LAKE_R = 520.0
WATER = -515.0


def lin(h):
    h = h.lstrip("#")
    return tuple((int(h[i:i + 2], 16) / 255) ** 2.2 for i in (0, 2, 4))


def coll():
    c = bpy.data.collections.get("EpiSet")
    if c is None:
        c = bpy.data.collections.new("EpiSet")
        SC.collection.children.link(c)
    return c


def new_obj(name, bm, mats):
    old = bpy.data.objects.get(name)
    if old:
        bpy.data.objects.remove(old, do_unlink=True)
    me = bpy.data.meshes.new(name)
    bm.to_mesh(me)
    bm.free()
    for m in mats:
        me.materials.append(m)
    o = bpy.data.objects.new(name, me)
    coll().objects.link(o)
    return o


def mat(name, rgb, rough=0.8, emit=None, estr=0.0, metal=0.0, haze=True):
    m = bpy.data.materials.get(name)
    if m is not None:
        bpy.data.materials.remove(m)
    m = bpy.data.materials.new(name)
    m.use_nodes = True
    b = next(n for n in m.node_tree.nodes if n.type == "BSDF_PRINCIPLED")
    b.inputs["Base Color"].default_value = (*rgb, 1)
    b.inputs["Roughness"].default_value = rough
    b.inputs["Metallic"].default_value = metal
    if emit:
        b.inputs["Emission Color"].default_value = (*emit, 1)
        b.inputs["Emission Strength"].default_value = estr
    m.diffuse_color = (*rgb, 1)
    if haze and HAZE:
        add_haze(m, HAZE, start=900, end=10000, strength=0.75)
    return m


def smooth(t):
    t = max(0.0, min(1.0, t))
    return t * t * (3 - 2 * t)


def height(x, y):
    r = math.hypot(x, y)
    n = noise.noise(Vector((x / 700, y / 700, 0.4))) * 40 + noise.noise(Vector((x / 160, y / 160, 1.7))) * 8
    valley = -505 + n
    # the hilltop under the level, sloping down into the valley
    hill = -260 - max(0.0, r - 60) * 0.7 + noise.noise(Vector((x / 120, y / 120, 3.3))) * 10 * smooth((r - 120) / 200)
    k = 60.0  # smooth max
    h = max(valley, hill)
    h += max(0.0, k - abs(valley - hill)) ** 2 / (4 * k)
    # castle crag
    dc = (Vector((x, y)) - CASTLE).length
    crag = -150 - (dc / 420) ** 2 * 260 + noise.noise(Vector((x / 90, y / 90, 5.0))) * 30
    h = max(h, crag)
    # the lake bowl
    dl = (Vector((x, y)) - LAKE).length
    if dl < LAKE_R + 200:
        t = smooth((dl - LAKE_R + 80) / 260)
        h = h * t + (WATER - 30) * (1 - t)
    # far mountains: a ring of peaks, lower straight ahead so the Core stands against the sky
    ang = math.atan2(x, y)
    ahead = math.exp(-(ang / 0.45) ** 2)
    ridge = smooth((r - 4200) / 3500) * (900 + 700 * noise.noise(Vector((math.cos(ang) * 3, math.sin(ang) * 3, 7.0))))
    ridge *= 1 - 0.75 * ahead
    peaks = abs(noise.noise(Vector((x / 900, y / 900, 9.0)))) * 500 * smooth((r - 4500) / 2500)
    crags = (1 - abs(noise.noise(Vector((x / 380, y / 380, 11.0))))) ** 3 * 320 * smooth((r - 4800) / 2000)
    return h + ridge + (peaks + crags) * (1 - 0.6 * ahead)


def box(bm, c, size, top=0, side=None, bottom=None, rot=0.0):
    """Axis box (yaw `rot` radians) into bm; material index per face: top, sides, bottom."""
    side = top if side is None else side
    bottom = side if bottom is None else bottom
    r = bmesh.ops.create_cube(bm, size=1.0)
    vs = r["verts"]
    m = Matrix.Translation(Vector(c)) @ Matrix.Rotation(rot, 4, "Z") @ Matrix.Diagonal((*size, 1))
    bmesh.ops.transform(bm, matrix=m, verts=vs)
    faces = {f for v in vs for f in v.link_faces}
    for f in faces:
        f.normal_update()
        f.material_index = top if f.normal.z > 0.5 else (bottom if f.normal.z < -0.5 else side)
    return faces


def window_quads(bm, c, size, rot, idx, rows=1, cols=2, wsz=(6, 6), rng=random, chance=0.75, z0=0.45):
    """Small emissive window quads just off the four walls of a box (warm lit windows)."""
    hx, hy, hz = size[0] / 2, size[1] / 2, size[2] / 2
    R = Matrix.Rotation(rot, 3, "Z")
    for nrm, half_w, half_d in (((1, 0), hy, hx), ((-1, 0), hy, hx), ((0, 1), hx, hy), ((0, -1), hx, hy)):
        n = Vector((nrm[0], nrm[1], 0))
        t = Vector((-nrm[1], nrm[0], 0))
        for ri in range(rows):
            for ci in range(cols):
                if rng.random() > chance:
                    continue
                u = (ci + 0.5) / cols * 2 - 1
                z = -hz + hz * 2 * (z0 + (0.4 * ri / max(1, rows - 1) if rows > 1 else 0))
                centre = n * (half_d + 0.6) + t * (u * half_w * 0.7)
                centre.z = z
                pts = []
                for du, dz in ((-1, -1), (1, -1), (1, 1), (-1, 1)):
                    p = centre + t * (du * wsz[0] / 2)
                    p.z += dz * wsz[1] / 2
                    pts.append(Vector(c) + R @ p)
                f = bm.faces.new([bm.verts.new(p) for p in pts])
                f.material_index = idx


def cyl(bm, c, r1, r2, depth, seg=16, side=0, cap=0):
    res = bmesh.ops.create_cone(bm, cap_ends=True, segments=seg, radius1=r1, radius2=r2, depth=depth,
                                matrix=Matrix.Translation(Vector(c)))
    for f in {f for v in res["verts"] for f in v.link_faces}:
        f.normal_update()
        f.material_index = cap if abs(f.normal.z) > 0.9 else side
        f.smooth = abs(f.normal.z) <= 0.9


def cottage(bm, x, y, z, rot, rng, wall=0, roof=1, win=2, scale=1.0):
    """Cottage with a gable roof and a few warm windows (material indices wall/roof/win)."""
    s = (rng.uniform(26, 40) * scale, rng.uniform(20, 28) * scale, rng.uniform(16, 24) * scale)
    box(bm, (x, y, z + s[2] / 2 - 2), s, top=wall, rot=rot)
    R3 = Matrix.Rotation(rot, 3, "Z")
    hx, hy, rz = s[0] / 2 + 2, s[1] / 2 + 3, z + s[2] - 2
    v = [bm.verts.new(Vector((x, y, 0)) + R3 @ Vector(p)) for p in
         ((-hx, -hy, rz), (hx, -hy, rz), (hx, hy, rz), (-hx, hy, rz), (-hx, 0, rz + s[1] * 0.6), (hx, 0, rz + s[1] * 0.6))]
    for q in ((v[0], v[1], v[5], v[4]), (v[2], v[3], v[4], v[5]), (v[0], v[4], v[3]), (v[1], v[2], v[5])):
        bm.faces.new(q).material_index = roof
    window_quads(bm, (x, y, z + s[2] / 2 - 2), s, rot, win, cols=2, wsz=(4, 5), rng=rng, chance=0.6)
