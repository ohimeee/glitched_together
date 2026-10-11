"""Kai's fireball, made "real" (user, Oct 11: "make a real fireball animation and art").
Run: python textures/make_fireball.py. Upload with Studio MCP upload_image; ids in src/shared/Config/ToolFx.luau.

Soft volumetric fire (It Takes Two-like stylized realism, art-direction.md §12) instead of the flat painted flame:
  FX_FireLoop.png   8x8 flipbook (1024², 128 px frames), a looping turbulent ball of fire, colors baked in
                    (white-hot core → yellow → orange → red rim). The fireball's body: big particles locked to it.
  FX_FireBurst.png  8x8 one-shot flipbook: a fireball blooming out and cooling to dark smoke (impacts, meteor).
  FX_Ember.png      a soft round ember (white, tinted by the emitter): trail sparks.
  FX_FireTrail.png  a flame streak for the Trail behind the ball (U = along the trail, head at the left).
  FX_Scorch.png     a burnt splat decal left on the floor where a fireball lands.
"""
import os
import numpy as np
from PIL import Image

OUT = os.path.dirname(os.path.abspath(__file__)) + "/"
rng = np.random.default_rng(7)
GRID = rng.random((64, 64, 64)).astype(np.float32)


def noise3(x, y, z):
    """Trilinear value noise on a 64³ wrapped lattice (inputs any float arrays)."""
    xi, yi, zi = np.floor(x).astype(int), np.floor(y).astype(int), np.floor(z).astype(int)
    xf, yf, zf = x - xi, y - yi, z - zi
    xf, yf, zf = (v * v * (3 - 2 * v) for v in (xf, yf, zf))
    out = 0
    for dx in (0, 1):
        for dy in (0, 1):
            for dz in (0, 1):
                g = GRID[(xi + dx) % 64, (yi + dy) % 64, (zi + dz) % 64]
                w = (xf if dx else 1 - xf) * (yf if dy else 1 - yf) * (zf if dz else 1 - zf)
                out = out + g * w
    return out


def fbm(x, y, z, octaves=5):
    total, amp, norm = 0, 0.5, 0
    for _ in range(octaves):
        total = total + noise3(x, y, z) * amp
        norm += amp
        x, y, z, amp = x * 2.03, y * 2.03, z * 2.03, amp * 0.5
    return total / norm


# temperature → color ramp (stop, r, g, b)
RAMP = np.array(
    [
        (0.00, 70, 8, 4),
        (0.18, 170, 28, 8),
        (0.38, 240, 90, 18),
        (0.58, 255, 160, 40),
        (0.78, 255, 220, 110),
        (1.00, 255, 252, 235),
    ],
    dtype=np.float32,
)


def ramp(t):
    t = np.clip(t, 0, 1)
    rgb = np.zeros(t.shape + (3,), np.float32)
    for c in range(3):
        rgb[..., c] = np.interp(t, RAMP[:, 0], RAMP[:, c + 1])
    return rgb


def smooth(a, b, x):
    t = np.clip((x - a) / (b - a), 0, 1)
    return t * t * (3 - 2 * t)


F = 128  # frame px
N = 8  # grid
yy, xx = np.mgrid[0:F, 0:F].astype(np.float32)
U = (xx + 0.5) / F * 2 - 1
V = (yy + 0.5) / F * 2 - 1
R = np.sqrt(U * U + V * V)


def sheet(frame_fn):
    img = np.zeros((F * N, F * N, 4), np.float32)
    for i in range(N * N):
        rgba = frame_fn(i / (N * N))
        r, c = divmod(i, N)
        img[r * F : (r + 1) * F, c * F : (c + 1) * F] = rgba
    return img


def save(arr, name):
    Image.fromarray(np.clip(arr, 0, 255).astype(np.uint8), "RGBA").save(OUT + name)
    print("wrote", name)


# 1) looping fire ball -------------------------------------------------------------------------------------------
LOOP = 3.0  # noise distance travelled per loop


