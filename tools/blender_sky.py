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


def render_faces(scene, cam, out_dir, prefix, size=1024, samples=128, faces=None):
    """faces: optional subset, e.g. ['Dn', 'Ft'] for quick low-res previews (size=384, samples=24)."""
    os.makedirs(out_dir, exist_ok=True)
    cam.location = (0, 0, 0)
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
        cam.matrix_world = Matrix((R, U, -L)).transposed().to_4x4()  # camera X = right, Y = up, Z = -look
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
