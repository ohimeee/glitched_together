"""World 1 tool VFX textures (run: python textures/make_toolfx.py). Uploaded with Studio MCP upload_image; ids live in
src/shared/Config/ToolFx.luau. Chunky, hard-edged shapes (art-direction.md §12): Pixel Plains effects are made of
squares, the freeze is blue-white (never an owner color), the grapple rope is real braided rope."""
import math, os, random
import numpy as np
from PIL import Image, ImageDraw, ImageFilter

random.seed(9)
OUT = os.path.dirname(os.path.abspath(__file__)) + "/"
ICE = (190, 225, 255)
WHITE = (255, 255, 255)


def save(img, name):
    img.save(OUT + name)


# 1) Freeze shockwave ring: a thick hard-edged ring with a soft inner glow (flat-disc / billboard particle), 256
S = 256
img = Image.new("RGBA", (S, S), (0, 0, 0, 0))
d = ImageDraw.Draw(img)
glow = Image.new("RGBA", (S, S), (0, 0, 0, 0))
ImageDraw.Draw(glow).ellipse([28, 28, S - 28, S - 28], outline=ICE + (160,), width=26)
img = Image.alpha_composite(img, glow.filter(ImageFilter.GaussianBlur(10)))
d = ImageDraw.Draw(img)
d.ellipse([22, 22, S - 22, S - 22], outline=WHITE + (255,), width=14)
d.ellipse([40, 40, S - 40, S - 40], outline=ICE + (200,), width=5)
save(img, "FX_FreezeRing.png")

# 2) Pixel pause glyph (the ⏸ that bursts out of a frozen object), 64, hard pixels
S = 64
img = Image.new("RGBA", (S, S), (0, 0, 0, 0))
d = ImageDraw.Draw(img)
d.rectangle([10, 8, 56, 56], fill=ICE + (120,))
for x0 in (18, 36):
    d.rectangle([x0, 16, x0 + 10, 48], fill=WHITE + (255,))
save(img, "FX_PauseGlyph.png")

# 3) Pixel square sparkle (Pixel Plains particles are squares), 64: solid core, soft square halo
S = 64
img = Image.new("RGBA", (S, S), (0, 0, 0, 0))
halo = Image.new("RGBA", (S, S), (0, 0, 0, 0))
ImageDraw.Draw(halo).rectangle([14, 14, 50, 50], fill=WHITE + (150,))
img = Image.alpha_composite(img, halo.filter(ImageFilter.GaussianBlur(6)))
ImageDraw.Draw(img).rectangle([22, 22, 42, 42], fill=WHITE + (255,))
save(img, "FX_PixelSpark.png")

# Beams map the image's height along their length and its width across them: strips are drawn lengthwise, then
# turned upright on save.
# 4) Pause Beam texture: bright core, ice edges, pixel
#    ticks marching along it, 256 x 64
W, H = 256, 64
arr = np.zeros((H, W, 4), float)
y = np.linspace(-1, 1, H)[:, None]
core = np.clip(1 - np.abs(y) / 0.28, 0, 1) ** 0.7
edge = np.clip(1 - np.abs(y) / 0.9, 0, 1) ** 2
col = np.array(WHITE) * core[..., None] + np.array(ICE) * (1 - core[..., None])
arr[..., :3] = np.broadcast_to(col, (H, W, 3))
arr[..., 3] = np.broadcast_to(np.maximum(core, edge * 0.55) * 255, (H, W))
img = Image.fromarray(arr.astype(np.uint8), "RGBA")
d = ImageDraw.Draw(img)
for x in range(0, W, 64):  # pixel squares riding the beam
    for dy in (-18, 12):
        d.rectangle([x + 20, H // 2 + dy, x + 30, H // 2 + dy + 8], fill=WHITE + (255,))
save(img.rotate(90, expand=True), "FX_PauseBeam.png")

# 5) Grapple rope (Beam texture): braided natural rope with teal fibers twisted in, 256 x 64, opaque
W, H = 256, 64
img = Image.new("RGBA", (W, H), (0, 0, 0, 0))
d = ImageDraw.Draw(img)
ROPE = (205, 168, 110)
DARK = (140, 104, 60)
TEAL = (31, 199, 182)
d.rectangle([0, 10, W, H - 10], fill=ROPE + (255,))
for i, x in enumerate(range(-64, W + 64, 16)):  # diagonal strands, one teal per three
    c = TEAL if i % 3 == 0 else (ROPE if i % 2 else (225, 190, 132))
    d.polygon([(x, 10), (x + 12, 10), (x + 36, H - 10), (x + 24, H - 10)], fill=c + (255,))
    d.line([(x + 12, 10), (x + 36, H - 10)], fill=DARK + (255,), width=2)
    d.line([(x + 5, 12), (x + 26, H - 12)], fill=(255, 235, 200, 120), width=2)  # fiber highlight
d.line([(0, 10), (W, 10)], fill=DARK + (255,), width=2)
d.line([(0, H - 11), (W, H - 11)], fill=DARK + (255,), width=2)
# round it: light from above, darker toward the underside
arr = np.asarray(img).astype(float)
shade = 0.55 + 0.6 * np.clip(np.cos(np.linspace(-1.2, 1.9, H)), 0, 1)[:, None]
arr[..., :3] = np.clip(arr[..., :3] * shade[..., None], 0, 255)
save(Image.fromarray(arr.astype(np.uint8), "RGBA").rotate(90, expand=True), "FX_Rope.png")

# 6) Scanlines (Layer Shift overlay, tiled on screen), 64: thin white rows every 4 px, tinted teal in code
S = 64
arr = np.zeros((S, S, 4), np.uint8)
arr[..., :3] = 255
arr[::4, :, 3] = 255
arr[1::4, :, 3] = 90
Image.fromarray(arr, "RGBA").save(OUT + "FX_Scanlines.png")

print("ok")
