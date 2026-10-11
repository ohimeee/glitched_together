# Powder Hall arrow-trap kit (user, Oct 11 2P playtest: "give the traps a readable mounted crossbow look").
# Exec'd inside Blender through the MCP:  exec(open(<this file>).read()); build(); export()
# 1 unit = 1 stud; Blender x right, y depth, z up; front (into the hall) looks -Y; the origin of every piece is the
# swivel pivot, which is also the ArrowTrap holder's centre (2 x 2 x 2, its back face against the wall).
#   SC_Prop_TrapMount_Iron   riveted wall plate + a forged bracket out to the pivot collar (static, on the holder)
#   SC_Prop_TrapBow_Wood     the crossbow stock and its two bow limbs (swivels to aim at the spark)
#   SC_Prop_TrapBow_Iron     string, limb caps, bands, trigger and the loaded bolt's head (swivels with the wood)
# From the top-down castle camera it reads as a big "T": limbs across, stock pointing where the arrow will fly.
import bpy
import bmesh
import math
from mathutils import Vector, Matrix

REPO = r"C:\Users\User\OneDrive\Desktop\Coding\glitched_together"
OUT = REPO + r"\blender_assets\trap_kit"
SCENE = "TrapKit"
COLL = "TrapKit"


def scene():
    sc = bpy.data.scenes.get(SCENE) or bpy.data.scenes.new(SCENE)
    bpy.context.window.scene = sc
    c = bpy.data.collections.get(COLL) or bpy.data.collections.new(COLL)
    if c.name not in sc.collection.children:
        sc.collection.children.link(c)
    return sc, c


def mat(name, rgb, metal=0.0, rough=0.6):
    m = bpy.data.materials.get(name) or bpy.data.materials.new(name)
    m.use_nodes = True
    bsdf = next(n for n in m.node_tree.nodes if n.type == "BSDF_PRINCIPLED")
    lin = [(c / 255) ** 2.2 for c in rgb]
    bsdf.inputs["Base Color"].default_value = (*lin, 1)
    bsdf.inputs["Metallic"].default_value = metal
    bsdf.inputs["Roughness"].default_value = rough
    m.diffuse_color = (*lin, 1)
    return m


def box(bm, size, at, rot=None, bevel=0.06):
    """a bevelled box into bm"""
    tmp = bmesh.new()
    bmesh.ops.create_cube(tmp, size=1.0)
    bmesh.ops.scale(tmp, vec=Vector(size), verts=tmp.verts)
    if bevel > 0:
        bmesh.ops.bevel(tmp, geom=tmp.edges[:], offset=bevel, segments=2, affect="EDGES", profile=0.5)
    m = Matrix.Translation(Vector(at))
    if rot is not None:
        m = m @ rot
    bmesh.ops.transform(tmp, matrix=m, verts=tmp.verts)
    _merge(bm, tmp)


def cyl(bm, r, depth, at, rot=None, seg=12, r2=None):
    tmp = bmesh.new()
    bmesh.ops.create_cone(tmp, cap_ends=True, segments=seg, radius1=r, radius2=r if r2 is None else r2, depth=depth)
    m = Matrix.Translation(Vector(at))
    if rot is not None:
        m = m @ rot
    bmesh.ops.transform(tmp, matrix=m, verts=tmp.verts)
    _merge(bm, tmp)


def _merge(bm, tmp):
    me = bpy.data.meshes.new("_tmp")
    tmp.to_mesh(me)
    tmp.free()
    bm.from_mesh(me)
    bpy.data.meshes.remove(me)


def rod(bm, a, b, r, seg=8):
    """a cylinder from point a to point b"""
    a, b = Vector(a), Vector(b)
    d = b - a
    rot = d.to_track_quat("Z", "Y").to_matrix().to_4x4()
    cyl(bm, r, d.length, (a + b) / 2, rot, seg)


def new_obj(name, bm, material):
    _, coll = scene()
    old = bpy.data.objects.get(name)
    if old:
        bpy.data.objects.remove(old, do_unlink=True)
    me = bpy.data.meshes.new(name)
    bmesh.ops.remove_doubles(bm, verts=bm.verts, dist=0.0005)
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces[:])
    bm.to_mesh(me)
    bm.free()
    me.materials.append(material)
    ob = bpy.data.objects.new(name, me)
    coll.objects.link(ob)
    return ob


RX = lambda a: Matrix.Rotation(a, 4, "X")
RY = lambda a: Matrix.Rotation(a, 4, "Y")
RZ = lambda a: Matrix.Rotation(a, 4, "Z")

# limb curve: from the stock out to a tip, swept back toward the shooter (a recurve, readable from above)
SPAN = 2.1  # half width of the bow
PROD_Y = -2.0  # where the limbs leave the stock
TIP_BACK = 0.75  # how far back the tips sweep


