"""Game icon, Pip version (user, Oct 18: our own idea, not It Takes Two's). Like popular mascot icons
(Slime Rancher etc.): the mascot fills the square, tilted, on a glowing gradient, the logo along the bottom.
Pip (Blender scene IconPip → marketing/icon_pip_raw.png) gets magenta / cyan glitch pixels peeling off his right side.

Usage: python tools/paint_style/icon_pip.py
"""
import numpy as np
from PIL import Image, ImageDraw, ImageFilter

M = r"C:\Users\User\OneDrive\Desktop\Coding\glitched_together\marketing"
S = 1024
rng = np.random.default_rng(5)

# background: night-navy to violet radial glow, a soft teal/magenta haze behind Pip
y, x = np.mgrid[0:S, 0:S]
d = np.hypot(x - S * 0.5, y - S * 0.42) / (S * 0.72)
inner, outer = np.array([96, 70, 190]), np.array([16, 20, 60])
bg = inner * (1 - np.clip(d, 0, 1))[..., None] + outer * np.clip(d, 0, 1)[..., None]
for cx, cy, col, r in ((0.2, 0.75, (31, 199, 182), 0.45), (0.85, 0.3, (255, 43, 214), 0.45)):
    g = np.exp(-(((x - S * cx) ** 2 + (y - S * cy) ** 2) / (2 * (S * r * 0.5) ** 2)))[..., None]
    bg = bg * (1 - g * 0.35) + np.array(col) * g * 0.35
canvas = Image.fromarray(np.clip(bg, 0, 255).astype(np.uint8)).convert("RGBA")

# a few faint big pixels in the background
d2 = ImageDraw.Draw(canvas)
for _ in range(26):
    px, py, s = rng.integers(0, S), rng.integers(0, S), int(rng.integers(10, 34))
    col = [(255, 43, 214), (43, 242, 255), (255, 255, 255)][int(rng.integers(0, 3))]
    d2.rectangle([px, py, px + s, py + s], fill=col + (int(rng.integers(30, 80)),))

# Pip, big, centred a little high
pip = Image.open(M + r"\icon_pip_raw.png").convert("RGBA")
pip = pip.crop(pip.getbbox())
pw = int(S * 0.9)
pip = pip.resize((pw, int(pip.height * pw / pip.width)), Image.LANCZOS)
px, py = (S - pw) // 2 - int(S * 0.03), int(S * 0.04)
# glow behind him
glow = Image.new("RGBA", (S, S), (0, 0, 0, 0))
gl = Image.new("RGBA", pip.size, (255, 230, 255, 0))
gl.putalpha(pip.getchannel("A").point(lambda v: v * 0.7))
glow.alpha_composite(gl, (px, py))
canvas = Image.alpha_composite(canvas, glow.filter(ImageFilter.GaussianBlur(40)))
# glitch: his right edge breaks into pixels drifting right (cut squares from the sprite, offset, tinted)
a = np.asarray(pip)
alpha = a[:, :, 3] > 128
cols = np.nonzero(alpha.any(0))[0]
right = cols[-1]
cell = pw // 22
peel = Image.new("RGBA", pip.size, (0, 0, 0, 0))
mask = Image.new("L", pip.size, 255)
md = ImageDraw.Draw(mask)
for _ in range(60):
    cx = int(rng.integers(int(right - pw * 0.28), right))
    cy = int(rng.integers(0, pip.height - cell))
    blk = a[cy: cy + cell, cx: cx + cell]
    if blk.shape[0] < cell or blk.shape[1] < cell or (blk[:, :, 3] > 128).mean() < 0.6:
        continue
    md.rectangle([cx, cy, cx + cell, cy + cell], fill=0)  # hole where it left
    tint = [np.array([255, 43, 214]), np.array([43, 242, 255]), None][int(rng.integers(0, 3))]
    b = blk.astype(np.float64)
    if tint is not None:
        b[:, :, :3] = b[:, :, :3] * 0.35 + tint * 0.65
    dx = int(rng.integers(cell, int(pw * 0.2)))
    dy = int(rng.integers(-cell, cell))
    tx = min(pip.width - cell, cx + dx)
    peel.alpha_composite(Image.fromarray(b.astype(np.uint8)), (tx, max(0, cy + dy)))
pip.putalpha(Image.fromarray(np.minimum(np.asarray(pip.getchannel("A")), np.asarray(mask))))
canvas.alpha_composite(pip, (px, py))
canvas.alpha_composite(peel, (px, py))

# no text on the icon (user, Oct 18): the game name shows under it anyway
canvas.convert("RGB").save(M + r"\icon_pip_1024.png")
canvas.convert("RGB").resize((512, 512), Image.LANCZOS).save(M + r"\icon_pip_512.png")
print("saved icon_pip_512.png / icon_pip_1024.png")
