# The Hollow Dragon (World 2 boss), exec'd inside Blender through the MCP: exec(open(<this file>).read()), then
# build(). User pick (Oct 10, 2026): "Hollow storybook": a big storybook dragon (deep plum scales, gold-edged,
# chunky bone horns) whose middle the Glitch has eaten hollow: the chest is open round a glowing heart, magenta
# static frays the holes. References: skeletal bone dragons, It Takes Two's Dungeon Crawler (warm lava light,
# toy-like readable shapes from a top-down camera), kid-drawing dragons made 3D (chunky horns, big wings).
#
# Modeled as one creature in the boss's pivot space (Roblox studs, origin = the HollowDragon model's WorldPivot,
# front = -Z), then split per gameplay part (Body, Neck, Head, Tail, WingL/R, Rib): every mesh is
# HD_<Part>_<Surface>, and report() prints each one's size + offset from its part's centre (the skin numbers for
# ArtService/StarfallCastle.luau). Surfaces: Scales (MaterialVariant DragonScales, plum), Gold, Bone, Membrane,
# Static (neon magenta), Eye.
import bpy
import bmesh
import math
import random
from mathutils import Vector, Matrix

REPO = r"C:\Users\User\OneDrive\Desktop\Coding\glitched_together"
SCENE = "HollowDragon"
COLL = "HollowDragonKit"

# grey-box part centres in pivot space (Roblox x, y, z), from Greybox buildStarfallCastle (pivot (0, 0, 1618))
PARTS = {
    "Body": ((0, 7, 4), (24, 14, 30)),
    "Neck": ((0, 9, -16), (8, 7, 14)),
    "Head": ((0, 10, -28), (10, 8, 12)),
    "Tail": ((0, 3, 32), (6, 5, 26)),
    "WingL": ((-27, 15, 4), (30, 2, 24)),
    "WingR": ((27, 15, 4), (30, 2, 24)),
    "Rib": ((0, 0, 0), (1, 9, 1.2)),  # modeled at the origin: one mesh for all six ribs
}
COLORS = {
    "Scales": (0.30, 0.17, 0.42),
    "Gold": (0.95, 0.70, 0.25),
    "Bone": (0.90, 0.86, 0.76),
    "Membrane": (0.22, 0.12, 0.30),
    "Static": (1.0, 0.17, 0.84),
    "Eye": (1.0, 0.17, 0.84),
}


def rb(x, y, z):
    """Roblox (x, y, z) -> Blender (-x, z, y)"""
    return Vector((-x, z, y))


def scene():
    sc = bpy.data.scenes.get(SCENE) or bpy.data.scenes.new(SCENE)
    bpy.context.window.scene = sc
    c = bpy.data.collections.get(COLL) or bpy.data.collections.new(COLL)
    if c.name not in sc.collection.children:
        sc.collection.children.link(c)
    return sc, c


def mat(surface):
    name = "HD_" + surface
    m = bpy.data.materials.get(name)
    if m:
        return m
    m = bpy.data.materials.new(name)
    m.use_nodes = True
    bsdf = next(n for n in m.node_tree.nodes if n.type == "BSDF_PRINCIPLED")
    c = COLORS[surface]
    bsdf.inputs["Base Color"].default_value = (c[0] ** 2.2, c[1] ** 2.2, c[2] ** 2.2, 1)
    bsdf.inputs["Roughness"].default_value = 0.35 if surface == "Gold" else 0.6
    bsdf.inputs["Metallic"].default_value = 0.8 if surface == "Gold" else 0.0
    if surface in ("Static", "Eye"):
        bsdf.inputs["Emission Color"].default_value = (c[0], c[1], c[2], 1)
        bsdf.inputs["Emission Strength"].default_value = 3
    m.diffuse_color = (c[0], c[1], c[2], 1)
    return m


def remove(name):
    o = bpy.data.objects.get(name)
    if o:
        me = o.data
        bpy.data.objects.remove(o, do_unlink=True)
        if me and me.users == 0:
            bpy.data.meshes.remove(me)


def link(name, me, surface):
    remove(name)
    o = bpy.data.objects.new(name, me)
    scene()[1].objects.link(o)
    me.materials.clear()
    me.materials.append(mat(surface))
    return o


