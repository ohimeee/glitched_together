"""Epilogue sky: render settings, the night world shader (warm horizon glow, teal-navy dome, stars, Milky Way),
the moon over the castle and its light. exec after lib.py (build.py does both)."""
SC.render.engine = "CYCLES"
SC.cycles.device = "GPU"
SC.cycles.use_denoising = True
SC.view_settings.view_transform = "AgX"
try:
    SC.view_settings.look = "AgX - Medium High Contrast"
except TypeError:
    pass
SC.view_settings.exposure = 0.3  # user (Oct 11): a bit brighter

MOON_DIR = Vector((-0.86, 0.33, 0.39)).normalized()  # over the castle (left of the path), ~23 degrees up
MW_N = Vector((0.75, -0.2, 0.35)).normalized()  # Milky Way great circle: rises ahead-right, arcs over, sets behind-left

w = bpy.data.worlds.get("EpilogueWorld") or bpy.data.worlds.new("EpilogueWorld")
w.use_nodes = True
nt = w.node_tree
nt.nodes.clear()
N, L = nt.nodes.new, nt.links.new


def math_node(op, a=None, b=None, va=None, vb=None):
    m = N("ShaderNodeMath")
    m.operation = op
    if a is not None:
        L(a, m.inputs[0])
    elif va is not None:
        m.inputs[0].default_value = va
    if b is not None:
        L(b, m.inputs[1])
    elif vb is not None:
        m.inputs[1].default_value = vb
    return m.outputs[0]


def maprange(v, fmin, fmax, tmin=0.0, tmax=1.0):
    m = N("ShaderNodeMapRange")
    m.inputs["From Min"].default_value = fmin
    m.inputs["From Max"].default_value = fmax
    m.inputs["To Min"].default_value = tmin
    m.inputs["To Max"].default_value = tmax
    L(v, m.inputs["Value"])
    return m.outputs["Result"]


def mix_rgb(fac, a, b_color, blend="MIX"):
    m = N("ShaderNodeMix")
    m.data_type = "RGBA"
    m.blend_type = blend
    L(fac, m.inputs["Factor"])
    L(a, m.inputs["A"])
    if isinstance(b_color, tuple):
        m.inputs["B"].default_value = (*b_color, 1)
    else:
        L(b_color, m.inputs["B"])
    return m.outputs["Result"]


out = N("ShaderNodeOutputWorld")
bg = N("ShaderNodeBackground")
tc = N("ShaderNodeTexCoord")
nrm = N("ShaderNodeVectorMath"); nrm.operation = "NORMALIZE"  # world Generated = the view direction already
L(tc.outputs["Generated"], nrm.inputs[0])
D = nrm.outputs[0]
sep = N("ShaderNodeSeparateXYZ"); L(D, sep.inputs[0])
Z = sep.outputs["Z"]

# dome gradient by elevation: dusty-rose glow on the horizon -> violet -> teal-navy -> deep navy
ramp = N("ShaderNodeValToRGB")
els = ramp.color_ramp.elements
els[0].position = 0.0; els[0].color = (*lin("2A2A55"), 1)
els[1].position = 1.0; els[1].color = (*lin("070C26"), 1)
# fac = (z + 0.4) / 1.4: the horizon sits at 0.286
for pos, col in ((0.286, "C78F86"), (0.305, "8E6F9C"), (0.34, "3E4A8C"), (0.45, "1C2C66"), (0.65, "0E1840")):
    e = els.new(pos); e.color = (*lin(col), 1)
L(maprange(Z, -0.4, 1.0), ramp.inputs["Fac"])
sky = ramp.outputs["Color"]

# the horizon glow is warmer on the moon side
md = N("ShaderNodeVectorMath"); md.operation = "DOT_PRODUCT"; md.inputs[1].default_value = MOON_DIR
L(D, md.inputs[0])
moonside = math_node("MULTIPLY", maprange(md.outputs["Value"], 0.3, 1.0), maprange(Z, 0.35, -0.02))
sky = mix_rgb(math_node("MULTIPLY", moonside, None, vb=0.45), sky, lin("E8B48A"))
# moon halo
halo = math_node("POWER", maprange(md.outputs["Value"], 0.965, 1.0), None, vb=3.0)
sky = mix_rgb(math_node("MULTIPLY", halo, None, vb=0.25), sky, lin("B8C8F0"), "ADD")

# Milky Way: soft band around a great circle, cloudy, with dark dust lanes and a warm core
mwd = N("ShaderNodeVectorMath"); mwd.operation = "DOT_PRODUCT"; mwd.inputs[1].default_value = MW_N
L(D, mwd.inputs[0])
band = math_node("POWER", maprange(math_node("ABSOLUTE", mwd.outputs["Value"]), 0.0, 0.36, 1.0, 0.0), None, vb=1.8)
cl = N("ShaderNodeTexNoise"); cl.inputs["Scale"].default_value = 4.0; cl.inputs["Detail"].default_value = 10; cl.inputs["Roughness"].default_value = 0.62
L(D, cl.inputs["Vector"])
dust = N("ShaderNodeTexNoise"); dust.inputs["Scale"].default_value = 9.0; dust.inputs["Detail"].default_value = 8; dust.inputs["Roughness"].default_value = 0.6
L(D, dust.inputs["Vector"])
cloud = maprange(cl.outputs["Fac"], 0.4, 0.75)
lanes = maprange(dust.outputs["Fac"], 0.48, 0.6, 1.0, 0.25)
above = maprange(Z, -0.02, 0.2)
mw = math_node("MULTIPLY", math_node("MULTIPLY", band, cloud), math_node("MULTIPLY", lanes, above))
core = math_node("POWER", band, None, vb=4.0)
blue = N("ShaderNodeRGB"); blue.outputs[0].default_value = (*lin("B39BEA"), 1)  # violet band (user ref, Oct 11)
mwcol = mix_rgb(core, blue.outputs[0], lin("F4DCE6"))
sky = mix_rgb(math_node("MULTIPLY", mw, None, vb=1.1), sky, mwcol, "ADD")

