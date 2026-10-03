# Bookshelf + books, book-stack stairs, window + curtains, door, wall mouldings, rug, toy block.
# Positions follow src/lobby/server/LobbyRoom.luau. Run after kit.py.
import random

FLOOR, CEIL = -50, 125
RX0, RX1, RZ0, RZ1 = -160, 160, -230, 75
WIN_X, WIN_Y0, WIN_Y1 = 80, 12, 105
PAINT = mat("PaintedWood", (240, 232, 220), 0.5)
BRASS = mat("Brass", (206, 176, 110), 0.3, 1.0)
PALM = mat("Palette", (255, 255, 255), 0.7)
CURT = mat("Curtain", (214, 156, 176), 0.85)
RUGM = mat("Rug", (226, 214, 236), 0.9)
rnd = random.Random(2026)


def finish(o, angle=35):
    mb = bmesh.new()
    mb.from_mesh(o.data)
    bmesh.ops.recalc_face_normals(mb, faces=mb.faces)
    mb.to_mesh(o.data)
    mb.free()
    smooth(o, angle)
    return o


# ---------------------------------------------------------------- books (palette mesh)
def book_upright(bm, x_back, y, z, bd, bh, bw, color, lean=0.0):
    """Upright book: spine faces -X (the room), fore-edge against x_back. z = its near side, bw its thickness."""
    verts_all = []
    cz = z + bw / 2
    cx = x_back - bd / 2
    board = 0.28
    pieces = [
        ((cx, y + bh / 2, z + board / 2), (bd, bh, board), color),  # boards
        ((cx, y + bh / 2, z + bw - board / 2), (bd, bh, board), color),
        ((cx + 0.35, y + bh / 2, cz), (bd - 0.7, bh - 0.7, bw - 2 * board + 0.02), "pages"),  # page block, recessed
    ]
    for c, s, col in pieces:
        v = box_bm(bm, c, s)
        tag(bm, faces_of(v), col)
        verts_all += v
    # rounded spine: a squashed 8-sided tube along Y
    seg = 8
    ring_lo, ring_hi = [], []
    for k in range(seg + 1):
        a = math.pi / 2 + k / seg * math.pi  # front half (toward -X)
        dz = math.sin(a) * bw / 2
        ring_lo.append(bm.verts.new(rb(x_back - bd + 0.3 - abs(math.cos(a)) * 0.9, y, cz + dz)))
        ring_hi.append(bm.verts.new(rb(x_back - bd + 0.3 - abs(math.cos(a)) * 0.9, y + bh, cz + dz)))
    fs = []
    for k in range(seg):
        fs.append(bm.faces.new((ring_lo[k], ring_lo[k + 1], ring_hi[k + 1], ring_hi[k])))
    fs.append(bm.faces.new(ring_lo))
    fs.append(bm.faces.new(list(reversed(ring_hi))))
    tag(bm, fs, color)
    verts_all += ring_lo + ring_hi
    # gold bands on the spine
    if rnd.random() < 0.7:
        for yy in (y + bh * 0.12, y + bh * 0.85):
            v = box_bm(bm, (x_back - bd - 0.55, yy, cz), (0.3, 0.5, bw * 0.75))
            tag(bm, faces_of(v), "gold")
            verts_all += v
    if lean:
        # tip the book about its bottom spine-side corner, toward +Z
        piv = rb(x_back - bd, y, z + bw)
        bmesh.ops.rotate(bm, verts=verts_all, cent=piv, matrix=Matrix.Rotation(lean, 3, "X"))
    return verts_all


def book_flat(bm, cx, y, cz, w, d, t, yaw, color):
    """Book lying flat: covers top/bottom, spine on the -X side before yaw. Bottom at y."""
    vs = []
    board = 0.3
    for c, s, col in (
        ((cx, y + board / 2, cz), (w, board, d), color),
        ((cx, y + t - board / 2, cz), (w, board, d), color),
        ((cx - w / 2 + 0.4, y + t / 2, cz), (0.8, t, d), color),  # spine
        ((cx + 0.3, y + t / 2, cz), (w - 0.9, t - 2 * board + 0.02, d - 0.6), "pages"),
    ):
        v = box_bm(bm, c, s)
        tag(bm, faces_of(v), col)
        vs += v
    bmesh.ops.rotate(bm, verts=vs, cent=rb(cx, y, cz), matrix=Matrix.Rotation(yaw, 3, "Z"))
    return vs


