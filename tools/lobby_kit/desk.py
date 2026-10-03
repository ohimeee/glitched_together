# The kids' desk + chair (LobbyRoom.luau colliders: top 200x4x130 with its surface at y 0, legs at (+-94, +-59),
# drawer pedestal x 46..94 / y -48..-6 / z -60..60 with fronts on -Z, chair at (-36, -86) yaw 0.12).
# Oak (LobbyDesk), brass handles. Run after kit.py.
FLOOR = -50
OAK = mat("Oak", (214, 172, 128), 0.55)
BRASS = mat("Brass", (206, 176, 110), 0.3, 1.0)


def turned_leg(bm, x, z, top, bottom=FLOOR, scale=1.0):
    """A turned leg from `bottom` up to `top` (Roblox y), radius ~2.6*scale, with beads, a vase and a foot."""
    H = top - bottom
    s = scale
    prof = [
        (0.01, 0),
        (2.0 * s, 0),
        (2.3 * s, 0.6),
        (2.3 * s, 1.6),
        (1.7 * s, 2.4),
        (1.5 * s, H * 0.18),
        (1.9 * s, H * 0.22),
        (2.2 * s, H * 0.3),
        (2.0 * s, H * 0.42),
        (1.6 * s, H * 0.55),
        (1.4 * s, H * 0.68),
        (1.8 * s, H * 0.72),
        (2.1 * s, H * 0.75),
        (1.8 * s, H * 0.78),
        (1.5 * s, H * 0.82),
        (2.4 * s, H * 0.87),
        (2.6 * s, H * 0.9),
        (2.6 * s, H),
        (0.01, H),
    ]
    lathe_bm(bm, prof, (x, bottom, z), 20)


def build_desk():
    # top slab with a softly rounded edge (thumbnail profile: big radius on top, small below)
    top = rounded_box("LK_Desk_Oak", (0, -2, 0), (200, 4, 130), 1.4, 4, OAK)
    parts = [top]
    # apron rails under the top, between the legs
    for sz in (-1, 1):
        parts.append(rounded_box("tmp_apronz", (-12, -7.5, sz * 59), (176, 7, 2.4), 0.5, 2, OAK))
    parts.append(rounded_box("tmp_apronx", (-94, -7.5, 0), (2.4, 7, 112), 0.5, 2, OAK))
    # leg tops: square blocks under the top, then turned legs to the floor
    bm = bmesh.new()
    for sx in (-1, 1):
        for sz in (-1, 1):
            turned_leg(bm, sx * 94, sz * 59, -11.5)
    legs = obj_from_bm("tmp_legs", bm, OAK)
    smooth(legs, 35)
    parts.append(legs)
    for sx in (-1, 1):
        for sz in (-1, 1):
            parts.append(rounded_box("tmp_legblock", (sx * 94, -8, sz * 59), (6, 8, 6), 0.6, 2, OAK))
    # drawer pedestal: carcass, plinth, three panelled drawers
    parts.append(rounded_box("tmp_ped", (70, -27, 0), (48, 42, 120), 0.8, 2, OAK))
    parts.append(rounded_box("tmp_plinth", (70, -49, 0.5), (45, 2, 117), 0.4, 2, OAK))
    for k in range(3):
        y = FLOOR + 8 + k * 13 + 5.5  # drawer centre (as the old fronts)
        parts.append(rounded_box("tmp_df", (70, y, -60.6), (43, 11.6, 1.6), 0.5, 2, OAK))
        parts.append(rounded_box("tmp_dp", (70, y, -61.6), (35, 7, 0.8), 0.6, 3, OAK))  # raised panel
    # side panels on the pedestal's open side (x 46) for a framed look
    parts.append(rounded_box("tmp_pedframe", (45.6, -27, 0), (1.2, 38, 112), 0.4, 2, OAK))
    desk = join("LK_Desk_Oak", parts)
    uv_studs(desk)
    # brass cup handles + keyhole escutcheons
    bm = bmesh.new()
    for k in range(3):
        y = FLOOR + 8 + k * 13 + 5.5
        res = bmesh.ops.create_cone(bm, cap_ends=True, segments=16, radius1=2.0, radius2=2.0, depth=0.8)
        bmesh.ops.rotate(bm, verts=res["verts"], cent=(0, 0, 0), matrix=Matrix.Rotation(math.pi / 2, 3, "X"))
        bmesh.ops.translate(bm, verts=res["verts"], vec=rb(70, y + 0.6, -62.4))
        # a bar pull on two posts
        bar = bmesh.ops.create_cube(bm, size=1.0)
        bmesh.ops.scale(bm, vec=(7.0, 0.9, 0.9), verts=bar["verts"])
        bmesh.ops.translate(bm, verts=bar["verts"], vec=rb(70, y - 1.4, -63.0))
        for sx in (-3.2, 3.2):
            post = bmesh.ops.create_cube(bm, size=1.0)
            bmesh.ops.scale(bm, vec=(0.9, 1.6, 0.9), verts=post["verts"])
            bmesh.ops.translate(bm, verts=post["verts"], vec=rb(70 + sx, y - 1.4, -62.2))
    brass = obj_from_bm("LK_Desk_Brass", bm, BRASS)
    bevel(brass, 0.2, 2, 50)
    smooth(brass, 50)
    uv_studs(brass)
    return desk, brass