# stars: two Voronoi layers (fine + a few bright), denser along the Milky Way, fading at the horizon


def stars(scale, thresh, power, gain, radius):
    vor = N("ShaderNodeTexVoronoi"); vor.feature = "F1"; vor.inputs["Scale"].default_value = scale
    L(D, vor.inputs["Vector"])
    pt = math_node("POWER", maprange(vor.outputs["Distance"], 0.0, radius, 1.0, 0.0), None, vb=power)
    sc_ = N("ShaderNodeSeparateColor"); L(vor.outputs["Color"], sc_.inputs[0])
    gate = math_node("GREATER_THAN", sc_.outputs[0], None, vb=thresh)
    tw = maprange(sc_.outputs[1], 0.0, 1.0, 0.4, 1.0)  # per-star brightness
    return math_node("MULTIPLY", math_node("MULTIPLY", pt, gate), math_node("MULTIPLY", tw, None, vb=gain))


# user (Oct 11): "make more stars so appreciate the skies": lower gates (more cells lit) + a third fine dust layer
# radius is in Voronoi cells: one 1024 face pixel is ~0.0015 rad, so a star needs radius ~ 0.0015 * scale to cover
# a pixel (the first version used 0.06 everywhere: sub-pixel dots that the render averaged away)
s1 = stars(300, 0.86, 2.5, 2.6, 0.4)
s2 = stars(90, 0.74, 3, 6.0, 0.26)
s3 = stars(450, 0.92, 2, 1.4, 0.5)
dens = maprange(band, 0.0, 1.0, 0.6, 3.2)  # star fields pack along the Milky Way
st = math_node("MULTIPLY", math_node("MULTIPLY", math_node("ADD", math_node("ADD", s1, s2), s3), dens), maprange(Z, -0.01, 0.12))
sky = mix_rgb(st, sky, lin("EEF2FF"), "ADD")
L(sky, bg.inputs["Color"])
bg.inputs["Strength"].default_value = 1.25
L(bg.outputs["Background"], out.inputs["Surface"])
SC.world = w

# --- moon: emissive sphere with soft maria, far out along MOON_DIR; never casts shadows -------------------------
old = bpy.data.objects.get("EpiMoon")
if old:
    bpy.data.objects.remove(old, do_unlink=True)
bm = bmesh.new()
bmesh.ops.create_uvsphere(bm, u_segments=48, v_segments=24, radius=620)
moon = new_obj("EpiMoon", bm, [])
moon.location = MOON_DIR * 16000
for p in moon.data.polygons:
    p.use_smooth = True
mm = bpy.data.materials.get("E_Moon") or bpy.data.materials.new("E_Moon")
mm.use_nodes = True
mnt = mm.node_tree
mnt.nodes.clear()
mo = mnt.nodes.new("ShaderNodeOutputMaterial")
me_ = mnt.nodes.new("ShaderNodeEmission")
mn = mnt.nodes.new("ShaderNodeTexNoise"); mn.inputs["Scale"].default_value = 2.2; mn.inputs["Detail"].default_value = 6
mr_ = mnt.nodes.new("ShaderNodeValToRGB")
mr_.color_ramp.elements[0].position = 0.42; mr_.color_ramp.elements[0].color = (*lin("C9CFE0"), 1)
mr_.color_ramp.elements[1].position = 0.6; mr_.color_ramp.elements[1].color = (*lin("FFF6E6"), 1)
mnt.links.new(mn.outputs["Fac"], mr_.inputs["Fac"])
mnt.links.new(mr_.outputs["Color"], me_.inputs["Color"])
me_.inputs["Strength"].default_value = 6.0
mnt.links.new(me_.outputs["Emission"], mo.inputs["Surface"])
moon.data.materials.append(mm)
moon.visible_shadow = False
moon.visible_glossy = True

# moonlight
ld = bpy.data.lights.get("EpiMoonLight") or bpy.data.lights.new("EpiMoonLight", "SUN")
ld.energy = 1.6
ld.color = lin("C4D2FF")
ld.angle = math.radians(1.0)
lo = bpy.data.objects.get("EpiMoonLight") or bpy.data.objects.new("EpiMoonLight", ld)
if lo.name not in coll().objects:
    coll().objects.link(lo)
lo.rotation_mode = "QUATERNION"
lo.rotation_quaternion = (-MOON_DIR).to_track_quat("-Z", "Y")

cam = bpy.data.objects.get("EpiCam")
if cam is None:
    cam = bpy.data.objects.new("EpiCam", bpy.data.cameras.new("EpiCam"))
    coll().objects.link(cam)
cam.data.clip_end = 200000
SC.camera = cam
