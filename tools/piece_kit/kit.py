# Piece kit: small gameplay-piece skins that were still grey-box (exec'd inside Blender through the MCP:
# exec(open(<this file>).read())). Reuses the Prologue kit's helpers (tube, box, bevel, report...), then builds its own
# scene. Objects are PC_<Piece>_<Surface>, modeled at the origin in studs (Blender Z up = Roblox Y up).
#   Castle Ember Fuse: FuseStake (oak stake + iron cup with the fuse coil and a tinder knot Kai lights),
#                      FuseStaple (iron staple pinning the cord to the floor), FuseSplice (iron clamp + tinder at a break).
#   Grind rails:       RailBase (bolted floor flange), RailPole (unit-height pole, stretched in Y), RailClamp (saddle that
#                      cradles the 1-stud rail pipe).
import math
import bmesh
from mathutils import Vector

exec(open(r"C:\Users\User\OneDrive\Desktop\Coding\glitched_together\tools\prologue_kit\kit.py").read())

SCENE = "PieceKit"
COLL = "PieceKit"

OAK = mat("PC_Oak", (122, 84, 52), 0.75)
IRON = mat("PC_Iron", (58, 56, 60), 0.55, 0.8)
CORD = mat("PC_Cord", (205, 165, 110), 0.9)
TINDER = mat("PC_Tinder", (255, 150, 60), 0.6, 0.0, 2.0)
STEEL = mat("PC_Steel", (150, 152, 160), 0.4, 0.9)
BOLT = mat("PC_Bolt", (90, 92, 98), 0.35, 1.0)


def torus_obj(name, z, r_major, r_minor, material, seg=20, seg2=6, sx=1.0, sy=1.0):
    bm = bmesh.new()
    bmesh.ops.create_circle(bm, cap_ends=False, segments=seg2, radius=r_minor)
    for v in bm.verts:
        v.co = Vector((v.co.x + r_major, 0, v.co.y))
    bmesh.ops.spin(bm, geom=list(bm.verts) + list(bm.edges), cent=(0, 0, 0), axis=(0, 0, 1), steps=seg,
                   angle=math.tau, use_duplicate=False)
    bmesh.ops.remove_doubles(bm, verts=bm.verts, dist=0.0005)
    for v in bm.verts:
        v.co = Vector((v.co.x * sx, v.co.y * sy, v.co.z + z))
    return bm


def merge(bms):
    out = bmesh.new()
    for b in bms:
        me = bpy.data.meshes.new("tmp")
        b.to_mesh(me)
        b.free()
        out.from_mesh(me)
        bpy.data.meshes.remove(me)
    return out


