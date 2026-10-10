"""The plains side (+X), whole again but in the same realistic style as the rest (user, Oct 10: no voxel here):
a lakeside hamlet of lit cottages, a little jetty, and two stone windmills on the shore (the Pixel Plains windmill
hill, grown up). exec after terrain.py."""
rng = random.Random(7)
H_WALL = mat("E_HamletWall", lin("DCCCAA"), 0.85)
H_ROOF = mat("E_HamletRoof", lin("9A4B36"), 0.8)
H_WIN = bpy.data.materials.get("E_Window") or mat("E_Window", lin("FFC067"), 0.5, emit=lin("FFB24F"), estr=12.0, haze=False)
H_STONE = mat("E_MillStone", lin("B4AC9C"), 0.85)
H_WOOD = mat("E_MillWood", lin("6E5038"), 0.85)

bm = bmesh.new()
placed = tries = 0
while placed < 40 and tries < 3000:
    tries += 1
    a = rng.uniform(0, math.tau)
    d = LAKE_R + rng.uniform(70, 330)
    x, y = LAKE.x + math.cos(a) * d, LAKE.y + math.sin(a) * d
    z = height(x, y)
    if z < WATER + 4 or math.hypot(x, y) < 650:
        continue
    cottage(bm, x, y, z, a + math.pi / 2 + rng.uniform(-0.3, 0.3), rng)
    placed += 1
# scattered farmsteads across the meadows toward the hill
for _ in range(18):
    x, y = rng.uniform(600, 2400), rng.uniform(-600, 1300)
    cottage(bm, x, y, height(x, y), rng.uniform(0, math.tau), rng)
new_obj("EHamlet", bm, [H_WALL, H_ROOF, H_WIN])

# two stone windmills on the shore, sails facing the hilltop
bm = bmesh.new()
for ang in (2.3, 3.5):
    x, y = LAKE.x + math.cos(ang) * (LAKE_R + 120), LAKE.y + math.sin(ang) * (LAKE_R + 120)
    z = height(x, y) - 4
    cyl(bm, (x, y, z + 45), 20, 14, 90, seg=16, side=0, cap=0)  # tapered stone tower
    cyl(bm, (x, y, z + 102), 17, 0.5, 26, seg=16, side=1, cap=1)  # cap roof
    window_quads(bm, (x, y, z + 45), (26, 26, 90), 0, 2, rows=2, cols=1, wsz=(4, 6), rng=rng, chance=0.8)
    face = (Vector((0, 0)) - Vector((x, y))).normalized()
    yaw = math.atan2(face.y, face.x)
    hub = Vector((x, y, z + 90)) + Vector((face.x, face.y, 0)) * 18
    for k in range(4):
        a = k * math.pi / 2 + 0.4 + ang
        for part, dims, off in (("spar", (2, 2.4, 70), 35), ("sail", (1, 12, 50), 42)):
            r = bmesh.ops.create_cube(bm, size=1.0)
            m = (Matrix.Translation(hub) @ Matrix.Rotation(yaw, 4, "Z") @ Matrix.Rotation(a, 4, "X")
                 @ Matrix.Translation((0, 7 if part == "sail" else 0, off)) @ Matrix.Diagonal((*dims, 1)))
            bmesh.ops.transform(bm, matrix=m, verts=r["verts"])
            for f in {f for v in r["verts"] for f in v.link_faces}:
                f.material_index = 3 if part == "spar" else 4
new_obj("EMills", bm, [H_STONE, H_ROOF, H_WIN, H_WOOD, H_WALL])
