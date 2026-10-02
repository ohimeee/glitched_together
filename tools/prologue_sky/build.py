"""Prologue sky (Blender scene PrologueSky): the title screen of Kai and Miko's childhood game, built for real.

A navy theater void with soft stars and a faint nebula, a glossy mirror floor far below, giant floating menu panels
made of frosted acrylic with neon rims (NEW GAME, LOAD GAME, OPTIONS...), a volume slider, checkboxes, a giant mouse
cursor, the kid-handwritten "Starfall Kingdom" logo glowing on the horizon ahead, floating pixel stars, and a couple
of magenta Glitch cracks (Glitch level 1, art-direction section 7). Run through Blender MCP execute_blender_code:
    exec(open(r"<repo>/tools/prologue_sky/build.py").read())
Render with tools/blender_sky.py render_faces. See BLENDER_PLAYBOOK.md section 10.
"""
import bpy, bmesh, math, random
from mathutils import Vector, Matrix, noise

exec(open(r"C:\Users\User\OneDrive\Desktop\Coding\glitched_together\tools\core_sky\corelib.py").read())
random.seed(21)
FLOOR_Z = -700.0

sc = bpy.data.scenes.get("PrologueSky") or bpy.data.scenes.new("PrologueSky")
bpy.context.window.scene = sc
try:
    sc.render.engine = "CYCLES"
except TypeError:
    pass
sc.cycles.device = "GPU"
sc.cycles.use_denoising = True
sc.view_settings.view_transform = "AgX"
try:
    sc.view_settings.look = "AgX - Medium High Contrast"
except TypeError:
    pass


def pcoll():
    c = bpy.data.collections.get("PrologueSet")
    if c is None:
        c = bpy.data.collections.new("PrologueSet")
        sc.collection.children.link(c)
    return c


def pobj(name, bm, mats):
    old = bpy.data.objects.get(name)
    if old:
        bpy.data.objects.remove(old, do_unlink=True)
    me = bpy.data.meshes.new(name)
    bm.to_mesh(me)
    bm.free()
    for m in mats:
        me.materials.append(m)
    o = bpy.data.objects.new(name, me)
    pcoll().objects.link(o)
    return o


for o in list(pcoll().objects):
    bpy.data.objects.remove(o, do_unlink=True)