# ---------------------------------------------------------------- Fuse stake (design 1 x 1.6 x 1 → the FuseStart part)
def fuse_stake():
    # tapered square oak stake, 0.5 wide, 1.25 tall, slightly split top
    bm = bmesh.new()
    res = bmesh.ops.create_cone(bm, cap_ends=True, segments=4, radius1=0.36, radius2=0.31, depth=1.2)
    bmesh.ops.rotate(bm, verts=res["verts"], cent=(0, 0, 0), matrix=Matrix.Rotation(math.radians(45), 3, "Z"))
    bmesh.ops.translate(bm, vec=(0, 0, 0.6), verts=res["verts"])
    # driven point hidden in the floor: a short wedge so the base isn't a flat cut
    res = bmesh.ops.create_cone(bm, cap_ends=True, segments=4, radius1=0.05, radius2=0.36, depth=0.25)
    bmesh.ops.rotate(bm, verts=res["verts"], cent=(0, 0, 0), matrix=Matrix.Rotation(math.radians(45), 3, "Z"))
    bmesh.ops.translate(bm, vec=(0, 0, -0.12), verts=res["verts"])
    wood = from_bm("PC_FuseStake_Wood", bm, OAK)
    bevel(wood, 0.03, 2, 40)
    # iron: two bands round the stake + a cup on top on three little prongs
    parts = [torus_obj("b", z, 0.33, 0.045, IRON, 4, 4, 1.0, 1.0) for z in (0.3, 0.95)]
    for p in parts:
        bmesh.ops.rotate(p, verts=p.verts, cent=(0, 0, 0), matrix=Matrix.Rotation(math.radians(45), 3, "Z"))
    cup = bmesh.new()
    res = bmesh.ops.create_cone(cup, cap_ends=True, segments=16, radius1=0.22, radius2=0.42, depth=0.28)
    bmesh.ops.translate(cup, vec=(0, 0, 1.36), verts=res["verts"])
    # hollow the cup: inset + push the top face down
    top = [f for f in cup.faces if f.normal.z > 0.9]
    r = bmesh.ops.inset_region(cup, faces=top, thickness=0.05, depth=0)
    bmesh.ops.translate(cup, vec=(0, 0, -0.2), verts=list({v for f in top for v in f.verts}))
    rim = torus_obj("rim", 1.5, 0.42, 0.04, IRON, 20, 6)
    prongs = bmesh.new()
    for k in range(3):
        a = k * math.tau / 3
        tube(prongs, (0.2 * math.cos(a), 0.2 * math.sin(a), 1.12), (0.3 * math.cos(a), 0.3 * math.sin(a), 1.3), 0.035, 6)
    iron = from_bm("PC_FuseStake_Iron", merge(parts + [cup, rim, prongs]), IRON)
    # fuse coil sitting in the cup, its tail running down the stake to the floor (toward -Y = Roblox +Z, the path)
    coil = bmesh.new()
    pts = []
    for i in range(60):
        t = i / 59
        a = t * math.tau * 2.2
        rr = 0.3 - 0.18 * t
        pts.append(Vector((rr * math.cos(a), rr * math.sin(a), 1.36 + 0.05 * math.sin(t * 9))))
    for a, b in zip(pts, pts[1:]):
        tube(coil, a, b, 0.055, 6)
    tail = [pts[0], Vector((0.36, -0.1, 1.2)), Vector((0.38, -0.25, 0.7)), Vector((0.36, -0.35, 0.2)),
            Vector((0.3, -0.6, 0.06)), Vector((0.2, -0.95, 0.06))]
    for a, b in zip(tail, tail[1:]):
        tube(coil, a, b, 0.06, 6)
    bmesh.ops.remove_doubles(coil, verts=coil.verts, dist=0.01)
    from_bm("PC_FuseStake_Cord", coil, CORD)
    # tinder knot: the frayed end Kai lights (owner color in code)
    tb = bmesh.new()
    bmesh.ops.create_icosphere(tb, subdivisions=2, radius=0.17)
    for v in tb.verts:
        n = v.co.normalized()
        v.co = v.co * (1 + 0.25 * math.sin(7 * n.x + 5 * n.y) * math.cos(6 * n.z)) + Vector((0, 0, 1.47))
    from_bm("PC_FuseStake_Tinder", tb, TINDER)


# ---------------------------------------------------------------- staple: iron U pinned over the cord (cord runs along Y)
def fuse_staple():
    bm = bmesh.new()
    w, h, r = 0.36, 0.42, 0.06
    tube(bm, (-w, 0, -0.15), (-w, 0, h), r, 6)
    tube(bm, (w, 0, -0.15), (w, 0, h), r, 6)
    tube(bm, (-w, 0, h), (w, 0, h), r, 6)
    # little square washers where it enters the floor
    box(bm, (-w, 0, 0.02), (0.22, 0.22, 0.04))
    box(bm, (w, 0, 0.02), (0.22, 0.22, 0.04))
    bmesh.ops.remove_doubles(bm, verts=bm.verts, dist=0.002)
    from_bm("PC_FuseStaple_Iron", bm, IRON)


