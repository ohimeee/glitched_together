"""Starfall Castle fabrics (run: python textures/make_castle_fabric.py).

Poly Haven CC0 textiles for the castle's Fabric parts: quatrefoil_jacquard_fabric (the long royal rug) and
velour_velvet (the hanging sign banners). 1k maps, 8-bit RGB, lifted toward white so the part's Color tints them
(rug: banner red-violet, banners: royal purple). Outputs textures/polyhaven/castle_{rug,velvet}_{color,normal,rough}.png.
"""

import io
import json
import os
import subprocess
import urllib.request

from PIL import Image, ImageOps

OUT = os.path.join(os.path.dirname(__file__), "polyhaven")
SETS = {"castle_rug": "quatrefoil_jacquard_fabric", "castle_velvet": "velour_velvet"}


def files(asset: str) -> dict:
    raw = subprocess.run(["curl", "-s", f"https://api.polyhaven.com/files/{asset}"], capture_output=True, check=True).stdout
    return json.loads(raw)


def fetch(url: str) -> Image.Image:
    with urllib.request.urlopen(url) as r:
        return Image.open(io.BytesIO(r.read()))


def rgb(im: Image.Image) -> Image.Image:
    if im.mode in ("I;16", "I"):
        im = im.point(lambda v: v / 256).convert("L")
    return im.convert("RGB")


def tintable(color: Image.Image) -> Image.Image:
    """Greyscale pattern, bright, so the part Color carries the hue."""
    g = ImageOps.autocontrast(ImageOps.grayscale(color), cutoff=1)
    g = g.point(lambda v: int(110 + v * 145 / 255))
    return Image.merge("RGB", (g, g, g))


def main() -> None:
    os.makedirs(OUT, exist_ok=True)
    for name, asset in SETS.items():
        f = files(asset)
        tintable(rgb(fetch(f["Diffuse"]["1k"]["png"]["url"]))).save(os.path.join(OUT, f"{name}_color.png"))
        rgb(fetch(f["nor_gl"]["1k"]["png"]["url"])).save(os.path.join(OUT, f"{name}_normal.png"))
        rgb(fetch(f["Rough"]["1k"]["png"]["url"])).save(os.path.join(OUT, f"{name}_rough.png"))
        print(name, "ok")


if __name__ == "__main__":
    main()