# --- world: navy void, stars, faint nebula ---------------------------------------------------------------------
w = bpy.data.worlds.get("PrologueWorld") or bpy.data.worlds.new("PrologueWorld")
w.use_nodes = True
nt = w.node_tree
nt.nodes.clear()
N, L = nt.nodes.new, nt.links.new
out = N("ShaderNodeOutputWorld")
bg = N("ShaderNodeBackground")
tc = N("ShaderNodeTexCoord")
sub = N("ShaderNodeVectorMath"); sub.operation = "SUBTRACT"; sub.inputs[1].default_value = (0.5, 0.5, 0.5)
nrm = N("ShaderNodeVectorMath"); nrm.operation = "NORMALIZE"
L(tc.outputs["Generated"], sub.inputs[0]); L(sub.outputs[0], nrm.inputs[0])
sep = N("ShaderNodeSeparateXYZ"); L(nrm.outputs[0], sep.inputs[0])
mr = N("ShaderNodeMapRange"); mr.inputs["From Min"].default_value = -0.2; mr.inputs["From Max"].default_value = 1.0
L(sep.outputs["Z"], mr.inputs["Value"])
ramp = N("ShaderNodeValToRGB")
ramp.color_ramp.elements[0].position = 0.0
ramp.color_ramp.elements[0].color = (*lin("1C2858"), 1)
ramp.color_ramp.elements[1].position = 1.0
ramp.color_ramp.elements[1].color = (*lin("05081A"), 1)
e = ramp.color_ramp.elements.new(0.25); e.color = (*lin("111A3A"), 1)
L(mr.outputs["Result"], ramp.inputs["Fac"])
# stars: tiny voronoi points
vor = N("ShaderNodeTexVoronoi"); vor.feature = "F1"; vor.inputs["Scale"].default_value = 260
L(nrm.outputs[0], vor.inputs["Vector"])
st = N("ShaderNodeMapRange"); st.inputs["From Min"].default_value = 0.0; st.inputs["From Max"].default_value = 0.05
st.inputs["To Min"].default_value = 1.0; st.inputs["To Max"].default_value = 0.0
L(vor.outputs["Distance"], st.inputs["Value"])
pw = N("ShaderNodeMath"); pw.operation = "POWER"; pw.inputs[1].default_value = 6; L(st.outputs["Result"], pw.inputs[0])
# only some cells get a star (random cell color)
sc_ = N("ShaderNodeSeparateColor"); L(vor.outputs["Color"], sc_.inputs[0])
gate = N("ShaderNodeMath"); gate.operation = "GREATER_THAN"; gate.inputs[1].default_value = 0.3; L(sc_.outputs[0], gate.inputs[0])
sg = N("ShaderNodeMath"); sg.operation = "MULTIPLY"; L(pw.outputs[0], sg.inputs[0]); L(gate.outputs[0], sg.inputs[1])
up = N("ShaderNodeMapRange"); up.inputs["From Min"].default_value = -0.02; up.inputs["From Max"].default_value = 0.15
L(sep.outputs["Z"], up.inputs["Value"])
su = N("ShaderNodeMath"); su.operation = "MULTIPLY"; su.inputs[1].default_value = 3.0; L(sg.outputs[0], su.inputs[0])
su2 = N("ShaderNodeMath"); su2.operation = "MULTIPLY"; L(su.outputs[0], su2.inputs[0]); L(up.outputs["Result"], su2.inputs[1])
# nebula: soft violet / pink clouds, very faint
neb = N("ShaderNodeTexNoise"); neb.inputs["Scale"].default_value = 1.6; neb.inputs["Detail"].default_value = 6; neb.inputs["Roughness"].default_value = 0.6
L(nrm.outputs[0], neb.inputs["Vector"])
nm = N("ShaderNodeMapRange"); nm.inputs["From Min"].default_value = 0.52; nm.inputs["From Max"].default_value = 0.78; nm.inputs["To Max"].default_value = 0.3
L(neb.outputs["Fac"], nm.inputs["Value"])
nm2 = N("ShaderNodeMath"); nm2.operation = "MULTIPLY"; L(nm.outputs["Result"], nm2.inputs[0]); L(up.outputs["Result"], nm2.inputs[1])
mixn = N("ShaderNodeMix"); mixn.data_type = "RGBA"; mixn.inputs["B"].default_value = (*lin("6A4A9A"), 1)
L(nm2.outputs[0], mixn.inputs["Factor"]); L(ramp.outputs["Color"], mixn.inputs["A"])
add = N("ShaderNodeMix"); add.data_type = "RGBA"; add.blend_type = "ADD"; add.inputs["B"].default_value = (0.9, 0.93, 1.0, 1)
L(su2.outputs[0], add.inputs["Factor"]); L(mixn.outputs["Result"], add.inputs["A"])
L(add.outputs["Result"], bg.inputs["Color"])
bg.inputs["Strength"].default_value = 1.0
L(bg.outputs["Background"], out.inputs["Surface"])
sc.world = w

# --- materials ---------------------------------------------------------------------------------------------------
HAZE = lin("162050")
ACRYL = mat("P_Acrylic", lin("26356E"), 0.25, emit=lin("33458A"), estr=0.35)
ACRYL2 = mat("P_AcrylicLight", lin("3A4C8E"), 0.3, emit=lin("4A5DA6"), estr=0.4)
RIM = mat("P_NeonWhite", lin("EEF2FF"), 0.4, emit=lin("EEF2FF"), estr=5.0)
PINK = mat("P_NeonPink", lin("FF5FA2"), 0.4, emit=lin("FF5FA2"), estr=5.0)
LABEL = mat("P_Label", lin("EEF2FF"), 0.4, emit=lin("EEF2FF"), estr=3.0)
DARK = mat("P_Dark", lin("0A0F24"), 0.4)
GLITCH = mat("P_Glitch", lin("FF2BD6"), 0.5, emit=lin("FF2BD6"), estr=3.0)
CYAN = mat("P_GlitchCyan", lin("2BF2FF"), 0.5, emit=lin("2BF2FF"), estr=2.0)
for m in (ACRYL, ACRYL2, DARK):
    add_haze(m, HAZE, start=1200, end=11000, strength=0.8)