# ---------------------------------------------------------------- splice: hinged iron clamp around a cut cord + tinder
def fuse_splice():
    bm = bmesh.new()
    box(bm, (0, 0, 0.12), (1.2, 0.7, 0.18))
    box(bm, (0, 0, 0.32), (1.0, 0.5, 0.22))
    for x in (-0.45, 0.45):
        tube(bm, (x, -0.3, 0.42), (x, 0.3, 0.42), 0.07, 8)
    for x in (-0.5, 0.5):
        for y in (-0.28, 0.28):
            bmesh.ops.create_cone(bm, cap_ends=True, segments=6, radius1=0.06, radius2=0.06, depth=0.06)
            bm.verts.ensure_lookup_table()
            bmesh.ops.translate(bm, vec=(x, y, 0.23), verts=bm.verts[-12:])
    iron = from_bm("PC_FuseSplice_Iron", bm, IRON)
    bevel(iron, 0.03, 2, 40)
    cord = bmesh.new()
    tube(cord, (0, -0.9, 0.1), (0, -0.3, 0.2), 0.08, 6)
    tube(cord, (0, 0.3, 0.2), (0, 0.9, 0.1), 0.08, 6)
    from_bm("PC_FuseSplice_Cord", cord, CORD)
    tb = bmesh.new()
    bmesh.ops.create_icosphere(tb, subdivisions=2, radius=0.24)
    for v in tb.verts:
        n = v.co.normalized()
        v.co = Vector((v.co.x * 1.3, v.co.y, v.co.z * 0.8)) * (1 + 0.2 * math.sin(8 * n.x) * math.cos(5 * n.y)) \
            + Vector((0, 0, 0.55))
    from_bm("PC_FuseSplice_Tinder", tb, TINDER)


# ---------------------------------------------------------------- grind rail stanchion (three skins, stacked by code)
def rail_base():
    bm = bmesh.new()
    res = bmesh.ops.create_cone(bm, cap_ends=True, segments=24, radius1=1.1, radius2=1.0, depth=0.3)
    bmesh.ops.translate(bm, vec=(0, 0, 0.15), verts=res["verts"])
    res = bmesh.ops.create_cone(bm, cap_ends=True, segments=20, radius1=0.62, radius2=0.45, depth=0.5)
    bmesh.ops.translate(bm, vec=(0, 0, 0.55), verts=res["verts"])
    base = from_bm("PC_RailBase_Steel", bm, STEEL)
    bevel(base, 0.04, 2, 35)
    bolts = bmesh.new()
    for k in range(4):
        a = math.pi / 4 + k * math.pi / 2
        res = bmesh.ops.create_cone(bolts, cap_ends=True, segments=6, radius1=0.13, radius2=0.13, depth=0.14)
        bmesh.ops.translate(bolts, vec=(0.78 * math.cos(a), 0.78 * math.sin(a), 0.37), verts=res["verts"])
    from_bm("PC_RailBase_Bolt", bolts, BOLT)


def rail_pole():
    bm = bmesh.new()
    res = bmesh.ops.create_cone(bm, cap_ends=True, segments=16, radius1=0.38, radius2=0.38, depth=1.0)
    bmesh.ops.translate(bm, vec=(0, 0, 0.5), verts=res["verts"])
    from_bm("PC_RailPole_Steel", bm, STEEL)


def half_tube(bm, zc, r_in, r_out, length, seg):
    """Lower half of a thick-walled tube along Y, centred at (0, 0, zc)."""
    rings = []
    for y in (-length / 2, length / 2):
        row = []
        for i in range(seg + 1):
            a = math.pi + i * math.pi / seg
            row.append((bm.verts.new((r_out * math.cos(a), y, zc + r_out * math.sin(a))),
                        bm.verts.new((r_in * math.cos(a), y, zc + r_in * math.sin(a)))))
        rings.append(row)
    f, b = rings
    for i in range(seg):
        bm.faces.new((f[i][0], f[i + 1][0], b[i + 1][0], b[i][0]))  # outer
        bm.faces.new((f[i][1], b[i][1], b[i + 1][1], f[i + 1][1]))  # inner
        bm.faces.new((f[i][0], f[i][1], f[i + 1][1], f[i + 1][0]))  # front end
        bm.faces.new((b[i][0], b[i + 1][0], b[i + 1][1], b[i][1]))  # back end
    for row in rings:  # flat lips at the top of both arms
        pass
    for k in (0, seg):
        bm.faces.new((f[k][0], b[k][0], b[k][1], f[k][1]))


