# Lobby fixes (Oct 18, 2026, 36th session). Exec'd in Blender after kit.py (same helpers):
#   exec(open(kit.py).read()); exec(open(fix_oct18.py).read())
# 1. Floor toys: the wooden train track was 64 overlapping straight boxes (tops at one height = z-fighting shimmer
#    at every joint, user: "blinking"); now each strip is one continuous ring, no overlaps. Beach ball unchanged.
# 2. CRT monitor: replaces the generated CRT (a bulging dome front with no flat glass, so the title-screen panel hung
#    off the bezel). Bezel with a real opening: the screen Part in LobbyProps sits in it (opening + depth printed).
# Exports GLB (export_materials NONE) into blender_assets/lobby_fix/ for tools/mesh/upload_model.py.
import os

FLOOR = -50
PALM = mat("Palette", (255, 255, 255), 0.7)
OUT = r"C:\Users\User\OneDrive\Desktop\Coding\glitched_together\blender_assets\lobby_fix"
os.makedirs(OUT, exist_ok=True)


def finish(o, angle=35):
    mb = bmesh.new()
    mb.from_mesh(o.data)
    bmesh.ops.recalc_face_normals(mb, faces=mb.faces)
    mb.to_mesh(o.data)
    mb.free()
    smooth(o, angle)
    return o


def ring_strip(bm, cx, cz, rx, rz, off, w, y0, h, swatch, N=96):
    """A closed rectangular-section band along an ellipse (Roblox x/z), offset `off` from the centre line."""
    rows = []
    for k in range(N):
        a = k / N * math.tau
        px, pz = cx + math.cos(a) * rx, cz + math.sin(a) * rz
        nx, nz = rz * math.cos(a), rx * math.sin(a)  # outward normal of the ellipse
        L = math.hypot(nx, nz)
        nx, nz = nx / L, nz / L
        pts = []
        for d, y in ((off - w / 2, y0), (off - w / 2, y0 + h), (off + w / 2, y0 + h), (off + w / 2, y0)):
            pts.append(bm.verts.new(rb(px + nx * d, y, pz + nz * d)))
        rows.append(pts)
    faces = []
    for k in range(N):
        A, B = rows[k], rows[(k + 1) % N]
        for i in range(4):
            j = (i + 1) % 4
            faces.append(bm.faces.new((A[i], A[j], B[j], B[i])))
    tag(bm, faces, swatch)


def build_floor_toys():
    bm = pbm()
    cx, cz, rx, rz = 82, -160, 28, 26
    ring_strip(bm, cx, cz, rx, rz, 0, 7, FLOOR, 1.0, "rawwood")
    for off in (-2.1, 2.1):
        ring_strip(bm, cx, cz, rx, rz, off, 0.9, FLOOR, 1.5, "darkwood")
    sphere_bm_local(bm, (-40, FLOOR + 7, -218), 7, "toyred", 24, 14)
    o = obj_from_bm("LK_FloorToys_Pal", bm, PALM)
    finish(o, 40)
    palette_uv(o)
    me = o.data
    mb = bmesh.new()
    mb.from_mesh(me)
    lay = mb.faces.layers.int.get("sw")
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


def sphere_bm_local(bm, c, r, swatch, seg=16, rings=10):
    res = bmesh.ops.create_uvsphere(bm, u_segments=seg, v_segments=rings, radius=r)
    vs = res["verts"]
    bmesh.ops.translate(bm, verts=vs, vec=rb(*c))
    tag(bm, faces_of(vs), swatch)


# CRT, modelled at the origin (bottom centre), screen facing Roblox -Z. Opening / glass depth below.
OPEN_W, OPEN_H, OPEN_Y = 22, 17, 18.5  # screen opening (centre height)
BEZ_Z0, BEZ_Z1 = -14, -10  # bezel front .. back


def piece(name, center, size, swatch, radius=0.0, seg=3):
    bm = pbm()
    vs = box_bm(bm, center, size)
    tag(bm, faces_of(vs), swatch)
    o = obj_from_bm(name, bm, PALM)
    if radius > 0:
        bevel(o, radius, seg)
    return o


