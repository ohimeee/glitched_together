"""The GLITCHED TOGETHER wordmark for the painted thumbnails (user, Oct 18). Same look as the cover art's title
(tools/make_thumbnail.py: white, navy outline, magenta/teal split, glitch slices) plus the paint filter's language:
rows of the letters dragged sideways into fading smears, so the title sits in the painting.

Usage: python tools/paint_style/title.py <in.png> <out.png> big|corner [--seed N]
  big    = the two-line title on the left third (main thumbnail)
  corner = a small one-line title in the bottom-left corner (every other thumbnail)
"""
import argparse
import random
import numpy as np
from PIL import Image, ImageDraw, ImageFont, ImageFilter

FONT = r"C:\Windows\Fonts\Artifakt Element Black.ttf"
NAVY = (22, 30, 70)
MAGENTA = (255, 40, 190)
TEAL = (30, 210, 190)


def _layer(size, lines, font, xy, lh, fill, dx=0, dy=0, stroke=0, stroke_fill=None):
    lay = Image.new("RGBA", size, (0, 0, 0, 0))
    d = ImageDraw.Draw(lay)
    for i, t in enumerate(lines):
        d.text((xy[0] + dx, xy[1] + i * lh + dy), t, font=font, fill=fill, stroke_width=stroke, stroke_fill=stroke_fill)
    return lay


def _smear(lay, rng, count, max_len, band):
    """drag random rows of the lettering sideways with a fading tail (the paint filter's glitch drags)"""
    a = np.asarray(lay).astype(np.float64)
    h, w = a.shape[:2]
    ys, xs = np.nonzero(a[:, :, 3] > 200)
    if len(ys) == 0:
        return lay
    out = a.copy()
    for _ in range(count):
        i = rng.integers(0, len(ys))
        y, x = ys[i], xs[i]
        bh = int(rng.integers(1, band))
        length = int(rng.integers(max_len // 4, max_len))
        direction = -1 if rng.random() < 0.5 else 1
        for row in range(y, min(h, y + bh)):
            src = a[row, x].copy()
            if src[3] < 200:
                continue
            for k in range(1, length):
                xx = x + direction * k
                if xx < 0 or xx >= w:
                    break
                f = (1 - k / length) ** 1.5 * 0.85
                if out[row, xx, 3] < src[3] * f:
                    out[row, xx] = src * np.array([1, 1, 1, f])
    return Image.fromarray(np.clip(out, 0, 255).astype(np.uint8))


def wordmark(im, mode, seed=7):
    rng = np.random.default_rng(seed)
    random.seed(seed)
    W, H = im.size
    if mode == "big":
        size = round(H * 0.125)
        lines, xy, lh = ["GLITCHED", "TOGETHER"], (round(W * 0.045), round(H * 0.30)), round(size * 1.1)
        stroke, split, shadow_blur = round(size * 0.09), round(size * 0.07), 10
        smears, max_len, band = 240, round(W * 0.2), 7
    else:
        size = round(H * 0.052)
        lines, lh = ["GLITCHED TOGETHER"], 0
        f = ImageFont.truetype(FONT, size)
        xy = (round(W * 0.03), H - round(H * 0.03) - size)
        stroke, split, shadow_blur = max(3, round(size * 0.09)), max(2, round(size * 0.06)), 5
        smears, max_len, band = 60, round(W * 0.07), 3
    font = ImageFont.truetype(FONT, size)
    canvas = im.convert("RGBA")
    shadow = _layer(im.size, lines, font, xy, lh, (10, 15, 40, 150), 6, 8, stroke + 2, (10, 15, 40, 150))
    canvas = Image.alpha_composite(canvas, shadow.filter(ImageFilter.GaussianBlur(shadow_blur)))
    pink = _layer(im.size, lines, font, xy, lh, MAGENTA + (255,), -split, 0, stroke, MAGENTA + (255,))
    teal = _layer(im.size, lines, font, xy, lh, TEAL + (255,), split, 0, stroke, TEAL + (255,))
    canvas = Image.alpha_composite(canvas, _smear(pink, rng, smears // 2, max_len, band))
    canvas = Image.alpha_composite(canvas, _smear(teal, rng, smears // 2, max_len, band))
    main = _layer(im.size, lines, font, xy, lh, (255, 255, 255, 255), 0, 0, stroke, NAVY + (255,))
    # glitch slices: thin strips of the wordmark shifted sideways
    top = xy[1]
    bottom = xy[1] + max(1, len(lines)) * (lh or size) + size // 3
    for _ in range(4 if mode == "big" else 2):
        y = random.randint(top + 4, bottom - 4)
        hh = random.randint(max(2, size // 30), max(3, size // 14))
        dx = random.choice([-1, 1]) * random.randint(size // 12, size // 5)
        strip = main.crop((0, y, W, y + hh))
        main.paste((0, 0, 0, 0), (0, y, W, y + hh))
        main.alpha_composite(strip, (dx, y))
    # brush texture inside the letters: flat dabs of cream / cool white, like the painting's blocks
    m = np.asarray(main).astype(np.float64)
    white = (m[:, :, 3] > 200) & (m[:, :, :3].mean(2) > 200)
    yy, xx = np.nonzero(white)
    for _ in range(900 if mode == "big" else 200):
        if len(yy) == 0:
            break
        i = rng.integers(0, len(yy))
        y, x = yy[i], xx[i]
        dw, dh = int(rng.integers(size // 8, size // 2)), int(rng.integers(2, max(3, size // 14)))
        tint = np.array([255, 246, 228]) if rng.random() < 0.5 else np.array([226, 236, 255])
        box = white[y:y + dh, x:x + dw]
        m[y:y + dh, x:x + dw, :3][box] = tint
    main = Image.fromarray(m.astype(np.uint8))
    main = _smear(main, rng, smears, max_len, band)
    canvas = Image.alpha_composite(canvas, main)
    return canvas.convert("RGB")


if __name__ == "__main__":
    ap = argparse.ArgumentParser()
    ap.add_argument("src")
    ap.add_argument("dst")
    ap.add_argument("mode", choices=["big", "corner"])
    ap.add_argument("--seed", type=int, default=7)
    o = ap.parse_args()
    wordmark(Image.open(o.src), o.mode, o.seed).save(o.dst)
    print("saved", o.dst)
