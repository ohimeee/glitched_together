# Epilogue support notice board (user, Oct 12: the tip jar "in the actual world of epilogue like a post", beside the
# BACK TO LOBBY teleporter). A village notice board: two posts, framed plank board, little pitched plank roof.
# Exec'd inside Blender through the MCP:  exec(open(<this file>).read()); build(); export()
# Reuses the trap kit's helpers (box, mat, new_obj, export). Front looks -Y, origin bottom centre.
#   EP_Prop_SupportBoard_Wood    posts, rails, roof
#   EP_Prop_SupportBoard_Planks  the board (darker; the text SurfaceGui sits just in front of it, y -0.05)
#   EP_Prop_SupportBoard_Iron    corner brackets and foot plates
exec(open(r"C:\Users\User\OneDrive\Desktop\Coding\glitched_together\tools\trap_kit\kit.py").read())

SCENE = "SupportBoard"
COLL = "SupportBoard"
OUT = REPO + r"\blender_assets\support_board"


def build():
    scene()
    wood = mat("EP_BoardWood", (120, 82, 52), 0, 0.75)
    dark = mat("EP_BoardDark", (84, 56, 36), 0, 0.8)
    iron = mat("EP_BoardIron", (50, 50, 55), 0.8, 0.5)
    bm = bmesh.new()
    for x in (-2.7, 2.7):
        box(bm, (0.5, 0.5, 7.4), (x, 0, 3.7), bevel=0.07)  # posts
    for z in (6.15, 2.45):
        box(bm, (5.9, 0.42, 0.35), (0, 0, z), bevel=0.05)  # top / bottom rails
    for x in (-2.5, 2.5):
        box(bm, (0.3, 0.42, 3.9), (x, 0, 4.3), bevel=0.05)  # side rails
    for s in (-1, 1):
        box(bm, (6.8, 0.12, 1.25), (0, s * 0.5, 7.55), RX(s * 1.0), bevel=0.03)  # roof planks
    box(bm, (6.9, 0.22, 0.22), (0, 0, 7.95), bevel=0.04)  # ridge
    new_obj("EP_Prop_SupportBoard_Wood", bm, wood)
    bm = bmesh.new()
    for i in range(7):
        box(bm, (0.66, 0.16, 3.45), (-2.1 + i * 0.7, 0.05, 4.3), bevel=0.03)
    new_obj("EP_Prop_SupportBoard_Planks", bm, dark)
    bm = bmesh.new()
    for x in (-2.7, 2.7):
        for z in (2.45, 6.15):
            box(bm, (0.62, 0.08, 0.5), (x, -0.27, z), bevel=0.02)
        box(bm, (0.56, 0.56, 0.12), (x, 0, 0.06), bevel=0.02)
    new_obj("EP_Prop_SupportBoard_Iron", bm, iron)
