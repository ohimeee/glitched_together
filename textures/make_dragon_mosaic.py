"""Hollow Dragon hall floor inlay: a 16-point star compass of antique gold + ivory lines on a transparent ground, laid
as a Decal over the flagstones in front of the broken edge (ArtService/StarfallCastle dragonHall). Muted gold (#C9A04E),
never the neutral-yellow gameplay colour. Output: textures/dragon_mosaic.png (1024 x 1024)."""
import math
from PIL import Image, ImageDraw, ImageFilter

S = 1024
C = S / 2
GOLD = (201, 160, 78, 235)
GOLD_DARK = (150, 112, 52, 220)
IVORY = (232, 222, 200, 200)
PLUM = (70, 46, 96, 150)

img = Image.new("RGBA", (S, S), (0, 0, 0, 0))
d = ImageDraw.Draw(img)


def ring(r, w, col):
    d.ellipse((C - r, C - r, C + r, C + r), outline=col, width=w)


def pt(r, a):
    return (C + r * math.cos(a), C + r * math.sin(a))


# outer bands: two gold rings with an ivory zodiac band of small stars between them, on a plum band
d.ellipse((C - 496, C - 496, C + 496, C + 496), outline=PLUM, width=30)
for i in range(48):
    a = math.tau * i / 48
    x, y = pt(481, a)
    r = 6 if i % 4 == 0 else 3
    d.ellipse((x - r, y - r, x + r, y + r), fill=IVORY)
ring(420, 4, IVORY)
ring(500, 10, GOLD)
ring(462, 6, GOLD_DARK)

# 16-point star: long cardinal points, medium diagonals, short ones between; each point split light/dark (bevel look)
for i in range(16):
    a = math.tau * i / 16 - math.pi / 2
    length = 400 if i % 4 == 0 else (300 if i % 2 == 0 else 200)
    half = math.tau / 32 * (1.5 if i % 4 == 0 else 1.25)
    tip = pt(length, a)
    left = pt(95, a - half)
    right = pt(95, a + half)
    d.polygon([pt(0, a), left, tip], fill=GOLD if i % 2 == 0 else GOLD_DARK)
    d.polygon([pt(0, a), tip, right], fill=GOLD_DARK if i % 2 == 0 else IVORY)
    d.line([pt(0, a), tip], fill=PLUM, width=2)

# centre medallion: plum disc, gold rim, an ivory eight-point star
d.ellipse((C - 80, C - 80, C + 80, C + 80), fill=(70, 46, 96, 230), outline=GOLD, width=8)
star = []
for i in range(16):
    a = math.tau * i / 16 - math.pi / 2
    star.append(pt(62 if i % 2 == 0 else 26, a))
d.polygon(star, fill=IVORY)

# cracks: the Glitch's fault lines run across the inlay toward the hole (top of the image = toward the dragon)
d.line([pt(30, -1.9), pt(180, -1.75), pt(260, -1.62), pt(520, -1.5)], fill=(30, 22, 36, 200), width=5)
d.line([pt(140, -1.2), pt(330, -1.05), pt(520, -1.12)], fill=(30, 22, 36, 180), width=4)

img = img.filter(ImageFilter.GaussianBlur(0.8))  # soften the vector edges so it looks set in stone
img.save(__file__.replace("make_dragon_mosaic.py", "dragon_mosaic.png"))
print("ok")
