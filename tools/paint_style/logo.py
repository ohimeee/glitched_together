"""Finishes the 3D title logo (blender_assets/Logo.blend, scene Logo → marketing/logo_3d.png) and places it on art.

The render gets a few short sideways smears off the letters' right edges, the paint filter's language (tools/paint_style/paint.py).

Usage:
  python tools/paint_style/logo.py finish                      → marketing/logo_final.png (transparent)
  python tools/paint_style/logo.py place <in.png> <out.png> big|corner
"""
import sys
import numpy as np
from PIL import Image, ImageFilter

ROOT = r"C:\Users\User\OneDrive\Desktop\Coding\glitched_together\marketing"


def trim(im):
    return im.crop(im.getbbox())


def finish():
    im = trim(Image.open(ROOT + r"\logo_3d.png").convert("RGBA"))
    a = np.asarray(im).astype(np.float64)
    h, w = a.shape[:2]
    alpha = a[:, :, 3] > 30
    rows = np.nonzero(alpha.any(1))[0]
    out = a.copy()  # no cut through GLITCHED (user: remove the full-width seam line)
    # a few sideways smears from the letters' right edges (fading, the painting's glitch drags)
    rng = np.random.default_rng(11)
    ys = np.nonzero(out[:, :, 3].max(1) > 200)[0]
    for _ in range(26):
        y = int(rng.choice(ys))
        row = np.nonzero(out[y, :, 3] > 200)[0]
        if len(row) == 0:
            continue
        x = int(row[-1])
        hh = int(rng.integers(1, max(2, h // 120)))
        length = int(rng.integers(w // 20, w // 6))
        col = out[y: y + hh, x - 2].copy()
        for k in range(length):
            xx = x + k
            if xx >= w:
                break
            f = (1 - k / length) ** 1.6
            seg = out[y: y + hh, xx]
            seg[:] = np.where(seg[:, 3:4] > col[:, 3:4] * f, seg, col * np.array([1, 1, 1, f]))
    res = Image.fromarray(np.clip(out, 0, 255).astype(np.uint8))
    res.save(ROOT + r"\logo_final.png")
    print("saved logo_final.png", res.size)


def place(src, dst, mode):
    art = Image.open(src).convert("RGBA")
    logo = Image.open(ROOT + r"\logo_final.png").convert("RGBA")
    W, H = art.size
    if mode == "big":
        lw = int(W * 0.46)
        logo = logo.resize((lw, int(logo.height * lw / logo.width)), Image.LANCZOS)
        pos = (int(W * 0.03), int(H * 0.5 - logo.height * 0.55))
    else:
        lw = int(W * 0.19)
        logo = logo.resize((lw, int(logo.height * lw / logo.width)), Image.LANCZOS)
        pos = (int(W * 0.022), H - logo.height - int(H * 0.03))
    shadow = Image.new("RGBA", art.size, (0, 0, 0, 0))
    sh = Image.new("RGBA", logo.size, (8, 10, 30, 0))
    sh.putalpha(logo.getchannel("A").point(lambda v: v * 0.55))
    shadow.alpha_composite(sh, (pos[0] + W // 300, pos[1] + H // 140))
    art = Image.alpha_composite(art, shadow.filter(ImageFilter.GaussianBlur(W / 200)))
    art.alpha_composite(logo, pos)
    art.convert("RGB").save(dst)
    print("saved", dst)


if __name__ == "__main__":
    if sys.argv[1] == "finish":
        finish()
    else:
        place(sys.argv[2], sys.argv[3], sys.argv[4])
