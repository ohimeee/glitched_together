"""Lobby palette atlas (Oct 3, 2026): one 512x512 texture of 8x8 swatches (64 px) so many-colored lobby kit meshes
(books, toy blocks, pencils, planets...) can be one MeshPart each with TextureID. Each swatch carries a little surface
detail (cloth weave, paper lines, wood grain, paint speckle). Swatch order = SWATCHES below; Blender's
tools/lobby_kit/kit.py maps faces onto a swatch by index (PALETTE dict there mirrors this list).
Colors stay off the reserved gameplay colors (art-direction.md §6)."""
import numpy as np
from PIL import Image

S = 64
rng = np.random.default_rng(7)

SWATCHES = [
    # 0-7 cloth book covers
    ("cloth", (178, 58, 62)),  # 0 red
    ("cloth", (62, 88, 160)),  # 1 blue
    ("cloth", (72, 134, 92)),  # 2 green
    ("cloth", (222, 176, 72)),  # 3 mustard
    ("cloth", (232, 222, 200)),  # 4 cream
    ("cloth", (140, 92, 160)),  # 5 plum
    ("cloth", (112, 150, 208)),  # 6 cornflower
    ("cloth", (196, 112, 78)),  # 7 rust
    # 8-15
    ("pages", (238, 230, 208)),  # 8 page block
    ("foil", (214, 178, 96)),  # 9 gold foil
    ("cloth", (40, 48, 86)),  # 10 navy
    ("cloth", (46, 84, 62)),  # 11 forest
    ("cloth", (44, 40, 42)),  # 12 black
    ("paint", (244, 240, 232)),  # 13 white paint
    ("cloth", (226, 150, 166)),  # 14 pink
    ("leather", (128, 76, 48)),  # 15 brown leather
    # 16-23 painted toy wood
    ("paint", (204, 64, 58)),  # 16 toy red
    ("paint", (56, 102, 184)),  # 17 toy blue
    ("paint", (238, 192, 66)),  # 18 toy yellow
    ("paint", (66, 144, 86)),  # 19 toy green
    ("paint", (236, 228, 210)),  # 20 toy ivory
    ("graphite", (52, 52, 58)),  # 21 graphite
    ("paint", (242, 196, 64)),  # 22 pencil yellow
    ("wood", (214, 170, 120)),  # 23 raw pencil wood
    # 24-31
    ("metal", (196, 190, 176)),  # 24 ferrule tin
    ("rubber", (234, 140, 150)),  # 25 eraser pink
    ("paint", (150, 120, 200)),  # 26 lilac
    ("paint", (90, 70, 140)),  # 27 deep violet planet
    ("paint", (232, 120, 96)),  # 28 coral planet
    ("paint", (120, 190, 120)),  # 29 leaf green planet
    ("paint", (250, 214, 120)),  # 30 sun yellow
    ("wood", (176, 128, 84)),  # 31 darker wood
    # 32-39
    ("paper", (250, 236, 120)),  # 32 sticky note yellow
    ("paper", (250, 170, 190)),  # 33 sticky note pink
    ("paper", (246, 244, 236)),  # 34 white paper
    ("cardboard", (190, 150, 104)),  # 35 cardboard
    ("cloth", (96, 60, 48)),  # 36 chocolate
    ("cloth", (170, 196, 120)),  # 37 lime
    ("metal", (120, 124, 132)),  # 38 steel
    ("string", (236, 230, 214)),  # 39 cotton string
]


def noise(scale, amp):
    n = rng.normal(0, 1, (S // scale + 1, S // scale + 1))
    img = Image.fromarray(((n - n.min()) / (np.ptp(n) + 1e-6) * 255).astype(np.uint8))
    img = img.resize((S, S), Image.BICUBIC)
    return (np.asarray(img, np.float32) / 255 - 0.5) * amp


def swatch(kind, rgb):
    base = np.ones((S, S, 3), np.float32) * np.array(rgb, np.float32)
    y, x = np.mgrid[0:S, 0:S]
    if kind == "cloth":
        weave = (np.sin(x * 2.2) * np.sin(y * 2.2)) * 6
        shade = weave + noise(8, 22) + noise(2, 10)
    elif kind == "pages":
        shade = np.where(y % 3 == 0, -16, 0) + noise(16, 10) + noise(1, 6)
    elif kind == "foil":
        shade = noise(4, 40) + noise(1, 14)
    elif kind == "leather":
        shade = noise(3, 26) + noise(12, 30)
    elif kind == "paint":
        shade = noise(16, 10) + noise(1, 5)
    elif kind == "graphite":
        shade = noise(2, 20)
    elif kind == "wood":
        shade = np.sin(y * 0.6 + noise(16, 6) * 2) * 10 + noise(1, 6)
    elif kind == "metal":
        shade = noise(1, 10) + np.sin(x * 0.3) * 4
    elif kind == "rubber":
        shade = noise(4, 8)
    elif kind == "paper":
        shade = noise(16, 8) + noise(1, 4)
    elif kind == "cardboard":
        shade = noise(2, 14) + np.sin(x * 0.9) * 5
    elif kind == "string":
        shade = np.sin((x + y) * 1.6) * 10 + noise(1, 6)
    else:
        shade = 0
    out = base + np.asarray(shade, np.float32)[..., None]
    return np.clip(out, 0, 255)


atlas = np.zeros((S * 8, S * 8, 3), np.float32)
for i, (kind, rgb) in enumerate(SWATCHES):
    r, c = divmod(i, 8)
    atlas[r * S : (r + 1) * S, c * S : (c + 1) * S] = swatch(kind, rgb)
# unused cells: neutral grey
for i in range(len(SWATCHES), 64):
    r, c = divmod(i, 8)
    atlas[r * S : (r + 1) * S, c * S : (c + 1) * S] = 128
Image.fromarray(atlas.astype(np.uint8)).save(__file__.replace("make_lobby_palette.py", "lobby_palette.png"))
print("saved")
