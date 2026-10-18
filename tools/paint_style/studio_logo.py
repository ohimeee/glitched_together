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
    bg = night(S, S, S / 2, S * 0.48, 3)
    s = fit(sym, h=int(S * 0.74))
    pos = ((S - s.width) // 2, int(S * 0.5 - s.height * 0.52))
    bg = glow(bg, s, pos)
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
    bg = night(W, H, x0 + s.width / 2, H / 2, 9)
    sp = (x0, (H - s.height) // 2)
    bg = glow(bg, s, sp)
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
