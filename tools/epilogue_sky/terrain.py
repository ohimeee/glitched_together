"""Epilogue terrain: the hilltop under the level, the valley, the castle crag, the lake and the far ring of
mountains (two grids: 50 studs inside +-2500, 250 studs out to +-14000). exec after lib.py + sky.py."""


def ground_mat():
    """One ground shader: grass/meadow by noise, rock on slopes, snow on the high peaks (no per-face patches)."""
    m = mat("E_Ground", lin("4E7A4C"), 0.9, haze=False)
    t = m.node_tree
    b = next(n for n in t.nodes if n.type == "BSDF_PRINCIPLED")
    N_, L_ = t.nodes.new, t.links.new
    tc = N_("ShaderNodeTexCoord")
    geo = N_("ShaderNodeNewGeometry")
    nz = N_("ShaderNodeTexNoise"); nz.inputs["Scale"].default_value = 0.004; nz.inputs["Detail"].default_value = 6
    L_(tc.outputs["Object"], nz.inputs["Vector"])
    ramp = N_("ShaderNodeValToRGB")
    e = ramp.color_ramp.elements
    e[0].position = 0.35; e[0].color = (*lin("2F5236"), 1)
    e[1].position = 0.68; e[1].color = (*lin("7A8C52"), 1)
    mid = e.new(0.5); mid.color = (*lin("4C7646"), 1)
    L_(nz.outputs["Fac"], ramp.inputs["Fac"])
    sepn = N_("ShaderNodeSeparateXYZ"); L_(geo.outputs["Normal"], sepn.inputs[0])
    rock = N_("ShaderNodeMapRange"); rock.inputs["From Min"].default_value = 0.7; rock.inputs["From Max"].default_value = 0.55
    L_(sepn.outputs["Z"], rock.inputs["Value"])
    mr = N_("ShaderNodeMix"); mr.data_type = "RGBA"; mr.inputs["B"].default_value = (*lin("6C6878"), 1)
    L_(rock.outputs["Result"], mr.inputs["Factor"]); L_(ramp.outputs["Color"], mr.inputs["A"])
    sepp = N_("ShaderNodeSeparateXYZ"); L_(tc.outputs["Object"], sepp.inputs[0])
    sn2 = N_("ShaderNodeMath"); sn2.operation = "MULTIPLY_ADD"; sn2.inputs[1].default_value = 220; sn2.inputs[2].default_value = 0
    L_(nz.outputs["Fac"], sn2.inputs[0])
    snz = N_("ShaderNodeMath"); snz.operation = "ADD"; L_(sepp.outputs["Z"], snz.inputs[0]); L_(sn2.outputs[0], snz.inputs[1])
    snow = N_("ShaderNodeMapRange"); snow.inputs["From Min"].default_value = 760; snow.inputs["From Max"].default_value = 860
    L_(snz.outputs[0], snow.inputs["Value"])
    ms = N_("ShaderNodeMix"); ms.data_type = "RGBA"; ms.inputs["B"].default_value = (*lin("DCE2F2"), 1)
    L_(snow.outputs["Result"], ms.inputs["Factor"]); L_(mr.outputs["Result"], ms.inputs["A"])
    L_(ms.outputs["Result"], b.inputs["Base Color"])
    add_haze(m, HAZE, start=900, end=10000, strength=0.75)
    return m


G_GROUND = ground_mat()
G_WATER = mat("E_Water", lin("0C1638"), 0.04, haze=False)


def terrain_grid(name, step, half, hole=0.0):
    bm = bmesh.new()
    n = int(2 * half / step)
    verts = {}
    for i in range(n + 1):
        for j in range(n + 1):
            x, y = -half + i * step, -half + j * step
            if hole and max(abs(x), abs(y)) < hole - step:
                continue
            verts[(i, j)] = bm.verts.new((x, y, height(x, y)))
    for i in range(n):
        for j in range(n):
            q = [verts.get(k) for k in ((i, j), (i + 1, j), (i + 1, j + 1), (i, j + 1))]
            if None in q:
                continue
            cx, cy = -half + (i + 0.5) * step, -half + (j + 0.5) * step
            if hole and max(abs(cx), abs(cy)) < hole:
                continue
            f = bm.faces.new(q)
            f.smooth = True
    return new_obj(name, bm, [G_GROUND])


terrain_grid("ETerrainNear", 50, 2500)
terrain_grid("ETerrainFar", 250, 14000, hole=2500)

bm = bmesh.new()
bmesh.ops.create_circle(bm, cap_ends=True, radius=LAKE_R + 60, segments=64)
lake = new_obj("ELake", bm, [G_WATER])
lake.location = (LAKE.x, LAKE.y, WATER)
