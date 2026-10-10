"""Epilogue sky (Blender scene EpilogueSky, file blender_assets/EpilogueSky.blend): the finished kingdom at night.
Run through Blender MCP execute_blender_code:
    PARTS = None  # or a subset, e.g. ["sky", "terrain"]
    exec(open(r"<repo>/tools/epilogue_sky/build.py").read())
Then render: render_faces(SC, bpy.data.objects["EpiCam"], r"<repo>/textures/sky", "EP_Sky", origin=(0, 0, 0)).
See BLENDER_PLAYBOOK.md section 10."""
_D = r"C:\Users\User\OneDrive\Desktop\Coding\glitched_together\tools\epilogue_sky"
exec(open(_D + r"\lib.py").read())
HAZE = lin("23305E")
for _part in (globals().get("PARTS") or ["sky", "terrain", "plains", "castle", "core", "nature", "lanterns"]):
    exec(open(_D + "\\" + _part + ".py").read())
