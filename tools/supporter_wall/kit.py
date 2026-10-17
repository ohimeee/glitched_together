# Epilogue Supporter Wall (user, Oct 18: "the board should be special and nice art"): a village "hall of stars"
# board, grander than the SUPPORT notice board beside it. Two carved posts with gold star finials, a framed plank
# board (the polaroid podium SurfaceGui sits just in front of it), an arched crest of wooden voussoirs over a dark
# half-disc painted with little cream stars, a big gold star on the keystone, and two iron lantern arms.
# Exec'd inside Blender through the MCP:  exec(open(<this file>).read()); build(); export()
# Reuses the trap kit's helpers (box, cyl, mat, new_obj, export). Front looks -Y, origin bottom centre, 1 unit = 1 stud.
#   EP_Prop_SupporterWall_Wood    posts, frame rails, arch voussoirs, lantern arms' brackets
#   EP_Prop_SupporterWall_Planks  the board + the arch's half-disc (dark)
#   EP_Prop_SupporterWall_Gold    the crest star, post finials, the trim round the board and inside the arch
#   EP_Prop_SupporterWall_Iron    lantern arms + cages, corner brackets, foot plates
#   EP_Prop_SupporterWall_Glow    lantern glass (Neon in Roblox, warm)
#   EP_Prop_SupporterWall_Paint   the little painted stars on the arch
exec(open(r"C:\Users\User\OneDrive\Desktop\Coding\glitched_together\tools\trap_kit\kit.py").read())

SCENE = "SupporterWall"
COLL = "SupporterWall"
OUT = REPO + r"\blender_assets\supporter_wall"

POST_X = 8.2  # post centres
BOARD = (15.2, 9.0)  # plank board width, height
BOARD_Z = (3.2, 12.2)  # bottom, top
ARCH_C = 12.6  # arch centre height
ARCH_R = 7.75  # voussoir mid radius


def RY(a):
    return Matrix.Rotation(a, 4, "Y")


def star(bm, r_out, r_in, depth, at, points=5, spin=0.0):
    """a 5-point star prism standing in the XZ plane (faces -Y), centre `at`"""
    tmp = bmesh.new()
    front, back = [], []
    for i in range(points * 2):
        a = math.pi / 2 + spin + i * math.pi / points
        r = r_out if i % 2 == 0 else r_in
        x, z = math.cos(a) * r, math.sin(a) * r
        front.append(tmp.verts.new((at[0] + x, at[1] - depth / 2, at[2] + z)))
        back.append(tmp.verts.new((at[0] + x, at[1] + depth / 2, at[2] + z)))
    cf = tmp.verts.new((at[0], at[1] - depth / 2 - depth * 0.35, at[2]))  # domed centre, front
    cb = tmp.verts.new((at[0], at[1] + depth / 2, at[2]))
    n = len(front)
    for i in range(n):
        j = (i + 1) % n
        tmp.faces.new((front[i], front[j], cf))
        tmp.faces.new((back[j], back[i], cb))
        tmp.faces.new((front[j], front[i], back[i], back[j]))
    bmesh.ops.recalc_face_normals(tmp, faces=tmp.faces[:])
    _merge(bm, tmp)


def half_disc(bm, r, depth, at, seg=24):
    """a half-disc prism (flat side down) in the XZ plane, centre of the flat side at `at`"""
    tmp = bmesh.new()
    pts = [(math.cos(math.pi * i / seg) * r, math.sin(math.pi * i / seg) * r) for i in range(seg + 1)]
    f = [tmp.verts.new((at[0] + x, at[1] - depth / 2, at[2] + z)) for x, z in pts]
    b = [tmp.verts.new((at[0] + x, at[1] + depth / 2, at[2] + z)) for x, z in pts]
    tmp.faces.new(f)
    tmp.faces.new(list(reversed(b)))
    for i in range(len(pts)):
        j = (i + 1) % len(pts)
        tmp.faces.new((f[j], f[i], b[i], b[j]))
    bmesh.ops.recalc_face_normals(tmp, faces=tmp.faces[:])
    _merge(bm, tmp)


def arc_boxes(bm, r, n, size, y, bevel=0.05, a0=0.0, a1=math.pi):
    """n boxes along a half arc of radius r round (0, y, ARCH_C), each tangent to it"""
    for i in range(n):
        a = a0 + (a1 - a0) * (i + 0.5) / n
        at = (math.cos(a) * r, y, ARCH_C + math.sin(a) * r)
        box(bm, size, at, RY(-(a - math.pi / 2)), bevel=bevel)