def build_chair():
    x0, z0, yaw = -36, -86, 0.12
    parts = []
    bm = bmesh.new()
    leg_xy = [(sx * 20, sz * 19) for sx in (-1, 1) for sz in (-1, 1)]
    for lx, lz in leg_xy:
        turned_leg(bm, lx, lz, 30, 0, 0.75)
    legs = obj_from_bm("tmp_clegs", bm, OAK)
    smooth(legs, 35)
    parts.append(legs)
    # seat: thick, softly rounded, slightly saddled (two layers)
    parts.append(rounded_box("tmp_seat", (0, 32, 0), (46, 4, 44), 1.6, 4, OAK))
    # stretchers between the legs
    for sz in (-1, 1):
        parts.append(rounded_box("tmp_st", (0, 9, sz * 19), (38, 1.6, 1.6), 0.5, 2, OAK))
    for sx in (-1, 1):
        parts.append(rounded_box("tmp_st", (sx * 20, 12, 0), (1.6, 1.6, 36), 0.5, 2, OAK))
    # back: two posts, a curved top rail, a middle rail, five spindles (the back faces -Z, behind the sitter at -19)
    bz = -21
    for sx in (-1, 1):
        parts.append(rounded_box("tmp_post", (sx * 20.5, 34 + 22, bz), (3.2, 44, 3.2), 1.0, 3, OAK))
    rail = arch_rail("tmp_rail", -21, 21, 74, bz, 8, 2.6, 3.5, OAK, bulge=1.8)
    parts.append(rail)
    parts.append(rounded_box("tmp_mrail", (0, 46, bz), (40, 3, 2.2), 0.6, 2, OAK))
    for k in range(5):
        sx = -14 + k * 7
        parts.append(rounded_box("tmp_spindle", (sx, 59, bz), (2.2, 26, 1.6), 0.7, 3, OAK))
    chair = join("LK_Chair_Oak", parts)
    # place: chair modeled with its floor at y 0 around (0, 0); move to the room (floor -50) and turn
    chair.data.transform(Matrix.Rotation(yaw, 4, "Z"))  # Roblox yaw +a about Y == Blender +a about Z
    chair.data.transform(Matrix.Translation(rb(x0, FLOOR, z0)))
    uv_studs(chair)
    return chair


desk, brass = build_desk()
chair = build_chair()


def test_cubes():
    a = rounded_box("LK_TestStuds_Oak", (0, 30, -200), (10, 10, 10), 0.3, 1, OAK)
    uv_studs(a)
    b = rounded_box("LK_TestUnit_Oak", (20, 30, -200), (10, 10, 10), 0.3, 1, OAK)
    uv_studs(b, 10.0)


test_cubes()
print(report())
