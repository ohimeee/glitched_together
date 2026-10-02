exec(open(r"C:\Users\User\OneDrive\Desktop\Coding\glitched_together\tools\core_sky\corelib.py").read())
sc = scene()
bpy.context.window.scene = sc
try:
    sc.render.engine = "CYCLES"
except TypeError as e:
    print(e)
sc.cycles.device = "GPU"
sc.cycles.use_denoising = True
sc.view_settings.view_transform = "AgX"
try:
    sc.view_settings.look = "AgX - Medium High Contrast"
except TypeError:
    pass
sc.view_settings.exposure = 0.0

# --- world: pencil-sketched sky (grey gradient, faint dome grid, cloud outlines in graphite) -------------
w = bpy.data.worlds.get("CoreSkyWorld") or bpy.data.worlds.new("CoreSkyWorld")
w.use_nodes = True
nt = w.node_tree
nt.nodes.clear()
N = nt.nodes.new
L = nt.links.new
out = N("ShaderNodeOutputWorld")
bg = N("ShaderNodeBackground")
bg.inputs["Strength"].default_value = 1.0
tc = N("ShaderNodeTexCoord")
nrm = N("ShaderNodeVectorMath"); nrm.operation = "NORMALIZE"
L(tc.outputs["Generated"], nrm.inputs[0])
# Generated is 0..1 box coords; centre it first
sub = N("ShaderNodeVectorMath"); sub.operation = "SUBTRACT"; sub.inputs[1].default_value = (0.5, 0.5, 0.5)
L(tc.outputs["Generated"], sub.inputs[0]); L(sub.outputs[0], nrm.inputs[0])
sep = N("ShaderNodeSeparateXYZ"); L(nrm.outputs[0], sep.inputs[0])
# gradient by elevation
ramp = N("ShaderNodeValToRGB")
ramp.color_ramp.elements[0].position = 0.42
ramp.color_ramp.elements[0].color = (*lin("A3A7AE"), 1)
ramp.color_ramp.elements[1].position = 0.95
ramp.color_ramp.elements[1].color = (*lin("4C4F57"), 1)
e = ramp.color_ramp.elements.new(0.52)
e.color = (*lin("8E929A"), 1)
mr = N("ShaderNodeMapRange"); mr.inputs["From Min"].default_value = -1; mr.inputs["From Max"].default_value = 1
L(sep.outputs["Z"], mr.inputs["Value"]); L(mr.outputs["Result"], ramp.inputs["Fac"])
# sketched cloud outlines: contour of 3D noise on the view direction
nz = N("ShaderNodeTexNoise"); nz.inputs["Scale"].default_value = 3.6; nz.inputs["Detail"].default_value = 1.5; nz.inputs["Roughness"].default_value = 0.4
mp = N("ShaderNodeMapping"); mp.inputs["Scale"].default_value = (1, 1, 3.8)
L(nrm.outputs[0], mp.inputs["Vector"]); L(mp.outputs["Vector"], nz.inputs["Vector"])
d1 = N("ShaderNodeMath"); d1.operation = "SUBTRACT"; d1.inputs[1].default_value = 0.56
L(nz.outputs["Fac"], d1.inputs[0])
ab = N("ShaderNodeMath"); ab.operation = "ABSOLUTE"; L(d1.outputs[0], ab.inputs[0])
ln = N("ShaderNodeMapRange"); ln.inputs["From Min"].default_value = 0.0; ln.inputs["From Max"].default_value = 0.006
ln.inputs["To Min"].default_value = 1.0; ln.inputs["To Max"].default_value = 0.0
L(ab.outputs[0], ln.inputs["Value"])
# inside the cloud: pencil hatching (diagonal strokes) over a faint paper-white fill
fill = N("ShaderNodeMapRange"); fill.inputs["From Min"].default_value = 0.56; fill.inputs["From Max"].default_value = 0.6
fill.inputs["To Max"].default_value = 1.0
L(nz.outputs["Fac"], fill.inputs["Value"])
hs = N("ShaderNodeVectorMath"); hs.operation = "DOT_PRODUCT"; hs.inputs[1].default_value = (70, 70, 120)
L(nrm.outputs[0], hs.inputs[0])
hf = N("ShaderNodeMath"); hf.operation = "FRACT"; L(hs.outputs["Value"], hf.inputs[0])
hl = N("ShaderNodeMapRange"); hl.inputs["From Min"].default_value = 0.0; hl.inputs["From Max"].default_value = 0.18
hl.inputs["To Min"].default_value = 1.0; hl.inputs["To Max"].default_value = 0.0
L(hf.outputs[0], hl.inputs["Value"])
hm = N("ShaderNodeMath"); hm.operation = "MULTIPLY"; L(hl.outputs["Result"], hm.inputs[0]); L(fill.outputs["Result"], hm.inputs[1])
# only above the horizon
up = N("ShaderNodeMapRange"); up.inputs["From Min"].default_value = 0.03; up.inputs["From Max"].default_value = 0.2
L(sep.outputs["Z"], up.inputs["Value"])
lm = N("ShaderNodeMath"); lm.operation = "MULTIPLY"; L(ln.outputs["Result"], lm.inputs[0]); L(up.outputs["Result"], lm.inputs[1])
fw = N("ShaderNodeMath"); fw.operation = "MULTIPLY"; fw.inputs[1].default_value = 0.22; L(fill.outputs["Result"], fw.inputs[0])
fm = N("ShaderNodeMath"); fm.operation = "MULTIPLY"; L(fw.outputs[0], fm.inputs[0]); L(up.outputs["Result"], fm.inputs[1])
mixf = N("ShaderNodeMix"); mixf.data_type = "RGBA"; mixf.inputs["B"].default_value = (*lin("D9DBDF"), 1)
L(fm.outputs[0], mixf.inputs["Factor"]); L(ramp.outputs["Color"], mixf.inputs["A"])
hu = N("ShaderNodeMath"); hu.operation = "MULTIPLY"; hu.inputs[1].default_value = 0.3; L(hm.outputs[0], hu.inputs[0])
hu2 = N("ShaderNodeMath"); hu2.operation = "MULTIPLY"; L(hu.outputs[0], hu2.inputs[0]); L(up.outputs["Result"], hu2.inputs[1])
lsum = N("ShaderNodeMath"); lsum.operation = "MAXIMUM"; L(lm.outputs[0], lsum.inputs[0]); L(hu2.outputs[0], lsum.inputs[1])
lw = N("ShaderNodeMath"); lw.operation = "MULTIPLY"; lw.inputs[1].default_value = 0.7; L(lsum.outputs[0], lw.inputs[0])
mixl = N("ShaderNodeMix"); mixl.data_type = "RGBA"; mixl.inputs["B"].default_value = (*lin("34363C"), 1)
L(lw.outputs[0], mixl.inputs["Factor"]); L(mixf.outputs["Result"], mixl.inputs["A"])
# faint dome grid (latitude / longitude), like an editor's sky that was never painted
az = N("ShaderNodeMath"); az.operation = "ARCTAN2"; L(sep.outputs["Y"], az.inputs[0]); L(sep.outputs["X"], az.inputs[1])
azs = N("ShaderNodeMath"); azs.operation = "MULTIPLY"; azs.inputs[1].default_value = 36 / math.tau; L(az.outputs[0], azs.inputs[0])
el = N("ShaderNodeMath"); el.operation = "ARCSINE"; L(sep.outputs["Z"], el.inputs[0])
els = N("ShaderNodeMath"); els.operation = "MULTIPLY"; els.inputs[1].default_value = 18 / math.pi * 2; L(el.outputs[0], els.inputs[0])
gl = []
for src in (azs, els):
    fr = N("ShaderNodeMath"); fr.operation = "FRACT"; L(src.outputs[0], fr.inputs[0])
    c = N("ShaderNodeMath"); c.operation = "SUBTRACT"; c.inputs[1].default_value = 0.5; L(fr.outputs[0], c.inputs[0])
    a2 = N("ShaderNodeMath"); a2.operation = "ABSOLUTE"; L(c.outputs[0], a2.inputs[0])
    m2 = N("ShaderNodeMapRange"); m2.inputs["From Min"].default_value = 0.485; m2.inputs["From Max"].default_value = 0.5
    L(a2.outputs[0], m2.inputs["Value"])
    gl.append(m2)