def apply_mods(o):
    bpy.context.view_layer.objects.active = o
    for ob in bpy.context.view_layer.objects:
        ob.select_set(False)
    o.select_set(True)
    for m in list(o.modifiers):
        bpy.ops.object.modifier_apply(modifier=m.name)


def skin_tube(name, surface, pts, subdiv=2, smooth=True):
    """pts: list of ((x, y, z) Roblox, (rx, ry)) along a chain; Skin modifier -> subdivided organic tube"""
    me = bpy.data.meshes.new(name)
    bm = bmesh.new()
    vs = [bm.verts.new(rb(*p)) for p, _ in pts]
    for a, b in zip(vs, vs[1:]):
        bm.edges.new((a, b))
    bm.to_mesh(me)
    bm.free()
    o = link(name, me, surface)
    sk = o.modifiers.new("Skin", "SKIN")
    sk.use_smooth_shade = smooth
    for v, (_, r) in zip(me.skin_vertices[0].data, pts):
        v.radius = (r[0], r[1])  # Blender skin radius (x, y) in the vertex's local frame
    me.skin_vertices[0].data[0].use_root = True
    if subdiv:
        sd = o.modifiers.new("Sub", "SUBSURF")
        sd.levels = subdiv
    apply_mods(o)
    return o


def cone(name, surface, base, tip, r, segs=6):
    """a spike/horn from base to tip (Roblox coords), radius r at the base"""
    me = bpy.data.meshes.new(name)
    bm = bmesh.new()
    b, t = rb(*base), rb(*tip)
    axis = (t - b).normalized()
    ref = Vector((0, 0, 1)) if abs(axis.z) < 0.9 else Vector((1, 0, 0))
    u = axis.cross(ref).normalized()
    w = axis.cross(u)
    ring = [bm.verts.new(b + (u * math.cos(a) + w * math.sin(a)) * r) for a in (i / segs * math.tau for i in range(segs))]
    top = bm.verts.new(t)
    bm.faces.new(list(reversed(ring)))
    for i in range(segs):
        bm.faces.new((ring[i], ring[(i + 1) % segs], top))
    bm.to_mesh(me)
    bm.free()
    return link(name, me, surface)


def join(name, objs):
    objs = [o for o in objs if o]
    if not objs:
        return None
    for ob in bpy.context.view_layer.objects:
        ob.select_set(False)
    for o in objs:
        o.select_set(True)
    bpy.context.view_layer.objects.active = objs[0]
    bpy.ops.object.join()
    o = bpy.context.view_layer.objects.active
    old = bpy.data.objects.get(name)
    if old and old != o:
        remove(name)
    o.name = name
    o.data.name = name
    return o


def tris(o):
    return sum(len(p.vertices) - 2 for p in o.data.polygons)


