"""Night Owl Interactive logo files from the Blender layers (blender_assets/StudioLogo.blend, concept 2 "the moon is
the owl", picked by the user Oct 18 over moon-eyes and eyes-only; refs: big studio marks like Bungie / Naughty Dog /
Hazelight = one symbol + a clean wordmark).

Layers (transparent, rendered from the .blend): marketing/studio/layer_symbol.png, layer_wordmark.png.
Usage: python tools/paint_style/studio_logo.py  → emblem_512/1024.png, cover_1440x456.png, cover_720x228.png,
       splash_logo.png (transparent lockup for the intro splash)
"""
import os

import numpy as np
from PIL import Image, ImageDraw, ImageFilter

D = os.path.join(os.path.dirname(__file__), "..", "..", "marketing", "studio")


def trim(im):
    return im.crop(im.getbbox())


def fit(im, w=None, h=None):
    if w:
        return im.resize((w, round(im.height * w / im.width)), Image.LANCZOS)
    return im.resize((round(im.width * h / im.height), h), Image.LANCZOS)


def night(w, h, cx, cy, seed, stars=True):
    """deep navy with a soft moonlit glow at (cx, cy) and a few faint stars"""
    y, x = np.mgrid[0:h, 0:w]
    d = np.clip(np.hypot(x - cx, y - cy) / (max(w, h) * 0.55), 0, 1)[..., None]
    inner, outer = np.array([40, 44, 96]), np.array([9, 10, 26])
    a = inner * (1 - d) ** 1.6 + outer * (1 - (1 - d) ** 1.6)
    im = Image.fromarray(np.clip(a, 0, 255).astype(np.uint8)).convert("RGBA")
    if stars:
        rng = np.random.default_rng(seed)
        dr = ImageDraw.Draw(im)
        for _ in range(int(w * h / 6000)):
            sx, sy = rng.uniform(0, w), rng.uniform(0, h)
            r = rng.choice([0.8, 1.0, 1.4, 2.0]) * max(w, h) / 1440
            dr.ellipse([sx - r, sy - r, sx + r, sy + r], fill=(255, 240, 214, int(rng.integers(40, 150))))
    return im


def noise(w, h, seed, scale, octaves=4):
    """soft value noise 0..1 (blurred random grids added over a few octaves)"""
    rng = np.random.default_rng(seed)
    acc = np.zeros((h, w))
    amp, tot = 1.0, 0.0
    for o in range(octaves):
        gw, gh = max(2, int(w / scale * 2 ** o)), max(2, int(h / scale * 2 ** o))
        g = Image.fromarray((rng.random((gh, gw)) * 255).astype(np.uint8)).resize((w, h), Image.BICUBIC)
        acc += np.asarray(g, np.float64) / 255 * amp
        tot += amp
        amp *= 0.5
    return acc / tot


def twinkle(d, x, y, r, a):
    k = r * 0.18
    d.polygon([(x, y - r), (x + k, y - k), (x + r, y), (x + k, y + k), (x, y + r), (x - k, y + k), (x - r, y),
               (x - k, y - k)], fill=(255, 244, 222, a))
    d.ellipse([x - k * 1.6, y - k * 1.6, x + k * 1.6, y + k * 1.6], fill=(255, 250, 236, a))