def build_bookshelf():
    x0, x1, z0, z1 = 120, 158, -200, -120
    H = 124
    parts = []
    # sides with a soft rounded front, a kick cut-out at the floor
    for z in (z0, z1):
        parts.append(rounded_box("tmp_side", (139, FLOOR + H / 2, z), (38, H, 3), 0.9, 3, PAINT))
    parts.append(rounded_box("tmp_back", (157, FLOOR + H / 2, (z0 + z1) / 2), (2, H, z1 - z0), 0.3, 1, PAINT))
    levels = [FLOOR + 2, FLOOR + 26, FLOOR + 50, FLOOR + 74, FLOOR + 98, FLOOR + H - 2]
    for y in levels[:-1]:
        parts.append(rounded_box("tmp_shelf", (139.5, y - 1.25, (z0 + z1) / 2), (37, 2.5, z1 - z0 - 3), 0.9, 3, PAINT))
        # bullnose lip
        parts.append(rounded_box("tmp_lip", (120.6, y - 1.6, (z0 + z1) / 2), (1.6, 3.4, z1 - z0 - 3), 0.7, 3, PAINT))
    # top: overhanging cap + crown moulding, plinth at the base
    parts.append(rounded_box("tmp_cap", (138.5, levels[-1] + 0.25, (z0 + z1) / 2), (43, 2.5, z1 - z0 + 8), 1.0, 3, PAINT))
    bm = bmesh.new()
    prof = [(0, 0), (0.6, 0), (1.4, 0.5), (2.2, 1.4), (2.6, 2.5), (0, 2.5)]
    sweep_bm(bm, prof, (119, levels[-1] - 3.5, z0 - 3), (119, levels[-1] - 3.5, z1 + 3), (-1, 0, 0))
    crown = finish(obj_from_bm("tmp_crown", bm, PAINT))
    parts.append(crown)
    parts.append(rounded_box("tmp_plinth", (121.5, FLOOR + 2.5, (z0 + z1) / 2), (2, 5, z1 - z0 - 2), 0.5, 2, PAINT))
    shelf = join("LK_Shelf_Paint", parts)
    # ladder (oak): two rails leaning 6 deg on the shelf front, rounded rungs
    OAK = mat("Oak", (214, 172, 128), 0.55)
    lx, lz = x0 - 9, (z0 + z1) / 2
    lp = []
    tilt = math.radians(-6)
    for sz in (-6, 6):
        r = rounded_box("tmp_lr", (lx + 4, FLOOR + (H + 6) / 2, lz + sz), (2.2, H + 6, 2.2), 0.8, 3, OAK)
        r.data.transform(Matrix.Translation(-rb(lx + 4, FLOOR + (H + 6) / 2, lz + sz)))
        r.data.transform(Matrix.Rotation(tilt, 4, "Y"))  # Roblox roll about Z == Blender rotation about Y
        r.data.transform(Matrix.Translation(rb(lx + 4, FLOOR + (H + 6) / 2, lz + sz)))
        lp.append(r)
    bm = bmesh.new()
    for k in range(int(H / 8) + 1):
        y = FLOOR + 4 + k * 8
        x = lx + 4 + (y - (FLOOR + (H + 6) / 2)) * math.tan(math.radians(6))  # top leans into the shelf (+X), like the rails
        res = bmesh.ops.create_cone(bm, cap_ends=True, segments=10, radius1=0.75, radius2=0.75, depth=12.4)
        bmesh.ops.rotate(bm, verts=res["verts"], cent=(0, 0, 0), matrix=Matrix.Rotation(math.pi / 2, 3, "X"))
        bmesh.ops.translate(bm, verts=res["verts"], vec=rb(x, y, lz))
    rungs = obj_from_bm("tmp_rungs", bm, OAK)
    smooth(rungs, 50)
    lp.append(rungs)
    ladder = join("LK_Ladder_Oak", lp)

    # books on the shelves
    bm = pbm()
    keep_out = {1: (-150, -132), 4: (-176, -164)}  # the rocket (shelf 2) and the alarm clock (top shelf)
    for i, y in enumerate(levels[:-1]):
        z = z0 + 3
        while z < z1 - 8:
            ko = keep_out.get(i)
            if ko and ko[0] - 2 < z < ko[1]:
                z = ko[1]
                continue
            bw = rnd.uniform(1.8, 3.6)
            bh = rnd.uniform(13, 19.5)
            bd = rnd.uniform(10, 14)
            r = rnd.random()
            if r < 0.06:
                z += rnd.uniform(4, 8)
                continue
            if r < 0.12 and z + 14 < z1 - 8:
                # a little horizontal stack
                yy = y
                for _ in range(rnd.randint(2, 4)):
                    t = rnd.uniform(1.6, 2.6)
                    book_flat(bm, x1 - 9, yy, z + 7, 14, 11, t, rnd.uniform(-0.1, 0.1), rnd.choice(BOOK_COLORS))
                    yy += t
                z += 15
                continue
            lean = 0.0
            if r > 0.95:
                lean = -0.28  # leans on its neighbour
            book_upright(bm, x1 - 2, y, z, bd, bh, bw, rnd.choice(BOOK_COLORS), lean)
            z += bw + (2.8 if lean else 0.15)
    books = obj_from_bm("LK_ShelfBooks_Pal", bm, PALM)
    finish(books, 30)
    palette_uv(books)

    # stair stacks: book-stack stairs from the desk corner down to the floor (BookStackCollider positions)
    bm = pbm()
    for k in range(1, 10):
        x, z, top, w, d = -78, -76 - (k - 1) * 13, -5.4 * k, 20, 16
        yy = FLOOR
        base_yaw = rnd.uniform(-0.15, 0.15)
        while yy < top - 0.01:
            t = min(rnd.uniform(2.2, 3.6), top - yy)
            if t < 1:
                break
            book_flat(bm, x + rnd.uniform(-0.8, 0.8), yy, z + rnd.uniform(-0.8, 0.8), w * rnd.uniform(0.92, 1.05),
                      d * rnd.uniform(0.9, 1.05), t, base_yaw + rnd.uniform(-0.12, 0.12), rnd.choice(BOOK_COLORS))
            yy += t
    stairs = obj_from_bm("LK_StairBooks_Pal", bm, PALM)
    finish(stairs, 30)
    palette_uv(stairs)
    return shelf, ladder, books, stairs