# Body -------------------------------------------------------------------------------------------------------------
def body():
    rng = random.Random(3)
    # spine from the chest (-12) to the hips (+18): broad chest, belly, narrower hips; lying low on the floor
    trunk = skin_tube("HD_Body_Scales", "Scales", [
        ((0, 6.5, -12), (6.5, 5.0)),
        ((0, 7.0, -6), (10.5, 6.5)),
        ((0, 7.0, 2), (11.5, 7.0)),
        ((0, 6.5, 10), (10.0, 6.0)),
        ((0, 5.5, 17), (7.5, 4.8)),
    ])
    legs = []
    for side in (-1, 1):
        # front legs: shoulder -> elbow out to the side -> wrist down -> paw planted forward
        legs.append(skin_tube(f"legF{side}", "Scales", [
            ((side * 8.5, 7.5, -8), (3.6, 3.6)),
            ((side * 12.5, 5.0, -8.5), (2.7, 2.7)),
            ((side * 13.0, 1.6, -11.5), (2.0, 2.0)),
            ((side * 13.0, 0.9, -14.5), (1.8, 1.0)),
        ], subdiv=1))
        # rear legs: haunch -> knee up and back -> ankle down -> paw pointing forward
        legs.append(skin_tube(f"legR{side}", "Scales", [
            ((side * 8.0, 7.0, 15), (4.4, 4.4)),
            ((side * 12.5, 6.0, 17.5), (3.2, 3.2)),
            ((side * 12.8, 2.0, 20.5), (2.0, 2.0)),
            ((side * 12.8, 0.9, 17.0), (1.8, 1.0)),
        ], subdiv=1))
    trunk = join("HD_Body_Scales", [trunk] + legs)
    # gold-tipped dorsal ridge + bone claws
    spikes, claws = [], []
    for i, z in enumerate(range(-8, 18, 4)):
        h = 3.8 - abs(z - 3) * 0.08
        spikes.append(cone(f"sp{i}", "Gold", (0, 13.2 - abs(z - 2) * 0.12, z), (0, 13.2 + h, z + 1.8), 1.3))
    for side in (-1, 1):
        for fz in (-15.5, 16):
            for k in (-1, 0, 1):
                claws.append(cone(f"cl{side}{fz}{k}", "Bone", (side * 13 + k * 0.9, 0.8, fz), (side * 13 + k * 1.2, 0.2, fz - 1.8), 0.4, 5))
    join("HD_Body_Gold", spikes)
    join("HD_Body_Bone", claws)
    # the hollow: magenta static fraying round the open chest (flat shards standing off the rim)
    shards = []
    for i in range(22):
        a = rng.uniform(0, math.tau)
        r = rng.uniform(5.0, 6.2)
        base = (math.cos(a) * r * 0.9, 6.0 + math.sin(a) * r * 0.75, -11.6)
        tip = (base[0] * 1.15 + rng.uniform(-1, 1), base[1] + rng.uniform(-1, 1.5), -12.6 - rng.uniform(0, 1.5))
        shards.append(cone(f"st{i}", "Static", base, tip, 0.35, 3))
    join("HD_Body_Static", shards)
    # carve the chest open where the heart sits (just in front of the body, low)
    cut = bpy.data.objects.new("cut", bpy.data.meshes.new("cut"))
    bm = bmesh.new()
    bmesh.ops.create_uvsphere(bm, u_segments=16, v_segments=10, radius=5.2)
    bm.to_mesh(cut.data)
    bm.free()
    scene()[1].objects.link(cut)
    cut.location = rb(0, 5.0, -12.5)
    b = trunk.modifiers.new("Hollow", "BOOLEAN")
    b.operation = "DIFFERENCE"
    b.object = cut
    apply_mods(trunk)
    bpy.data.objects.remove(cut, do_unlink=True)
    return trunk


# Neck, head, tail ---------------------------------------------------------------------------------------------------
def neck():
    rng = random.Random(5)
    o = skin_tube("HD_Neck_Scales", "Scales", [
        ((0, 8.0, -9), (4.6, 4.2)),
        ((0, 9.5, -15), (3.6, 3.4)),
        ((0, 10.5, -21), (3.2, 3.0)),
        ((0, 10.8, -24), (3.2, 3.0)),
    ])
    spikes = [cone(f"ns{i}", "Gold", (0, 12.4 + i * 0.2, z), (0, 14.6 + i * 0.1, z + 1.6), 0.9) for i, z in enumerate((-22, -18, -14, -10))]
    join("HD_Neck_Gold", spikes)
    return o