gmax = N("ShaderNodeMath"); gmax.operation = "MAXIMUM"; L(gl[0].outputs["Result"], gmax.inputs[0]); L(gl[1].outputs["Result"], gmax.inputs[1])
gup = N("ShaderNodeMath"); gup.operation = "MULTIPLY"; L(gmax.outputs[0], gup.inputs[0]); L(up.outputs["Result"], gup.inputs[1])
gw = N("ShaderNodeMath"); gw.operation = "MULTIPLY"; gw.inputs[1].default_value = 0.16; L(gup.outputs[0], gw.inputs[0])
mixg = N("ShaderNodeMix"); mixg.data_type = "RGBA"; mixg.inputs["B"].default_value = (*lin("3E4047"), 1)
L(gw.outputs[0], mixg.inputs["Factor"]); L(mixl.outputs["Result"], mixg.inputs["A"])
L(mixg.outputs["Result"], bg.inputs["Color"])
L(bg.outputs["Background"], out.inputs["Surface"])
sc.world = w

# --- the drafting sheet ------------------------------------------------------------------------------------
m = bpy.data.materials.get("C_Sheet") or bpy.data.materials.new("C_Sheet")
m.use_nodes = True
nt = m.node_tree
nt.nodes.clear()
N = nt.nodes.new
L = nt.links.new
out = N("ShaderNodeOutputMaterial")
b = N("ShaderNodeBsdfPrincipled"); b.inputs["Roughness"].default_value = 0.95
tc = N("ShaderNodeTexCoord")
sep = N("ShaderNodeSeparateXYZ"); L(tc.outputs["Object"], sep.inputs[0])
lines = []
for step, width, strength in ((25, 0.05, 0.35), (125, 0.025, 0.75)):
    for axis in ("X", "Y"):
        dv = N("ShaderNodeMath"); dv.operation = "DIVIDE"; dv.inputs[1].default_value = step; L(sep.outputs[axis], dv.inputs[0])
        fr = N("ShaderNodeMath"); fr.operation = "FRACT"; L(dv.outputs[0], fr.inputs[0])
        c = N("ShaderNodeMath"); c.operation = "SUBTRACT"; c.inputs[1].default_value = 0.5; L(fr.outputs[0], c.inputs[0])
        a2 = N("ShaderNodeMath"); a2.operation = "ABSOLUTE"; L(c.outputs[0], a2.inputs[0])
        m2 = N("ShaderNodeMapRange"); m2.inputs["From Min"].default_value = 0.5 - width; m2.inputs["From Max"].default_value = 0.5
        m2.inputs["To Max"].default_value = strength
        L(a2.outputs[0], m2.inputs["Value"])
        lines.append(m2)
