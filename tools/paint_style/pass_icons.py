"""Game pass icons (Oct 19): "Glowing Aura" (99) and "Name Tag Color" (49), 512 x 512. Each shows what you get on
a plain blocky avatar (any player's avatar wears it): a warm gold glow + sparkles, or a coloured title tag over the
head with the colour choices below. Colours come from Config/Supporters (never teal / magenta: owner colours).

Usage: python tools/paint_style/pass_icons.py  ->  marketing/passes/pass_aura.png, pass_tag.png
"""
import pathlib

import numpy as np
from PIL import Image, ImageDraw, ImageFilter, ImageFont

ROOT = pathlib.Path(__file__).resolve().parents[2]
OUT = ROOT / "marketing" / "passes"
FONT = r"C:\Users\User\tools\fonts\LilitaOne-Regular.ttf"
S = 1024
AURA = (255, 226, 150)
TAGS = [(255, 200, 61), (255, 140, 66), (255, 92, 92), (150, 230, 80), (110, 170, 255), (235, 238, 245)]
rng = np.random.default_rng(7)


def background(glow):
    y, x = np.mgrid[0:S, 0:S]
    d = np.clip(np.hypot(x - S * 0.5, y - S * 0.45) / (S * 0.72), 0, 1)[..., None]
    bg = np.array([70, 60, 150]) * (1 - d) + np.array([14, 16, 48]) * d
    g = np.exp(-(((x - S * 0.5) ** 2 + (y - S * 0.5) ** 2) / (2 * (S * 0.22) ** 2)))[..., None]
    bg = bg * (1 - g * glow) + np.array(AURA) * g * glow
    return Image.fromarray(np.clip(bg, 0, 255).astype(np.uint8)).convert("RGBA")


def avatar(scale, cx, top):
    """classic blocky avatar: head, torso, arms, legs (rounded blocks), slate with a light top rim"""
    u = int(60 * scale)
    lay = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    d = ImageDraw.Draw(lay)
    body = (52, 58, 84, 255)
    r = int(u * 0.25)
    parts = [
        (cx - u, top, cx + u, top + 2 * u),  # head
        (cx - 2 * u, top + int(2.15 * u), cx + 2 * u, top + int(6.15 * u)),  # torso
        (cx - int(3.1 * u), top + int(2.15 * u), cx - int(2.1 * u), top + int(6.15 * u)),  # arms
        (cx + int(2.1 * u), top + int(2.15 * u), cx + int(3.1 * u), top + int(6.15 * u)),
        (cx - 2 * u, top + int(6.25 * u), cx - int(0.05 * u), top + int(10.2 * u)),  # legs
        (cx + int(0.05 * u), top + int(6.25 * u), cx + 2 * u, top + int(10.2 * u)),
    ]
    for p in parts:
        d.rounded_rectangle(p, r, fill=body)
    # face: two eyes + smile
    e = int(u * 0.22)
    for ex in (cx - int(0.45 * u), cx + int(0.45 * u)):
        d.ellipse([ex - e // 2, top + int(0.7 * u), ex + e // 2, top + int(0.7 * u) + e], fill=(235, 238, 245, 255))
    d.arc([cx - int(0.5 * u), top + int(0.9 * u), cx + int(0.5 * u), top + int(1.5 * u)], 20, 160,
          fill=(235, 238, 245, 255), width=max(3, u // 12))
    rim = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    rd = ImageDraw.Draw(rim)
    for p in parts:
        rd.rounded_rectangle(p, r, outline=(150, 160, 200, 255), width=max(3, u // 14))
    return Image.alpha_composite(lay, rim)


def sparkle(d, x, y, s, col):
    d.polygon([(x, y - s), (x + s * 0.22, y - s * 0.22), (x + s, y), (x + s * 0.22, y + s * 0.22),
               (x, y + s), (x - s * 0.22, y + s * 0.22), (x - s, y), (x - s * 0.22, y - s * 0.22)], fill=col)


def aura_icon():
    c = background(0.55)
    fig = avatar(1.3, S // 2, int(S * 0.13))
    a = np.asarray(fig.getchannel("A"))
    halo = Image.new("RGBA", (S, S), AURA + (0,))
    halo.putalpha(Image.fromarray(a).filter(ImageFilter.MaxFilter(41)))
    for blur, k in ((70, 1.0), (28, 0.9), (10, 0.8)):
        h = halo.filter(ImageFilter.GaussianBlur(blur))
        h.putalpha(h.getchannel("A").point(lambda v, k=k: int(v * k)))
        c = Image.alpha_composite(c, h)
    c = Image.alpha_composite(c, fig)
    d = ImageDraw.Draw(c)
    for _ in range(26):
        ang = rng.uniform(0, 2 * np.pi)
        rad = rng.uniform(0.25, 0.45) * S
        x, y = S / 2 + np.cos(ang) * rad * 0.8, S * 0.52 + np.sin(ang) * rad
        sparkle(d, x, y, rng.uniform(10, 30), AURA + (int(rng.uniform(170, 255)),))
    return c


def tag_icon():
    c = background(0.25)
    c = Image.alpha_composite(c, avatar(1.5, S // 2, int(S * 0.47)))
    d = ImageDraw.Draw(c)
    font = ImageFont.truetype(FONT, 150)
    text = "★ VIP"
    star_font = ImageFont.truetype(r"C:\Windows\Fonts\seguisym.ttf", 120)
    # pill: dark with a gold outline, gold title
    tw = d.textlength("VIP", font=font) + 150
    x0, y0 = S / 2 - tw / 2 - 50, S * 0.17
    d.rounded_rectangle([x0, y0, S - x0, y0 + 200], 100, fill=(20, 22, 40, 235), outline=TAGS[0], width=10)
    d.text((x0 + 60, y0 + 38), "★", font=star_font, fill=TAGS[0])
    d.text((x0 + 60 + 140, y0 + 18), "VIP", font=font, fill=TAGS[0])
    # colour choices under the tag
    n, r, gap = len(TAGS), 30, 86
    sx = S / 2 - gap * (n - 1) / 2
    for i, col in enumerate(TAGS):
        cx, cy = sx + i * gap, y0 + 270
        d.ellipse([cx - r, cy - r, cx + r, cy + r], fill=col, outline=(255, 255, 255), width=5 if i == 0 else 0)
    del text
    return c


if __name__ == "__main__":
    OUT.mkdir(parents=True, exist_ok=True)
    for name, img in (("aura", aura_icon()), ("tag", tag_icon())):
        img.convert("RGB").resize((512, 512), Image.LANCZOS).save(OUT / f"pass_{name}.png")
        print("saved", name)
