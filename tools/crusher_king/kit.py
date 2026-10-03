# Crusher King kit (exec'd inside Blender through the MCP: exec(open(<this file>).read())).
# The World 1 boss as a real object at giant scale (It Takes Two's Toolbox boss: a worn real thing, its face made of
# its own parts): a pixel-art king built from painted wooden toy cubes, paint chipped to bare beech on the edges,
# Glitch-magenta static cubes where the infection shows. One mesh per grey-box part (CK_<Part>), modeled centred at
# the origin at the part's size (Blender X = -Roblox x, Blender Y = Roblox z, Blender Z = Roblox y; front = -Y).
# All faces UV'd into textures/king_palette.png (make_king_palette.py): each cube face spans its whole swatch so
# the bevel lands on the chipped rim. Placed by ArtService/PixelPlains.luau skins (King*).
import bpy
import bmesh
import random
from mathutils import Vector

REPO = r"C:\Users\User\OneDrive\Desktop\Coding\glitched_together"
SCENE = "CrusherKing"
COLL = "CrusherKingKit"
N = 8  # atlas grid
SWATCHES = [
    "robe", "robe_dark", "gold", "gold_dark", "ermine", "black", "skin", "skin_shade", "brown", "hair", "white",
    "rose", "ruby", "sapphire", "iron", "iron_dark", "kai", "glitch", "velvet", "leather", "wood",
]


def scene():
    sc = bpy.data.scenes.get(SCENE) or bpy.data.scenes.new(SCENE)
    bpy.context.window.scene = sc
    c = bpy.data.collections.get(COLL) or bpy.data.collections.new(COLL)
    if c.name not in sc.collection.children:
        sc.collection.children.link(c)
    return sc, c


def palette_material():
    m = bpy.data.materials.get("CK_Palette")
    if m:
        return m
    m = bpy.data.materials.new("CK_Palette")
    m.use_nodes = True
    nt = m.node_tree
    bsdf = next(n for n in nt.nodes if n.type == "BSDF_PRINCIPLED")
    tex = nt.nodes.new("ShaderNodeTexImage")
    tex.image = bpy.data.images.load(REPO + r"\textures\king_palette.png", check_existing=True)
    tex.interpolation = "Closest"
    nt.links.new(tex.outputs["Color"], bsdf.inputs["Base Color"])
    bsdf.inputs["Roughness"].default_value = 0.55
    return m


def remove(name):
    o = bpy.data.objects.get(name)
    if o:
        me = o.data
        bpy.data.objects.remove(o, do_unlink=True)
        if me and me.users == 0:
            bpy.data.meshes.remove(me)


def voxels(name, size, counts, paint, bevel=0.14, seed=1):
    """size: Roblox (x, y, z) studs; counts: cubes per axis; paint(ix, iy, iz) -> swatch name or None (empty).
    ix runs +Roblox x, iy up, iz from the FRONT (Roblox -z) backwards."""
    rng = random.Random(seed)
    sx, sy, sz = (size[i] / counts[i] for i in range(3))
    cells = {}
    for ix in range(counts[0]):
        for iy in range(counts[1]):
            for iz in range(counts[2]):
                sw = paint(ix, iy, iz)
                if sw:
                    cells[(ix, iy, iz)] = sw
    bm = bmesh.new()
    owner = {}
    for (ix, iy, iz), sw in cells.items():
        nb = [(1, 0, 0), (-1, 0, 0), (0, 1, 0), (0, -1, 0), (0, 0, 1), (0, 0, -1)]
        if all((ix + a, iy + b, iz + c) in cells for a, b, c in nb):
            continue  # buried
        # Roblox cube bounds -> Blender
        x0 = -size[0] / 2 + ix * sx
        y0 = -size[1] / 2 + iy * sy
        z0 = -size[2] / 2 + iz * sz
        g = 0.04  # a hairline gap: separate blocks, not one slab
        bx = (-(x0 + sx - g), -(x0 + g))
        by = (z0 + g, z0 + sz - g)  # Blender Y = Roblox z (front = -Y = low iz)
        bz = (y0 + g, y0 + sy - g)
        res = bmesh.ops.create_cube(bm, size=1)
        vs = res["verts"]
        for v in vs:
            v.co = Vector((
                bx[0] if v.co.x < 0 else bx[1],
                by[0] if v.co.y < 0 else by[1],
                bz[0] if v.co.z < 0 else bz[1],
            ))
        idx = SWATCHES.index(sw) * 2 + rng.randrange(2)
        for f in {f for v in vs for f in v.link_faces}:
            owner[f] = (idx, (bx, by, bz))
    edges = list(bm.edges)
    b = min(sx, sy, sz) * bevel
    res = bmesh.ops.bevel(bm, geom=edges + list(bm.verts), offset=b, segments=1, affect="EDGES", profile=0.5)
    bm.normal_update()
    uv = bm.loops.layers.uv.verify()
    # after the bevel, find each face's cube by its centre
    boxes = list({id(v[1]): v for v in owner.values()}.values())
    inset = 0.03
    for f in bm.faces:
        c = f.calc_center_median()
        hit = None
        for idx, (bx, by, bz) in boxes:
            if bx[0] - 1e-3 <= c.x <= bx[1] + 1e-3 and by[0] - 1e-3 <= c.y <= by[1] + 1e-3 and bz[0] - 1e-3 <= c.z <= bz[1] + 1e-3:
                hit = (idx, (bx, by, bz))
                break
        if not hit:
            continue
        idx, (bx, by, bz) = hit
        r, col = divmod(idx, N)
        n = f.normal
        ax = max(range(3), key=lambda i: abs(n[i]))
        lo = (bx[0], by[0], bz[0])
        ext = (bx[1] - bx[0], by[1] - by[0], bz[1] - bz[0])
        a, bb = [(1, 2), (0, 2), (0, 1)][ax]
        for l in f.loops:
            p = l.vert.co
            fu = (p[a] - lo[a]) / ext[a]
            fv = (p[bb] - lo[bb]) / ext[bb]
            fu = inset + max(0, min(1, fu)) * (1 - 2 * inset)
            fv = inset + max(0, min(1, fv)) * (1 - 2 * inset)
            l[uv].uv = ((col + fu) / N, 1 - (r + 1) / N + fv / N)
    remove(name)
    me = bpy.data.meshes.new(name)
    bm.to_mesh(me)
    bm.free()
    o = bpy.data.objects.new(name, me)
    scene()[1].objects.link(o)
    me.materials.append(palette_material())
    return o