def limb_points(side, n=7):
    pts = []
    for i in range(n + 1):
        t = i / n
        x = side * (0.25 + (SPAN - 0.25) * t)
        y = PROD_Y + TIP_BACK * (t ** 1.6) - 0.18 * math.sin(t * math.pi)  # bellies forward, tips back
        pts.append(Vector((x, y, 0.05)))
    return pts


def build():
    scene()
    wood = mat("SC_TrapWood", (126, 84, 50), 0.0, 0.7)
    iron = mat("SC_TrapIron", (58, 58, 64), 0.8, 0.45)

    # --- mount: wall plate (back face at y = +1, the wall), bracket arms, pivot collar
    bm = bmesh.new()
    box(bm, (2.6, 0.3, 2.4), (0, 0.85, 0), bevel=0.08)
    for x in (-1.0, 1.0):
        for z in (-0.9, 0.9):
            cyl(bm, 0.12, 0.12, (x, 0.66, z), RX(math.pi / 2), 8, 0.07)  # rivet heads
    box(bm, (0.35, 1.3, 0.3), (0, 0.15, -0.45), bevel=0.05)  # lower arm out to the collar
    box(bm, (0.3, 0.9, 0.3), (0, 0.45, 0.25), RX(-0.6), bevel=0.05)  # brace
    cyl(bm, 0.32, 0.6, (0, -0.35, -0.35), None, 12)  # collar the bow turns on
    new_obj("SC_Prop_TrapMount_Iron", bm, iron)

    # --- bow wood: stock + limbs
    bm = bmesh.new()
    box(bm, (0.42, 3.4, 0.38), (0, -0.85, 0.05), bevel=0.08)  # stock from the butt (+0.85) to the nose (-2.55)
    box(bm, (0.5, 0.9, 0.55), (0, 0.6, -0.05), RX(0.15), bevel=0.1)  # butt
    for side in (-1, 1):
        pts = limb_points(side)
        for a, b in zip(pts, pts[1:]):
            th = 0.17 - 0.07 * (abs(a.x) / SPAN)
            d = b - a
            yaw = math.atan2(d.y, d.x)
            box(bm, (d.length + 0.08, th, 0.2), (a + b) / 2, RZ(yaw), bevel=0.03)
    new_obj("SC_Prop_TrapBow_Wood", bm, wood)

    # --- bow iron: string, caps, bands, trigger, bolt
    bm = bmesh.new()
    nut = Vector((0, -0.55, 0.28))
    for side in (-1, 1):
        tip = limb_points(side)[-1]
        cyl(bm, 0.1, 0.32, tip, None, 8)  # limb cap
        rod(bm, tip + Vector((0, 0.02, 0.05)), nut, 0.035, 6)  # string
    box(bm, (0.5, 0.18, 0.46), (0, PROD_Y + 0.05, 0.05), bevel=0.03)  # prod band
    box(bm, (0.48, 0.14, 0.44), (0, -0.2, 0.05), bevel=0.03)  # band at the nut
    box(bm, (0.12, 0.35, 0.12), nut + Vector((0, 0.05, 0)), bevel=0.02)  # nut
    box(bm, (0.08, 0.12, 0.45), (0, 0.15, -0.3), RX(0.3), bevel=0.02)  # trigger
    rod(bm, (0, -0.5, 0.34), (0, -2.75, 0.34), 0.06, 6)  # the loaded bolt's shaft (iron-shod)
    cyl(bm, 0.14, 0.4, (0, -2.95, 0.34), RX(math.pi / 2), 6, 0.0)  # bolt head (points -Y)
    new_obj("SC_Prop_TrapBow_Iron", bm, iron)

    for ob in bpy.data.collections[COLL].objects:
        tris = sum(len(p.vertices) - 2 for p in ob.data.polygons)
        print(ob.name, "tris", tris, "dims", tuple(round(d, 2) for d in ob.dimensions))


def export():
    import os

    os.makedirs(OUT, exist_ok=True)
    for ob in list(bpy.data.collections[COLL].objects):
        bpy.ops.object.select_all(action="DESELECT")
        ob.select_set(True)
        bpy.context.view_layer.objects.active = ob
        bpy.ops.export_scene.gltf(
            filepath=os.path.join(OUT, ob.name + ".glb"),
            use_selection=True,
            use_active_scene=True,
            export_format="GLB",
            export_materials="NONE",
        )
        # offsets in Roblox space (glTF import turns 180 about Y: Blender +X = Roblox -X, Blender -Y = Roblox -Z)
        c = sum((ob.matrix_world @ Vector(b) for b in ob.bound_box), Vector()) / 8
        print("EXPORT", ob.name, "centre roblox", (round(-c.x, 3), round(c.z, 3), round(c.y * -1 * -1, 3)))