# ---------------------------------------------------------------- window, curtains, rod
def build_window():
    z = RZ1  # wall face
    parts = []
    w = WIN_X * 2
    # casing (architrave) on the room face: moulded strips around the opening + corner rosette blocks
    prof = [(0, 0), (0.8, 0), (1.3, 0.8), (1.5, 2.5), (1.2, 4.2), (1.6, 5.4), (1.0, 6.4), (0, 6.4)]
    bm = bmesh.new()
    # jambs: run vertically -> build as sweeps along Y using a rotated profile: do with boxes + bevel instead
    for sx in (-1, 1):
        parts.append(rounded_box("tmp_jamb", (sx * (WIN_X + 3.2), (WIN_Y0 + WIN_Y1) / 2, z - 0.8), (6.4, WIN_Y1 - WIN_Y0, 1.6), 0.6, 3, PAINT))
        parts.append(rounded_box("tmp_bead", (sx * (WIN_X + 1.6), (WIN_Y0 + WIN_Y1) / 2, z - 1.7), (1.4, WIN_Y1 - WIN_Y0, 0.9), 0.4, 3, PAINT))
        parts.append(rounded_box("tmp_block", (sx * (WIN_X + 3.2), WIN_Y1 + 3.2, z - 1.0), (7.4, 7.4, 2.0), 0.7, 3, PAINT))
    parts.append(rounded_box("tmp_head", (0, WIN_Y1 + 3.2, z - 0.8), (w, 6.4, 1.6), 0.6, 3, PAINT))
    sweep_bm(bm, [(0, 0), (2.2, 0), (2.6, 0.9), (1.8, 1.8), (0, 1.8)], (-WIN_X - 7, WIN_Y1 + 6.9, z), (WIN_X + 7, WIN_Y1 + 6.9, z), (0, 0, -1))
    parts.append(finish(obj_from_bm("tmp_cornice", bm, PAINT)))
    # deep frame inside the opening (the wall is 4 thick) + sashes with glazing bars
    for sx in (-1, 1):
        parts.append(rounded_box("tmp_reveal", (sx * (WIN_X - 0.8), (WIN_Y0 + WIN_Y1) / 2, z + 2), (1.6, WIN_Y1 - WIN_Y0, 4), 0.3, 1, PAINT))
    parts.append(rounded_box("tmp_reveal", (0, WIN_Y1 - 0.8, z + 2), (w, 1.6, 4), 0.3, 1, PAINT))
    for sx in (-1, 1):
        cx = sx * WIN_X / 2
        sw = WIN_X - 2.4
        sh = WIN_Y1 - WIN_Y0 - 3
        cy = WIN_Y0 + 1.5 + sh / 2
        for dx in (-sw / 2 + 1.4, sw / 2 - 1.4):
            parts.append(rounded_box("tmp_stile", (cx + dx, cy, z + 2.2), (2.8, sh, 2.0), 0.4, 2, PAINT))
        for dy in (-sh / 2 + 1.6, sh / 2 - 1.6):
            parts.append(rounded_box("tmp_rail", (cx, cy + dy, z + 2.2), (sw, 3.2, 2.0), 0.4, 2, PAINT))
        # glazing bars: 1 vertical, 3 horizontal
        parts.append(rounded_box("tmp_bar", (cx, cy, z + 2.2), (1.0, sh, 1.2), 0.3, 2, PAINT))
        for k in (1, 2, 3):
            parts.append(rounded_box("tmp_bar", (cx, WIN_Y0 + 1.5 + sh * k / 4, z + 2.2), (sw, 1.0, 1.2), 0.3, 2, PAINT))
    # sill with a rounded nose + apron below
    parts.append(rounded_box("tmp_sill", (0, WIN_Y0 - 1.5, z - 4), (w + 16, 3, 14), 1.2, 4, PAINT))
    parts.append(rounded_box("tmp_apron", (0, WIN_Y0 - 6, z - 0.8), (w + 4, 6, 1.6), 0.6, 3, PAINT))
    win = join("LK_Window_Paint", parts)

    # curtain rod (brass), brackets, finials, rings
    bm = bmesh.new()
    ry, rz = WIN_Y1 + 12, z - 8
    res = bmesh.ops.create_cone(bm, cap_ends=True, segments=16, radius1=0.9, radius2=0.9, depth=w + 70)
    bmesh.ops.rotate(bm, verts=res["verts"], cent=(0, 0, 0), matrix=Matrix.Rotation(math.pi / 2, 3, "Y"))
    bmesh.ops.translate(bm, verts=res["verts"], vec=rb(0, ry, rz))
    for sx in (-1, 1):
        lathe_bm(bm, [(0.01, 0), (1.2, 0), (2.0, 1.0), (2.2, 2.2), (1.4, 3.6), (0.6, 4.2), (0.01, 4.6)], (0, 0, 0), 14)
    rod = obj_from_bm("tmp_rod", bm, BRASS)
    # move the two finials (built at origin pointing up) to the ends, pointing outward
    me = rod.data
    mb = bmesh.new()
    mb.from_mesh(me)
    near = [v for v in mb.verts if v.co.length < 6]
    half = len(near) // 2
    for idx, sx in ((0, -1), (1, 1)):
        vs = near[idx * half:(idx + 1) * half]
        bmesh.ops.rotate(mb, verts=vs, cent=(0, 0, 0), matrix=Matrix.Rotation(-sx * math.pi / 2, 3, "Y"))
        bmesh.ops.translate(mb, verts=vs, vec=rb(sx * (w / 2 + 35), ry, rz))
    for sx in (-1, 1):
        for bx in (WIN_X + 14, WIN_X + 32):
            v = box_bm(mb, (sx * bx, ry + 0.5, (rz + z) / 2), (1.4, 2.0, z - rz))
    # rings at the pleat crowns
    for sx in (-1, 1):
        for k in range(8):
            x = sx * (WIN_X + 7 + k * 3.4)
            res = bmesh.ops.create_cone(mb, cap_ends=True, segments=12, radius1=1.35, radius2=1.35, depth=0.6)
            bmesh.ops.rotate(mb, verts=res["verts"], cent=(0, 0, 0), matrix=Matrix.Rotation(math.pi / 2, 3, "Y"))
            bmesh.ops.translate(mb, verts=res["verts"], vec=rb(x, ry, rz))
    mb.to_mesh(me)
    mb.free()
    remove("LK_CurtainRod_Brass")
    rod.name = "LK_CurtainRod_Brass"
    finish(rod, 40)

    # curtains: pleated panels gathered by tie-backs, hem brushing the floor
    curt = []
    remove("LK_Curtains_Fabric")
    for sx in (-1, 1):
        bm = bmesh.new()
        NU, NV = 56, 48
        xi, xo = WIN_X + 5, WIN_X + 33  # inner (window) edge, outer edge (distance from centre)
        top, bot = ry - 1.5, FLOOR + 0.4
        tie = 22.0
        grid = []
        for j in range(NV + 1):
            v = j / NV
            y = top + (bot - top) * v
            # gather: full at the top, pinched at the tie-back, flaring to the hem
            if y > tie:
                tt = (top - y) / (top - tie)
                f = 1 - 0.62 * (tt ** 1.6)
            else:
                tt = (tie - y) / (tie - bot)
                f = 0.38 + 0.5 * (1 - (1 - tt) ** 2)
            amp = 1.6 / max(f, 0.3) ** 0.6
            row = []
            for i in range(NU + 1):
                u = i / NU
                d = xo - (xo - xi) * u * f
                pleat = math.sin(u * math.pi * 2 * 7.5) * amp * (0.85 + 0.15 * math.sin(v * 7 + u * 3))
                zz = rz + 1.5 + pleat
                row.append(bm.verts.new(rb(sx * d, y, zz)))
            grid.append(row)
        for j in range(NV):
            for i in range(NU):
                a, b, c, dd = grid[j][i], grid[j][i + 1], grid[j + 1][i + 1], grid[j + 1][i]
                bm.faces.new((a, b, c, dd) if sx > 0 else (dd, c, b, a))
        o = obj_from_bm(f"tmp_curtain{sx}", bm, CURT)
        sol = o.modifiers.new("S", "SOLIDIFY")
        sol.thickness = 0.5
        apply_mods(o)
        curt.append(o)
        # tie-back: a soft fabric band round the gathered waist + a tassel
        tb = rounded_box(f"tmp_tie{sx}", (sx * (xo - (xo - xi) * 0.38 / 2), tie, rz + 1.5), ((xo - xi) * 0.4 + 2, 2.2, 6.2), 0.9, 3, CURT)
        curt.append(tb)
    left = finish(join("LK_CurtainL_Fabric", curt[0:2]), 60)
    right = finish(join("LK_CurtainR_Fabric", curt[2:4]), 60)
    return win, rod, (left, right)