def head():
    skull = skin_tube("HD_Head_Scales", "Scales", [
        ((0, 11.0, -23), (3.6, 3.4)),
        ((0, 11.2, -27), (3.9, 3.0)),
        ((0, 10.4, -31), (2.8, 2.2)),
        ((0, 9.8, -34), (2.2, 1.7)),
    ])
    jaw = skin_tube("jaw", "Scales", [
        ((0, 8.6, -25), (3.0, 1.6)),
        ((0, 8.0, -30), (2.3, 1.2)),
        ((0, 7.8, -33.5), (1.6, 0.9)),
    ])
    skull = join("HD_Head_Scales", [skull, jaw])
    bone = []
    for side in (-1, 1):
        # chunky horns sweeping back, then a smaller pair; teeth along the jaw line
        horn = skin_tube(f"horn{side}", "Bone", [
            ((side * 2.4, 13.4, -25), (1.1, 1.1)),
            ((side * 3.6, 15.2, -22.5), (0.8, 0.8)),
            ((side * 4.2, 16.0, -19.5), (0.45, 0.45)),
            ((side * 4.0, 16.2, -18.0), (0.12, 0.12)),
        ], subdiv=1)
        bone.append(horn)
        bone.append(cone(f"hs{side}", "Bone", (side * 3.4, 12.0, -24), (side * 5.6, 12.4, -21.5), 0.45, 5))
        for k in range(4):
            z = -33 + k * 1.6
            bone.append(cone(f"t{side}{k}", "Bone", (side * (1.5 + k * 0.25), 9.0, z), (side * (1.5 + k * 0.25), 8.2, z), 0.22, 4))
    join("HD_Head_Bone", bone)
    eyes = []
    for side in (-1, 1):
        me = bpy.data.meshes.new("eye")
        bm = bmesh.new()
        bmesh.ops.create_uvsphere(bm, u_segments=10, v_segments=6, radius=0.75)
        bm.to_mesh(me)
        bm.free()
        e = link(f"eye{side}", me, "Eye")
        e.location = rb(side * 2.5, 12.0, -28.5)
        e.scale = (1.0, 1.4, 0.7)
        bpy.context.view_layer.update()
        for ob in bpy.context.view_layer.objects:
            ob.select_set(False)
        e.select_set(True)
        bpy.context.view_layer.objects.active = e
        bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
        eyes.append(e)
    join("HD_Head_Eye", eyes)
    return skull


def tail():
    o = skin_tube("HD_Tail_Scales", "Scales", [
        ((0, 5.5, 17), (5.0, 4.0)),
        ((0, 4.0, 24), (3.6, 3.0)),
        ((3, 2.5, 31), (2.6, 2.2)),
        ((1, 1.8, 38), (1.8, 1.5)),
        ((-3, 1.3, 43), (1.0, 0.9)),
        ((-4, 1.1, 45.5), (0.3, 0.3)),
    ])
    gold = [cone(f"ts{i}", "Gold", p, (p[0], p[1] + h, p[2] + 1.4), r) for i, (p, h, r) in enumerate((
        ((0, 8.8, 22), 2.6, 1.0), ((1.5, 6.0, 28), 2.0, 0.8), ((2.4, 4.3, 33), 1.6, 0.6), ((0.4, 3.2, 38), 1.2, 0.5),
    ))]
    # the spade at the tip
    me = bpy.data.meshes.new("spade")
    bm = bmesh.new()
    pts = [rb(-4, 1.1, 44.5), rb(-6.8, 1.1, 46.5), rb(-4.6, 1.1, 50.5), rb(-1.6, 1.1, 46.8)]
    f = bm.faces.new([bm.verts.new(p) for p in pts])
    bmesh.ops.solidify(bm, geom=[f], thickness=0.5)
    bm.to_mesh(me)
    bm.free()
    gold.append(link("spade", me, "Gold"))
    join("HD_Tail_Gold", gold)
    return o