def build():
    scene()
    wood = mat("EP_WallWood", (120, 82, 52), 0, 0.75)
    dark = mat("EP_WallDark", (70, 46, 32), 0, 0.8)
    gold = mat("EP_WallGold", (232, 182, 76), 0.9, 0.3)
    iron = mat("EP_WallIron", (50, 50, 55), 0.8, 0.5)
    glow = mat("EP_WallGlow", (255, 196, 130), 0, 0.4)
    paint = mat("EP_WallPaint", (240, 228, 200), 0, 0.7)

    # wood: posts (stepped top), frame rails, arch voussoirs, keystone block
    bm = bmesh.new()
    for x in (-POST_X, POST_X):
        box(bm, (0.9, 0.9, 13.2), (x, 0, 6.6), bevel=0.08)
        box(bm, (1.15, 1.15, 0.4), (x, 0, 13.3), bevel=0.06)  # cap
        box(bm, (1.2, 1.2, 0.6), (x, 0, 0.6), bevel=0.06)  # plinth
    for z in BOARD_Z:
        box(bm, (BOARD[0] + 1.0, 0.5, 0.45), (0, 0, z), bevel=0.06)
    for x in (-BOARD[0] / 2 - 0.25, BOARD[0] / 2 + 0.25):
        box(bm, (0.45, 0.5, BOARD_Z[1] - BOARD_Z[0]), (x, 0, sum(BOARD_Z) / 2), bevel=0.06)
    arc_boxes(bm, ARCH_R, 11, (2.05, 0.6, 0.9), 0)
    box(bm, (1.5, 0.7, 1.2), (0, 0, ARCH_C + ARCH_R + 0.1), bevel=0.08)  # keystone
    new_obj("EP_Prop_SupporterWall_Wood", bm, wood)

    # planks: the board (vertical planks) + the arch's half-disc
    bm = bmesh.new()
    n = 11
    w = BOARD[0] / n
    for i in range(n):
        box(bm, (w - 0.05, 0.16, BOARD[1]), (-BOARD[0] / 2 + w * (i + 0.5), 0.12, sum(BOARD_Z) / 2), bevel=0.03)
    half_disc(bm, ARCH_R - 0.35, 0.16, (0, 0.12, ARCH_C - 0.2))
    new_obj("EP_Prop_SupporterWall_Planks", bm, dark)

    # gold: crest star on the keystone, finials, a thin trim inside the frame and along the arch's inner edge
    bm = bmesh.new()
    star(bm, 1.9, 0.85, 0.45, (0, -0.25, ARCH_C + ARCH_R + 1.6))
    for x in (-POST_X, POST_X):
        cyl(bm, 0.18, 0.5, (x, 0, 13.75))
        star(bm, 0.75, 0.33, 0.3, (x, 0, 14.6))
    for z in (BOARD_Z[0] + 0.3, BOARD_Z[1] - 0.3):
        box(bm, (BOARD[0] - 0.3, 0.08, 0.12), (0, -0.0, z), bevel=0.02)
    for x in (-BOARD[0] / 2 + 0.15, BOARD[0] / 2 - 0.15):
        box(bm, (0.12, 0.08, BOARD[1] - 0.6), (x, -0.0, sum(BOARD_Z) / 2), bevel=0.02)
    arc_boxes(bm, ARCH_R - 0.55, 20, (1.25, 0.1, 0.14), -0.05, bevel=0.02)
    new_obj("EP_Prop_SupporterWall_Gold", bm, gold)

    # iron: lantern arms out from the posts' fronts, cages, corner brackets, foot plates
    bm = bmesh.new()
    for s in (-1, 1):
        x = s * POST_X
        box(bm, (0.16, 1.6, 0.16), (x, -1.2, 11.6), bevel=0.02)  # arm out the front
        box(bm, (0.12, 0.12, 0.5), (x, -1.95, 11.35), bevel=0.01)  # hanger
        box(bm, (0.9, 0.9, 0.14), (x, -1.95, 11.05), bevel=0.03)  # lantern cap
        box(bm, (0.9, 0.9, 0.12), (x, -1.95, 9.75), bevel=0.03)  # lantern base
        for dx in (-0.4, 0.4):
            for dy in (-0.4, 0.4):
                box(bm, (0.08, 0.08, 1.2), (x + dx, -1.95 + dy, 10.4), bevel=0.0)
        box(bm, (1.3, 1.3, 0.12), (x, 0, 0.06), bevel=0.02)  # foot plate
        for z in BOARD_Z:
            box(bm, (0.7, 0.08, 0.6), (s * (BOARD[0] / 2 + 0.25), -0.29, z), bevel=0.02)
    new_obj("EP_Prop_SupporterWall_Iron", bm, iron)

    # glow: the lantern glass
    bm = bmesh.new()
    for s in (-1, 1):
        box(bm, (0.7, 0.7, 1.15), (s * POST_X, -1.95, 10.4), bevel=0.05)
    new_obj("EP_Prop_SupporterWall_Glow", bm, glow)

    # paint: little cream stars on the arch's dark half-disc, round the crest
    bm = bmesh.new()
    rng = [(-4.6, 1.2, 0.42), (-2.6, 3.6, 0.32), (0.0, 5.0, 0.5), (2.7, 3.4, 0.36), (4.8, 1.4, 0.3),
           (-1.3, 1.6, 0.26), (1.5, 1.8, 0.28), (-5.6, 3.0, 0.22), (5.4, 3.3, 0.24), (-0.9, 3.4, 0.2), (1.0, 4.0, 0.22)]
    for x, dz, r in rng:
        star(bm, r, r * 0.45, 0.06, (x, 0.02, ARCH_C - 0.2 + dz), spin=x * 0.2)
    new_obj("EP_Prop_SupporterWall_Paint", bm, paint)


def report():
    for ob in bpy.data.collections[COLL].objects:
        tris = sum(len(p.vertices) - 2 for p in ob.data.polygons)
        c = sum((ob.matrix_world @ Vector(b) for b in ob.bound_box), Vector()) / 8
        d = ob.dimensions
        print(ob.name, "tris", tris, "centre roblox", (round(-c.x, 3), round(c.z, 3), round(c.y, 3)),
              "size roblox", (round(d.x, 3), round(d.z, 3), round(d.y, 3)))
