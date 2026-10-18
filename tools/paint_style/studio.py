"""Night Owl Interactive studio art (Roblox community emblem + cover photo, user, Oct 18).

Direction A+C picked by the user from Google refs: an owl silhouette perched in a big cream crescent on a night-blue
sky (logo shape, reads small), painted with paint.py (the alex_twin_ speed-paint refs) and a few glitch pixels
peeling off one ear tuft. Our own drawing: nothing traced from the references.

Usage: python tools/paint_style/studio.py      → marketing/studio/emblem_512.png, emblem_1024.png, cover_1440x456.png
"""
import os
import sys

import numpy as np
from PIL import Image, ImageDraw, ImageFilter, ImageFont

sys.path.insert(0, os.path.dirname(__file__))
from paint import paint  # noqa: E402

OUT = os.path.join(os.path.dirname(__file__), "..", "..", "marketing", "studio")
FONT = r"C:\Users\User\tools\fonts\LuckiestGuy-Regular.ttf"

NAVY_TOP = np.array([18, 24, 62])
NAVY_LOW = np.array([44, 58, 128])
MOON = (242, 228, 192)
MOON_SHADE = (214, 196, 156)
OWL = (14, 16, 34)
OWL_RIM = (96, 112, 182)  # moonlight caught on the owl's sky-side edge
FACE = (42, 50, 96)
AMBER = (255, 162, 40)
AMBER_DEEP = (214, 96, 22)
BRANCH = (26, 22, 30)


