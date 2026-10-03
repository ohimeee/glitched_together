# The bed against the left wall (LobbyRoom.luau colliders: x -158..-94, z -228..-96, frame 14 tall from y -46,
# headboard at z -228, mattress top y -17). White-painted wood frame with turned posts and an arched slatted
# headboard; a soft mattress; a gingham quilt draped by Blender's cloth sim; two plump pillows. Run after kit.py.
import random

FLOOR = -50
PAINT = mat("PaintedWood", (240, 232, 220), 0.5)
LINEN = mat("Linen", (244, 242, 236), 0.8)
QUILT = mat("Quilt", (214, 222, 240), 0.8)
X0, X1, Z0, Z1 = -158, -94, -228, -96
CX, CZ = (X0 + X1) / 2, (Z0 + Z1) / 2
TOP = FLOOR + 33  # mattress top


def post(bm, x, z, top, finial=True):
    H = top - FLOOR
    prof = [(0.01, 0), (2.4, 0), (2.6, 0.8), (2.2, 1.8), (2.0, 4)]
    # square-ish turned post: long straight shaft with beads near rail heights
    prof += [(2.0, H * 0.45), (2.5, H * 0.47), (2.0, H * 0.5), (2.0, H * 0.86), (2.5, H * 0.88), (2.2, H * 0.92)]
    if finial:
        prof += [(1.4, H * 0.95), (1.4, H), (2.4, H + 1.0), (2.9, H + 2.6), (2.4, H + 4.2), (1.2, H + 5.2), (0.01, H + 5.6)]
    else:
        prof += [(2.2, H), (0.01, H)]
    lathe_bm(bm, prof, (x, FLOOR, z), 20)


def build_frame():
    parts = []
    bm = bmesh.new()
    head_top, foot_top = FLOOR + 58, FLOOR + 30
    for x in (X0 + 2.5, X1 - 2.5):
        post(bm, x, Z0 + 2.5, head_top)
        post(bm, x, Z1 - 2.5, foot_top)
    posts = obj_from_bm("tmp_posts", bm, PAINT)
    smooth(posts, 35)
    parts.append(posts)
    # side + end rails (the box the mattress sits in)
    for x in (X0 + 2.5, X1 - 2.5):
        parts.append(rounded_box("tmp_rail", (x, FLOOR + 11, CZ), (2.6, 12, Z1 - Z0 - 6), 0.8, 3, PAINT))
    for z in (Z0 + 2.5, Z1 - 2.5):
        parts.append(rounded_box("tmp_rail", (CX, FLOOR + 11, z), (X1 - X0 - 6, 12, 2.6), 0.8, 3, PAINT))
    # headboard: arched top rail, lower rail, 7 slats; footboard: low arch, 5 slats
    for z, y_low, y_high, arch, n in ((Z0 + 2.5, FLOOR + 18, head_top - 8, 7, 7), (Z1 - 2.5, FLOOR + 18, foot_top - 3, 3, 5)):
        W = X1 - X0 - 5
        rail = arch_rail("tmp_arch", X0 + 2.5, X1 - 2.5, y_high, z, 4.5, 2.4, arch, PAINT)
        parts.append(rail)
        parts.append(rounded_box("tmp_low", (CX, y_low, z), (W, 3.4, 2.4), 0.7, 2, PAINT))
        for k in range(n):
            t = (k + 1) / (n + 1)
            x = X0 + 2.5 + t * W
            top = y_high + math.sin(t * math.pi) * arch
            parts.append(rounded_box("tmp_slat", (x, (y_low + top) / 2, z), (3.2, top - y_low, 1.4), 0.6, 3, PAINT))
    frame = join("LK_Bed_Paint", parts)
    return frame


def build_mattress():
    m = rounded_box("LK_Bed_Linen", (CX, (FLOOR + 17 + TOP) / 2, CZ + 1), (X1 - X0 - 4, TOP - (FLOOR + 17), Z1 - Z0 - 8), 3.2, 5, LINEN)
    smooth(m, 60)
    return m


