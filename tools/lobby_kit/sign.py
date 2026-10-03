# The lobby's instruction sign (user, Oct 3, 2026: "make that board realistic too and stylish"): a double-sided A-frame
# chalkboard ("sandwich board") standing in the middle of the capsule ring on the desk. Oak frames, slate boards, a
# chalk tray, brass hinges, chalk sticks and a felt eraser at its foot. The chalk lettering is a SurfaceGui in
# LobbyBuilder, laid on the same board planes (keep HINGE / FOOT / BOARD in sync with LobbyBuilder.SIGN).
# Run after kit.py.
HINGE = (0.0, 22.0, -14.0)  # top hinge (Roblox), the ring centre on the desk
SPREAD = 6.0  # each foot this far out from the hinge along Z
W, H = 16.0, 17.0  # slate board size
BOARD_AT = 11.0  # board centre: this far down the slope from the hinge
OAK = mat("Oak", (214, 172, 128), 0.55)
SLATE = mat("Slate", (44, 56, 52), 0.85)
BRASS = mat("Brass", (206, 176, 110), 0.3, 1.0)
PALM = mat("Palette", (255, 255, 255), 0.7)


def panel_frame(side):
    """Matrix (Blender space) mapping panel-local coords (x right, y up the slope, z out of the board) for one side
    (-1 = front, facing -Z; +1 = back)."""
    hx, hy, hz = HINGE
    foot = Vector((0, 0, hz + side * SPREAD))
    hinge = Vector((hx, hy, hz))
    down = (foot - hinge).normalized()
    up = -down
    right = Vector((1, 0, 0)) if side < 0 else Vector((-1, 0, 0))
    normal = right.cross(up)  # Roblox: LookVector = -(right x up) ... we want the outward normal
    normal = -normal
    return hinge, up, right, normal


def to_b(p):
    return rb(p.x, p.y, p.z)


def panel_box(bm, side, cx, cy, cz, sx, sy, sz):
    """A box in panel-local coords (cy measured down the slope from the hinge, cz out of the board)."""
    hinge, up, right, normal = panel_frame(side)
    verts = box_bm(bm, (0, 0, 0), (sx, sy, sz))  # local, axis-aligned in Roblox terms (x, y, z)
    for v in verts:
        # v.co is in Blender space of a Roblox-local box: undo rb() to get Roblox-local (x, y, z)
        lx, ly, lz = -v.co.x, v.co.z, v.co.y
        p = Vector(HINGE) + right * (cx + lx) + up * (-cy + ly) + normal * (cz + lz)
        v.co = to_b(p)
    return verts


def build_sign():
    L = math.sqrt(HINGE[1] ** 2 + SPREAD ** 2)  # slope length hinge -> foot
    bm = bmesh.new()
    for side in (-1, 1):
        # stiles run the full slope (they are the legs), rails above and below the board
        for sx in (-1, 1):
            panel_box(bm, side, sx * (W / 2 + 1.0), L / 2 - 0.3, 0.0, 2.0, L + 0.6, 1.4)
        panel_box(bm, side, 0, BOARD_AT - H / 2 - 1.0, 0.0, W + 4, 2.0, 1.4)  # top rail
        panel_box(bm, side, 0, BOARD_AT + H / 2 + 1.0, 0.0, W + 4, 2.0, 1.4)  # bottom rail
        if side < 0:  # chalk tray on the front
            panel_box(bm, side, 0, BOARD_AT + H / 2 + 2.2, 1.4, W, 0.6, 2.0)
            panel_box(bm, side, 0, BOARD_AT + H / 2 + 1.7, 2.3, W, 1.2, 0.4)
    frame = obj_from_bm("LK_Sign_Oak", bm, OAK)
    bevel(frame, 0.35, 2, 40)
    smooth(frame, 35)
    bm = bmesh.new()
    for side in (-1, 1):
        panel_box(bm, side, 0, BOARD_AT, -0.1, W + 0.4, H + 0.4, 0.6)
    board = obj_from_bm("LK_SignBoard_Slate", bm, SLATE)
    bm = bmesh.new()
    for sx in (-1, 1):  # brass hinges across the top
        lathe_bm(bm, [(0.01, -2), (0.7, -2), (0.7, 2), (0.01, 2)], (0, 0, 0), 10)
    hinges = obj_from_bm("tmp_h", bm, BRASS)
    me = hinges.data
    mb = bmesh.new()
    mb.from_mesh(me)
    allv = list(mb.verts)
    n = len(allv) // 2
    for i, sx in enumerate((-1, 1)):
        vs = allv[i * n:(i + 1) * n]
        bmesh.ops.rotate(mb, verts=vs, cent=(0, 0, 0), matrix=Matrix.Rotation(math.pi / 2, 3, "Y"))
        bmesh.ops.translate(mb, verts=vs, vec=rb(sx * (W / 2 + 1.0), HINGE[1] + 0.2, HINGE[2]))
    mb.to_mesh(me)
    mb.free()
    remove("LK_SignHinge_Brass")
    hinges.name = "LK_SignHinge_Brass"
    smooth(hinges, 50)
    # chalk sticks on the tray + a felt eraser at the foot
    bm = pbm()
    for i, (dx, col) in enumerate(((-4.5, "white"), (-2.5, "pink"), (3.0, "noteyellow"))):
        vs = panel_box(bm, -1, dx, BOARD_AT + H / 2 + 1.6, 2.3 + 0.6, 2.4, 0.55, 0.55)
        tag(bm, faces_of(vs), col)
    hx, hy, hz = HINGE
    vs = box_bm(bm, (5.5, 0.9, hz - SPREAD - 4.5), (6, 1.0, 2.6))
    tag(bm, faces_of(vs), "darkwood")
    vs = box_bm(bm, (5.5, 0.2, hz - SPREAD - 4.5), (6, 0.6, 2.6))
    tag(bm, faces_of(vs), "navy")
    bits = obj_from_bm("LK_SignBits_Pal", bm, PALM)
    bevel(bits, 0.12, 1, 40)
    palette_uv(bits)
    return frame, board, hinges, bits


build_sign()
print("\n".join(l for l in report().splitlines() if "Sign" in l))
