"""Speed-paint filter for marketing art (user, Oct 18: thumbnails in the style of the user's reference folder:
flat square-brush color blocks, long horizontal smears, thin dark scratches, blown-out highlights). Style only,
from our own Blender renders: nothing is copied from the references.

Usage: python tools/paint_style/paint.py <in.png> <out.png> [--seed N] [--strokes N] [--width W]
"""
import argparse
import numpy as np
from PIL import Image, ImageFilter


def box_mean(a, r):
    """mean over a (2r+1)^2 box, per channel, via integral images"""
    pad = np.pad(a, ((r + 1, r), (r + 1, r), (0, 0)), mode="edge").astype(np.float64)
    s = pad.cumsum(0).cumsum(1)
    k = 2 * r + 1
    return (s[k:, k:] - s[:-k, k:] - s[k:, :-k] + s[:-k, :-k]) / (k * k)


def kuwahara(img, r):
    """classic 4-quadrant Kuwahara: flattens detail into painted blocks, keeps edges"""
    a = img.astype(np.float64)
    lum = a.mean(2, keepdims=True)
    m = box_mean(a, r)
    v = box_mean(lum * lum, r) - box_mean(lum, r) ** 2
    h, w = a.shape[:2]
    best_m = np.zeros_like(a)
    best_v = np.full((h, w, 1), np.inf)
    for dy in (-r, r):
        for dx in (-r, r):
            ys = np.clip(np.arange(h) + dy // 2, 0, h - 1)
            xs = np.clip(np.arange(w) + dx // 2, 0, w - 1)
            mm = m[ys][:, xs]
            vv = v[ys][:, xs]
            take = vv < best_v
            best_v = np.where(take, vv, best_v)
            best_m = np.where(take, mm, best_m)
    return best_m


def paint(src, seed, strokes, out_w):
    rng = np.random.default_rng(seed)
    im = src.convert("RGB")
    im = im.resize((out_w, round(im.height * out_w / im.width)), Image.LANCZOS)
    a = np.asarray(im).astype(np.float64)
    h, w = a.shape[:2]
    base = kuwahara(a, max(2, w // 400))
    # posterize a little: fewer, flatter values (the references read as a handful of colour blocks)
    base = np.round(base / 18) * 18
    canvas = base.copy()
    lum = a.mean(2)
    gy, gx = np.gradient(lum)
    edge = np.hypot(gx, gy)

    # detail map: strokes are big where the picture is flat (sky, fields) and skip silhouettes, so shapes stay crisp
    from PIL import ImageFilter as _F
    det = np.asarray(Image.fromarray(np.clip(edge * 4, 0, 255).astype(np.uint8)).filter(_F.GaussianBlur(w / 160)))
    det = det.astype(np.float64) / max(1.0, det.max())

    # 1) flat square-brush dabs: short wide rectangles, colour sampled from the source, mostly horizontal
    for _ in range(strokes):
        y = rng.integers(0, h)
        x = rng.integers(0, w)
        d = det[y, x]
        if d > 0.35 or rng.random() < d * 2:
            continue
        c = base[y, x]
        k = 1.0 - d * 2
        lw = int(rng.integers(w // 160, w // 40) * (0.4 + k))
        lh = int(rng.integers(max(2, h // 300), max(3, h // 110)) * (0.6 + k * 0.6))
        x0, x1 = max(0, x - lw // 2), min(w, x + lw // 2)
        y0, y1 = max(0, y - lh // 2), min(h, y + lh // 2)
        alpha = rng.uniform(0.5, 0.9)
        canvas[y0:y1, x0:x1] = canvas[y0:y1, x0:x1] * (1 - alpha) + c * alpha

    # 2) long horizontal smears ("glitch drags"): a row band dragged sideways from where it starts
    for _ in range(strokes // 80):
        y = rng.integers(0, h)
        x = rng.integers(0, w)
        bh = int(rng.integers(1, max(2, h // 300)))
        length = int(rng.integers(w // 40, w // 9))
        y0, y1 = y, min(h, y + bh)
        x1 = min(w, x + length)
        if x1 - x < 4:
            continue
        if det[y, x] > 0.25:
            continue
        col = canvas[y0:y1, x:x + 1].copy()
        fade = np.linspace(0.9, 0.0, x1 - x)[None, :, None]
        canvas[y0:y1, x:x1] = canvas[y0:y1, x:x1] * (1 - fade) + col * fade

    # 3) thin dark scratch lines along strong edges, slightly off-axis
    strong = np.percentile(edge, 97)
    for _ in range(strokes // 6):
        y = rng.integers(2, h - 2)
        x = rng.integers(2, w - 2)
        if edge[y, x] < strong:
            continue
        ang = rng.normal(0, 0.25) + (np.pi / 2 if rng.random() < 0.25 else 0)
        L = int(rng.integers(w // 80, w // 25))
        t = np.arange(L)
        xs = np.clip((x + np.cos(ang) * t).astype(int), 0, w - 1)
        ys = np.clip((y + np.sin(ang) * t).astype(int), 0, h - 1)
        canvas[ys, xs] = canvas[ys, xs] * 0.45 + np.array([24, 20, 18]) * 0.55

    # 4) blow out the highlights (white-hot sun spots) and add a faint paper grain
    l2 = canvas.mean(2, keepdims=True)
    hi = np.clip((l2 - 200) / 40, 0, 1)
    canvas = canvas * (1 - hi * 0.6) + 255 * hi * 0.6
    canvas += rng.normal(0, 3.5, canvas.shape)
    out = Image.fromarray(np.clip(canvas, 0, 255).astype(np.uint8))
    return out.filter(ImageFilter.UnsharpMask(radius=1.2, percent=60, threshold=2))


if __name__ == "__main__":
    ap = argparse.ArgumentParser()
    ap.add_argument("src")
    ap.add_argument("dst")
    ap.add_argument("--seed", type=int, default=7)
    ap.add_argument("--strokes", type=int, default=26000)
    ap.add_argument("--width", type=int, default=1920)
    o = ap.parse_args()
    paint(Image.open(o.src), o.seed, o.strokes, o.width).save(o.dst)
    print("saved", o.dst)
