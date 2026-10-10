# Crusher King throne hall palette (tools/boss_arena/kit.py): 8x8 swatches of 64 px, like tree_palette.png (flat toy
# colors, a faint pixel bevel per voxel face) plus a light speckle on stone so the big walls don't read as plastic.
# Index = row * 8 + col; the kit's constants (STONE, OLD, MOSS, ...) must match this order.
import random

from PIL import Image, ImageDraw

S = 64
N = 8
COLORS = [
    # 0  castle stone, warm cream-grey, dark -> light (shade 0..7)
    (88, 82, 78), (108, 101, 94), (128, 120, 110), (148, 139, 126), (168, 158, 142), (188, 177, 158), (206, 195, 175), (224, 214, 194),
    # 8  old foundation stone, cooler grey, dark -> light
    (64, 66, 74), (80, 82, 90), (98, 100, 108), (116, 118, 126), (134, 136, 144), (152, 154, 160), (170, 172, 178), (190, 192, 196),
    # 16 moss / ivy, dark -> light
    (36, 88, 40), (48, 108, 44), (62, 128, 46), (82, 148, 48), (104, 166, 52), (130, 184, 60), (160, 202, 72), (192, 220, 96),
    # 24 banner royal purple (the king's robe), dark -> light
    (52, 26, 82), (66, 34, 104), (84, 44, 128), (102, 54, 150), (118, 64, 168), (136, 82, 186), (156, 104, 204), (180, 132, 220),
    # 32 gold, dark -> light
    (120, 78, 20), (150, 100, 24), (176, 124, 30), (200, 148, 40), (222, 172, 50), (236, 192, 70), (246, 212, 104), (252, 232, 150),
    # 40 wood dark -> light, 44 slate roof (plum-grey) dark -> light
    (74, 46, 28), (104, 68, 40), (138, 94, 58), (176, 128, 84), (58, 50, 74), (76, 66, 96), (96, 86, 118), (120, 110, 140),
    # 48 glitch magenta, glitch black, cyan fringe, white
    (255, 43, 214), (14, 10, 20), (43, 242, 255), (246, 244, 236),
    # 52 carpet velvet (the throne's), dark -> light
    (104, 18, 32), (132, 24, 42), (164, 30, 48), (190, 48, 64),
    # 56 iron dark -> light
    (42, 42, 48), (62, 62, 70), (88, 88, 98), (118, 118, 128),
    # 60 stained glass: amber, violet, deep blue, rose
    (246, 178, 60), (150, 90, 210), (54, 82, 196), (232, 120, 150),
]
SPECKLE = set(range(0, 16))  # stone swatches


def swatch(color, i):
    rng = random.Random(i * 7919)
    img = Image.new("RGB", (S, S), color)
    d = ImageDraw.Draw(img)
    if i in SPECKLE:
        for _ in range(70):
            x, y = rng.randrange(S), rng.randrange(S)
            k = rng.uniform(0.86, 1.1)
            c = tuple(max(0, min(255, int(ch * k))) for ch in color)
            r = rng.choice((1, 1, 2))
            d.rectangle([x, y, x + r, y + r], fill=c)
    hi = tuple(min(255, int(c * 1.08) + 6) for c in color)
    lo = tuple(int(c * 0.86) for c in color)
    d.line([(0, 0), (S - 1, 0)], fill=hi, width=3)
    d.line([(0, 0), (0, S - 1)], fill=hi, width=3)
    d.line([(0, S - 1), (S - 1, S - 1)], fill=lo, width=3)
    d.line([(S - 1, 0), (S - 1, S - 1)], fill=lo, width=3)
    return img


def main():
    atlas = Image.new("RGB", (S * N, S * N), (128, 128, 128))
    for i, color in enumerate(COLORS):
        r, c = divmod(i, N)
        atlas.paste(swatch(color, i), (c * S, r * S))
    atlas.save("arena_palette.png")
    print("swatches", len(COLORS))


if __name__ == "__main__":
    main()
