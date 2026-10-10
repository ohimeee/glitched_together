# Hollow Dragon hide (MaterialVariant "DragonScales", tools/hollow_dragon/kit.py meshes): overlapping rounded scales
# in offset rows, tileable. The color map is near-white with darker rims and a soft top-light per scale, so the part
# Color (plum) tints it; the normal map is built from the same height field (OpenGL convention, Roblox).
import math
import random

from PIL import Image

S = 512
ROWS = 16  # rows per tile: spacing (32 px) under a scale's height, so rows overlap
COLS = 8


def height_field():
    """fish-scale overlap: discs in offset rows, row spacing smaller than a disc, so each lower row covers the bottom
    of the one below; the last painted (highest) disc containing a pixel wins"""
    import numpy as np

    rng = random.Random(4)
    cw = S / COLS
    ch = S / ROWS
    R = cw * 0.62
    ys, xs = np.mgrid[0:S, 0:S].astype(float)
    h = np.zeros((S, S))
    rim = np.ones((S, S))
    for r in range(ROWS + 2, -3, -1):  # bottom row first: each row above lies over the one below (roof tiles)
        off = (r % 2) * cw / 2
        cy = r * ch
        for c in range(-1, COLS + 1):
            cx = c * cw + off
            j = 0.06 * math.sin(c * 2.1 + r * 1.3)  # periodic per row/col so the tile still wraps
            # rows run past both edges (no vertical wrap copies: with an even row count the edges match)
            for tx in (-S, 0, S):
                dx = (xs - cx - tx) / R
                dy = (ys - cy) / (R * 1.05)
                d = np.sqrt(dx * dx + dy * dy)
                inside = (d < 1.0) & (dy > -0.35)  # a scale shows below its row line
                v = np.cos(np.clip(d, 0, 1) * np.pi / 2) * (1 + j)
                h = np.where(inside, v, h)
                rim = np.where(inside, d, rim)
    return h.tolist(), rim.tolist()


def main():
    h, rim = height_field()
    color = Image.new("RGB", (S, S))
    normal = Image.new("RGB", (S, S))
    rough = Image.new("L", (S, S))
    cp, np_, rp = color.load(), normal.load(), rough.load()
    for y in range(S):
        for x in range(S):
            v = h[y][x]
            d = rim[y][x]
            # bright centre, darker toward the rim, a dark gap between scales
            shade = 0.55 + 0.45 * v - (0.25 if d > 0.88 else 0)
            light = 0.08 * max(0.0, (S - y % (S // ROWS) * ROWS) / S)  # faint top light per row
            g = max(0, min(255, int(255 * (shade + light))))
            cp[x, y] = (g, int(g * 0.97), g)
            dx = h[y][(x + 1) % S] - h[y][(x - 1) % S]
            dy = h[(y + 1) % S][x] - h[(y - 1) % S][x]
            nx, ny, nz = -dx * 3, dy * 3, 1.0
            l = math.sqrt(nx * nx + ny * ny + nz * nz)
            np_[x, y] = (int((nx / l * 0.5 + 0.5) * 255), int((ny / l * 0.5 + 0.5) * 255), int((nz / l * 0.5 + 0.5) * 255))
            rp[x, y] = int(255 * (0.45 + 0.35 * d))  # glossy centres, matte edges
    color.save("dragon_scales_color.png")
    normal.save("dragon_scales_normal.png")
    rough.save("dragon_scales_rough.png")
    print("ok")


if __name__ == "__main__":
    main()
