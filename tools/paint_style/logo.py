"""Finishes the 3D title logo (blender_assets/Logo.blend, scene Logo → marketing/logo_3d.png) and places it on art.

The render gets pixels breaking off GLITCHED, a white sticker outline and a slight tilt (finish()).

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
    """Stumble Guys / Fall Guys style finish (user refs, Oct 18): pixels breaking off the end of GLITCHED (magenta /
    cyan, the game's glitch), a thick white sticker outline round everything, a slight upward tilt."""
    im = trim(Image.open(ROOT + r"\logo_3d.png").convert("RGBA"))
    pad = im.width // 10
    big = Image.new("RGBA", (im.width + pad * 2, im.height + pad * 2), (0, 0, 0, 0))
    big.alpha_composite(im, (pad, pad))
    a = np.asarray(big).astype(np.float64)
    h, w = a.shape[:2]
    al = a[:, :, 3] > 128
    rows = np.nonzero(al.any(1))[0]
    top_end = int(rows[0] + (rows[-1] - rows[0]) * 0.36)  # GLITCHED = top band
    gcols = np.nonzero(al[: top_end].any(0))[0]
    right = int(gcols[-1])
    cell = max(6, w // 70)
    rng = np.random.default_rng(3)
    out = a.copy()
    blocks = []
    for _ in range(40):
        cx = int(rng.integers(right - cell * 3, right - cell))
        cy = int(rng.integers(rows[0], top_end - cell))
        blk = a[cy: cy + cell, cx: cx + cell]
        if (blk[:, :, 3] > 128).mean() < 0.7:
            continue
        blocks.append((cx, cy, blk.copy()))
        if len(blocks) >= 9:
            break
    for i, (cx, cy, blk) in enumerate(blocks):
        if i % 2 == 0:  # only some pieces leave a gap: the navy depth shows through
            out[cy: cy + cell, cx: cx + cell] = np.array([22, 30, 70, 255])
        dx = int(rng.integers(cell, cell * 9)); dy = int(rng.integers(-cell * 2, cell * 2))
        tint = (np.array([255, 43, 214]), np.array([43, 242, 255]), None)[i % 3]
        b = blk.copy()
        if tint is not None:
            m = b[:, :, 3] > 0
            b[m, :3] = b[m, :3] * 0.3 + tint * 0.7
        x, y = min(w - cell, cx + dx), max(0, cy + dy)
        out[y: y + cell, x: x + cell] = np.where(b[:, :, 3:4] > 0, b, out[y: y + cell, x: x + cell])
    res = Image.fromarray(np.clip(out, 0, 255).astype(np.uint8))
    # white sticker outline: dilate the alpha, fill white, logo on top
    ring = res.getchannel("A").point(lambda v: 255 if v > 60 else 0).filter(ImageFilter.MaxFilter(1 + 2 * (w // 110)))
    ring = ring.filter(ImageFilter.GaussianBlur(1.2))
    sticker = Image.new("RGBA", res.size, (255, 255, 255, 0)); sticker.putalpha(ring)
    soft = Image.new("RGBA", res.size, (10, 14, 40, 0)); soft.putalpha(ring.point(lambda v: v * 0.45))
    base = Image.new("RGBA", res.size, (0, 0, 0, 0))
    base.alpha_composite(soft.filter(ImageFilter.GaussianBlur(6)), (4, 8))
    base.alpha_composite(sticker); base.alpha_composite(res)
    base = base.rotate(4, resample=Image.BICUBIC, expand=True)
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