def rail_clamp():
    # saddle: collar on the pole top, a curved cradle under a 1-stud pipe running along Y, two bolted ears
    bm = bmesh.new()
    res = bmesh.ops.create_cone(bm, cap_ends=True, segments=16, radius1=0.46, radius2=0.46, depth=0.45)
    bmesh.ops.translate(bm, vec=(0, 0, 0.22), verts=res["verts"])
    # cradle: smooth half pipe under the rail (pipe axis Y, centre z = 1.0, radius 0.5)
    half_tube(bm, 1.0, 0.53, 0.68, 0.7, 16)
    tube(bm, (0, 0, 0.4), (0, 0, 0.45), 0.3, 12)
    clamp = from_bm("PC_RailClamp_Steel", bm, STEEL)
    bevel(clamp, 0.02, 1, 40)
    bolts = bmesh.new()
    for x in (-0.68, 0.68):
        res = bmesh.ops.create_cone(bolts, cap_ends=True, segments=6, radius1=0.11, radius2=0.11, depth=0.5)
        bmesh.ops.rotate(bolts, verts=res["verts"], cent=(0, 0, 0), matrix=Matrix.Rotation(math.pi / 2, 3, "X"))
        bmesh.ops.translate(bolts, vec=(x, 0, 1.0), verts=res["verts"])
    from_bm("PC_RailClamp_Bolt", bolts, BOLT)


def build_all():
    scene()
    for o in list(scene()[1].objects):
        remove(o.name)
    fuse_stake()
    fuse_staple()
    fuse_splice()
    rail_base()
    rail_pole()
    rail_clamp()
    xs = {"FuseStake": -6, "FuseStaple": -3, "FuseSplice": 0, "RailBase": 3, "RailPole": 6, "RailClamp": 9}
    for o in scene()[1].objects:
        o.location = (xs.get(o.name.split("_")[1], 0), 0, 0)
    return report()


# ---------------------------------------------------------------- Pixel Plains voxel mine track (user pick, Oct 3)
# Track = one 4-stud piece along Y (Roblox Z): two square iron rails (tops at z 0.5 = the grind collider's top, gauge 1.5)
# on two chunky oak sleepers. Trestle = one 6-stud tower piece: two legs of stacked voxel log blocks + a plank tie.
# Cap = the cross beam on top of a trestle that the track sits on.
PLANK = mat("PC_Plank", (176, 128, 80), 0.8)
LOG = mat("PC_Log", (107, 74, 43), 0.85)


def vox(bm, c, s, b=0.06):
    """A voxel block with a small bevel added later (bevel() on the whole object)."""
    box(bm, c, s)


def track():
    rails = bmesh.new()
    for x in (-0.75, 0.75):
        box(rails, (x, 0, 0.3), (0.32, 4.0, 0.4))
        for y in (-1, 1):  # tie plates + spikes where the rail meets a sleeper
            box(rails, (x, y, 0.13), (0.6, 0.5, 0.06))
            box(rails, (x + 0.22, y, 0.18), (0.1, 0.1, 0.1))
            box(rails, (x - 0.22, y, 0.18), (0.1, 0.1, 0.1))
    r = from_bm("PC_Track_Iron", rails, IRON)
    bevel(r, 0.03, 1, 40)
    sl = bmesh.new()
    for y in (-1, 1):
        box(sl, (0, y, -0.1), (3.0, 0.8, 0.4))
        box(sl, (1.25, y, -0.1), (0.5, 0.7, 0.44))  # chunky pixel-step ends
        box(sl, (-1.25, y, -0.1), (0.5, 0.7, 0.44))
    o = from_bm("PC_Track_Plank", sl, PLANK)
    bevel(o, 0.04, 1, 40)


def trestle():
    logs = bmesh.new()
    for x in (-1.6, 1.6):
        for k in range(6):  # 6 voxel log blocks, alternating a hair in width so the stack reads as blocks
            w = 1.2 if k % 2 == 0 else 1.14
            box(logs, (x, 0, -3 + 0.5 + k), (w, w, 0.98))
    o = from_bm("PC_Trestle_Log", logs, LOG)
    bevel(o, 0.06, 1, 40)
    pl = bmesh.new()
    box(pl, (0, 0.75, 0.6), (4.4, 0.3, 0.6))
    box(pl, (0, -0.75, -1.4), (4.4, 0.3, 0.6))
    o = from_bm("PC_Trestle_Plank", pl, PLANK)
    bevel(o, 0.04, 1, 40)


def trestle_cap():
    bm = bmesh.new()
    box(bm, (0, 0, 0), (5.0, 1.3, 0.7))
    box(bm, (0, 0, 0.45), (3.4, 1.0, 0.2))
    o = from_bm("PC_TrestleCap_Plank", bm, PLANK)
    bevel(o, 0.05, 1, 40)