def fire_loop(p):
    def field(z):
        # domain-warped turbulence: licks rise "up" the frame (−V) and the pattern scrolls upward over time
        wx = fbm(U * 1.6 + 21, (V + z) * 1.6 + 2, z * 0.6 + 8, 3) - 0.5
        wy = fbm(U * 1.6 + 4, (V + z) * 1.6 + 30, z * 0.6 + 12, 3) - 0.5
        uu, vv = U + wx * 0.45, V + wy * 0.45
        n = fbm(uu * 2.0 + 11, (vv + z * 0.9) * 2.0 + 5, z * 0.8 + 3)
        d = fbm(uu * 4.5 + 3, (vv + z * 1.4) * 4.5 + 9, z * 1.3 + 17, 4)
        rr = np.sqrt(uu * uu + vv * vv)
        return n, d, rr

    # crossfade two offsets of the same field so frame 63 → 0 loops seamlessly
    n1, d1, r1 = field(p * LOOP)
    n2, d2, r2 = field((p - 1) * LOOP)
    n = n1 * (1 - p) + n2 * p
    det = d1 * (1 - p) + d2 * p
    rr = r1 * (1 - p) + r2 * p
    edge = 0.74 + (n - 0.5) * 0.9 + np.clip(-V, 0, 1) * 0.12  # ragged rim, taller licks on top
    body = 1 - smooth(edge * 0.15, edge, rr)
    heat = body * (0.25 + 1.0 * det) * (1.15 - rr * 0.7)
    rgb = ramp(heat * 0.95)
    alpha = smooth(0.03, 0.3, heat) * 255
    return np.dstack([rgb, alpha])


save(sheet(fire_loop), "FX_FireLoop.png")



# 2) one-shot burst (bloom → cool → smoke) -----------------------------------------------------------------------
def fire_burst(p):
    grow = 1 - (1 - min(1, p * 1.6)) ** 3  # fast bloom, then holds size
    radius = 0.3 + 0.62 * grow
    n = fbm(U * 2.4 + 2, V * 2.4 - p * 1.2 + 7, p * 2.0 + 1)
    det = fbm(U * 6 + 9, V * 6 - p * 2 + 1, p * 3 + 5, 4)
    edge = radius * (0.78 + (n - 0.5) * 0.7)
    density = (1 - smooth(edge * 0.25, edge, R)) * (0.6 + 0.6 * det)
    heat = density * max(0.0, 1 - p * 1.35) ** 1.3 * 1.5
    smoke = np.array([58, 50, 52], np.float32)
    fire = ramp(heat)
    mix = smooth(0.05, 0.4, heat)[..., None]
    rgb = smoke * (1 - mix) + fire * mix
    fade = (1 - smooth(0.55, 1.0, p)) * (1 - p * 0.35)
    alpha = smooth(0.06, 0.4, density) * fade * 255
    return np.dstack([rgb, alpha])


save(sheet(fire_burst), "FX_FireBurst.png")

# 3) ember ------------------------------------------------------------------------------------------------------
S = 64
ey, ex = np.mgrid[0:S, 0:S].astype(np.float32)
er = np.sqrt(((ex + 0.5) / S * 2 - 1) ** 2 + ((ey + 0.5) / S * 2 - 1) ** 2)
glow = np.clip(1 - er, 0, 1) ** 2.2
core = smooth(0.35, 0.0, er)
a = np.clip(glow * 0.8 + core, 0, 1) * 255
save(np.dstack([np.full((S, S), 255.0), np.full((S, S), 255.0), np.full((S, S), 255.0), a]), "FX_Ember.png")

# 4) trail streak (U along the trail: head = left, tail = right; V across) ------------------------------------------
W, H = 256, 64
ty, tx = np.mgrid[0:H, 0:W].astype(np.float32)
u = tx / W
v = (ty + 0.5) / H * 2 - 1
n = fbm(tx / W * 6 + 1, ty / H * 1.5 + 3, np.full_like(tx, 2.0))
width = (1 - u) ** 0.7 * (0.75 + (n - 0.5) * 0.8)
heat = (1 - smooth(width * 0.2, width + 1e-3, np.abs(v))) * (1 - u) ** 1.2 * 1.25
t_rgb = ramp(heat)
t_a = smooth(0.03, 0.3, heat) * 255
save(np.dstack([t_rgb, t_a]), "FX_FireTrail.png")

# 5) scorch decal -------------------------------------------------------------------------------------------------
S = 256
sy, sx = np.mgrid[0:S, 0:S].astype(np.float32)
su, sv = (sx + 0.5) / S * 2 - 1, (sy + 0.5) / S * 2 - 1
sr = np.sqrt(su * su + sv * sv)
ang = np.arctan2(sv, su)
n = fbm(np.cos(ang) * 2 + 4, np.sin(ang) * 2 + 4, sr * 3 + 1)
spikes = 0.62 + (n - 0.5) * 0.9
burn = 1 - smooth(spikes * 0.3, spikes, sr)
grain = fbm(sx / 18, sy / 18, np.full_like(sx, 9.0), 4)
alpha = np.clip(burn * (0.55 + grain * 0.6), 0, 1) * 235
glow_ring = smooth(0.35, 0.05, sr)  # still-hot centre, warm brown
col = np.dstack([25 + glow_ring * 60, 18 + glow_ring * 22, 14 + glow_ring * 6])
save(np.dstack([col, alpha]), "FX_Scorch.png")
