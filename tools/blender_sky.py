"""Render a Roblox skybox (6 cube faces) from the current Blender scene.

Paste into Blender through the Blender MCP `execute_blender_code` (or run with --python), then call
    render_faces(bpy.context.scene, cam_obj, out_dir, prefix, size=1024, samples=128)
Faces come out as <prefix>_Bk/Ft/Lf/Rt/Up/Dn.png, ready for Studio MCP upload_image and Worlds.luau Look.Skybox.

Face mapping (measured in Studio with labelled test faces, Oct 2 2026). Roblox world: Bk = +Z, Ft = -Z, Lf = +X,
Rt = -X; Up's image top points to +X, Dn's image top to -X. Blender (x, y, z) = Roblox (-x, z, y), so in Blender:
    Bk looks +Y, Ft -Y, Lf -X, Rt +X (all upright), Up looks +Z with screen-up -X, Dn looks -Z with screen-up +X.
The camera sits at the origin with a 90 degree FOV; put the level's height at z = 0 and build the world around it.
Set the camera clip_end high (100000+): the default 100 hides everything past 100 units.
"""
import os

import bpy
from mathutils import Matrix, Vector

FACES = {
    "Bk": ((0, 1, 0), (0, 0, 1)),
    "Ft": ((0, -1, 0), (0, 0, 1)),
    "Lf": ((-1, 0, 0), (0, 0, 1)),
    "Rt": ((1, 0, 0), (0, 0, 1)),
    "Up": ((0, 0, 1), (-1, 0, 0)),
    "Dn": ((0, 0, -1), (1, 0, 0)),
}


def render_faces(scene, cam, out_dir, prefix, size=1024, samples=128, faces=None, origin=(0, 0, 0)):
    """faces: optional subset, e.g. ['Dn', 'Ft'] for quick low-res previews (size=384, samples=24).
    origin: camera position; raise z to make the ground read further below the level (castle: z 700)."""
    os.makedirs(out_dir, exist_ok=True)
    cam.data.angle = 1.5707963  # 90 degrees
    cam.data.clip_start = 1
    cam.data.clip_end = max(cam.data.clip_end, 200000)
    scene.camera = cam
    scene.render.resolution_x = scene.render.resolution_y = size
    scene.render.resolution_percentage = 100
    scene.cycles.samples = samples
    for name, (look, up) in FACES.items():
        if faces and name not in faces:
            continue
        L, U = Vector(look), Vector(up)
        R = L.cross(U)
        cam.matrix_world = Matrix.Translation(Vector(origin)) @ Matrix((R, U, -L)).transposed().to_4x4()  # X right, Y up, Z -look
        scene.render.filepath = os.path.join(out_dir, f"{prefix}_{name}.png")
        bpy.ops.render.render(write_still=True, scene=scene.name)


def add_haze(material, color, start=600, end=12000, strength=0.8):
    """Aerial perspective without volumes: fade a material toward `color` with camera distance."""
    nt = material.node_tree
    out = next(n for n in nt.nodes if n.type == "OUTPUT_MATERIAL")
    src = out.inputs["Surface"].links[0].from_socket
    cam = nt.nodes.new("ShaderNodeCameraData")
    mr = nt.nodes.new("ShaderNodeMapRange")
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


def moon_material(mat, tint=(1.0, 0.95, 0.86), strength=1.0):
    """A moon that reads as a moon, not a flat disc (Oct 17): Generated-coord maria + craters + fine noise, warm tint,
    limb darkening (Layer Weight Facing is 1 at grazing). Keep strength ~1-1.6 (Epilogue 1.55 with a soft halo): much higher blows out to a white disc."""
    mat.use_nodes = True
    nt = mat.node_tree
    nt.nodes.clear()
    N = nt.nodes.new
    L = nt.links.new
    out, emit, coord = N("ShaderNodeOutputMaterial"), N("ShaderNodeEmission"), N("ShaderNodeTexCoord")
    maria = N("ShaderNodeTexNoise"); maria.inputs["Scale"].default_value = 1.6; maria.inputs["Detail"].default_value = 4
    maria.inputs["Roughness"].default_value = 0.55
    mr = N("ShaderNodeValToRGB")
    mr.color_ramp.elements[0].position = 0.42; mr.color_ramp.elements[0].color = (0.22, 0.22, 0.27, 1)
    mr.color_ramp.elements[1].position = 0.6; mr.color_ramp.elements[1].color = (1, 1, 1, 1)
    vor = N("ShaderNodeTexVoronoi"); vor.inputs["Scale"].default_value = 7
    vr = N("ShaderNodeValToRGB")
    vr.color_ramp.elements[0].position = 0.05; vr.color_ramp.elements[0].color = (0.55, 0.55, 0.6, 1)
    vr.color_ramp.elements[1].position = 0.22; vr.color_ramp.elements[1].color = (1, 1, 1, 1)
    fine = N("ShaderNodeTexNoise"); fine.inputs["Scale"].default_value = 22; fine.inputs["Detail"].default_value = 6
    fr = N("ShaderNodeMapRange"); fr.inputs["To Min"].default_value = 0.85; fr.inputs["To Max"].default_value = 1.05
    def mul(a, b):
        m = N("ShaderNodeMix"); m.data_type = "RGBA"; m.blend_type = "MULTIPLY"; m.inputs[0].default_value = 1
        L(a, m.inputs[6])
        if isinstance(b, tuple):
            m.inputs[7].default_value = (*b, 1)
        else:
            L(b, m.inputs[7])
        return m.outputs[2]
    for tex in (maria, vor, fine):
        L(coord.outputs["Generated"], tex.inputs["Vector"])
    L(maria.outputs["Fac"], mr.inputs["Fac"]); L(vor.outputs["Distance"], vr.inputs["Fac"]); L(fine.outputs["Fac"], fr.inputs["Value"])
    L(mul(mul(mul(mr.outputs["Color"], vr.outputs["Color"]), fr.outputs["Result"]), tint), emit.inputs["Color"])
    lw = N("ShaderNodeLayerWeight"); lw.inputs["Blend"].default_value = 0.5
    inv = N("ShaderNodeMath"); inv.operation = "SUBTRACT"; inv.inputs[0].default_value = 1
    limb = N("ShaderNodeMath"); limb.operation = "POWER"; limb.inputs[1].default_value = 0.6
    k = N("ShaderNodeMath"); k.operation = "MULTIPLY"; k.inputs[1].default_value = strength
    L(lw.outputs["Facing"], inv.inputs[1]); L(inv.outputs[0], limb.inputs[0]); L(limb.outputs[0], k.inputs[0])
    L(k.outputs[0], emit.inputs["Strength"]); L(emit.outputs[0], out.inputs["Surface"])
    return mat