# Wings --------------------------------------------------------------------------------------------------------------
def wing(side, torn):
    """folded over its flank at rest: root along the spine, leading-edge arm, four finger bones fanning back, a
    scalloped membrane between them (0.5 thick), gold claw at the wrist; torn = static-frayed holes"""
    rng = random.Random(11 if side > 0 else 12)
    s = "R" if side > 0 else "L"
    y = 15.0
    root_front, root_back = (side * 12, y, -8), (side * 12, y, 15)
    wrist = (side * 30, y + 0.6, -9)
    tips = [(side * 42, y, -6), (side * 41, y, 4), (side * 36, y, 12), (side * 27, y, 16)]
    # membrane: root -> wrist -> scallops between finger tips -> back root
    outline = [root_front, wrist, tips[0]]
    for a, b in zip(tips, tips[1:]):
        mid = ((a[0] + b[0]) / 2, y, (a[2] + b[2]) / 2)
        towards = Vector((wrist[0] - mid[0], 0, wrist[2] - mid[2])).normalized() * 3.2
        outline.append((mid[0] + towards.x, y, mid[2] + towards.z))
        outline.append(b)
    outline.append(root_back)
    me = bpy.data.meshes.new("mem")
    bm = bmesh.new()
    verts = [bm.verts.new(rb(*p)) for p in outline]
    if side < 0:
        verts.reverse()
    face = bm.faces.new(verts)
    bmesh.ops.triangulate(bm, faces=[face])
    bmesh.ops.subdivide_edges(bm, edges=list(bm.edges), cuts=2, use_grid_fill=True)
    if torn:
        # holes the Glitch chewed through the membrane
        for _ in range(4):
            c = rb(side * rng.uniform(22, 36), y, rng.uniform(-2, 10))
            kill = [f for f in bm.faces if (f.calc_center_median() - c).length < rng.uniform(1.6, 2.6)]
            bmesh.ops.delete(bm, geom=kill, context="FACES")
    for v in bm.verts:  # a little sag between the bones
        v.co.z -= 0.6 * math.sin(min(1, abs(v.co.x) / 42) * math.pi)
    bmesh.ops.solidify(bm, geom=list(bm.faces), thickness=0.5)
    bm.to_mesh(me)
    bm.free()
    mem = link(f"HD_Wing{s}_Membrane", me, "Membrane")
    bones = [skin_tube(f"arm{s}", "Scales", [(root_front, (1.4, 1.4)), (wrist, (1.0, 1.0))], subdiv=1)]
    for i, t in enumerate(tips):
        bones.append(skin_tube(f"f{s}{i}", "Scales", [(wrist, (0.7, 0.7)), (t, (0.25, 0.25))], subdiv=1))
    join(f"HD_Wing{s}_Scales", bones)
    golds = [cone(f"wc{s}", "Gold", wrist, (wrist[0] + side * 2.5, wrist[1] + 0.8, wrist[2] - 2.2), 0.7)]
    join(f"HD_Wing{s}_Gold", golds)
    return mem


def rib():
    # one curved bone (fits the 1 x 9 x 1.2 grey-box rib, centred at the origin)
    return skin_tube("HD_Rib_Bone", "Bone", [
        ((0, -4.5, 0), (0.45, 0.55)),
        ((0.35, -1.5, 0), (0.55, 0.6)),
        ((0.4, 1.5, 0), (0.5, 0.55)),
        ((0.1, 4.5, 0), (0.3, 0.35)),
    ], subdiv=2)


def build():
    scene()
    out = []
    body()
    neck()
    head()
    tail()
    wing(-1, False)
    wing(1, True)
    rib()
    for o in bpy.data.collections[COLL].objects:
        if o.name.startswith("HD_"):
            out.append(f"{o.name}: tris={tris(o)}")
    return "\n".join(out)


def report():
    """each HD_<Part>_<Surface> mesh: Roblox size + offset from its grey-box part's centre (skin numbers)"""
    out = []
    for o in sorted(bpy.data.collections[COLL].objects, key=lambda o: o.name):
        if not o.name.startswith("HD_"):
            continue
        part = o.name.split("_")[1]
        centre = PARTS[part][0]
        bb = [o.matrix_world @ Vector(c) for c in o.bound_box]
        lo = Vector((min(p.x for p in bb), min(p.y for p in bb), min(p.z for p in bb)))
        hi = Vector((max(p.x for p in bb), max(p.y for p in bb), max(p.z for p in bb)))
        c = (lo + hi) / 2
        size = hi - lo
        rc = (-c.x, c.z, c.y)  # Blender -> Roblox
        off = tuple(round(rc[i] - centre[i], 3) for i in range(3))
        out.append(f"{o.name}: size=({size.x:.2f}, {size.z:.2f}, {size.y:.2f}) offset={off} tris={tris(o)}")
    return "\n".join(out)


def export():
    sc, c = scene()
    objs = [o for o in c.objects if o.name.startswith("HD_")]
    bpy.ops.object.select_all(action="DESELECT")
    for o in objs:
        o.select_set(True)
    bpy.context.view_layer.objects.active = objs[0]
    bpy.ops.export_scene.fbx(
        filepath=REPO + r"\blender_assets\HollowDragon.fbx",
        use_selection=True,
        object_types={"MESH"},
        apply_unit_scale=True,
        bake_space_transform=True,
        path_mode="COPY",
        embed_textures=True,
    )
    bpy.data.libraries.write(REPO + r"\blender_assets\HollowDragon.blend", set(objs), fake_user=True)
    return f"exported {len(objs)}"