def build_pp():
    scene()
    for o in list(scene()[1].objects):
        if o.name.split("_")[1] in ("Track", "Trestle", "TrestleCap"):
            remove(o.name)
    track()
    trestle()
    trestle_cap()
    xs = {"Track": 14, "Trestle": 20, "TrestleCap": 26}
    for o in scene()[1].objects:
        if o.name.split("_")[1] in xs:
            o.location = (xs[o.name.split("_")[1]], 0, 0)
    return [l for l in report().splitlines() if "Track" in l or "Trestle" in l]


# ---------------------------------------------------------------- v2 after the user's It Takes Two refs (Oct 3):
# a single iron rail on a wooden ladder (two side stringers + rungs), plus a gallows support: a side arm off a
# trestle tower with a chain hanging down to a hanger under the rail.
def track2():
    rail = bmesh.new()
    box(rail, (0, 0, 0.27), (0.5, 4.0, 0.46))  # rail top at z 0.5 (the grind collider's top)
    for y in (-1.33, 0, 1.33):
        box(rail, (0, y, 0.02), (0.8, 0.45, 0.06))  # base plate
        for x in (-0.3, 0.3):
            box(rail, (x, y, 0.08), (0.1, 0.1, 0.1))
    o = from_bm("PC_Track2_Iron", rail, IRON)
    bevel(o, 0.03, 1, 40)
    rungs = bmesh.new()
    for y in (-1.33, 0, 1.33):
        box(rungs, (0, y, -0.15), (2.4, 0.55, 0.3))
    o = from_bm("PC_Track2_Plank", rungs, PLANK)
    bevel(o, 0.04, 1, 40)
    st = bmesh.new()
    for x in (-1.05, 1.05):
        box(st, (x, 0, -0.42), (0.34, 4.0, 0.5))
    o = from_bm("PC_Track2_Log", st, LOG)
    bevel(o, 0.04, 1, 40)


def chain():
    bm = bmesh.new()
    n = 8  # 4 studs: 8 links of 0.5
    for k in range(n):
        z = -2 + 0.25 + k * 0.5
        if k % 2 == 0:  # link in the XZ plane
            box(bm, (-0.14, 0, z), (0.07, 0.07, 0.42))
            box(bm, (0.14, 0, z), (0.07, 0.07, 0.42))
            box(bm, (0, 0, z - 0.19), (0.34, 0.07, 0.07))
            box(bm, (0, 0, z + 0.19), (0.34, 0.07, 0.07))
        else:  # turned 90 degrees
            box(bm, (0, -0.14, z), (0.07, 0.07, 0.42))
            box(bm, (0, 0.14, z), (0.07, 0.07, 0.42))
            box(bm, (0, 0, z - 0.19), (0.07, 0.34, 0.07))
            box(bm, (0, 0, z + 0.19), (0.07, 0.34, 0.07))
    from_bm("PC_Chain_Iron", bm, IRON)


def arm():
    # beam along +X from the tower (x 0) to x 5.2, a diagonal brace under it, an iron hook block at the tip
    logs = bmesh.new()
    box(logs, (2.6, 0, 0), (5.6, 1.0, 0.9))
    o = from_bm("PC_Arm_Log", logs, LOG)
    bevel(o, 0.05, 1, 40)
    pl = bmesh.new()
    d = math.atan2(2.4, 3.0)
    box(pl, (1.6, 0, -1.3), (3.9, 0.5, 0.45), rot=Matrix.Rotation(d, 3, "Y"))
    o = from_bm("PC_Arm_Plank", pl, PLANK)
    bevel(o, 0.04, 1, 40)
    hk = bmesh.new()
    box(hk, (4.9, 0, -0.55), (0.5, 0.5, 0.25))
    box(hk, (4.9, 0, -0.75), (0.2, 0.2, 0.3))
    from_bm("PC_Arm_Iron", hk, IRON)


def build_v2():
    scene()
    for o in list(scene()[1].objects):
        if o.name.split("_")[1] in ("Track2", "Chain", "Arm"):
            remove(o.name)
    track2()
    chain()
    arm()
    xs = {"Track2": 32, "Chain": 37, "Arm": 40}
    for o in scene()[1].objects:
        if o.name.split("_")[1] in xs:
            o.location = (xs[o.name.split("_")[1]], 0, 0)
    return [l for l in report().splitlines() if any(k in l for k in ("Track2", "Chain", "Arm"))]