def tris(o):
    return sum(len(p.vertices) - 2 for p in o.data.polygons)


# Pixel maps -------------------------------------------------------------------------------------------------------
# Face rows are written top to bottom, columns left to right AS THE PLAYERS SEE HIM (they stand at -z looking +z, so
# their right is -x): column c -> ix = nx - 1 - c.

HEAD_FACE = [
    "SSSSSSSS",
    "HHSSSSHH",
    "SWKSSKWS",
    "RSSssSSG",
    "BBBssBBG",
    "BBBKKBBB",
    ".BBBBBB.",
]
FACE_KEY = {
    "S": "skin", "s": "skin_shade", "B": "brown", "H": "hair", "K": "black", "W": "white", "R": "rose",
    "G": "glitch", ".": None,
}


def head(ix, iy, iz):
    nx, ny = 8, 7
    if iz == 0:
        return FACE_KEY[HEAD_FACE[ny - 1 - iy][nx - 1 - ix]]
    if iy <= 1 and iz <= 2 and 0 < ix < nx - 1:
        return "brown"  # the beard wraps under the jaw
    if iy == 0:
        return None if iz <= 2 else "skin_shade"
    if iz >= 4 and iy >= 2 or iy == ny - 1 and iz >= 1:
        return "hair"
    if iz == 3 and iy == 3 and ix in (0, nx - 1):
        return "skin_shade"  # ears
    if ix == 0 and iy in (2, 3) and iz in (1, 2):
        return "glitch"  # the infection spreading round his cheek
    return "skin"


def crown(ix, iy, iz):
    n = 7
    ring = ix in (0, n - 1) or iz in (0, n - 1)
    if not ring:
        return None
    if iy <= 1:
        if iz == 0 and iy == 1:
            return {3: "ruby", 1: "sapphire", 5: "sapphire"}.get(ix, "gold")
        return "gold" if iy == 1 else "gold_dark"
    # points: every other cube round the ring, the corners always
    k = ix + iz
    corner = ix in (0, n - 1) and iz in (0, n - 1)
    if corner or k % 2 == 0:
        if iy == 3:
            return "ruby" if corner else "gold"
        return "gold"
    return None


def torso(ix, iy, iz):
    if iy == 5:
        return "black" if (ix + iz) % 3 == 0 else "ermine"  # ermine collar with tail spots
    if iz == 3 or ix in (0, 8):
        return "velvet" if iy >= 2 else "ruby"  # the cape hangs down his back and sides
    if iz == 0 and iy == 4 and ix in (3, 4, 5):
        return "brown"  # beard tip over the chest
    if iz == 0 and ix == 4:
        return "gold" if iy % 2 == 1 else "robe_dark"  # buttons down the front
    if iz == 0 and ix in (1, 7):
        return "ermine"  # ermine edge of the cape
    if (ix, iy, iz) in ((6, 2, 0), (7, 3, 1)):
        return "glitch"
    return "robe_dark" if iy == 0 else "robe"


