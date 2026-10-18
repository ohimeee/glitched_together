"""Night Owl Interactive studio art (Roblox community emblem + cover photo, user, Oct 18).

Direction A+C picked by the user from Google refs: an owl perched in a big cream crescent on a night-blue sky
(logo shape, reads small), painted with paint.py (the alex_twin_ speed-paint refs). Second pass (user: "improve the
image elements", refs: indie studio mascots like Foxdrift / Real Big Studios, Roblox group logos like Moonlight
Production, Dribbble owl mascots): the owl is a mascot now (light face disc, big eyes + brows, light belly with
feather marks, wings, gripping toes, dark outline), sparkle stars, a leafy branch, chunky 3D cover letters.
No glitch pixels (user). Our own drawing: nothing traced from the references.

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

NAVY_TOP = np.array([16, 20, 58])
NAVY_LOW = np.array([48, 52, 130])
MOON = (246, 232, 196)
MOON_SHADE = (222, 202, 160)
INK = (16, 14, 36)  # outlines
BODY = (74, 66, 132)
BODY_SHADE = (52, 46, 100)
WING = (46, 40, 92)
BELLY = (206, 194, 226)
BELLY_MARK = (150, 136, 186)
DISC = (232, 222, 240)
AMBER = (255, 170, 44)
AMBER_DEEP = (222, 104, 24)
BRANCH = (64, 42, 38)
BRANCH_DARK = (40, 26, 28)
LEAF = (58, 92, 62)
LEAF_DARK = (36, 62, 44)


def P_(cx, top, s):
    return lambda x, y: (cx + x * s, top + y * s)


def bez(p0, p1, p2, p3, n=40):
    t = np.linspace(0, 1, n)[:, None]
    p0, p1, p2, p3 = map(np.array, (p0, p1, p2, p3))
    pts = (1 - t) ** 3 * p0 + 3 * (1 - t) ** 2 * t * p1 + 3 * (1 - t) * t ** 2 * p2 + t ** 3 * p3
    return [tuple(p) for p in pts]


def shape(d, pts, fill, ink, width):
    d.polygon(pts, fill=fill)
    d.line(pts + [pts[0]], fill=ink, width=int(width), joint="curve")


def disc(d, x, y, r, fill, ink=None, width=0):
    d.ellipse([x - r, y - r, x + r, y + r], fill=fill, outline=ink, width=int(width) if ink else 0)


def sky(w, h, seed):
    """night gradient + small stars"""
    rng = np.random.default_rng(seed)
    y, x = np.mgrid[0:h, 0:w]
    t = (y / h)[..., None]
    a = NAVY_TOP * (1 - t) + NAVY_LOW * t
    im = Image.fromarray(np.clip(a, 0, 255).astype(np.uint8)).convert("RGBA")
    d = ImageDraw.Draw(im)
    for _ in range(int(w * h / 12000)):
        sx, sy = int(rng.integers(0, w)), int(rng.integers(0, int(h * 0.8)))
        r = int(rng.choice([1, 1, 2, 3])) * max(1, min(w, h) // 600)
        d.ellipse([sx - r, sy - r, sx + r, sy + r], fill=(255, 244, 220, int(rng.integers(120, 255))))
    return im


def moon_glow(im, cx, cy, r):
    g = Image.new("RGBA", im.size, (0, 0, 0, 0))
    ImageDraw.Draw(g).ellipse([cx - r * 1.3, cy - r * 1.3, cx + r * 1.3, cy + r * 1.3], fill=(170, 170, 240, 110))
    return Image.alpha_composite(im, g.filter(ImageFilter.GaussianBlur(r * 0.35)))


def crescent(im, cx, cy, r):
    """full disc minus an offset disc (opening to the upper right, behind the owl), dark rim + soft craters"""
    m = Image.new("L", im.size, 0)
    md = ImageDraw.Draw(m)
    md.ellipse([cx - r, cy - r, cx + r, cy + r], fill=255)
    ox, oy, orr = cx + r * 0.42, cy - r * 0.30, r * 0.86
    md.ellipse([ox - orr, oy - orr, ox + orr, oy + orr], fill=0)
    layer = Image.new("RGBA", im.size, MOON + (255,))
    ld = ImageDraw.Draw(layer)
    # shade band along the inner (lit-side) edge, then craters
    ld.ellipse([ox - orr * 1.12, oy - orr * 1.12, ox + orr * 1.12, oy + orr * 1.12], fill=MOON_SHADE + (255,))
    ld.ellipse([ox - orr * 1.05 - r * 0.05, oy - orr * 1.05, ox + orr * 1.05 - r * 0.05, oy + orr * 1.05],
               fill=MOON + (255,))
    for fx, fy, fr in ((-0.66, 0.05, 0.10), (-0.48, 0.5, 0.07), (-0.22, 0.8, 0.05), (-0.74, -0.38, 0.05)):
        disc(ld, cx + fx * r, cy + fy * r, fr * r, MOON_SHADE + (255,))
    layer.putalpha(m)
    im = Image.alpha_composite(im, layer)
    # thin ink rim round the crescent so it reads as a sticker shape
    edge = m.filter(ImageFilter.FIND_EDGES).filter(ImageFilter.MaxFilter(max(3, int(r * 0.025) | 1)))
    rim = Image.new("RGBA", im.size, INK + (255,))
    rim.putalpha(edge.point(lambda v: 200 if v > 40 else 0))
    return Image.alpha_composite(im, rim)


def sparkle(d, x, y, r, fill):
    """4-point twinkle star"""
    k = r * 0.22
    d.polygon([(x, y - r), (x + k, y - k), (x + r, y), (x + k, y + k), (x, y + r), (x - k, y + k), (x - r, y),
               (x - k, y - k)], fill=fill)


def branch(im, x0, y0, x1, y1, thick):
    d = ImageDraw.Draw(im)
    ink = thick * 0.28
    # leaves first (behind the bough), clustered at the far end and one near the start
    def leaf(lx, ly, ang, L):
        ca, sa = np.cos(ang), np.sin(ang)
        pts = []
        for t in np.linspace(0, np.pi, 18):
            u = (1 - np.cos(t)) / 2 * L
            v = np.sin(t) * L * 0.28
            pts.append((lx + u * ca - v * sa, ly + u * sa + v * ca))
        for t in np.linspace(np.pi, 0, 18)[1:-1]:
            u = (1 - np.cos(t)) / 2 * L
            v = -np.sin(t) * L * 0.28
            pts.append((lx + u * ca - v * sa, ly + u * sa + v * ca))
        shape(d, pts, LEAF, INK, ink * 0.7)
        d.line([(lx, ly), (lx + ca * L * 0.85, ly + sa * L * 0.85)], fill=LEAF_DARK, width=int(ink * 0.6))
    ex, ey = x0 + (x1 - x0) * 0.9, y0 + (y1 - y0) * 0.9
    for ang, L in ((-0.9, 3.2), (-0.2, 3.6), (0.5, 3.0), (-1.6, 2.6)):
        leaf(ex, ey, ang, thick * L)
    sx, sy = x0 + (x1 - x0) * 0.12, y0 + (y1 - y0) * 0.12
    leaf(sx, sy, 2.3, thick * 2.6)
    # the bough: tapered, ink outline, a lighter top edge + bark nicks
    nx, ny = -(y1 - y0), (x1 - x0)
    n = np.hypot(nx, ny)
    nx, ny = nx / n, ny / n
    top_, bot_ = [], []
    for t in np.linspace(0, 1, 30):
        w = thick * (1.0 - 0.45 * t) * 0.5
        bx, by = x0 + (x1 - x0) * t, y0 + (y1 - y0) * t + np.sin(t * 6) * thick * 0.12
        top_.append((bx - nx * w, by - ny * w))
        bot_.append((bx + nx * w, by + ny * w))
    shape(d, top_ + bot_[::-1], BRANCH, INK, ink)
    d.line(top_[2:-2], fill=(110, 76, 64), width=int(thick * 0.12))
    rng = np.random.default_rng(2)
    for t in rng.uniform(0.05, 0.95, 9):
        bx, by = x0 + (x1 - x0) * t, y0 + (y1 - y0) * t + np.sin(t * 6) * thick * 0.12
        d.line([(bx, by - thick * 0.05), (bx + thick * 0.5, by + thick * 0.08)], fill=BRANCH_DARK,
               width=int(thick * 0.08))
    # a twig with a little fork
    tx, ty = x0 + (x1 - x0) * 0.7, y0 + (y1 - y0) * 0.7
    d.line([(tx, ty), (tx + thick * 1.6, ty - thick * 1.9)], fill=INK, width=int(thick * 0.42))
    d.line([(tx, ty), (tx + thick * 1.6, ty - thick * 1.9)], fill=BRANCH, width=int(thick * 0.22))


def owl(im, cx, top, s):
    """the mascot: round body with ear tufts, dark wings, light belly + face disc, big amber eyes, brows, toes"""
    d = ImageDraw.Draw(im)
    P = P_(cx, top, s)
    ink = s * 0.022

    # body silhouette (tufts, V brow dip, round shoulders, body to the tail)
    body = []
    body += bez(P(0, 0.12), P(-0.07, 0.08), P(-0.16, 0.0), P(-0.26, -0.1))
    body += bez(P(-0.26, -0.1), P(-0.25, 0.03), P(-0.27, 0.12), P(-0.30, 0.22))
    body += bez(P(-0.30, 0.22), P(-0.36, 0.36), P(-0.36, 0.56), P(-0.31, 0.72))
    body += bez(P(-0.31, 0.72), P(-0.26, 0.86), P(-0.16, 0.97), P(0, 0.99))
    body += bez(P(0, 0.99), P(0.16, 0.97), P(0.26, 0.86), P(0.31, 0.72))
    body += bez(P(0.31, 0.72), P(0.36, 0.56), P(0.36, 0.36), P(0.30, 0.22))
    body += bez(P(0.30, 0.22), P(0.27, 0.12), P(0.25, 0.03), P(0.26, -0.1))
    body += bez(P(0.26, -0.1), P(0.16, 0.0), P(0.07, 0.08), P(0, 0.12))
    # tail feathers peeking under the branch
    for tx in (-0.07, 0.0, 0.07):
        shape(d, [P(tx - 0.045, 0.94), P(tx + 0.045, 0.94), P(tx + 0.02, 1.13), P(tx - 0.02, 1.13)], WING, INK, ink)
    shape(d, body, BODY, INK, ink * 1.4)
    # shade on the side away from the moon
    d.polygon(bez(P(0.18, 0.3), P(0.34, 0.4), P(0.33, 0.7), P(0.2, 0.9)) +
              bez(P(0.2, 0.9), P(0.27, 0.7), P(0.27, 0.45), P(0.18, 0.3)), fill=BODY_SHADE)

    # belly: light egg with rows of little V feather marks
    bel = bez(P(0, 0.42), P(-0.25, 0.42), P(-0.24, 0.92), P(0, 0.95)) + \
        bez(P(0, 0.95), P(0.24, 0.92), P(0.25, 0.42), P(0, 0.42))
    d.polygon(bel, fill=BELLY)
    for row, yy in enumerate((0.56, 0.66, 0.76, 0.86)):
        n = 3 if row % 2 == 0 else 2
        for k in range(n):
            x = (k - (n - 1) / 2) * 0.1
            d.line([P(x - 0.03, yy), P(x, yy + 0.03), P(x + 0.03, yy)], fill=BELLY_MARK, width=int(ink * 0.9),
                   joint="curve")

    # wings folded over the sides, scalloped feather tips
    for side in (-1, 1):
        w = []
        w += bez(P(side * 0.29, 0.3), P(side * 0.42, 0.42), P(side * 0.4, 0.7), P(side * 0.24, 0.9))
        w += bez(P(side * 0.24, 0.9), P(side * 0.2, 0.76), P(side * 0.2, 0.52), P(side * 0.29, 0.3))
        shape(d, w, WING, INK, ink)
        for t, yy in ((0.34, 0.62), (0.31, 0.72), (0.27, 0.81)):
            d.arc([P(side * t - 0.05, yy - 0.04)[0] if side > 0 else P(side * t - 0.05, yy - 0.04)[0],
                   P(0, yy - 0.04)[1], P(side * t + 0.05, yy)[0] if side > 0 else P(side * t + 0.05, yy)[0],
                   P(0, yy + 0.05)[1]], 20, 160, fill=INK, width=int(ink * 0.7))

    # face disc: two light rounds under the brows (heart-shaped mask)
    for ex in (-0.115, 0.115):
        disc(d, *P(ex, 0.25), s * 0.135, DISC, INK, ink)
    disc(d, *P(0, 0.31), s * 0.07, DISC)  # fills the notch between the rounds at the beak
    # brows: the dark V from the tufts sits over the top of the disc → a bright, confident look
    d.polygon([P(-0.27, 0.08), P(-0.18, 0.1), P(0, 0.2), P(0.18, 0.1), P(0.27, 0.08), P(0.27, 0.0), P(0, 0.12),
               P(-0.27, 0.0)], fill=BODY)
    d.line([P(-0.25, 0.115), P(-0.12, 0.13), P(0, 0.2), P(0.12, 0.13), P(0.25, 0.115)], fill=INK,
           width=int(ink * 1.1), joint="curve")

    # eyes: amber iris, big round pupil, two glints
    for ex in (-0.115, 0.115):
        x, y = P(ex, 0.26)
        r = s * 0.088
        disc(d, x, y, r, AMBER_DEEP, INK, ink)
        disc(d, x, y, r * 0.8, AMBER)
        disc(d, x + r * 0.05, y + r * 0.05, r * 0.5, INK)
        disc(d, x - r * 0.18, y - r * 0.2, r * 0.2, (255, 255, 255))
        disc(d, x + r * 0.22, y + r * 0.22, r * 0.08, (255, 255, 255))
    # beak
    shape(d, [P(-0.04, 0.315), P(0.04, 0.315), P(0, 0.41)], AMBER_DEEP, INK, ink * 0.8)
    # toes gripping the bough
    for fx in (-0.085, 0.085):
        for t in (-0.03, 0, 0.03):
            x, y = P(fx + t, 0.985)
            d.ellipse([x - s * 0.017, y - s * 0.022, x + s * 0.017, y + s * 0.035], fill=AMBER_DEEP, outline=INK,
                      width=int(ink * 0.6))


def scene(w, h, cx, cy, r, seed):
    """moon + owl + branch, the owl sitting on the crescent's low inner curve"""
    im = sky(w, h, seed)
    im = moon_glow(im, cx, cy, r)
    im = crescent(im, cx, cy, r)
    s = r * 1.15
    top = cy - r * 0.6
    ocx = cx + r * 0.08
    by = top + s * 1.0
    # tail first, branch over it, then the owl (its toes land on top of the branch)
    branch(im, cx - r * 1.1, by + s * 0.04, cx + r * 1.2, by - s * 0.06, s * 0.085)
    owl(im, ocx, top, s)
    return im


