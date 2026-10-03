# Pixel Plains voxel tree palette (tools/pp_trees/trees.py): 8x8 swatches of 64 px, flat toy-plastic colors with a
# faint pixel bevel, so each voxel face reads as one clean pixel of color. Order must match SWATCHES in trees.py.
from PIL import Image, ImageDraw

S = 64
N = 8
COLORS = [
    # leaves, dark -> light (shade 0..7)
    (36, 88, 40), (48, 108, 44), (62, 128, 46), (82, 148, 48), (104, 166, 52), (130, 184, 60), (160, 202, 72), (192, 220, 96),
    # pine needles, dark -> light
    (22, 64, 52), (30, 82, 60), (40, 100, 66), (54, 118, 72), (70, 136, 80), (90, 152, 90), (112, 168, 100), (136, 184, 112),
    # bark, dark -> light
    (66, 40, 26), (84, 52, 32), (104, 66, 40), (124, 82, 50), (144, 98, 62), (164, 116, 76), (180, 134, 92), (196, 152, 110),
    # birch bark light -> dark marks, then birch leaves (lighter, yellower)
    (236, 232, 220), (214, 210, 198), (190, 186, 176), (60, 56, 52), (120, 170, 64), (146, 190, 74), (174, 206, 90), (204, 224, 118),
    # apples, blossoms, moss
    (196, 40, 40), (226, 70, 56), (250, 236, 240), (244, 206, 220), (96, 132, 48), (120, 150, 56), (230, 196, 60), (250, 226, 120),
    # petals (purple, blue, white, red), then rock greys dark -> light
    (150, 100, 210), (90, 130, 230), (248, 248, 240), (228, 60, 70), (96, 98, 108), (122, 124, 134), (148, 150, 158), (176, 178, 186),
]


def swatch(color):
    img = Image.new("RGB", (S, S), color)
    d = ImageDraw.Draw(img)
    hi = tuple(min(255, int(c * 1.08) + 6) for c in color)
    lo = tuple(int(c * 0.88) for c in color)
    d.line([(0, 0), (S - 1, 0)], fill=hi, width=3)
    d.line([(0, 0), (0, S - 1)], fill=hi, width=3)
    d.line([(0, S - 1), (S - 1, S - 1)], fill=lo, width=3)
    d.line([(S - 1, 0), (S - 1, S - 1)], fill=lo, width=3)
    return img


def main():
    atlas = Image.new("RGB", (S * N, S * N), (128, 128, 128))
    for i, color in enumerate(COLORS):
        r, c = divmod(i, N)
        atlas.paste(swatch(color), (c * S, r * S))
    atlas.save("tree_palette.png")
    print("swatches", len(COLORS))


if __name__ == "__main__":
    main()
