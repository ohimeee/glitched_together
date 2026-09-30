"""Pixel Plains textures (run: python textures/make_pixelplains.py). Uploaded with Studio MCP upload_image;
ids live in the code that uses them: crayon sun -> Config/Worlds.luau, belt tread -> ArtService/PixelPlains.luau,
PixelPlastic maps -> adventure.project.json (MaterialService). Re-upload after changing anything here."""
import math, os, random
import numpy as np
from PIL import Image, ImageDraw, ImageFilter
random.seed(5)
OUT = os.path.dirname(os.path.abspath(__file__)) + "/"

def crayon_line(d, pts, color, width, passes=4, jitter=3):
    # several wobbly, semi-transparent passes = waxy crayon stroke
    for p in range(passes):
        q = [(x + random.uniform(-jitter, jitter), y + random.uniform(-jitter, jitter)) for x, y in pts]
        a = random.randint(150, 230)
        d.line(q, fill=color + (a,), width=max(2, int(width * random.uniform(0.7, 1.1))), joint="curve")

# 1) Crayon sun (kid drawing on the skybox, art-direction §8), 512 RGBA
S = 512; img = Image.new("RGBA", (S, S), (0, 0, 0, 0)); d = ImageDraw.Draw(img)
cx = cy = S / 2; R = 120
GOLD = (255, 200, 61); ORANGE = (255, 150, 40); INK = (120, 60, 20)
# rays: chunky wobbly strokes, alternate long/short
for i in range(12):
    a = i * math.tau / 12 + random.uniform(-0.06, 0.06)
    r0 = R + 18; r1 = R + (105 if i % 2 == 0 else 70)
    pts = [(cx + math.cos(a) * (r0 + (r1 - r0) * t), cy + math.sin(a) * (r0 + (r1 - r0) * t)) for t in (0, 0.5, 1)]
    crayon_line(d, pts, ORANGE, 20, 5, 4)
# filled face: scribble fill with many strokes
for k in range(260):
    y = cy - R + (2 * R) * k / 260 + random.uniform(-2, 2)
    half = math.sqrt(max(0, R * R - (y - cy) ** 2)) * random.uniform(0.9, 1.0)
    d.line([(cx - half, y + random.uniform(-4, 4)), (cx + half, y + random.uniform(-4, 4))], fill=GOLD + (random.randint(170, 255),), width=4)
# wobbly outline
ring = [(cx + math.cos(t) * (R + math.sin(t * 5) * 3), cy + math.sin(t) * (R + math.cos(t * 3) * 3)) for t in [i * math.tau / 60 for i in range(61)]]
crayon_line(d, ring, ORANGE, 10, 4, 2.5)
# smiley: dot eyes, big smile, rosy cheeks
for ex in (-42, 42):
    d.ellipse([cx + ex - 12, cy - 38 - 16, cx + ex + 12, cy - 38 + 16], fill=INK + (235,))
for ex in (-72, 72):
    d.ellipse([cx + ex - 20, cy + 14 - 12, cx + ex + 20, cy + 14 + 12], fill=(255, 120, 110, 110))
smile = [(cx + math.cos(t) * 62, cy + 5 + math.sin(t) * 50) for t in [math.radians(20 + i * 7) for i in range(21)]]
crayon_line(d, smile, INK, 11, 3, 2)
img = img.filter(ImageFilter.GaussianBlur(0.6))
# the sky draws the sun additively: keep the hue, drop the value so it lands on warm gold instead of white
arr = np.asarray(img).astype(float)
arr[..., :3] *= np.array([0.62, 0.42, 0.12])
Image.fromarray(arr.astype(np.uint8), "RGBA").save(OUT + "PP_CrayonSun2.png")

# 2) Conveyor belt (tileable 256): dark rubber slats, painted chevrons pointing along +V (up the image = travel)
S = 256; img = Image.new("RGB", (S, S), (46, 46, 54)); d = ImageDraw.Draw(img)
for y in range(S):  # rubber noise
    for x in range(0, S, 2):
        n = random.randint(-6, 6)
        img.putpixel((x, y), (46 + n, 46 + n, 54 + n))
for sy in range(0, S, 32):  # slat grooves every 32 px (tiles cleanly)
    d.rectangle([0, sy, S, sy + 4], fill=(26, 26, 32))
    d.line([(0, sy + 5), (S, sy + 5)], fill=(70, 70, 80), width=1)
PALE = (154, 154, 166)
for cy0 in (64, 192):  # two chevrons per tile
    for off in (0, 22):
        y = cy0 + off
        d.line([(64, y + 26), (128, y - 6), (192, y + 26)], fill=PALE, width=10, joint="curve")
# on a belt's top face V runs along the belt: chevrons point down the image (+V) = the way it carries you
img.rotate(180).save(OUT + "PP_BeltTread3.png")


# 3) PixelPlastic MaterialVariant: near-white glossy toy plastic, soft 1-stud pixel bevel grid (8 cells/tile)
rng = np.random.default_rng(4)
N = 512; CELLS = 8; cs = N // CELLS; edge = 7  # px bevel per cell edge
y, x = np.mgrid[0:N, 0:N]
fx = x % cs; fy = y % cs
dx = np.minimum(fx, cs - 1 - fx); dy = np.minimum(fy, cs - 1 - fy)
d = np.minimum(dx, dy).astype(float)
h = np.clip(d / edge, 0, 1); h = h * h * (3 - 2 * h)  # soft rounded bevel
# per-cell tiny height/tilt differences (molded, slightly uneven voxels)
cid = (y // cs) * CELLS + (x // cs)
cellh = rng.uniform(-0.04, 0.04, CELLS * CELLS)[cid]
noise = rng.normal(0, 1, (N, N))
nimg = Image.fromarray(((noise - noise.min()) / np.ptp(noise) * 255).astype(np.uint8)).filter(ImageFilter.GaussianBlur(2.5))
fine = np.asarray(nimg).astype(float) / 255 - 0.5
H = h + cellh * h + fine * 0.05
# normal map (OpenGL, +Y up): tileable gradients
s = 5.0
gx = (np.roll(H, -1, 1) - np.roll(H, 1, 1)) * s
gy = (np.roll(H, -1, 0) - np.roll(H, 1, 0)) * s
nx, ny, nz = -gx, gy, np.ones_like(H)
l = np.sqrt(nx * nx + ny * ny + nz * nz)
nrm = np.stack([nx / l, ny / l, nz / l], -1) * 0.5 + 0.5
Image.fromarray((nrm * 255).astype(np.uint8)).save(OUT + "PP_PixelPlastic_Normal.png")
# color: near white, grooves a touch darker (baked AO), faint per-cell value shift
col = 1.0 + cellh * 0.5 + fine * 0.03 - (1 - h) * 0.14
col = np.clip(col, 0, 1)
Image.fromarray((np.stack([col] * 3, -1) * 255).astype(np.uint8)).save(OUT + "PP_PixelPlastic_Color2.png")
# roughness: glossy faces, rougher grooves, faint scuffs
rough = 0.55 + (1 - h) * 0.2 + np.abs(fine) * 0.2
Image.fromarray((np.clip(rough, 0, 1) * 255).astype(np.uint8)).save(OUT + "PP_PixelPlastic_Rough2.png")


print("ok")