def sparkles(im, pts):
    d = ImageDraw.Draw(im)
    for x, y, r in pts:
        sparkle(d, x, y, r, (255, 246, 222, 255))


def emblem():
    S = 2048
    im = scene(S, S, S * 0.45, S * 0.52, S * 0.36, 3)
    flat = im.convert("RGB")
    flat.save(os.path.join(OUT, "emblem_flat.png"))
    painted = paint(flat, seed=3, strokes=22000, out_w=1024, punch=1.1).convert("RGBA")
    sparkles(painted, ((842, 196, 26), (902, 300, 13), (150, 120, 18), (860, 820, 15), (96, 700, 11)))
    painted.convert("RGB").save(os.path.join(OUT, "emblem_1024.png"))
    painted.convert("RGB").resize((512, 512), Image.LANCZOS).save(os.path.join(OUT, "emblem_512.png"))
    painted.convert("RGB").resize((150, 150), Image.LANCZOS).save(os.path.join(OUT, "emblem_preview150.png"))


def chunky_text(d, xy, text, font, fill, depth, ink_w):
    """Roblox-style 3D letters: an ink extrusion down-right, a thick ink outline, then the face"""
    x, y = xy
    for k in range(depth, 0, -1):
        d.text((x + k * 0.6, y + k), text, font=font, fill=INK, stroke_width=ink_w, stroke_fill=INK)
    d.text((x, y), text, font=font, fill=fill, stroke_width=ink_w, stroke_fill=INK)