FLOOR = mat("P_Floor", lin("0B1230"), 0.12)
FLOOR.node_tree.nodes  # glossy mirror stage; faint grid of UI-white lines
fnt = FLOOR.node_tree
fb = next(n for n in fnt.nodes if n.type == "BSDF_PRINCIPLED")
ftc = fnt.nodes.new("ShaderNodeTexCoord")
fsep = fnt.nodes.new("ShaderNodeSeparateXYZ"); fnt.links.new(ftc.outputs["Object"], fsep.inputs[0])
lines = []
for axis in ("X", "Y"):
    dv = fnt.nodes.new("ShaderNodeMath"); dv.operation = "DIVIDE"; dv.inputs[1].default_value = 400
    fnt.links.new(fsep.outputs[axis], dv.inputs[0])
    fr = fnt.nodes.new("ShaderNodeMath"); fr.operation = "PINGPONG"; fr.inputs[1].default_value = 0.5
    fnt.links.new(dv.outputs[0], fr.inputs[0])
    mr2 = fnt.nodes.new("ShaderNodeMapRange"); mr2.inputs["From Min"].default_value = 0.0; mr2.inputs["From Max"].default_value = 0.012
    mr2.inputs["To Min"].default_value = 1.0; mr2.inputs["To Max"].default_value = 0.0
    fnt.links.new(fr.outputs[0], mr2.inputs["Value"])
    lines.append(mr2)
mx = fnt.nodes.new("ShaderNodeMath"); mx.operation = "MAXIMUM"
fnt.links.new(lines[0].outputs["Result"], mx.inputs[0]); fnt.links.new(lines[1].outputs["Result"], mx.inputs[1])
gm = fnt.nodes.new("ShaderNodeMath"); gm.operation = "MULTIPLY"; gm.inputs[1].default_value = 0.6
fnt.links.new(mx.outputs[0], gm.inputs[0])
fnt.links.new(gm.outputs[0], fb.inputs["Emission Strength"])
fb.inputs["Emission Color"].default_value = (*lin("3B57B8"), 1)
add_haze(FLOOR, HAZE, start=1500, end=20000, strength=0.9)
bm = bmesh.new()
bmesh.ops.create_grid(bm, x_segments=1, y_segments=1, size=60000)
fo = pobj("PrologueFloor", bm, [FLOOR])
fo.location = (0, 0, FLOOR_Z)

FONT_UI = bpy.data.fonts.load(r"C:\Windows\Fonts\ARLRDBD.TTF", check_existing=True)
FONT_KID = bpy.data.fonts.load(r"C:\Windows\Fonts\segoeprb.ttf", check_existing=True)


def text(name, body, font, size, mat_, loc, rot, extrude=0.0):
    cu = bpy.data.curves.new(name, "FONT")
    cu.body = body
    cu.font = font
    cu.size = size
    cu.align_x = "CENTER"
    cu.align_y = "CENTER"
    cu.extrude = extrude
    o = bpy.data.objects.new(name, cu)
    o.data.materials.append(mat_)
    o.location = loc
    o.rotation_euler = rot
    pcoll().objects.link(o)
    return o


def facing(x, y):
    return math.atan2(-x, y)  # yaw that turns an upright -Y-facing panel toward the origin


