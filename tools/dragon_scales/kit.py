# Hollow Dragon weak-point scales (CLAUDE.md step 7: the neon balls on its legs read as embers at its claws).
# Each becomes an armoured scale knot grown out of the leg: a ring of overlapping plum plates (pinecone rows) round a
# core that glows Kai-orange through the gaps while the scales are open (HollowDragon setScales colours the Core).
# Round on purpose: the same mesh works on all four legs whatever the facing. Fits the 3 x 3 x 3 Scale holder.
# Exec'd inside Blender through the MCP:  exec(open(<this file>).read()); build(); export()
#   HD_Scale_Plates   the plates (dragon plum)
#   HD_Scale_Core     the glowing core (coloured by the boss code: open / shut / burnt)
exec(open(r"C:\Users\User\OneDrive\Desktop\Coding\glitched_together\tools\trap_kit\kit.py").read())

SCENE = "DragonScales"
COLL = "DragonScales"
OUT = REPO + r"\blender_assets\dragon_scales"


def plate(bm, at, normal, up, w=0.62, h=0.8, t=0.12):
    """one curved scale: a flattened, slightly cupped teardrop facing `normal`, pointing down along -up"""
    tmp = bmesh.new()
    bmesh.ops.create_uvsphere(tmp, u_segments=12, v_segments=8, radius=1.0)
    for v in tmp.verts:
        x, y, z = v.co
        z2 = z * h
        x2 = x * w * (0.55 + 0.45 * (z + 1) / 2)  # wider at the top, a point at the bottom
        y2 = y * t + 0.18 * (x * x)  # cupped
        v.co = Vector((x2, y2, z2))
    n = Vector(normal).normalized()
    u = Vector(up)
    u = (u - n * u.dot(n)).normalized()
    r = n.cross(u)
    m = Matrix(((r.x, -n.x, u.x, 0), (r.y, -n.y, u.y, 0), (r.z, -n.z, u.z, 0), (0, 0, 0, 1)))
    bmesh.ops.transform(tmp, matrix=Matrix.Translation(Vector(at)) @ m, verts=tmp.verts)
    _merge(bm, tmp)


def build():
    sc, coll = scene()
    for ob in list(coll.objects):
        bpy.data.objects.remove(ob, do_unlink=True)
    plum = mat("HD_ScalePlum", (70, 46, 96), 0.2, 0.45)
    ember = mat("HD_ScaleCore", (255, 140, 40), 0.0, 0.4)
    bm = bmesh.new()
    rows = ((-0.55, 7, 1.05), (0.05, 8, 1.2), (0.6, 7, 1.0), (1.05, 4, 0.6))  # (height, count, ring radius)
    for k, (z, count, rad) in enumerate(rows):
        for i in range(count):
            a = (i + 0.5 * (k % 2)) / count * math.tau
            out = Vector((math.cos(a), math.sin(a), 0.35 + 0.25 * k))
            at = Vector((rad * math.cos(a), rad * math.sin(a), z))
            plate(bm, at, out, (0, 0, 1), w=0.62 - 0.08 * k, h=0.78 - 0.1 * k)
    plate(bm, (0, 0, 1.32), (0, 0, 1), (1, 0, 0), w=0.4, h=0.4, t=0.1)  # cap
    ob = new_obj("HD_Scale_Plates", bm, plum)
    for f in ob.data.polygons:
        f.use_smooth = True
    bm = bmesh.new()
    tmp = bmesh.new()
    bmesh.ops.create_icosphere(tmp, subdivisions=3, radius=1.05)
    for v in tmp.verts:
        v.co.z *= 1.15
    _merge(bm, tmp)
    ob = new_obj("HD_Scale_Core", bm, ember)
    for f in ob.data.polygons:
        f.use_smooth = True


def export():
    import os

    os.makedirs(OUT, exist_ok=True)
    allpts = [o.matrix_world @ Vector(b) for o in bpy.data.collections[COLL].objects for b in o.bound_box]
    mid = sum(allpts, Vector()) / len(allpts)
    lo = Vector((min(p.x for p in allpts), min(p.y for p in allpts), min(p.z for p in allpts)))
    hi = Vector((max(p.x for p in allpts), max(p.y for p in allpts), max(p.z for p in allpts)))
    mid = (lo + hi) / 2
    print("DESIGN", (round(hi.x - lo.x, 3), round(hi.z - lo.z, 3), round(hi.y - lo.y, 3)))
    for ob in list(bpy.data.collections[COLL].objects):
        bpy.ops.object.select_all(action="DESELECT")
        ob.select_set(True)
        bpy.context.view_layer.objects.active = ob
        bpy.ops.export_scene.gltf(
            filepath=os.path.join(OUT, ob.name + ".glb"),
            use_selection=True,
            use_active_scene=True,
            export_format="GLB",
            export_materials="NONE",
        )
        b = [ob.matrix_world @ Vector(c) for c in ob.bound_box]
        lo2 = Vector((min(p.x for p in b), min(p.y for p in b), min(p.z for p in b)))
        hi2 = Vector((max(p.x for p in b), max(p.y for p in b), max(p.z for p in b)))
        c = (lo2 + hi2) / 2
        sz = hi2 - lo2
        print("MESH", ob.name, "size", (round(sz.x, 3), round(sz.z, 3), round(sz.y, 3)),
              "offset", (round(-(c.x - mid.x), 3), round(c.z - mid.z, 3), round(c.y - mid.y, 3)))
