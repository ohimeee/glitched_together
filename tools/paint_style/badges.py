"""Badge icons (LAUNCH.md §4, Oct 19): 8 round 512 x 512 icons from our own art, painted with the speed-paint
filter so they match the thumbnails. Worlds = the painted loading cards; bosses = the King painting and frames
from the trailer's boss intro takes (marketing/badges/src_*.png). Roblox shows badges as circles: the subject
sits in the middle, a ring frames it (silver = world, gold = boss / game finished). No text: the badge name shows.

Usage: python tools/paint_style/badges.py   ->  marketing/badges/badge_<name>.png
"""
import pathlib
import sys

import numpy as np
from PIL import Image, ImageDraw, ImageFilter

ROOT = pathlib.Path(__file__).resolve().parents[2]
sys.path.insert(0, str(pathlib.Path(__file__).parent))
from paint import paint  # noqa: E402

OUT = ROOT / "marketing" / "badges"
LC = ROOT / "textures" / "loading"
S = 512

# name: (source, centre x, centre y (fractions), crop side as a fraction of the source height, ring)
BADGES = {
    "prologue": (LC / "LC_Prologue.png", 0.74, 0.70, 0.60, "silver"),
    "pixel_plains": (LC / "LC_PixelPlains.png", 0.62, 0.50, 0.85, "silver"),
    "starfall_castle": (LC / "LC_Castle.png", 0.70, 0.45, 0.90, "silver"),
    "glitched_core": (LC / "LC_Core.png", 0.62, 0.45, 0.80, "silver"),
    "game_finished": (LC / "LC_Epilogue.png", 0.65, 0.47, 0.80, "gold"),
    "crusher_king": (ROOT / "marketing" / "paint_king.png", 0.52, 0.52, 0.85, "gold"),
    "hollow_dragon": (OUT / "src_dragon.png", 0.60, 0.55, 0.85, "gold"),
    "the_unfinished": (OUT / "src_unfinished.png", 0.50, 0.58, 0.80, "gold"),
}
RINGS = {"silver": ((235, 240, 255), (120, 130, 170)), "gold": ((255, 226, 150), (190, 120, 40))}


def crop(src, cx, cy, side):
    im = Image.open(src).convert("RGB")
    w, h = im.size
    s = int(h * side)
    x = min(max(0, int(w * cx - s / 2)), w - s)
    y = min(max(0, int(h * cy - s / 2)), h - s)
    return im.crop((x, y, x + s, y + s))


def badge(name, src, cx, cy, side, ring):
    sq = crop(src, cx, cy, side).resize((S * 2, S * 2), Image.LANCZOS)
    art = paint(sq, seed=sum(map(ord, name)), strokes=900, out_w=S * 2, punch=1.6 if name == "glitched_core" else 1.15).convert("RGBA")
    art = art.resize((S, S), Image.LANCZOS)
    # soft vignette pulls the eye to the middle
    y, x = np.mgrid[0:S, 0:S]
    d = np.clip(np.hypot(x - S / 2, y - S / 2) / (S / 2), 0, 1)
    shade = (1 - 0.45 * d**3)[..., None]
    a = np.asarray(art).astype(np.float64)
    a[..., :3] *= shade
    art = Image.fromarray(a.clip(0, 255).astype(np.uint8))
    # ring: dark outer line, bright band, thin inner shadow
    hi, lo = RINGS[ring]
    dr = ImageDraw.Draw(art)
    m = 6
    dr.ellipse([m, m, S - m, S - m], outline=lo + (255,), width=26)
    dr.ellipse([m + 5, m + 5, S - m - 5, S - m - 5], outline=hi + (255,), width=14)
    glow = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    ImageDraw.Draw(glow).ellipse([m + 26, m + 26, S - m - 26, S - m - 26], outline=(0, 0, 0, 140), width=10)
    art = Image.alpha_composite(art, glow.filter(ImageFilter.GaussianBlur(6)))
    # outside the circle: transparent (Roblox crops to a circle anyway)
    mask = Image.new("L", (S, S), 0)
    ImageDraw.Draw(mask).ellipse([m - 2, m - 2, S - m + 2, S - m + 2], fill=255)
    art.putalpha(mask)
    art.save(OUT / f"badge_{name}.png")
    return art


if __name__ == "__main__":
    only = sys.argv[1:]
    for n, args in BADGES.items():
        if not only or n in only:
            badge(n, *args)
            print("saved", n)
