# Pixel Plains voxel surfaces (MaterialVariants PPGrass / PPDirt / PPStone in adventure.project.json): every tile is
# 8x8 one-stud "voxel" cells (StudsPerTile 8), each cell one flat color from a small palette with a bevelled edge in
# the normal map, so any floor size reads as a block of chunky cubes (same stylized-voxel look as the trees and the
# Crusher King) instead of one stretched mesh. Writes pp_<surface>_color/normal/rough.png (512 px).
import math
import random

from PIL import Image, ImageDraw

S = 512
CELLS = 8
C = S // CELLS
BEVEL = 6  # px of bevel per cell edge

SURFACES = {
    "grass": {
        "colors": [(90, 152, 62), (82, 142, 56), (98, 160, 66), (76, 134, 52), (106, 166, 70), (86, 148, 58)],  # meadow, not lime
        "accent": [(128, 180, 84), (68, 124, 48)],  # a few lighter blades / darker clumps
        "accent_p": 0.12,
        "rough": 200,
    },
    "dirt": {
        "colors": [(140, 94, 56), (128, 84, 50), (150, 102, 62), (120, 78, 46), (134, 90, 54)],
        "accent": [(160, 150, 140), (104, 66, 40)],  # pebbles, dark clods
        "accent_p": 0.08,
        "rough": 230,
    },
    "stone": {
        "colors": [(138, 140, 148), (126, 128, 136), (150, 152, 160), (118, 120, 128), (144, 146, 152)],
        "accent": [(96, 140, 72), (104, 106, 114)],  # moss, dark crack stones
        "accent_p": 0.1,
        "rough": 210,
    },
}


def cell_normal(x, y):
    """Normal (0..255) for a pixel inside a cell: flat in the middle, tilted outward on the bevel."""
    nx = ny = 0.0
    if x < BEVEL:
        nx = -1
    elif x >= C - BEVEL:
        nx = 1
    if y < BEVEL:
        ny = 1  # OpenGL: +Y up in the image
    elif y >= C - BEVEL:
        ny = -1
    n = (nx * 0.55, ny * 0.55, 1.0)
    l = math.sqrt(sum(c * c for c in n))
    return tuple(int((c / l * 0.5 + 0.5) * 255) for c in n)


def make(name, spec, seed):
    rng = random.Random(seed)
    color = Image.new("RGB", (S, S))
    normal = Image.new("RGB", (S, S))
    rough = Image.new("L", (S, S), spec["rough"])
    cd = ImageDraw.Draw(color)
    rd = ImageDraw.Draw(rough)
    nrm = Image.new("RGB", (C, C))
    for y in range(C):
        for x in range(C):
            nrm.putpixel((x, y), cell_normal(x, y))
    for cy in range(CELLS):
        for cx in range(CELLS):
            base = rng.choice(spec["colors"])
            if rng.random() < spec["accent_p"]:
                base = rng.choice(spec["accent"])
            x0, y0 = cx * C, cy * C
            cd.rectangle([x0, y0, x0 + C - 1, y0 + C - 1], fill=base)
            # bevel shading in the color too (light top-left, dark bottom-right) so it reads without normals
            hi = tuple(min(255, int(c * 1.12)) for c in base)
            lo = tuple(int(c * 0.82) for c in base)
            cd.rectangle([x0, y0, x0 + C - 1, y0 + BEVEL - 1], fill=hi)
            cd.rectangle([x0, y0, x0 + BEVEL - 1, y0 + C - 1], fill=hi)
            cd.rectangle([x0, y0 + C - BEVEL, x0 + C - 1, y0 + C - 1], fill=lo)
            cd.rectangle([x0 + C - BEVEL, y0, x0 + C - 1, y0 + C - 1], fill=lo)
            # a little speckle inside the cell (pixel-art dithering, 4 px dots)
            for _ in range(rng.randint(2, 5)):
                px = x0 + BEVEL + rng.randrange(0, C - 2 * BEVEL - 4)
                py = y0 + BEVEL + rng.randrange(0, C - 2 * BEVEL - 4)
                v = rng.choice((0.92, 1.07))
                cd.rectangle([px, py, px + 3, py + 3], fill=tuple(min(255, int(c * v)) for c in base))
            normal.paste(nrm, (x0, y0))
            rd.rectangle([x0, y0, x0 + C - 1, y0 + BEVEL - 1], fill=spec["rough"] - 25)
    color.save(f"pp_{name}_color.png")
    normal.save(f"pp_{name}_normal.png")
    rough.save(f"pp_{name}_rough.png")


if __name__ == "__main__":
    for i, (n, spec) in enumerate(SURFACES.items()):
        make(n, spec, 100 + i)
    print("ok")