def sky(w, h, cx, cy, seed, horizon=None, halo=0.55, clouds=0.47, stars=1.0):
    """a richer night: vertical gradient (indigo top → violet-blue low), clouds lit near the moon, a starry band,
    a halo round (cx, cy), vignette; with horizon = y of the far hills, two hill ridges + a pine treeline"""
    rng = np.random.default_rng(seed)
    U = max(w, h)
    y, x = np.mgrid[0:h, 0:w].astype(np.float64)
    t = (y / h)[..., None]
    top, mid, low = np.array([8, 9, 28]), np.array([22, 24, 70]), np.array([52, 46, 112])
    a = np.where(t < 0.55, top + (mid - top) * (t / 0.55), mid + (low - mid) * ((t - 0.55) / 0.45))
    # moon halo: wide soft glow + a faint ring
    r = np.hypot(x - cx, y - cy)[..., None]
    R = min(w, h) * 0.5
    a = a + np.array([120, 112, 170]) * np.exp(-(r / (R * 0.9)) ** 2) * halo
    a = a + np.array([200, 180, 150]) * np.exp(-((r - R * 0.78) / (R * 0.05)) ** 2) * 0.07
    # starry band (soft diagonal milky haze)
    band = np.exp(-(((x - w * 0.15) * 0.35 + (y - h * 0.1) - (x * 0.45)) / (U * 0.16)) ** 2)[..., None]
    a = a + np.array([70, 64, 120]) * band * noise(w, h, seed + 1, U / 6)[..., None] * 0.45
    # clouds: noise thresholded into soft wisps, brighter near the moon
    n = noise(w, h, seed + 2, U / 3, 5)
    cl = np.clip((n - clouds) * 3.2, 0, 1)[..., None]
    lit = np.exp(-(r / (R * 1.4)) ** 2)
    a = a * (1 - cl * 0.55) + (np.array([60, 58, 112]) + np.array([150, 130, 140]) * lit) * cl * 0.55
    im = Image.fromarray(np.clip(a, 0, 255).astype(np.uint8)).convert("RGBA")
    dr = ImageDraw.Draw(im)
    # stars: denser in the band, none behind thick cloud
    for _ in range(int(w * h / 2500 * stars)):
        sx, sy = rng.uniform(0, w), rng.uniform(0, h * (0.8 if horizon else 1.0))
        bi, ci = int(min(h - 1, sy)), int(min(w - 1, sx))
        if cl[bi, ci, 0] > 0.4 or rng.random() > (0.25 + band[bi, ci, 0] * 0.9) * stars:
            continue
        rr = rng.choice([0.6, 0.8, 1.0, 1.3, 1.8]) * U / 1440
        dr.ellipse([sx - rr, sy - rr, sx + rr, sy + rr], fill=(255, 242, 220, int(rng.integers(50, 210))))
    for _ in range(max(3, int(U / 300 * stars))):
        sx, sy = rng.uniform(0, w), rng.uniform(0, h * 0.6)
        if np.hypot(sx - cx, sy - cy) < R * 0.9:
            continue
        twinkle(dr, sx, sy, rng.uniform(6, 13) * U / 1440, int(rng.integers(150, 230)))
    if horizon:
        # far ridge (hazy), near ridge, then a pine treeline in near-black indigo
        for k, (col, base, amp, sc_) in enumerate((((40, 38, 92), horizon, h * 0.07, w / 3),
                                                   ((22, 20, 54), horizon + h * 0.07, h * 0.06, w / 5))):
            nn = noise(w, 1, seed + 10 + k, sc_, 3)[0]
            ridge = base - nn * amp * 2
            pts = [(i, ridge[i]) for i in range(0, w, 4)] + [(w, h), (0, h)]
            dr.polygon(pts, fill=col + (255,))
        tl = horizon + h * 0.16
        dr.rectangle([0, tl, w, h], fill=(10, 9, 26, 255))
        xx = 0.0
        while xx < w:
            ph = rng.uniform(0.06, 0.16) * h
            pw = ph * rng.uniform(0.32, 0.42)
            for j in range(4):  # stacked tiers
                ty = tl - ph + ph * j / 4
                tw = pw * (0.4 + j * 0.22)
                dr.polygon([(xx, ty), (xx + tw / 2, ty + ph * 0.42), (xx - tw / 2, ty + ph * 0.42)],
                           fill=(10, 9, 26, 255))
            xx += pw * rng.uniform(0.35, 0.8)
    # vignette
    v = np.clip(np.hypot((x - w / 2) / (w * 0.75), (y - h / 2) / (h * 0.85)), 0, 1)
    vig = Image.fromarray((v ** 2.2 * 150).astype(np.uint8))
    shade = Image.new("RGBA", (w, h), (2, 2, 10, 0))
    shade.putalpha(vig)
    return Image.alpha_composite(im, shade)


def glow(im, sym, pos, strength=110, blur=0.08):
    """warm halo behind the symbol (its alpha, blurred)"""
    g = Image.new("RGBA", im.size, (0, 0, 0, 0))
    halo = Image.new("RGBA", sym.size, (255, 214, 150, 0))
    halo.putalpha(sym.getchannel("A").point(lambda v: v * strength // 255))
    g.alpha_composite(halo, pos)
    return Image.alpha_composite(im, g.filter(ImageFilter.GaussianBlur(sym.width * blur)))


def main():
    sym = trim(Image.open(os.path.join(D, "layer_symbol.png")).convert("RGBA"))
    word = trim(Image.open(os.path.join(D, "layer_wordmark.png")).convert("RGBA"))

    # emblem: symbol only (it reads at 150 px; a wordmark wouldn't)
    S = 1024
    bg = sky(S, S, S / 2, S * 0.48, 3, halo=0.18, clouds=0.6, stars=2.6)
    s = fit(sym, h=int(S * 0.74))
    pos = ((S - s.width) // 2, int(S * 0.5 - s.height * 0.52))
    bg = glow(bg, s, pos, strength=200, blur=0.06)
    bg.alpha_composite(s, pos)
    bg.convert("RGB").save(os.path.join(D, "emblem_1024.png"))
    bg.convert("RGB").resize((512, 512), Image.LANCZOS).save(os.path.join(D, "emblem_512.png"))
    bg.convert("RGB").resize((150, 150), Image.LANCZOS).save(os.path.join(D, "emblem_preview150.png"))

    # cover 1440x456 (built at 2x): symbol + wordmark side by side, centred as one group
    W, H = 2880, 912
    s = fit(sym, h=int(H * 0.72))
    wm = fit(word, h=int(H * 0.40))
    gap = int(H * 0.12)
    total = s.width + gap + wm.width
    x0 = (W - total) // 2
    bg = sky(W, H, x0 + s.width / 2, H / 2, 9, horizon=H * 0.74, halo=0.4)
    sp = (x0, (H - s.height) // 2)
    bg = glow(bg, s, sp, strength=190, blur=0.06)
    bg.alpha_composite(s, sp)
    bg.alpha_composite(wm, (x0 + s.width + gap, (H - wm.height) // 2))
    out = bg.convert("RGB").resize((1440, 456), Image.LANCZOS)
    out.save(os.path.join(D, "cover_1440x456.png"))
    out.resize((720, 228), Image.LANCZOS).save(os.path.join(D, "cover_720x228.png"))

    # splash lockup: symbol over the wordmark, transparent (the intro puts it on black)
    s = fit(sym, h=900)
    wm = fit(word, w=int(s.width * 1.25))
    gap = 70
    L = Image.new("RGBA", (max(s.width, wm.width), s.height + gap + wm.height), (0, 0, 0, 0))
    L.alpha_composite(s, ((L.width - s.width) // 2, 0))
    L.alpha_composite(wm, ((L.width - wm.width) // 2, s.height + gap))
    L.save(os.path.join(D, "splash_logo.png"))
    print("saved", os.path.abspath(D))


if __name__ == "__main__":
    main()