def panel(i, label, x, y, z, w_, h_, tilt=0.0, roll=0.0, rim=None, broken=False):
    """frosted acrylic slab (bevelled), neon rim, glowing label; faces the camera at the origin"""
    yaw = facing(x, y)
    rot = Matrix.Translation(Vector((x, y, z))) @ Matrix.Rotation(yaw, 4, "Z") @ Matrix.Rotation(tilt, 4, "X") @ Matrix.Rotation(roll, 4, "Y")
    bm = bmesh.new()
    d = max(8.0, h_ * 0.08)
    ret = bmesh.ops.create_cube(bm, size=1.0)
    for v in ret["verts"]:
        v.co = Vector((v.co.x * w_, v.co.y * d, v.co.z * h_))
    bmesh.ops.bevel(bm, geom=[e for e in bm.edges if abs(e.verts[0].co.y - e.verts[1].co.y) > 0.1 * d], offset=h_ * 0.22, segments=6, affect="EDGES")
    for f in bm.faces:
        f.material_index = 0
    # rim: thin rounded ring just in front, outlining the slab (emissive tube made of short boxes)
    r = h_ * 0.22
    pts = []
    for cx, cz, a0 in ((w_ / 2 - r, h_ / 2 - r, 0), (-w_ / 2 + r, h_ / 2 - r, 90), (-w_ / 2 + r, -h_ / 2 + r, 180), (w_ / 2 - r, -h_ / 2 + r, 270)):
        for k in range(7):
            a = math.radians(a0 + k * 15)
            pts.append(Vector((cx + math.cos(a) * r, -d / 2 - 1.5, cz + math.sin(a) * r)))
    tube = max(2.5, h_ * 0.025)
    for k in range(len(pts)):
        p0, p1 = pts[k], pts[(k + 1) % len(pts)]
        if broken and 0.35 < k / len(pts) < 0.6:
            continue
        mid = (p0 + p1) / 2
        seg = p1 - p0
        ang = math.atan2(seg.z, seg.x)
        rr = bmesh.ops.create_cube(bm, size=1.0)
        for v in rr["verts"]:
            v.co = Matrix.Translation(mid) @ Matrix.Rotation(-ang, 4, "Y") @ Vector((v.co.x * (seg.length + tube), v.co.y * tube, v.co.z * tube))
        for f in {f for v in rr["verts"] for f in v.link_faces}:
            f.material_index = 1
    bm.transform(rot)
    o = pobj(f"PPanel{i}", bm, [ACRYL if i % 3 else ACRYL2, rim or RIM])
    if label:
        t = text(f"PLabel{i}", label, FONT_UI, h_ * 0.42, LABEL, (0, 0, 0), (0, 0, 0), extrude=1.0)
        t.matrix_world = rot @ Matrix.Translation(Vector((0, -d / 2 - 2.5, -h_ * 0.02))) @ Matrix.Rotation(math.radians(90), 4, "X")
    if broken:  # a magenta Glitch crack across the slab, cyan fringe offset
        bm2 = bmesh.new()
        n = 8
        prev = None
        for k in range(n + 1):
            t_ = k / n
            px = -w_ * 0.15 + w_ * 0.3 * t_ + random.uniform(-0.05, 0.05) * w_
            pz = h_ / 2 - h_ * t_
            for mi, off in ((0, 0.0), (1, 6.0)):
                pass
            cur = (px, pz)
            if prev:
                for mi, off in ((0, 0.0), (1, h_ * 0.03)):
                    a = Vector((prev[0] + off, -d / 2 - 3 - mi, prev[1]))
                    b = Vector((cur[0] + off, -d / 2 - 3 - mi, cur[1]))
                    mid = (a + b) / 2
                    seg = b - a
                    ang = math.atan2(seg.z, seg.x)
                    rr = bmesh.ops.create_cube(bm2, size=1.0)
                    for v in rr["verts"]:
                        v.co = Matrix.Translation(mid) @ Matrix.Rotation(-ang, 4, "Y") @ Vector((v.co.x * (seg.length + 3), v.co.y * 2, v.co.z * h_ * 0.035))
                    for f in {f for v in rr["verts"] for f in v.link_faces}:
                        f.material_index = mi
            prev = cur
        bm2.transform(rot)
        pobj(f"PCrack{i}", bm2, [GLITCH, CYAN])
    return rot


def at(az, el, dist):
    a, e = math.radians(az), math.radians(el)
    return (math.cos(a) * math.cos(e) * dist, math.sin(a) * math.cos(e) * dist, math.sin(e) * dist)


# azimuth 90 = +Y = straight ahead along the level
PANELS = [  # all above the horizon and far: below it they read like platforms the players could reach
    ("NEW GAME", 62, 9, 4600, 1500, 360, 0.08, 0.03, False),
    ("LOAD GAME", 118, 6, 5000, 1550, 360, -0.05, -0.04, False),
    ("OPTIONS", 38, 4, 4200, 1300, 330, 0.15, 0.06, True),
    ("CREDITS", 145, 3, 4000, 1200, 300, -0.1, 0.1, False),
    ("QUIT", 168, 13, 5600, 1000, 300, 0.05, -0.12, False),
    ("CONTINUE?", 15, 16, 6200, 1900, 420, 0.0, 0.05, False),
    ("SETTINGS", 215, 7, 4400, 1400, 330, 0.1, -0.08, False),
    ("PLAYER 2", 250, 4, 4100, 1300, 330, -0.12, 0.05, False),
    ("SAVE SLOT 1", 290, 11, 5000, 1700, 360, 0.06, 0.02, True),
    ("SAVE SLOT 2", 322, 5, 4600, 1700, 360, -0.04, -0.06, False),
    ("", 345, 22, 7000, 2200, 500, 0.0, 0.1, False),
    ("", 190, 20, 7400, 2000, 480, 0.1, 0.0, False),
    ("PRESS START", 96, 4, 3800, 1300, 300, 0.2, 0.0, False),
]
for i, (label, az, el, dist, w_, h_, tilt, roll, broken) in enumerate(PANELS):
    x, y, z = at(az, el, dist)
    panel(i, label, x, y, z, w_, h_, tilt, roll, rim=PINK if i % 4 == 0 else None, broken=broken)