def shoulder(ix, iy, iz):
    if iy == 1:
        return "ermine" if iz == 0 else "velvet"
    return "gold" if (ix + iz) % 2 == 0 else "gold_dark"  # fringed epaulette under the cape


def arm(ix, iy, iz):
    if iy == 0:
        return "gold"
    if iy == 1:
        return "ermine"
    return "robe_dark" if iy == 4 else "robe"


def fist(ix, iy, iz):
    if iy == 2:
        return "kai"  # gauntlet cuff: Kai's freeze target
    if iz == 0:
        return "iron_dark" if ix % 2 == 0 else "iron"  # fingers
    if iy == 0 and (ix in (0, 3) or iz == 3):
        return "iron_dark"
    return "iron"


def belt(ix, iy, iz):
    if ix in (2, 3):
        return "black" if iy == 1 and ix == 2 else "gold"  # buckle with a prong
    return "leather"


def lap(ix, iy, iz):
    if iy == 0 and iz <= 1 and ix in (1, 2, 3, 6, 7, 8):
        return "black"  # boots
    if iy == 0:
        return "gold"  # hem
    if iy == 3:
        return "robe"
    if iz == 0 and ix in (2, 3, 6, 7) and iy == 2:
        return "robe_dark"  # knees
    if (ix, iy, iz) == (9, 1, 0):
        return "glitch"
    return "robe"


def throne(ix, iy, iz):
    if iy == 3 and 0 < ix < 10 and 0 < iz < 6:
        return "velvet"
    if iy == 3:
        return "gold"
    return "gold_dark" if ix in (0, 10) and iz in (0, 6) else "wood"


THRONE_BACK = [
    "...G.G.G...",
    ".GGGGGGGGG.",
    "GGVVVGVVVGG",
    "GVVVGRGVVVG",
    "GVVVVGVVVVG",
    "GVVVVVVVVVG",
    "GVVVVVVVVVG",
    "GVVVVVVVVVG",
    "GVVVVVVVVVG",
    "GVVVVVVVVVG",
    "GVVVVVVVVVG",
    "GGGGGGGGGGG",
]
BACK_KEY = {"G": "gold", "V": "velvet", "R": "ruby", ".": None}


def throne_back(ix, iy, iz):
    return BACK_KEY[THRONE_BACK[11 - iy][10 - ix]]


PARTS = {
    # name: (Roblox size, cube counts, painter)
    "CK_Head": ((20, 18, 18), (8, 7, 7), head),
    "CK_Crown": ((14, 8, 14), (7, 4, 7), crown),
    "CK_Torso": ((36, 24, 16), (9, 6, 4), torso),
    "CK_Shoulder": ((12, 6, 14), (3, 2, 4), shoulder),
    "CK_Arm": ((8, 18, 10), (2, 5, 3), arm),
    "CK_Fist": ((12, 10, 12), (4, 3, 4), fist),
    "CK_Belt": ((30, 12, 4), (6, 3, 1), belt),
    "CK_Lap": ((40, 18, 12), (10, 4, 3), lap),
    "CK_Throne": ((44, 17, 28), (11, 4, 7), throne),
    "CK_ThroneBack": ((44, 48, 6), (11, 12, 1), throne_back),
}


def build():
    scene()
    out = []
    x = 0
    for i, (name, (size, counts, paint)) in enumerate(PARTS.items()):
        o = voxels(name, size, counts, paint, seed=i + 1)
        o.location = Vector((x, 0, 0))  # laid out in a row for a look; export resets to the origin
        x += size[0] + 10
        out.append(f"{name}: size={size} tris={tris(o)}")
    return "\n".join(out)


def export():
    sc, c = scene()
    objs = [o for o in c.objects if o.name.startswith("CK_")]
    saved = {o.name: o.location.copy() for o in objs}
    for o in objs:
        o.location = Vector((0, 0, 0))
    bpy.ops.object.select_all(action="DESELECT")
    for o in objs:
        o.select_set(True)
    bpy.context.view_layer.objects.active = objs[0]
    bpy.ops.export_scene.fbx(
        filepath=REPO + r"\blender_assets\CrusherKing.fbx",
        use_selection=True,
        object_types={"MESH"},
        apply_unit_scale=True,
        bake_space_transform=True,
        path_mode="STRIP",
    )
    for o in objs:
        o.location = saved[o.name]
    bpy.data.libraries.write(REPO + r"\blender_assets\CrusherKing.blend", set(objs), fake_user=True)
    return f"exported {len(objs)}"
