# Crusher King palette atlas (tools/crusher_king/kit.py): 8x8 swatches of 128 px. Each swatch = one painted wooden
# toy cube face: brushed paint over faint wood grain, paint chipped away near the edges to bare beech, a dark
# worn rim. The kit UVs every cube face over the whole swatch, so the bevels land on the chipped rim.
# Index = row * 8 + col; names and order must match SWATCHES in tools/crusher_king/kit.py.
import math
import random

from PIL import Image, ImageDraw, ImageFilter

S = 128
N = 8
COLORS = [
    ("robe", (118, 64, 168)),
    ("robe_dark", (84, 44, 128)),
    ("gold", (236, 186, 52)),
    ("gold_dark", (190, 132, 30)),
    ("ermine", (246, 242, 230)),
    ("black", (34, 30, 36)),
    ("skin", (240, 196, 150)),
    ("skin_shade", (214, 160, 118)),
    ("brown", (112, 68, 40)),
    ("hair", (84, 52, 34)),
    ("white", (250, 250, 246)),
    ("rose", (232, 128, 120)),
    ("ruby", (212, 40, 56)),
    ("sapphire", (44, 92, 210)),
    ("iron", (128, 132, 142)),
    ("iron_dark", (86, 90, 100)),
    ("kai", (255, 140, 26)),  # Kai's tangerine (art-direction.md §6): the fists are his freeze targets
    ("glitch", (255, 43, 214)),  # the Glitch's magenta
    ("velvet", (164, 30, 48)),
    ("leather", (92, 56, 32)),
    ("wood", (222, 184, 132)),
]
BARE = (226, 192, 142)  # beech under the paint


def grain(img, rng, strength):
    d = ImageDraw.Draw(img)
    for _ in range(26):
        y = rng.uniform(0, S)
        amp = rng.uniform(1, 4)
        f = rng.uniform(0.02, 0.06)
        ph = rng.uniform(0, 6.3)
        shade = rng.uniform(-1, 1) * strength
        pts = [(x, y + amp * math.sin(x * f + ph)) for x in range(0, S + 4, 4)]
        col = tuple(max(0, min(255, int(c + shade))) for c in img.getpixel((0, int(y) % S)))
        d.line(pts, fill=col, width=rng.choice((1, 1, 2)))


def swatch(color, seed, glitch=False):
    rng = random.Random(seed)
    img = Image.new("RGB", (S, S), color)
    grain(img, rng, 10)  # wood grain telegraphing through the paint
    # brush strokes
    d = ImageDraw.Draw(img)
    for _ in range(40):
        x = rng.uniform(0, S)
        y = rng.uniform(0, S)
        l = rng.uniform(10, 40)
        v = rng.uniform(-7, 7)
        c = tuple(max(0, min(255, int(ch + v))) for ch in color)
        d.line([(x, y), (x + l, y + rng.uniform(-1, 1))], fill=c, width=2)
    img = img.filter(ImageFilter.GaussianBlur(0.6))
    # chips: bare wood showing through, mostly along the rim
    bare = Image.new("RGB", (S, S), BARE)
    grain(bare, rng, 18)
    mask = Image.new("L", (S, S), 0)
    m = ImageDraw.Draw(mask)
    for _ in range(rng.randint(2, 4)):
        side = rng.randrange(4)
        t = rng.uniform(4, S - 4)
        r = rng.uniform(2, 6)
        cx, cy = [(t, 3), (S - 3, t), (t, S - 3), (3, t)][side]
        m.ellipse([cx - r * 1.6, cy - r, cx + r * 1.6, cy + r], fill=255)
    for _ in range(rng.randint(0, 2)):  # a ding in the middle
        cx, cy, r = rng.uniform(20, S - 20), rng.uniform(20, S - 20), rng.uniform(1.5, 3)
        m.ellipse([cx - r, cy - r, cx + r, cy + r], fill=255)
    mask = mask.filter(ImageFilter.GaussianBlur(0.8))
    img = Image.composite(bare, img, mask)
    # dark grime in the very rim
    rim = Image.new("L", (S, S), 0)
    ImageDraw.Draw(rim).rectangle([0, 0, S - 1, S - 1], outline=70, width=4)  # the bevel: paint worn darker
    img = Image.composite(Image.new("RGB", (S, S), (50, 36, 26)), img, rim.filter(ImageFilter.GaussianBlur(1.5)))
    if glitch:  # static: horizontal tears + a few dead pixels, no wood (the Glitch isn't paint)
        img = Image.new("RGB", (S, S), color)
        d = ImageDraw.Draw(img)
        for _ in range(18):
            y = rng.randrange(S)
            h = rng.randint(1, 6)
            c = rng.choice([(255, 255, 255), (20, 0, 30), (0, 240, 255), (255, 120, 235)])
            d.rectangle([rng.randrange(-20, S // 2), y, rng.randrange(S // 2, S + 20), y + h], fill=c)
    return img


def main():
    atlas = Image.new("RGB", (S * N, S * N), (128, 128, 128))
    i = 0
    for name, color in COLORS:
        for variant in range(2):
            r, c = divmod(i, N)
            atlas.paste(swatch(color, 1000 + i * 7919, name == "glitch"), (c * S, r * S))
            i += 1
    atlas.save("king_palette.png")
    print("swatches", i)


if __name__ == "__main__":
    main()