# volume slider + checkboxes + toggle: UI widgets built big
bm = bmesh.new()
x, y, z = at(22, 20, 4200)
yaw = facing(x, y)
R = Matrix.Translation(Vector((x, y, z))) @ Matrix.Rotation(yaw, 4, "Z") @ Matrix.Rotation(0.1, 4, "Y")
box(bm, (0, 0, 0), (1800, 30, 60), mi=0)
box(bm, (-200, -30, 0), (1300, 10, 40), mi=1)
cyl(bm, (420, -40, 0), (420, 40, 0), 130, seg=24, mi=1)
bm.transform(R)
pobj("PSlider", bm, [DARK, RIM])
text("PSliderLabel", "VOLUME", FONT_UI, 160, LABEL, (0, 0, 0), (0, 0, 0)).matrix_world = R @ Matrix.Translation(Vector((-500, -40, 220))) @ Matrix.Rotation(math.radians(90), 4, "X")
for k, (az, el, dist, on) in enumerate(((150, 25, 4500, True), (30, 28, 5000, False), (200, 8, 4200, True))):
    x, y, z = at(az, el, dist)
    R = Matrix.Translation(Vector((x, y, z))) @ Matrix.Rotation(facing(x, y), 4, "Z") @ Matrix.Rotation(random.uniform(-0.3, 0.3), 4, "Y")
    bm = bmesh.new()
    s = 360
    for a, b_ in (((0, s / 2), (s, 30)), ((0, -s / 2), (s, 30)), ((s / 2, 0), (30, s)), ((-s / 2, 0), (30, s))):
        box(bm, (a[0], 0, a[1]), (b_[0], 30, b_[1]), mi=0)
    box(bm, (0, 10, 0), (s, 10, s), mi=1)
    if on:  # a big checkmark
        for (p0, p1) in (((-110, 0), (-20, -100)), ((-20, -100), (140, 120))):
            a = Vector((p0[0], -25, p0[1])); b_ = Vector((p1[0], -25, p1[1]))
            mid = (a + b_) / 2; seg = b_ - a; ang = math.atan2(seg.z, seg.x)
            rr = bmesh.ops.create_cube(bm, size=1.0)
            for v in rr["verts"]:
                v.co = Matrix.Translation(mid) @ Matrix.Rotation(-ang, 4, "Y") @ Vector((v.co.x * (seg.length + 40), v.co.y * 30, v.co.z * 40))
            for f in {f for v in rr["verts"] for f in v.link_faces}:
                f.material_index = 2
    bm.transform(R)
    pobj(f"PCheck{k}", bm, [RIM, ACRYL, PINK])

# the giant mouse cursor arrow, tilted, floating over the menu
bm = bmesh.new()
outline = [(0, 0), (0, -1000), (240, -770), (420, -1150), (560, -1090), (390, -720), (720, -720)]
for layer, (mi, scale_, yoff) in enumerate(((0, 1.0, 0), (1, 1.12, 30))):
    cx = sum(p[0] for p in outline) / len(outline); cz = sum(p[1] for p in outline) / len(outline)
    vs_f, vs_b = [], []
    for (px, pz) in outline:
        px = cx + (px - cx) * scale_; pz = cz + (pz - cz) * scale_
        vs_f.append(bm.verts.new((px, yoff - 30, pz)))
        vs_b.append(bm.verts.new((px, yoff + 30, pz)))
    f1 = bm.faces.new(vs_f); f1.material_index = mi
    f2 = bm.faces.new(list(reversed(vs_b))); f2.material_index = mi
    for k in range(len(outline)):
        j = (k + 1) % len(outline)
        f = bm.faces.new((vs_f[k], vs_f[j], vs_b[j], vs_b[k])); f.material_index = mi