def sky(w, h, seed):
    """night gradient + a soft glow behind the moon + a few stars"""
    rng = np.random.default_rng(seed)
    y, x = np.mgrid[0:h, 0:w]
    t = (y / h)[..., None]
    a = NAVY_TOP * (1 - t) + NAVY_LOW * t
    im = Image.fromarray(np.clip(a, 0, 255).astype(np.uint8)).convert("RGBA")
    d = ImageDraw.Draw(im)
    for _ in range(int(w * h / 9000)):
        sx, sy = int(rng.integers(0, w)), int(rng.integers(0, int(h * 0.8)))
        r = int(rng.choice([1, 1, 2, 3])) * max(1, min(w, h) // 600)
        d.ellipse([sx - r, sy - r, sx + r, sy + r], fill=(255, 244, 220, int(rng.integers(120, 255))))
    return im


def moon_glow(im, cx, cy, r):
    g = Image.new("RGBA", im.size, (0, 0, 0, 0))
    ImageDraw.Draw(g).ellipse([cx - r * 1.25, cy - r * 1.25, cx + r * 1.25, cy + r * 1.25], fill=(150, 160, 230, 90))
    return Image.alpha_composite(im, g.filter(ImageFilter.GaussianBlur(r * 0.35)))


def crescent(im, cx, cy, r):
    """full disc minus an offset disc (opening to the upper right, behind the owl)"""
    m = Image.new("L", im.size, 0)
    md = ImageDraw.Draw(m)
    md.ellipse([cx - r, cy - r, cx + r, cy + r], fill=255)
    ox, oy, orr = cx + r * 0.42, cy - r * 0.30, r * 0.86
    md.ellipse([ox - orr, oy - orr, ox + orr, oy + orr], fill=0)
    layer = Image.new("RGBA", im.size, MOON + (255,))
    # a few painted craters / shade on the inner edge
    ld = ImageDraw.Draw(layer)
    for fx, fy, fr in ((-0.62, 0.05, 0.11), (-0.45, 0.48, 0.08), (-0.2, 0.78, 0.06), (-0.75, -0.35, 0.06)):
        ld.ellipse([cx + fx * r - fr * r, cy + fy * r - fr * r, cx + fx * r + fr * r, cy + fy * r + fr * r],
                   fill=MOON_SHADE + (255,))
    layer.putalpha(m)
    return Image.alpha_composite(im, layer)


def bez(p0, p1, p2, p3, n=40):
    t = np.linspace(0, 1, n)[:, None]
    p0, p1, p2, p3 = map(np.array, (p0, p1, p2, p3))
    pts = (1 - t) ** 3 * p0 + 3 * (1 - t) ** 2 * t * p1 + 3 * (1 - t) * t ** 2 * p2 + t ** 3 * p3
    return [tuple(p) for p in pts]


def owl_outline(cx, top, s):
    """one closed owl silhouette (ear tufts, V brow, round shoulders, body tapering to the feet), unit s = owl height"""
    def P(x, y):
        return (cx + x * s, top + y * s)
    pts = []
    pts += bez(P(0, 0.14), P(-0.07, 0.10), P(-0.17, 0.02), P(-0.27, -0.09))     # brow V → left tuft tip
    pts += bez(P(-0.27, -0.09), P(-0.26, 0.04), P(-0.27, 0.13), P(-0.29, 0.22))  # tuft down to the cheek
    pts += bez(P(-0.29, 0.22), P(-0.33, 0.34), P(-0.34, 0.52), P(-0.30, 0.68))  # shoulder → wing
    pts += bez(P(-0.30, 0.68), P(-0.27, 0.82), P(-0.18, 0.95), P(-0.08, 1.0))   # wing to the tail
    pts += bez(P(-0.08, 1.0), P(-0.03, 1.02), P(0.03, 1.02), P(0.08, 1.0))
    pts += bez(P(0.08, 1.0), P(0.18, 0.95), P(0.27, 0.82), P(0.30, 0.68))
    pts += bez(P(0.30, 0.68), P(0.34, 0.52), P(0.33, 0.34), P(0.29, 0.22))
    pts += bez(P(0.29, 0.22), P(0.27, 0.13), P(0.26, 0.04), P(0.27, -0.09))
    pts += bez(P(0.27, -0.09), P(0.17, 0.02), P(0.07, 0.10), P(0, 0.14))
    return pts


def owl(im, cx, top, s):
    d = ImageDraw.Draw(im)
    out = owl_outline(cx, top, s)
    # moonlight rim: the same shape nudged left, light, then the dark owl over it
    d.polygon([(x + s * 0.03, y - s * 0.01) for x, y in out], fill=OWL_RIM)
    d.polygon(out, fill=OWL)

    def P(x, y):
        return (cx + x * s, top + y * s)

    # facial disc: two overlapping rounds round the eyes
    for ex in (-0.105, 0.105):
        x, y = P(ex, 0.25)
        r = s * 0.125
        d.ellipse([x - r, y - r, x + r, y + r], fill=FACE)
    # wing edges + chest chevrons (lighter navy marks, like the refs' few hard strokes)
    for side in (-1, 1):
        d.line([P(side * 0.27, 0.42), P(side * 0.22, 0.66), P(side * 0.12, 0.9)], fill=FACE, width=int(s * 0.022))
    for i, (yy, ww) in enumerate(((0.52, 0.09), (0.62, 0.11), (0.72, 0.10), (0.82, 0.08))):
        for k in (-1, 0, 1):
            x0 = k * 0.075 - ww * 0.4
            d.line([P(x0, yy), P(x0 + ww * 0.4, yy + 0.035), P(x0 + ww * 0.8, yy)], fill=FACE, width=int(s * 0.016))
    # eyes: amber with a deep ring, round pupil, a cream glint
    for ex in (-0.105, 0.105):
        x, y = P(ex, 0.25)
        r = s * 0.082
        d.ellipse([x - r, y - r, x + r, y + r], fill=AMBER_DEEP)
        r2 = r * 0.82
        d.ellipse([x - r2, y - r2, x + r2, y + r2], fill=AMBER)
        rp = r * 0.45
        d.ellipse([x - rp, y - rp, x + rp, y + rp], fill=OWL)
        gx, gy, gr = x - r * 0.28, y - r * 0.3, r * 0.17
        d.ellipse([gx - gr, gy - gr, gx + gr, gy + gr], fill=MOON)
    # beak
    d.polygon([P(-0.035, 0.31), P(0.035, 0.31), P(0, 0.39)], fill=AMBER_DEEP)
    # feet on the branch
    for fx in (-0.07, 0.07):
        for t in (-0.025, 0, 0.025):
            x, y = P(fx + t, 0.99)
            d.ellipse([x - s * 0.014, y - s * 0.02, x + s * 0.014, y + s * 0.03], fill=AMBER_DEEP)
    return out


def branch(im, x0, y0, x1, y1, thick):
    d = ImageDraw.Draw(im)
    d.line([(x0, y0), (x1, y1)], fill=BRANCH, width=int(thick))
    # a twig + a few leaves off the far end
    tx, ty = x0 + (x1 - x0) * 0.78, y0 + (y1 - y0) * 0.78
    d.line([(tx, ty), (tx + thick * 2.2, ty - thick * 2.0)], fill=BRANCH, width=int(thick * 0.45))
    for k in range(3):
        lx, ly = tx + thick * (1.2 + k * 0.6), ty - thick * (1.4 + k * 0.5)
        d.ellipse([lx - thick * 0.5, ly - thick * 0.22, lx + thick * 0.5, ly + thick * 0.22], fill=BRANCH)


def peel(im, box, cell, n, seed, drift):
    """glitch: square cells cut from a region and dropped further right, tinted amber / cream (no teal/magenta:
    those are the game's owner colours)"""
    rng = np.random.default_rng(seed)
    a = np.asarray(im.convert("RGB")).astype(np.float64)
    base = Image.fromarray(a.astype(np.uint8)).convert("RGBA")
    d = ImageDraw.Draw(base)
    x0, y0, x1, y1 = box
    for _ in range(n):
        cx = int(rng.integers(x0, x1 - cell))
        cy = int(rng.integers(y0, y1 - cell))
        blk = a[cy:cy + cell, cx:cx + cell].copy()
        if blk.mean() > 60:  # only owl pixels peel (dark)
            continue
        tint = [np.array(AMBER), np.array(MOON), None][int(rng.integers(0, 3))]
        if tint is not None:
            blk = blk * 0.35 + tint * 0.65
        dx = int(rng.integers(cell, drift))
        dy = int(rng.integers(-cell, cell))
        d.rectangle([cx, cy, cx + cell - 1, cy + cell - 1], fill=tuple(int(v) for v in a[cy, cx - cell * 3 if cx > cell * 3 else cx]))
        base.paste(Image.fromarray(blk.astype(np.uint8)), (min(im.width - cell, cx + dx), cy + dy))
    return base


def scene(w, h, cx, cy, r, seed):
    """moon + owl + branch, the owl sitting on the crescent's low inner curve"""
    im = sky(w, h, seed)
    im = moon_glow(im, cx, cy, r)
    im = crescent(im, cx, cy, r)
    s = r * 1.22
    top = cy - r * 0.62
    ocx = cx + r * 0.06
    branch(im, cx - r * 1.05, top + s * 1.05, cx + r * 1.25, top + s * 0.95, s * 0.06)
    owl(im, ocx, top, s)
    return im, (ocx, top, s)


def emblem():
    S = 2048
    im, (ocx, top, s) = scene(S, S, S * 0.46, S * 0.52, S * 0.36, 3)
    flat = im.convert("RGB")
    flat.save(os.path.join(OUT, "emblem_flat.png"))
    painted = paint(flat, seed=3, strokes=30000, out_w=1024, punch=1.15)
    k = 1024 / S
    # pixels peel off the right ear tuft and drift right
    box = (int((ocx + s * 0.12) * k), int((top - s * 0.09) * k), int((ocx + s * 0.31) * k), int((top + s * 0.1) * k))
    painted = peel(painted, box, cell=16, n=70, seed=5, drift=150)
    painted.convert("RGB").save(os.path.join(OUT, "emblem_1024.png"))
    painted.convert("RGB").resize((512, 512), Image.LANCZOS).save(os.path.join(OUT, "emblem_512.png"))
    painted.convert("RGB").resize((150, 150), Image.LANCZOS).save(os.path.join(OUT, "emblem_preview150.png"))


def cover():
    W, H = 2880, 912  # 2x of 1440x456
    im, (ocx, top, s) = scene(W, H, W * 0.80, H * 0.50, H * 0.40, 9)
    flat = im.convert("RGB")
    painted = paint(flat, seed=9, strokes=40000, out_w=1440, punch=1.1).convert("RGBA")
    k = 1440 / W
    w, h = painted.size
    txt = Image.new("RGBA", painted.size, (0, 0, 0, 0))
    d = ImageDraw.Draw(txt)
    big = ImageFont.truetype(FONT, int(h * 0.30))
    small = ImageFont.truetype(FONT, int(h * 0.15))
    x0 = int(w * 0.06)
    for text, font, y, fill in (("NIGHT OWL", big, h * 0.20, MOON), ("INTERACTIVE", small, h * 0.56, AMBER)):
        d.text((x0 + h * 0.012, y + h * 0.018), text, font=font, fill=OWL)  # drop shadow
        d.text((x0, y), text, font=font, fill=fill, stroke_width=int(h * 0.012), stroke_fill=OWL)
    ta = np.asarray(txt).astype(np.float64)
    rng = np.random.default_rng(4)
    ys = np.nonzero(ta[:, :, 3].max(1) > 200)[0]
    for _ in range(18):  # sideways glitch drags off the letters' right edges
        y = int(rng.choice(ys))
        row = np.nonzero(ta[y, :, 3] > 200)[0]
        hh = int(rng.integers(2, 6))
        x = int(row[-1]) - 2
        L = int(rng.integers(40, 160))
        col = ta[y:y + hh, x:x + 1].copy()
        fade = np.linspace(1, 0, L)[None, :, None]
        seg = ta[y:y + hh, x:x + L]
        ta[y:y + hh, x:x + L] = np.maximum(seg, col[:, :, :] * np.concatenate([np.ones((1, seg.shape[1], 3)), fade[:, :seg.shape[1]]], 2))
    # stars after the paint pass (posterizing wipes the small ones), kept out of the letters and the moon
    sd = ImageDraw.Draw(painted)
    mx, my, mr = w * 0.80, h * 0.50, h * 0.40 * 1.3
    for _ in range(90):
        sx, sy = float(rng.integers(0, w)), float(rng.integers(0, int(h * 0.85)))
        if ta[int(sy), int(sx), 3] > 0 or np.hypot(sx - mx, sy - my) < mr:
            continue
        r = float(rng.choice([1, 1, 1.5, 2.2]))
        sd.ellipse([sx - r, sy - r, sx + r, sy + r], fill=(255, 244, 220, int(rng.integers(140, 255))))
    painted = Image.alpha_composite(painted, Image.fromarray(ta.astype(np.uint8)))
    box = (int((ocx + s * 0.12) * k), int((top - s * 0.09) * k), int((ocx + s * 0.31) * k), int((top + s * 0.1) * k))
    painted = peel(painted, box, cell=9, n=60, seed=6, drift=90)
    painted.convert("RGB").save(os.path.join(OUT, "cover_1440x456.png"))
    painted.convert("RGB").resize((720, 228), Image.LANCZOS).save(os.path.join(OUT, "cover_720x228.png"))


if __name__ == "__main__":
    os.makedirs(OUT, exist_ok=True)
    emblem()
    cover()
    print("saved", os.path.abspath(OUT))
