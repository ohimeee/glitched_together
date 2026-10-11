"""Starfall Castle tool VFX textures (run: python textures/make_castlefx.py). Uploaded with Studio MCP upload_image;
ids live in src/shared/Config/ToolFx.luau. Storybook-stylized (art-direction.md §12): hard-edged layered flames,
star-shaped sparks for Kai's fire (his motif), a white sword slash, soft smoke, a dashed area ring. Particles are
drawn white/greyscale where the emitter's Color should tint them, and in full color where the bands are the look."""
import math, os, random
import numpy as np
from PIL import Image, ImageDraw, ImageFilter

random.seed(12)
OUT = os.path.dirname(os.path.abspath(__file__)) + "/"
WHITE = (255, 255, 255)


def flame_poly(cx, base, w, h, lean=0.0, steps=40):
    """Teardrop flame outline: round belly at the bottom, curling tip at the top."""
    pts = []
    for i in range(steps + 1):
        t = i / steps * 0.94  # 0 bottom → tip (stops short of a hairline point), right side
        r = w * math.sin(math.pi * min(1, t * 1.15)) ** 0.8 * (1 - t) ** 0.35
        x = cx + r + lean * h * t * t
        pts.append((x, base - h * t))
    for i in range(steps, -1, -1):
        t = i / steps * 0.94
        r = w * math.sin(math.pi * min(1, t * 1.15)) ** 0.8 * (1 - t) ** 0.35
        x = cx - r + lean * h * t * t
        pts.append((x, base - h * t))
    return pts


# 1) Flame (full color, layered bands like painted game fire), 256
S = 256
img = Image.new("RGBA", (S, S), (0, 0, 0, 0))
d = ImageDraw.Draw(img)
for w, h, col in (
    (86, 220, (226, 70, 40, 255)),  # red rim
    (70, 180, (255, 140, 40, 255)),  # orange
    (48, 128, (255, 205, 70, 255)),  # yellow
    (24, 70, (255, 248, 210, 255)),  # hot core
):
    d.polygon(flame_poly(S / 2, S - 18, w, h, lean=0.12), fill=col)
img.save(OUT + "FX_Flame.png")

# 2) Star spark (Kai's motif): a chunky five-point star with a soft glow, white (tinted by the emitter), 128
S = 128
img = Image.new("RGBA", (S, S), (0, 0, 0, 0))


def star(cx, cy, ro, ri, rot=-math.pi / 2):
    pts = []
    for i in range(10):
        r = ro if i % 2 == 0 else ri
        a = rot + i * math.pi / 5
        pts.append((cx + r * math.cos(a), cy + r * math.sin(a)))
    return pts


glow = Image.new("RGBA", (S, S), (0, 0, 0, 0))
ImageDraw.Draw(glow).polygon(star(64, 66, 52, 24), fill=WHITE + (170,))
img = Image.alpha_composite(img, glow.filter(ImageFilter.GaussianBlur(7)))
ImageDraw.Draw(img).polygon(star(64, 66, 40, 18), fill=WHITE + (255,))
img.save(OUT + "FX_StarSpark.png")

# 3) Sword slash: a crescent swoosh, bright leading edge fading to the tail, white, 256
S = 256
arr = np.zeros((S, S, 4), float)
yy, xx = np.mgrid[0:S, 0:S]
cx, cy = S * 0.5, S * 0.62
r = np.hypot(xx - cx, yy - cy)
ang = np.arctan2(yy - cy, xx - cx)  # -pi..pi, top half is negative
band = np.clip(1 - np.abs(r - 92) / 22, 0, 1)  # the crescent band
sweep = np.clip((-ang - 0.25) / (math.pi - 0.5), 0, 1)  # 0 at the tail (right) → 1 at the leading edge (left)
alpha = band ** 0.6 * sweep ** 1.3 * (ang < -0.2)
arr[..., :3] = 255
arr[..., 3] = np.clip(alpha, 0, 1) * 255
Image.fromarray(arr.astype(np.uint8), "RGBA").filter(ImageFilter.GaussianBlur(1.2)).save(OUT + "FX_Slash.png")
# the backhand swing sweeps the other way: the same swoosh mirrored
Image.open(OUT + "FX_Slash.png").transpose(Image.FLIP_LEFT_RIGHT).save(OUT + "FX_SlashBack.png")

# 4) Smoke puff: soft lumpy cloud, grey-white (tinted), 128
S = 128
img = Image.new("RGBA", (S, S), (0, 0, 0, 0))
d = ImageDraw.Draw(img)
for _ in range(9):
    r = random.randint(18, 30)
    x = random.randint(40, 88)
    y = random.randint(44, 84)
    d.ellipse([x - r, y - r, x + r, y + r], fill=(235, 235, 240, 150))
img.filter(ImageFilter.GaussianBlur(5)).save(OUT + "FX_Smoke.png")

# 5) Dashed area ring (meteor / rally target on the floor, readable from the top-down camera), white, 256
S = 256
img = Image.new("RGBA", (S, S), (0, 0, 0, 0))
d = ImageDraw.Draw(img)
for i in range(24):
    a0 = i * 360 / 24
    d.arc([10, 10, S - 10, S - 10], a0, a0 + 9, fill=WHITE + (255,), width=12)
d.ellipse([34, 34, S - 34, S - 34], outline=WHITE + (110,), width=4)
fill = Image.new("RGBA", (S, S), (0, 0, 0, 0))
ImageDraw.Draw(fill).ellipse([16, 16, S - 16, S - 16], fill=WHITE + (45,))
Image.alpha_composite(fill, img).save(OUT + "FX_AreaRing.png")

print("ok")
