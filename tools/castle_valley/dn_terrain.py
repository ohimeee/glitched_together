exec(open(r"C:\Users\User\OneDrive\Desktop\Coding\glitched_together\tools\castle_valley\dnlib.py").read())
S = 12
R = 2580
bm = bmesh.new()
n = R * 2 // S + 1
grid = []
cols = []
grass = lin("4C6642"); dry = lin("6E7148"); dirt = lin("75614A"); mud = lin("3E3B31"); grav = lin("817B6E")


def mix(a, b, t):
    return tuple(a[i] * (1 - t) + b[i] * t for i in range(3))


for j in range(n):
    y = -R + j * S
    row = []
    for i in range(n):
        x = -R + i * S
        row.append(bm.verts.new((x, y, height(x, y))))
    grid.append(row)
for j in range(n - 1):
    for i in range(n - 1):
        f = bm.faces.new((grid[j][i], grid[j][i + 1], grid[j + 1][i + 1], grid[j + 1][i]))
        f.smooth = True
o = new_obj("DnTerrain", bm, [bpy.data.materials["C_Meadow"]])
me = o.data
ca = me.color_attributes.new("Col", "FLOAT_COLOR", "POINT")
for v in me.vertices:
    x, y, z = v.co
    rd = river_dist(x, y)
    dr = road_dist(x, y)
    r = max(abs(x), abs(y))
    nn = noise.noise(Vector((x / 150, y / 150, 5.0))) * 0.4 + noise.noise(Vector((x / 45, y / 45, 1.0))) * 0.15 + 0.5
    c = mix(grass, dry, max(0, min(1, (nn - 0.45) * 2.2)))
    if rd < 58:
        t = max(0, min(1, (58 - rd) / 22)); c = mix(c, mud, t)
        if rd < 30:
            c = mix(c, grav, 0.5)
    if dr < 13 and rd > 32 and r < 1500:
        t = max(0, min(1, (13 - dr) / 5)); c = mix(c, dirt, t)
    r = max(abs(x), abs(y))
    if r > 1100 and rd > 58:
        t = min(1, (r - 1100) / 350); c = mix(c, lin("4A5E48"), t)
    ca.data[v.index].color = (*c, 1)
print("terrain", len(me.polygons))