def pillow(name, cx, cz, yaw, w=24, d=17, h=8):
    bm = bmesh.new()
    res = bmesh.ops.create_grid(bm, x_segments=18, y_segments=14, size=0.5)
    # a grid sheet -> top and bottom halves of a pillow (puffed by (1-x^2)(1-z^2))
    top_verts = res["verts"]
    dup = bmesh.ops.duplicate(bm, geom=list(set(top_verts) | faces_of(top_verts)))
    bot_verts = [g for g in dup["geom"] if isinstance(g, bmesh.types.BMVert)]
    bmesh.ops.reverse_faces(bm, faces=[g for g in dup["geom"] if isinstance(g, bmesh.types.BMFace)])
    rnd = random.Random(name)
    for verts, sgn in ((top_verts, 1), (bot_verts, -1)):
        for v in verts:
            x, y = v.co.x * 2, v.co.y * 2  # -1..1
            puff = (1 - x * x) * (1 - y * y)
            puff = puff ** 0.6
            # corners pinch, edges a touch wavy
            z = sgn * (h / 2) * puff + (0.25 * math.sin(x * 9 + rnd.random()) * puff if sgn > 0 else 0)
            v.co = Vector((x * w / 2 * (1 - 0.06 * (1 - y * y)), y * d / 2 * (1 - 0.06 * (1 - x * x)), z))
    bmesh.ops.remove_doubles(bm, verts=bm.verts, dist=0.01)
    o = obj_from_bm(name, bm, LINEN)
    smooth(o, 80)
    o.data.transform(Matrix.Rotation(yaw, 4, "Z"))
    o.data.transform(Matrix.Translation(rb(cx, TOP + h / 2 - 1.2, cz)))
    return o


def build_pillows():
    a = pillow("tmp_pillowA", CX - 14, Z0 + 16, 0.08)
    b = pillow("tmp_pillowB", CX + 14, Z0 + 15, -0.12)
    return join("LK_Pillows_Linen", [a, b])


def build_quilt(frames=110):
    """A gingham quilt dropped onto the mattress with Blender's cloth sim (frozen at `frames`)."""
    remove("LK_Bed_Quilt")
    # sheet a bit wider than the bed; its far edge tucked against the wall side (x -158), it hangs over the room side
    # (x -94) and the foot (z -96)
    qx0, qx1 = X0 + 4, X1 + 16  # spills down the open side to the floor (the book stairs stand 6 studs out)
    qz0, qz1 = Z0 + 34, Z1 + 20
    bm = bmesh.new()
    res = bmesh.ops.create_grid(bm, x_segments=46, y_segments=60, size=0.5)
    for v in res["verts"]:
        u, w = v.co.x + 0.5, v.co.y + 0.5
        v.co = rb(qx0 + u * (qx1 - qx0), TOP + 1.5, qz0 + w * (qz1 - qz0))
    rnd = random.Random(3)
    for v in bm.verts:  # a little lumpiness so it settles into soft folds, not a flat sheet
        v.co.z += rnd.uniform(0, 0.8) + 2.5 * math.sin(v.co.x * 0.25) * math.sin(v.co.y * 0.18) + 2.5
    q = obj_from_bm("LK_Bed_Quilt", bm, QUILT)
    # the floor stops the overhang
    fbm = bmesh.new()
    box_bm(fbm, (CX + 40, FLOOR - 1, CZ), (200, 2, 220))
    floor = obj_from_bm("tmp_floor", fbm)
    floor.modifiers.new("Collision", "COLLISION")
    # colliders: mattress + frame
    for n in ("LK_Bed_Linen", "LK_Bed_Paint", "LK_Pillows_Linen"):
        o = bpy.data.objects[n]
        if not o.collision or not o.modifiers.get("Collision"):
            o.modifiers.new("Collision", "COLLISION")
        o.collision.thickness_outer = 0.3
        o.collision.cloth_friction = 8
    # pin the wall-side edge so it stays tucked
    vg = q.vertex_groups.new(name="pin")
    vg.add([v.index for v in q.data.vertices if (-v.co.x) < qx0 + 1.0], 1.0, "REPLACE")
    cl = q.modifiers.new("Cloth", "CLOTH")
    s = cl.settings
    s.quality = 8
    s.mass = 0.4
    s.tension_stiffness = 20
    s.compression_stiffness = 20
    s.bending_stiffness = 0.6
    s.air_damping = 2
    s.vertex_group_mass = "pin"
    cl.collision_settings.distance_min = 0.4
    cl.collision_settings.use_self_collision = False
    sc = bpy.context.scene
    sc.frame_start = 1
    sc.frame_end = frames
    cl.point_cache.frame_start = 1
    cl.point_cache.frame_end = frames
    sc.gravity = (0, 0, -260)  # studs: 1 stud ~ 1.5 cm here, so a strong pull drapes it in fewer frames
    for f in range(1, frames + 1):
        sc.frame_set(f)
    apply_mods(q)
    for n in ("LK_Bed_Linen", "LK_Bed_Paint", "LK_Pillows_Linen"):
        o = bpy.data.objects[n]
        m = o.modifiers.get("Collision")
        if m:
            o.modifiers.remove(m)
    sc.frame_set(1)
    bpy.data.objects.remove(floor, do_unlink=True)
    sol = q.modifiers.new("Solid", "SOLIDIFY")
    sol.thickness = 1.0
    sol.offset = 1
    apply_mods(q)
    smooth(q, 70)
    return q


frame = build_frame()
mattress = build_mattress()
pillows = build_pillows()
quilt = build_quilt()
print(report())