x, y, z = at(66, 4, 4200)
bm.transform(Matrix.Translation(Vector((x, y, z))) @ Matrix.Rotation(facing(x, y), 4, "Z") @ Matrix.Rotation(-0.35, 4, "Y") @ Matrix.Scale(0.6, 4))
pobj("PCursor", bm, [mat("P_CursorWhite", lin("EEF2FF"), 0.35, emit=lin("EEF2FF"), estr=1.2), DARK])

# the logo on the horizon ahead: kid handwriting in neon, a star over it
x, y, z = at(90, 15, 9500)
logo_rot = (math.radians(90), 0, facing(x, y))
text("PLogo", "Starfall Kingdom", FONT_KID, 1900, mat("P_LogoWhite", lin("FFF4E0"), 0.4, emit=lin("FFF4E0"), estr=7.0), (x, y, z), logo_rot, extrude=20)
glow = text("PLogoGlow", "Starfall Kingdom", FONT_KID, 1900, PINK, (x * 1.01, y * 1.01, z * 1.01 - 25), logo_rot, extrude=10)
glow.data.offset = 26
bm = bmesh.new()
sx, sy, sz = at(90, 23.5, 9400)
star_pts = []
for k in range(10):
    a = math.radians(90 + k * 36)
    rr = 520 if k % 2 == 0 else 220
    star_pts.append((math.cos(a) * rr, math.sin(a) * rr))
vs = [bm.verts.new((p[0], 0, p[1])) for p in star_pts]
c0 = bm.verts.new((0, 0, 0))
for k in range(10):
    bm.faces.new((c0, vs[k], vs[(k + 1) % 10]))
bm.transform(Matrix.Translation(Vector((sx, sy, sz))) @ Matrix.Rotation(facing(sx, sy), 4, "Z") @ Matrix.Rotation(0.2, 4, "Y"))
pobj("PLogoStar", bm, [mat("P_StarGold", lin("FFD98A"), 0.4, emit=lin("FFD98A"), estr=6.0)])

# floating pixel stars all around
bm = bmesh.new()
for k in range(55):
    az = random.uniform(0, 360); el = random.uniform(-5, 35); dist = random.uniform(2500, 9000)
    x, y, z = at(az, el, dist)
    s = dist * random.uniform(0.003, 0.007)
    R = Matrix.Translation(Vector((x, y, z))) @ Matrix.Rotation(facing(x, y), 4, "Z") @ Matrix.Rotation(random.uniform(0, 1.5), 4, "Y")
    for (px, pz, wx, wz) in ((0, 0, 3, 1), (0, 0, 1, 3)):
        for v in box(bm, (px, 0, pz), (wx * s, s * 0.6, wz * s), mi=0 if k % 5 else 1):
            v.co = R @ v.co
pobj("PPixelStars", bm, [RIM, PINK])
print("prologue built")


# --- toy planets (reference: It Takes Two's space chapter: glossy painted toy planets, rings, floating toy blocks) --
def planet_mat(name, c1, c2, bands=7.0):
    m = bpy.data.materials.get(name) or bpy.data.materials.new(name)
    m.use_nodes = True
    nt = m.node_tree
    nt.nodes.clear()
    o_ = nt.nodes.new("ShaderNodeOutputMaterial")
    b = nt.nodes.new("ShaderNodeBsdfPrincipled")
    b.inputs["Roughness"].default_value = 0.22
    b.inputs["Coat Weight"].default_value = 0.6  # lacquered toy paint
    t = nt.nodes.new("ShaderNodeTexCoord")
    sp = nt.nodes.new("ShaderNodeSeparateXYZ"); nt.links.new(t.outputs["Object"], sp.inputs[0])
    wv = nt.nodes.new("ShaderNodeTexWave"); wv.wave_type = "BANDS"; wv.bands_direction = "Z"
    wv.inputs["Scale"].default_value = bands; wv.inputs["Distortion"].default_value = 0.6; wv.inputs["Detail"].default_value = 2
    nt.links.new(t.outputs["Generated"], wv.inputs["Vector"])
    rp = nt.nodes.new("ShaderNodeValToRGB")
    rp.color_ramp.elements[0].color = (*c1, 1); rp.color_ramp.elements[1].color = (*c2, 1)
    nt.links.new(wv.outputs["Fac"], rp.inputs["Fac"])
    nt.links.new(rp.outputs["Color"], b.inputs["Base Color"])
    nt.links.new(b.outputs["BSDF"], o_.inputs["Surface"])
    add_haze(m, HAZE, start=1500, end=18000, strength=0.7)
    return m


