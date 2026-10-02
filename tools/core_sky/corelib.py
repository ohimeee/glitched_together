"""Glitched Core sky (Blender scene CoreSky): the unfinished level as a real scale model.

Grey-primer chunks of the earlier worlds on brass model stands rising from an endless pencil-gridded drafting
sheet, foam-board castle blockouts with scaffolding, wire armatures where parts are missing, a pencil-sketched sky,
a few magenta Glitch tears. Run through Blender MCP execute_blender_code:
    exec(open(r"<repo>/tools/core_sky/build.py").read())
then render with tools/blender_sky.py render_faces. See BLENDER_PLAYBOOK.md section 10.
"""
import bpy, bmesh, math, random
from mathutils import Vector, noise, Matrix

SHEET_Z = -900.0  # the drafting sheet far below the level


def lin(h):
    h = h.lstrip("#")
    return tuple((int(h[i:i + 2], 16) / 255) ** 2.2 for i in (0, 2, 4))


def scene():
    sc = bpy.data.scenes.get("CoreSky")
    if sc is None:
        sc = bpy.data.scenes.new("CoreSky")
    return sc


def coll(name="CoreSet"):
    sc = scene()
    c = bpy.data.collections.get(name)
    if c is None:
        c = bpy.data.collections.new(name)
        sc.collection.children.link(c)
    return c


def mat(name, rgb, rough=0.8, metal=0.0, emit=None, estr=0.0):
    m = bpy.data.materials.get(name)
    if m is None:
        m = bpy.data.materials.new(name)
        m.use_nodes = True
    b = next(n for n in m.node_tree.nodes if n.type == "BSDF_PRINCIPLED")
    b.inputs["Base Color"].default_value = (*rgb, 1)
    b.inputs["Roughness"].default_value = rough
    b.inputs["Metallic"].default_value = metal
    if emit:
        b.inputs["Emission Color"].default_value = (*emit, 1)
        b.inputs["Emission Strength"].default_value = estr
    m.diffuse_color = (*rgb, 1)
    return m


def new_obj(name, bm, mats, collection="CoreSet"):
    old = bpy.data.objects.get(name)
    if old:
        bpy.data.objects.remove(old, do_unlink=True)
    me = bpy.data.meshes.new(name)
    bm.to_mesh(me)
    bm.free()
    for m in mats:
        me.materials.append(m)
    o = bpy.data.objects.new(name, me)
    coll(collection).objects.link(o)
    return o


def box(bm, c, s, rot=0.0, mi=0, tilt=(0.0, 0.0)):
    """c = centre (x, y, z), s = size (sx, sy, sz)"""
    M = Matrix.Translation(Vector(c)) @ Matrix.Rotation(rot, 4, "Z") @ Matrix.Rotation(tilt[0], 4, "X") @ Matrix.Rotation(tilt[1], 4, "Y")
    ret = bmesh.ops.create_cube(bm, size=1.0)
    for v in ret["verts"]:
        v.co = M @ Vector((v.co.x * s[0], v.co.y * s[1], v.co.z * s[2]))
    for f in {f for v in ret["verts"] for f in v.link_faces}:
        f.material_index = mi
    return ret["verts"]


def cyl(bm, a, b, r, seg=8, mi=0, r2=None):
    """cylinder (or cone with r2) from point a to b"""
    a, b = Vector(a), Vector(b)
    d = b - a
    L = d.length
    q = d.to_track_quat("Z", "Y")
    M = Matrix.Translation(a) @ q.to_matrix().to_4x4()
    ret = bmesh.ops.create_cone(bm, cap_ends=True, segments=seg, radius1=r, radius2=r if r2 is None else r2, depth=L)
    for v in ret["verts"]:
        v.co = M @ (v.co + Vector((0, 0, L / 2)))
    for f in {f for v in ret["verts"] for f in v.link_faces}:
        f.material_index = mi
    return ret["verts"]


def add_haze(material, color, start=900, end=14000, strength=0.85):
    nt = material.node_tree
    if any(n.label == "haze" for n in nt.nodes):
        return
    out = next(n for n in nt.nodes if n.type == "OUTPUT_MATERIAL")
    src = out.inputs["Surface"].links[0].from_socket
    cam = nt.nodes.new("ShaderNodeCameraData")
    mr = nt.nodes.new("ShaderNodeMapRange")
    mr.label = "haze"
    mr.inputs["From Min"].default_value = start
    mr.inputs["From Max"].default_value = end
    mr.inputs["To Max"].default_value = strength
    em = nt.nodes.new("ShaderNodeEmission")
    em.inputs["Color"].default_value = (*color, 1)
    mix = nt.nodes.new("ShaderNodeMixShader")
    nt.links.new(cam.outputs["View Distance"], mr.inputs["Value"])
    nt.links.new(mr.outputs["Result"], mix.inputs["Fac"])
    nt.links.new(src, mix.inputs[1])
    nt.links.new(em.outputs["Emission"], mix.inputs[2])
    nt.links.new(mix.outputs["Shader"], out.inputs["Surface"])
