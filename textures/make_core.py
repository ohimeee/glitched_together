"""Glitched Core surfaces (run: python textures/make_core.py).

The unfinished level as a real unfinished scale model (memory realistic-ittakestwo-art): grey primer over
cast concrete, with the builders' pencil construction grid still on the floor. Bases are Poly Haven CC0
textures (concrete_floor_worn_001 for floors, concrete_wall_004 for walls), downloaded at 1k, pulled to a
neutral primer grey; the floor gets faint graphite grid lines and a few hand marks baked into the color map.
Outputs textures/polyhaven/core_*_{color,normal,rough}.png (8-bit RGB). Upload with Studio upload_image and
declare MaterialVariants CoreFloor / CoreWall in adventure.project.json.
"""

import io
import json
import os
import random
import subprocess
import urllib.request

from PIL import Image, ImageDraw, ImageFilter, ImageOps

OUT = os.path.join(os.path.dirname(__file__), "polyhaven")
SETS = {"core_floor": "concrete_floor_worn_001", "core_wall": "concrete_wall_004"}


def files(asset: str) -> dict:
    # the API 403s Python's urllib; curl works (TOOLS.md §3)
    raw = subprocess.run(
        ["curl", "-s", f"https://api.polyhaven.com/files/{asset}"], capture_output=True, check=True
    ).stdout
    return json.loads(raw)


def fetch(url: str) -> Image.Image:
    with urllib.request.urlopen(url) as r:
        return Image.open(io.BytesIO(r.read()))


def rgb(im: Image.Image) -> Image.Image:
    if im.mode in ("I;16", "I"):
        im = im.point(lambda v: v / 256).convert("L")
    return im.convert("RGB")


def primer(color: Image.Image, level: int) -> Image.Image:
    """Neutral grey at `level` mean, keeping the concrete's mottling (no beige/green cast)."""
    g = ImageOps.grayscale(color)
    mean = sum(i * c for i, c in enumerate(g.histogram())) / (g.width * g.height)
    g = g.point(lambda v: max(0, min(255, int(level + (v - mean) * 0.8))))
    return Image.merge("RGB", (g, g, g))


def pencil_grid(im: Image.Image, cells: int, seed: int) -> Image.Image:
    """Faint graphite construction lines: a grid, slightly wobbly, plus a few tick marks and crosses."""
    rnd = random.Random(seed)
    w, h = im.size
    layer = Image.new("L", im.size, 0)
    d = ImageDraw.Draw(layer)
    step = w // cells
    for i in range(cells + 1):
        x = i * step
        pts = [(x + rnd.uniform(-1.5, 1.5), y) for y in range(0, h + 32, 32)]
        d.line(pts, fill=70, width=2)
        y = i * step
        pts = [(xx, y + rnd.uniform(-1.5, 1.5)) for xx in range(0, w + 32, 32)]
        d.line(pts, fill=70, width=2)
    for _ in range(10):  # measurement ticks and little crosses where the builders measured
        cx, cy = rnd.randrange(w), rnd.randrange(h)
        s = rnd.randint(8, 16)
        d.line([(cx - s, cy - s), (cx + s, cy + s)], fill=90, width=2)
        d.line([(cx - s, cy + s), (cx + s, cy - s)], fill=90, width=2)
    layer = layer.filter(ImageFilter.GaussianBlur(0.8))
    dark = Image.new("RGB", im.size, (55, 57, 62))
    return Image.composite(dark, im, layer)


def main() -> None:
    os.makedirs(OUT, exist_ok=True)
    for name, asset in SETS.items():
        f = files(asset)
        color = rgb(fetch(f["Diffuse"]["1k"]["png"]["url"]))
        normal = rgb(fetch(f["nor_gl"]["1k"]["png"]["url"]))
        rough = rgb(fetch(f["Rough"]["1k"]["png"]["url"]))
        if name == "core_floor":
            color = pencil_grid(primer(color, 168), 4, 7)  # 4 cells per tile: StudsPerTile 16 → a line every 4 studs
        else:
            color = primer(color, 150)
        color.save(os.path.join(OUT, f"{name}_color.png"))
        normal.save(os.path.join(OUT, f"{name}_normal.png"))
        rough.save(os.path.join(OUT, f"{name}_rough.png"))
        print(name, "ok")


if __name__ == "__main__":
    main()