def cover():
    W, H = 2880, 912  # 2x of 1440x456
    im = scene(W, H, W * 0.80, H * 0.50, H * 0.40, 9)
    flat = im.convert("RGB")
    painted = paint(flat, seed=9, strokes=34000, out_w=1440, punch=1.1).convert("RGBA")
    w, h = painted.size
    rng = np.random.default_rng(4)
    # stars after the paint pass (posterizing wipes the small ones), kept out of the moon and the text block
    sd = ImageDraw.Draw(painted)
    mx, my, mr = w * 0.80, h * 0.50, h * 0.40 * 1.3
    for _ in range(90):
        sx, sy = float(rng.integers(0, w)), float(rng.integers(0, int(h * 0.9)))
        if (sx < w * 0.58 and h * 0.12 < sy < h * 0.8) or np.hypot(sx - mx, sy - my) < mr:
            continue
        r = float(rng.choice([1, 1, 1.5, 2.2]))
        sd.ellipse([sx - r, sy - r, sx + r, sy + r], fill=(255, 244, 220, int(rng.integers(140, 255))))
    sparkles(painted, ((1030, 70, 14), (1390, 120, 9), (860, 380, 10), (640, 60, 8), (1340, 410, 8)))
    txt = Image.new("RGBA", painted.size, (0, 0, 0, 0))
    d = ImageDraw.Draw(txt)
    big = ImageFont.truetype(FONT, int(h * 0.31))
    small = ImageFont.truetype(FONT, int(h * 0.155))
    x0 = int(w * 0.055)
    chunky_text(d, (x0, h * 0.17), "NIGHT OWL", big, MOON, int(h * 0.03), int(h * 0.016))
    chunky_text(d, (x0 + h * 0.01, h * 0.57), "INTERACTIVE", small, AMBER, int(h * 0.022), int(h * 0.012))
    painted = Image.alpha_composite(painted, txt)
    painted.convert("RGB").save(os.path.join(OUT, "cover_1440x456.png"))
    painted.convert("RGB").resize((720, 228), Image.LANCZOS).save(os.path.join(OUT, "cover_720x228.png"))


if __name__ == "__main__":
    os.makedirs(OUT, exist_ok=True)
    emblem()
    cover()
    print("saved", os.path.abspath(OUT))
