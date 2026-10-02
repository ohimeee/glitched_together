exec(open(r"C:\Users\User\OneDrive\Desktop\Coding\glitched_together\tools\castle_valley\dnlib.py").read())
import json
random.seed(11)
houses = json.load(open(os.path.join(SCR, "houses.json")))
PINES = [mat("D_Pine%d" % i, lin(h), 0.85) for i, h in enumerate(("2E4A36", "34503A", "3A5A3C", "2A4434"))]
LEAF = [mat("D_Leaf%d" % i, lin(h), 0.85) for i, h in enumerate(("4F6A3A", "5E7240", "6A6A3C"))]
BARK = mat("D_Bark", lin("4A3A2C"), 0.9)
ROCK = mat("D_Rock", lin("7C786E"), 0.9)

# simple grid lookup for houses
def near_house(x, y, pad):
    for hx, hy, r in houses:
        if abs(hx - x) < r + pad and abs(hy - y) < r + pad:
            return True
    return False

bm = bmesh.new()
placed = 0
cell = {}
for k in range(78000):
    x = random.uniform(-2500, 2500); y = random.uniform(-2500, 2500)
    rd = river_dist(x, y)
    if rd < 36:
        continue
    dr = road_dist(x, y)
    if dr < 16:
        continue
    if near_house(x, y, 22):
        continue
    # forest density: big noise masses + thinning near the village/road
    dens = noise.noise(Vector((x / 380, y / 380, 9.0))) * 0.5 + 0.5
    if math.hypot(x - (-30), y - 260) < 330:
        dens -= 0.3  # village meadows
    if dr < 40:
        dens -= 0.25
    lone = random.random() < 0.035
    if not lone and random.random() > (dens - 0.25) * 1.9:
        continue
    if max(abs(x), abs(y)) > 1400 and height(x, y) < WATER + 3:
        continue
    key = (int(x // 9), int(y // 9))
    if key in cell:
        continue
    cell[key] = 1
    z = height(x, y)
    if random.random() < (0.35 if lone else 0.8):
        h = random.uniform(22, 44)
        r = h * random.uniform(0.28, 0.34)
        mi = random.randrange(4)
        rot = random.uniform(0, 6.3)
        cone(bm, x, y, z - 1, 1.0, h * 0.18, seg=5, mi=4, r_top=0.8)
        for tier, (rf, zf, hf) in enumerate(((1.0, 0.14, 0.5), (0.74, 0.4, 0.42), (0.48, 0.64, 0.36))):
            cone(bm, x, y, z + h * zf, r * rf, h * hf, seg=8, mi=mi, rot=rot + tier)
    else:
        h = random.uniform(16, 26)
        cone(bm, x, y, z - 1, 1.2, h * 0.5, seg=5, mi=4, r_top=0.9)
        mi = 5 + random.randrange(3)
        for b in range(3):
            bx = x + random.uniform(-3, 3); by = y + random.uniform(-3, 3)
            rr = h * random.uniform(0.22, 0.3)
            # low-poly blob = two cones back to back
            cz = z + h * random.uniform(0.55, 0.75)
            cone(bm, bx, by, cz, rr, rr * 0.9, seg=7, mi=mi, rot=random.uniform(0, 6))
            cone(bm, bx, by, cz, rr, -rr * 0.6, seg=7, mi=mi, rot=random.uniform(0, 6))
    placed += 1
o = new_obj("DnTrees", bm, PINES + [BARK] + LEAF)
print("trees", placed, len(o.data.polygons))

# rocks: river stones + outcrops
bm = bmesh.new()
for k in range(900):
    x = random.uniform(-1300, 1300); y = random.uniform(-1300, 1300)
    rd = river_dist(x, y)
    if road_dist(x, y) < 14 or near_house(x, y, 10):
        continue
    if 9 < rd < 40:
        s = random.uniform(2, 6)
    elif noise.noise(Vector((x / 200, y / 200, 3.0))) > 0.35 and rd > 80:
        s = random.uniform(5, 16)
    else:
        continue
    z = height(x, y)
    ret = bmesh.ops.create_icosphere(bm, subdivisions=1, radius=s)
    for v in ret["verts"]:
        v.co.x = v.co.x * random.uniform(0.8, 1.3) + x
        v.co.y = v.co.y * random.uniform(0.8, 1.3) + y
        v.co.z = v.co.z * random.uniform(0.4, 0.7) + z - s * 0.15
o = new_obj("DnRocks", bm, [ROCK])
print("rocks", len(o.data.polygons))

# river water: strip along the centreline with ripples
W = mat("D_River", lin("1B2738"), 0.16)
next(n for n in W.node_tree.nodes if n.type == "BSDF_PRINCIPLED").inputs["Specular IOR Level"].default_value = 0.3
nt = W.node_tree
b = next(n for n in nt.nodes if n.type == "BSDF_PRINCIPLED")
if not any(n.type == "BUMP" for n in nt.nodes):
    tc = nt.nodes.new("ShaderNodeTexCoord")
    wv = nt.nodes.new("ShaderNodeTexNoise"); wv.inputs["Scale"].default_value = 0.08; wv.inputs["Detail"].default_value = 4
    mp = nt.nodes.new("ShaderNodeMapping"); mp.inputs["Scale"].default_value = (1, 4, 1)
    nt.links.new(tc.outputs["Object"], mp.inputs["Vector"]); nt.links.new(mp.outputs["Vector"], wv.inputs["Vector"])
    bu = nt.nodes.new("ShaderNodeBump"); bu.inputs["Strength"].default_value = 0.25
    nt.links.new(wv.outputs["Fac"], bu.inputs["Height"]); nt.links.new(bu.outputs["Normal"], b.inputs["Normal"])
bm = bmesh.new()
prev = None
for xi in range(-2600, 2601, 8):
    x = float(xi)
    yc = river_y(x)
    a = bm.verts.new((x, yc - 55, WATER + 0.6)); c = bm.verts.new((x, yc + 55, WATER + 0.6))
    if prev:
        bm.faces.new((prev[0], a, c, prev[1]))
    prev = (a, c)
new_obj("DnRiver", bm, [W])
