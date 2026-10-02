"""Ambient particle textures (AmbientController): a soft round mote, a fluffy seed (dandelion), a graphite flake.
Run: python textures/make_ambient.py. White on transparent so each emitter's Color tints them."""
import math
import numpy as np
from PIL import Image

S = 128
y, x = np.mgrid[0:S, 0:S]
cx = cy = (S - 1) / 2
r = np.hypot(x - cx, y - cy) / (S / 2)

# soft mote: bright core, long soft falloff
a = np.clip(1 - r, 0, 1) ** 2.2
img = np.zeros((S, S, 4), np.uint8)
img[..., :3] = 255
img[..., 3] = (a * 255).astype(np.uint8)
Image.fromarray(img).save("AMB_Mote.png")

# dandelion seed: thin radial filaments around a tiny core
ang = np.arctan2(y - cy, x - cx)
fil = (np.cos(ang * 14) * 0.5 + 0.5) ** 30 * np.clip(1 - r, 0, 1) * (r > 0.12)
core = np.clip(1 - r / 0.14, 0, 1)
a = np.clip(fil * 0.9 + core, 0, 1)
img[..., 3] = (a * 255).astype(np.uint8)
Image.fromarray(img).save("AMB_Seed.png")

# graphite flake: an irregular sharp-edged shard
rng = np.random.default_rng(3)
pts = [(cx + math.cos(t) * S * 0.42 * rng.uniform(0.55, 1.0), cy + math.sin(t) * S * 0.3 * rng.uniform(0.5, 1.0)) for t in np.linspace(0, 2 * math.pi, 7, endpoint=False)]
from PIL import ImageDraw
im = Image.new("RGBA", (S, S), (255, 255, 255, 0))
ImageDraw.Draw(im).polygon(pts, fill=(255, 255, 255, 235))
im.save("AMB_Flake.png")
print("ok")
