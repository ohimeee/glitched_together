"""Finishes the 3D title logo (blender_assets/Logo.blend, scene Logo → marketing/logo_3d.png) and places it on art.

The render gets a few short sideways smears and a white sticker outline (finish()).

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
    """The logo as the user approved it (flat orange / teal 3D letters, a few short sideways smears) plus a thick white
    sticker outline round everything (user, Oct 18: "go back to our old logo, just keep that white outline")."""
    im = trim(Image.open(ROOT + r"\logo_3d.png").convert("RGBA"))
    pad = im.width // 14
    big = Image.new("RGBA", (im.width + pad * 2, im.height + pad * 2), (0, 0, 0, 0))
    big.alpha_composite(im, (pad, pad))
    out = np.asarray(big).astype(np.float64).copy()
    h, w = out.shape[:2]
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
        length = int(rng.integers(w // 24, w // 8))
        col = out[y: y + hh, x - 2].copy()
        for k in range(length):
            xx = x + k
            if xx >= w:
                break
            f = (1 - k / length) ** 1.6
            seg = out[y: y + hh, xx]
            seg[:] = np.where(seg[:, 3:4] > col[:, 3:4] * f, seg, col * np.array([1, 1, 1, f]))
    res = Image.fromarray(np.clip(out, 0, 255).astype(np.uint8))
    # white sticker outline round the letters (not the smears: built from the solid letters only)
    solid = Image.fromarray((np.asarray(big)[:, :, 3] > 60).astype(np.uint8) * 255)
    ring = solid.filter(ImageFilter.MaxFilter(1 + 2 * (w // 110))).filter(ImageFilter.GaussianBlur(1.2))
    sticker = Image.new("RGBA", res.size, (255, 255, 255, 0)); sticker.putalpha(ring)
    soft = Image.new("RGBA", res.size, (10, 14, 40, 0)); soft.putalpha(ring.point(lambda v: v * 0.45))
    base = Image.new("RGBA", res.size, (0, 0, 0, 0))
    base.alpha_composite(soft.filter(ImageFilter.GaussianBlur(6)), (4, 8))
    base.alpha_composite(sticker); base.alpha_composite(res)
    base = trim(base)
    base.save(ROOT + r"\logo_final.png")
    print("saved logo_final.png", base.size)


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