PLANETS = [  # az, el, dist, radius, colors, ring
    (128, 16, 5200, 900, ("E39A5B", "B85A4A"), True),
    (40, 30, 7000, 700, ("7B6FD6", "C3B8FF"), False),
    (230, 20, 6000, 1200, ("4A7FD0", "9FD0F2"), True),
    (305, 32, 8000, 600, ("F2C46B", "D9824A"), False),
    (175, 7, 4800, 380, ("B57BE0", "6C4AA8"), False),
]
for k, (az, el, dist, rad, cols, ring) in enumerate(PLANETS):
    x, y, z = at(az, el, dist)
    bm = bmesh.new()
    bmesh.ops.create_uvsphere(bm, u_segments=48, v_segments=24, radius=rad)
    for f in bm.faces:
        f.smooth = True
    o = pobj(f"PPlanet{k}", bm, [planet_mat(f"P_Planet{k}", lin(cols[0]), lin(cols[1]), bands=random.uniform(4, 9))])
    o.location = (x, y, z)
    o.rotation_euler = (random.uniform(-0.4, 0.4), random.uniform(-0.4, 0.4), 0)
    if ring:
        bm = bmesh.new()
        segs = 96
        r0, r1 = rad * 1.35, rad * 1.9
        inner = [bm.verts.new((math.cos(a) * r0, math.sin(a) * r0, 0)) for a in (i / segs * math.tau for i in range(segs))]
        outer = [bm.verts.new((math.cos(a) * r1, math.sin(a) * r1, 0)) for a in (i / segs * math.tau for i in range(segs))]
        for i in range(segs):
            j = (i + 1) % segs
            bm.faces.new((inner[i], inner[j], outer[j], outer[i]))
        bmesh.ops.solidify(bm, geom=bm.faces[:], thickness=rad * 0.03)
        ro = pobj(f"PRing{k}", bm, [mat(f"P_Ring{k}", lin("EEE2C8"), 0.3, emit=lin("FFD9A0"), estr=0.15)])
        ro.location = (x, y, z)
        ro.rotation_euler = (math.radians(22), math.radians(-12), math.radians(az))

# floating toy blocks: hundreds of small painted cubes drifting at every depth
bm = bmesh.new()
cols = [mat(f"P_Block{i}", lin(h), 0.35) for i, h in enumerate(("2E3F86", "4A3A8E", "6B5BC4", "1F2A5E", "8E7BE8"))]
for c in cols:
    add_haze(c, HAZE, start=1500, end=18000, strength=0.75)
for k in range(420):
    az = random.uniform(0, 360); el = random.uniform(-25, 40); dist = random.uniform(900, 9000)
    x, y, z = at(az, el, dist)
    s = dist * random.uniform(0.008, 0.03)
    box(bm, (x, y, z), (s, s, s), rot=random.uniform(0, 6.3), mi=random.randrange(len(cols)), tilt=(random.uniform(-1, 1), random.uniform(-1, 1)))
pobj("PBlocks", bm, cols)

# a cool rim/key light from above-behind and a warm low fill from the logo's side
for name, energy, color, rot in (("PKey", 1.2, (0.7, 0.75, 1.0), (math.radians(40), 0, math.radians(200))),
                                  ("PWarm", 0.5, (1.0, 0.75, 0.55), (math.radians(80), 0, math.radians(0)))):
    ld = bpy.data.lights.get(name) or bpy.data.lights.new(name, "SUN")
    ld.energy = energy; ld.color = color; ld.angle = math.radians(6)
    lo = bpy.data.objects.get(name) or bpy.data.objects.new(name, ld)
    if lo.name not in sc.collection.objects:
        sc.collection.objects.link(lo)
    lo.rotation_euler = rot
    lo.visible_glossy = False  # the mirror floor would show the lamp as a bright blob
cd = bpy.data.cameras.get("PCamData") or bpy.data.cameras.new("PCamData")
cam = bpy.data.objects.get("PCam") or bpy.data.objects.new("PCam", cd)
if cam.name not in sc.collection.objects:
    sc.collection.objects.link(cam)
sc.camera = cam
print("planets + blocks + lights ok")
