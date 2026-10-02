"""Castle sky valley (Blender scene CastleSky, collection DnSet): run in order through execute_blender_code:
    exec(open(r"<repo>/tools/castle_valley/dn_terrain.py").read()), then dn_village.py, then dn_nature.py.
orig_h.txt = the original global terrain heights (CTerrain was pushed down under the patch). Render with
tools/blender_sky.py render_faces(..., origin=(0, 0, 700)). See BLENDER_PLAYBOOK.md section 10."""
import bpy, bmesh, math, random, os
from mathutils import Vector, noise

SC = bpy.data.scenes["CastleSky"]
SCR = r"C:\Users\User\OneDrive\Desktop\Coding\glitched_together\tools\castle_valley"
WATER = -455.0


def lin(h):
    h = h.lstrip("#")
    return tuple((int(h[i:i + 2], 16) / 255) ** 2.2 for i in (0, 2, 4))


def river_y(x):
    return 150 * math.sin(x / 260.0) + 55 * math.sin(x / 97.0 + 1.0) - 110


def road_x(y):
    # road runs along y, crosses the river near (x~-60)
    return -40 - 140 * math.sin((y + 126) / 260.0) + 15 * math.sin(y / 150.0)


def river_dist(x, y):
    # approx distance to river centreline (sample nearby x)
    best = 1e9
    for dx in range(-90, 91, 6):
        xx = x + dx
        d = math.hypot(xx - x, river_y(xx) - y)
        if d < best:
            best = d
    return best


def road_dist(x, y):
    best = 1e9
    for dy in range(-90, 91, 6):
        yy = y + dy
        d = math.hypot(road_x(yy) - x, yy - y)
        if d < best:
            best = d
    return best


_G = None


def global_h(x, y):
    """bilinear sample of the ORIGINAL global terrain (100-stud grid) saved to orig_h.txt"""
    global _G
    if _G is None:
        _G = {}
        with open(os.path.join(SCR, "orig_h.txt")) as f:
            for line in f:
                a, b, c = line.split()
                _G[(int(a), int(b))] = float(c)
    x0 = math.floor(x / 100) * 100
    y0 = math.floor(y / 100) * 100
    tx = (x - x0) / 100
    ty = (y - y0) / 100
    g = lambda a, b: _G.get((a, b), -440.0)
    return (g(x0, y0) * (1 - tx) * (1 - ty) + g(x0 + 100, y0) * tx * (1 - ty)
            + g(x0, y0 + 100) * (1 - tx) * ty + g(x0 + 100, y0 + 100) * tx * ty)


def local_h(x, y):
    n = noise.noise(Vector((x / 420, y / 420, 0.3))) * 18 + noise.noise(Vector((x / 90, y / 90, 2.1))) * 4
    rd = river_dist(x, y)
    base = -436 + n + min(rd, 500) * 0.035
    if rd < 11:
        z = -466
    elif rd < 34:
        t = (rd - 11) / 23
        t = t * t * (3 - 2 * t)
        z = -470 * (1 - t) + base * t
    else:
        z = base
    # road: flatten a little
    dr = road_dist(x, y)
    if dr < 10 and rd > 40:
        z = z - 0.6
    return z


def channel(rd, base):
    if rd < 11:
        return -466.0
    if rd < 34:
        t = (rd - 11) / 23
        t = t * t * (3 - 2 * t)
        return -466 * (1 - t) + base * t
    return base


def height(x, y):
    r = max(abs(x), abs(y))
    if r <= 1050:
        return local_h(x, y)
    g = global_h(x, y)
    t = min(1.0, (r - 1050) / 400)
    t = t * t * (3 - 2 * t)
    h = local_h(x, y) * (1 - t) + g * t
    if r < 2550:
        rd = river_dist(x, y)
        if rd < 60:
            fade = max(0.0, min(1.0, (2550 - r) / 150))
            h = h * (1 - fade) + channel(rd, h) * fade
    return h


def mat(name, rgb, rough=0.8, emit=None, estr=0.0, metal=0.0):
    m = bpy.data.materials.get(name)
    if m is None:
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
    return m


def link(obj):
    col = bpy.data.collections.get("DnSet")
    if col is None:
        col = bpy.data.collections.new("DnSet")
        SC.collection.children.link(col)
    col.objects.link(obj)
    return obj


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
    return link(o)


def box(bm, cx, cy, z0, sx, sy, sz, rot=0.0, mi=0):
    c, s = math.cos(rot), math.sin(rot)
    vs = []
    for dz in (0, sz):
        for dx, dy in ((-1, -1), (1, -1), (1, 1), (-1, 1)):
            px, py = dx * sx / 2, dy * sy / 2
            vs.append(bm.verts.new((cx + px * c - py * s, cy + px * s + py * c, z0 + dz)))
    faces = [(0, 3, 2, 1), (4, 5, 6, 7), (0, 1, 5, 4), (1, 2, 6, 5), (2, 3, 7, 6), (3, 0, 4, 7)]
    out = []
    for f in faces:
        fa = bm.faces.new([vs[i] for i in f])
        fa.material_index = mi
        out.append(fa)
    return out


def cone(bm, cx, cy, z0, r, h, seg=7, mi=0, rot=0.0, r_top=0.0):
    bot = []
    top = []
    for i in range(seg):
        a = rot + i / seg * math.tau
        bot.append(bm.verts.new((cx + math.cos(a) * r, cy + math.sin(a) * r, z0)))
        if r_top > 0:
            top.append(bm.verts.new((cx + math.cos(a) * r_top, cy + math.sin(a) * r_top, z0 + h)))
    if r_top > 0:
        for i in range(seg):
            j = (i + 1) % seg
            bm.faces.new((bot[i], bot[j], top[j], top[i])).material_index = mi
        bm.faces.new(top).material_index = mi
    else:
        apex = bm.verts.new((cx, cy, z0 + h))
        for i in range(seg):
            j = (i + 1) % seg
            bm.faces.new((bot[i], bot[j], apex)).material_index = mi
    bm.faces.new(list(reversed(bot))).material_index = mi


def gable(bm, cx, cy, z0, sx, sy, wall, roof, rot, mi_wall, mi_roof, over=1.5):
    """house: box walls + pitched roof along local x"""
    box(bm, cx, cy, z0, sx, sy, wall, rot, mi_wall)
    c, s = math.cos(rot), math.sin(rot)
    P = lambda px, py, pz: bm.verts.new((cx + px * c - py * s, cy + px * s + py * c, pz))
    hx, hy = sx / 2 + over, sy / 2 + over
    zt = z0 + wall
    a = P(-hx, -hy, zt - 0.6); b = P(hx, -hy, zt - 0.6); r1 = P(hx, 0, zt + roof); r0 = P(-hx, 0, zt + roof)
    d = P(-hx, hy, zt - 0.6); e = P(hx, hy, zt - 0.6)
    bm.faces.new((a, b, r1, r0)).material_index = mi_roof
    bm.faces.new((e, d, r0, r1)).material_index = mi_roof
    bm.faces.new((a, r0, d)).material_index = mi_roof
    bm.faces.new((b, e, r1)).material_index = mi_roof