# ---------------------------------------------------------------- door
def build_door():
    dx, z = 90, RZ0
    parts = []
    # door leaf with six raised panels (3 rows x 2) on the room face
    parts.append(rounded_box("tmp_leaf", (dx, FLOOR + 70, z + 1), (60, 140, 2), 0.4, 2, PAINT))
    for row, (h, cy) in enumerate(((36, FLOOR + 112), (30, FLOOR + 74), (40, FLOOR + 30))):
        for sx in (-1, 1):
            cx = dx + sx * 13.5
            parts.append(rounded_box("tmp_panelframe", (cx, cy, z + 2.25), (22, h, 0.5), 0.2, 1, PAINT))
            parts.append(rounded_box("tmp_panel", (cx, cy, z + 2.6), (17, h - 5, 0.9), 0.8, 3, PAINT))
    # casing: two legs + head with plinth blocks
    for sx in (-1, 1):
        parts.append(rounded_box("tmp_case", (dx + sx * 33, FLOOR + 72, z + 1.2), (5, 144, 2.4), 0.6, 3, PAINT))
        parts.append(rounded_box("tmp_plinthb", (dx + sx * 33, FLOOR + 5, z + 1.4), (6, 10, 2.8), 0.5, 2, PAINT))
    parts.append(rounded_box("tmp_casehead", (dx, FLOOR + 145, z + 1.2), (71, 5, 2.4), 0.6, 3, PAINT))
    bm = bmesh.new()
    sweep_bm(bm, [(0, 0), (2.4, 0), (3.2, 0.8), (2.8, 1.6), (0, 1.6)], (dx - 37, FLOOR + 147.5, z), (dx + 37, FLOOR + 147.5, z), (0, 0, 1))
    parts.append(finish(obj_from_bm("tmp_cap", bm, PAINT)))
    door = join("LK_Door_Paint", parts)
    # brass knob with a rosette, two hinges
    bm = bmesh.new()
    kx, ky = dx - 22, FLOOR + 62
    lathe_bm(bm, [(0.01, 0), (2.4, 0), (2.4, 0.5), (1.0, 0.8), (0.7, 2.2), (1.9, 3.2), (2.2, 4.2), (1.6, 5.2), (0.01, 5.4)], (0, 0, 0), 18)
    vs = list(bm.verts)
    bmesh.ops.rotate(bm, verts=vs, cent=(0, 0, 0), matrix=Matrix.Rotation(-math.pi / 2, 3, "X"))  # point toward +Roblox Z
    bmesh.ops.translate(bm, verts=vs, vec=rb(kx, ky, z + 2))
    for hy in (FLOOR + 20, FLOOR + 120):
        box_bm(bm, (dx + 29.6, hy, z + 2.1), (1.2, 8, 0.4))
        box_bm(bm, (dx + 30.2, hy, z + 2.4), (0.9, 8.4, 0.9))
    knob = finish(obj_from_bm("LK_Door_Brass", bm, BRASS), 50)
    return door, knob