acc = lines[0].outputs["Result"]
for l2 in lines[1:]:
    mx = N("ShaderNodeMath"); mx.operation = "MAXIMUM"; L(acc, mx.inputs[0]); L(l2.outputs["Result"], mx.inputs[1]); acc = mx.outputs[0]
smudge = N("ShaderNodeTexNoise"); smudge.inputs["Scale"].default_value = 0.0015; smudge.inputs["Detail"].default_value = 6
L(tc.outputs["Object"], smudge.inputs["Vector"])
pap = N("ShaderNodeValToRGB")
pap.color_ramp.elements[0].color = (*lin("8E9198"), 1)
pap.color_ramp.elements[1].color = (*lin("B4B7BC"), 1)
L(smudge.outputs["Fac"], pap.inputs["Fac"])
mixc = N("ShaderNodeMix"); mixc.data_type = "RGBA"; mixc.inputs["B"].default_value = (*lin("3D3F45"), 1)
L(acc, mixc.inputs["Factor"]); L(pap.outputs["Color"], mixc.inputs["A"])
L(mixc.outputs["Result"], b.inputs["Base Color"])
L(b.outputs["BSDF"], out.inputs["Surface"])
bm = bmesh.new()
bmesh.ops.create_grid(bm, x_segments=1, y_segments=1, size=60000)
o = new_obj("CoreSheet", bm, [m])
o.location = (0, 0, SHEET_Z)

# --- light + camera ------------------------------------------------------------------------------------------
ld = bpy.data.lights.get("CoreKey") or bpy.data.lights.new("CoreKey", "SUN")
ld.energy = 2.6
ld.angle = math.radians(14)
ld.color = (0.92, 0.95, 1.0)
lo = bpy.data.objects.get("CoreKey") or bpy.data.objects.new("CoreKey", ld)
if lo.name not in sc.collection.objects:
    sc.collection.objects.link(lo)
lo.rotation_euler = (math.radians(38), 0, math.radians(35))
fd = bpy.data.lights.get("CoreFill") or bpy.data.lights.new("CoreFill", "SUN")
fd.energy = 0.7
fd.angle = 0.8
fd.color = (0.85, 0.88, 0.95)
fd.use_shadow = False
fo = bpy.data.objects.get("CoreFill") or bpy.data.objects.new("CoreFill", fd)
if fo.name not in sc.collection.objects:
    sc.collection.objects.link(fo)
fo.rotation_euler = (math.radians(150), 0, math.radians(200))
cd = bpy.data.cameras.get("CoreCamData") or bpy.data.cameras.new("CoreCamData")
cam = bpy.data.objects.get("CoreCam") or bpy.data.objects.new("CoreCam", cd)
if cam.name not in sc.collection.objects:
    sc.collection.objects.link(cam)
cd.clip_end = 200000
sc.camera = cam
print("setup ok")