def build_monitor():
    parts = []
    # bezel: a rounded slab with the screen opening cut through it
    bez = piece("tmp_bezel", (0, 17.5, (BEZ_Z0 + BEZ_Z1) / 2), (30, 27, BEZ_Z1 - BEZ_Z0), "ivory", 1.2, 4)
    cut = piece("tmp_cut", (0, OPEN_Y, (BEZ_Z0 + BEZ_Z1) / 2), (OPEN_W, OPEN_H, 10), "graphite", 0.8, 3)
    m = bez.modifiers.new("Cut", "BOOLEAN")
    m.operation = "DIFFERENCE"
    m.object = cut
    m.solver = "EXACT"
    apply_mods(bez)
    bpy.data.objects.remove(cut, do_unlink=True)
    # the opening's inner walls read dark (the tube's mouth)
    mb = bmesh.new()
    mb.from_mesh(bez.data)
    lay = mb.faces.layers.int.get("sw")
    for f in mb.faces:
        c = f.calc_center_median()  # Blender space: x = -X, y = Z, z = Y
        if abs(c.x) < OPEN_W / 2 + 0.05 and abs(c.z - OPEN_Y) < OPEN_H / 2 + 0.05 and f.normal.y > -0.5:
            f[lay] = PAL["graphite"]
    mb.to_mesh(bez.data)
    mb.free()
    parts.append(bez)
    # dark backing behind the opening (the screen Part covers it; this keeps the gaps dark)
    parts.append(piece("tmp_back", (0, OPEN_Y, BEZ_Z1 + 0.5), (OPEN_W + 1, OPEN_H + 1, 1), "black"))
    # tapered tube housing
    bm = pbm()
    vs = box_bm(bm, (0, 17.5, 1), (28, 25, 22))
    for v in vs:
        if v.co.y > rb(0, 0, 1).y:  # back half (+Z in Roblox = +y in Blender)
            v.co.x *= 0.62
            v.co.z = 17.5 + (v.co.z - 17.5) * 0.62 - 1.5 + 0  # z = Roblox Y
    tag(bm, faces_of(vs), "ivory")
    tube = obj_from_bm("tmp_tube", bm, PALM)
    bevel(tube, 1.4, 4)
    parts.append(tube)
    # vents sunk into the sloped tube top (top falls from y 30 at z -10 to 23.75 at z 12)
    slope = math.atan2(30 - 23.75, 22)
    for k in range(6):
        z = 1
        y = 30 - (z + 10) / 22 * 6.25 - 0.1
        bm = pbm()
        vs = box_bm(bm, (-6.25 + k * 2.5, y, z), (1.0, 0.5, 9), Matrix.Rotation(-slope, 3, "X"))
        tag(bm, faces_of(vs), "graphite")
        parts.append(obj_from_bm(f"tmp_vent{k}", bm, PALM))
    # control strip under the screen: buttons + power LED
    for k in range(4):
        parts.append(piece(f"tmp_btn{k}", (4 + k * 2.6, 6.8, BEZ_Z0 - 0.25), (1.8, 1.2, 0.8), "graphite", 0.3, 2))
    parts.append(piece("tmp_led", (-9, 6.8, BEZ_Z0 - 0.2), (1.0, 1.0, 0.6), "lime", 0.25, 2))
    parts.append(piece("tmp_grill", (-4, 6.8, BEZ_Z0 - 0.15), (6, 1.4, 0.5), "steel", 0.3, 2))
    # swivel stand
    parts.append(piece("tmp_base", (0, 0.9, 0), (20, 1.8, 18), "ivory", 0.8, 3))
    parts.append(piece("tmp_neck", (0, 4, 1), (12, 5, 10), "ivory", 0.8, 3))  # reaches the tube's raised back
    o = join("LK_Monitor_Pal", parts)
    finish(o, 35)
    palette_uv(o)
    return o


def export(o):
    for x in bpy.context.view_layer.objects:
        x.select_set(False)
    o.select_set(True)
    bpy.context.view_layer.objects.active = o
    path = os.path.join(OUT, o.name + ".glb")
    bpy.ops.export_scene.gltf(filepath=path, use_selection=True, use_active_scene=True, export_format="GLB",
                              export_materials="NONE")
    return path


toys = build_floor_toys()
mon = build_monitor()
print(report())
print("EXPORT", export(toys), export(mon))