# ---------------------------------------------------------------- skirting + crown mouldings
def build_trim():
    bm = bmesh.new()
    skirt = [(0, 0), (1.6, 0), (1.6, 5.2), (1.2, 5.6), (1.2, 6.2), (0.8, 6.6), (0.5, 7.2), (0, 7.4)]
    crown = [(0, 0), (0.4, 0), (0.9, 0.6), (1.6, 1.2), (2.6, 1.7), (3.4, 2.6), (3.8, 3.8), (4.2, 4.6), (4.2, 5.4), (0, 5.4)]
    # crown hangs from the ceiling: profile measured downward
    crown_dn = [(d, -h) for d, h in crown]
    walls = [
        ((RX0, RZ0), (RX0, RZ1), (1, 0, 0)),
        ((RX1, RZ1), (RX1, RZ0), (-1, 0, 0)),
        ((RX1, RZ0), (RX0, RZ0), (0, 0, 1)),
        ((RX0, RZ1), (RX1, RZ1), (0, 0, -1)),
    ]
    for (ax, az), (bx, bz), n in walls:
        a, b = Vector((ax, 0, az)), Vector((bx, 0, bz))
        if n == (0, 0, 1):  # door wall: break the skirting at the door casing
            for seg in (((RX1, RZ0), (90 + 36, RZ0)), ((90 - 36, RZ0), (RX0, RZ0))):
                sweep_bm(bm, skirt, (seg[0][0], FLOOR, seg[0][1]), (seg[1][0], FLOOR, seg[1][1]), n)
        else:
            sweep_bm(bm, skirt, (ax, FLOOR, az), (bx, FLOOR, bz), n)
        sweep_bm(bm, list(reversed(crown_dn)), (ax, CEIL, az), (bx, CEIL, bz), n)
    trim = finish(obj_from_bm("LK_Trim_Paint", bm, PAINT), 30)
    return trim


# ---------------------------------------------------------------- rug, toy block
def build_rug():
    bm = bmesh.new()
    prof = [(0.01, 0), (56.5, 0), (59.4, 0.3), (60, 1.2), (59.4, 2.1), (57, 2.5), (40, 2.2), (0.01, 2.2)]
    lathe_bm(bm, prof, (-10, FLOOR, -150), 64)
    return finish(obj_from_bm("LK_Rug_Fur", bm, RUGM), 50)


def build_toyblock():
    """A 1-stud ABC block (scaled per instance in Roblox): bevelled cube with a raised border on every face."""
    parts = [rounded_box("tmp_tb", (0, 300, 0), (0.92, 0.92, 0.92), 0.06, 3, PALM)]
    for n in ((1, 0, 0), (-1, 0, 0), (0, 1, 0), (0, -1, 0), (0, 0, 1), (0, 0, -1)):
        nv = Vector(n)
        c = Vector((0, 300, 0)) + nv * 0.47
        size = Vector((0.98, 0.98, 0.98))
        for i in range(3):
            if n[i] != 0:
                size[i] = 0.06
        # four border strips per face
        for k in range(3):
            if n[k] != 0:
                continue
        axes = [i for i in range(3) if n[i] == 0]
        for ax in axes:
            other = [i for i in axes if i != ax][0]
            for s in (-1, 1):
                cc = c.copy()
                cc[other] += s * 0.43
                ss = size.copy()
                ss[other] = 0.12
                parts.append(rounded_box("tmp_tbb", tuple(cc), tuple(ss), 0.02, 1, PALM))
    blk = join("LK_ToyBlock_Wood", parts)
    return finish(blk, 40)


shelf, ladder, books, stairs = build_bookshelf()
win, rod, curtains = build_window()
door, knob = build_door()
trim = build_trim()
rug = build_rug()
toy = build_toyblock()
print(report())
