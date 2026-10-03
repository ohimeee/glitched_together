"""Kids' crayon drawings for the lobby bedroom walls (LobbyRoom posters). Run: python textures/make_lobby_drawings.py
Wax-crayon look: every stroke is many jittered thin lines with gaps (paper tooth), on off-white paper with a slight
tint and creases. Our own drawings of our own game (Starfall Castle, Kai + Miko, Pixel Plains, the level-3 plan)."""
import math
import random

from PIL import Image, ImageDraw, ImageFilter, ImageFont

W, H = 768, 1024
random.seed(9)
FONT = "C:/Windows/Fonts/segoeprb.ttf"


def paper(w=W, h=H, tint=(246, 240, 226)):
    im = Image.new("RGB", (w, h), tint)
    d = ImageDraw.Draw(im)
    for _ in range(9000):  # paper grain
        x, y = random.randrange(w), random.randrange(h)
        c = random.randint(-10, 6)
        d.point((x, y), fill=tuple(max(0, min(255, t + c)) for t in tint))
    for _ in range(2):  # a fold crease
        y = random.randint(int(h * 0.3), int(h * 0.7))
        d.line([(0, y), (w, y + random.randint(-12, 12))], fill=tuple(t - 18 for t in tint), width=2)
    return im


def crayon_line(d, pts, color, width=10, passes=5):
    for _ in range(passes):
        jit = [(x + random.uniform(-width * 0.35, width * 0.35), y + random.uniform(-width * 0.35, width * 0.35)) for x, y in pts]
        for a, b in zip(jit, jit[1:]):
            steps = max(2, int(math.dist(a, b) / 3))
            for s in range(steps):
                if random.random() < 0.12:
                    continue  # paper tooth gaps
                t0, t1 = s / steps, (s + 1) / steps
                p0 = (a[0] + (b[0] - a[0]) * t0, a[1] + (b[1] - a[1]) * t0)
                p1 = (a[0] + (b[0] - a[0]) * t1, a[1] + (b[1] - a[1]) * t1)
                d.line([p0, p1], fill=color, width=max(1, int(width / passes * random.uniform(0.8, 1.6))))


def crayon_fill(d, poly, color, density=0.9, angle=0.6, gap=7):
    xs = [p[0] for p in poly]
    ys = [p[1] for p in poly]
    mask = Image.new("L", (W, H), 0)
    ImageDraw.Draw(mask).polygon(poly, fill=255)
    for k in range(int(min(ys)) - W - 50, int(max(ys)) + 50, gap):
        x0, x1 = min(xs) - 50, max(xs) + 50
        a = (x0, k)
        b = (x1, k + (x1 - x0) * math.tan(angle))
        steps = int(math.dist(a, b) / 4)
        for s in range(steps):
            t = s / steps
            x = a[0] + (b[0] - a[0]) * t
            y = a[1] + (b[1] - a[1]) * t
            if 0 <= x < W and 0 <= y < H and mask.getpixel((int(x), int(y))) and random.random() < density:
                d.line([(x, y), (x + 4, y + 4 * math.tan(angle))], fill=color, width=random.randint(2, 4))


def scribble_text(d, text, xy, size, color, rot=0):
    f = ImageFont.truetype(FONT, size)
    d.text(xy, text, fill=color, font=f)


def star(cx, cy, r):
    return [(cx + math.cos(math.radians(-90 + i * 36)) * (r if i % 2 == 0 else r * 0.45),
             cy + math.sin(math.radians(-90 + i * 36)) * (r if i % 2 == 0 else r * 0.45)) for i in range(10)]


def finish(im, name):
    im = im.filter(ImageFilter.GaussianBlur(0.6))
    im.save(name)


# 1: Starfall Castle at night
im = paper()
d = ImageDraw.Draw(im)
crayon_fill(d, [(0, 0), (W, 0), (W, 620), (0, 620)], (52, 58, 120), density=0.75)
crayon_fill(d, [(0, 620), (W, 560), (W, H), (0, H)], (72, 140, 76), density=0.8)
for t in ((180, 380, 120, 300), (590, 380, 120, 300)):
    x, y, w, h = t
    crayon_fill(d, [(x - w / 2, y), (x + w / 2, y), (x + w / 2, y + h), (x - w / 2, y + h)], (170, 160, 176))
    crayon_fill(d, [(x - w / 2 - 20, y), (x, y - 140), (x + w / 2 + 20, y)], (150, 70, 160))
crayon_fill(d, [(240, 480), (530, 480), (530, 700), (240, 700)], (186, 176, 190))
crayon_fill(d, [(340, 700), (430, 700), (430, 600), (385, 560), (340, 600)], (90, 60, 40))
for cx, cy, r in ((120, 120, 30), (360, 90, 44), (650, 150, 26), (520, 260, 20), (260, 220, 18)):
    crayon_fill(d, star(cx, cy, r), (255, 214, 90))
    crayon_line(d, star(cx, cy, r) + [star(cx, cy, r)[0]], (230, 170, 40), 5, 2)
crayon_line(d, [(240, 480), (240, 700), (530, 700), (530, 480), (240, 480)], (60, 60, 70), 6, 3)
scribble_text(d, "STARFALL", (110, 760), 110, (240, 120, 60))
scribble_text(d, "KINGDOM", (150, 880), 100, (240, 120, 60))
finish(im, "lobby_drawing_castle.png")

# 2: Kai + Miko, best friends
im = paper(tint=(244, 242, 232))
d = ImageDraw.Draw(im)
crayon_fill(d, [(0, 760), (W, 740), (W, H), (0, H)], (100, 170, 90), density=0.7)
crayon_fill(d, [(560, 60), (700, 60), (700, 200), (560, 200)], (255, 210, 70))
for (cx, color, label) in ((250, (255, 138, 43), "KAI"), (520, (31, 160, 182), "MIKO")):
    crayon_fill(d, [(cx - 45, 300), (cx + 45, 300), (cx + 45, 390), (cx - 45, 390)], (250, 220, 190))
    crayon_line(d, [(cx - 45, 300), (cx + 45, 300), (cx + 45, 390), (cx - 45, 390), (cx - 45, 300)], (70, 60, 50), 6, 2)
    crayon_line(d, [(cx - 20, 335), (cx - 18, 340)], (40, 40, 40), 8, 2)
    crayon_line(d, [(cx + 18, 335), (cx + 20, 340)], (40, 40, 40), 8, 2)
    crayon_line(d, [(cx - 20, 365), (cx, 375), (cx + 20, 365)], (190, 60, 60), 6, 2)
    crayon_fill(d, [(cx - 60, 400), (cx + 60, 400), (cx + 70, 600), (cx - 70, 600)], color)
    crayon_line(d, [(cx - 30, 600), (cx - 35, 740)], (60, 70, 120), 14, 3)
    crayon_line(d, [(cx + 30, 600), (cx + 35, 740)], (60, 70, 120), 14, 3)
    scribble_text(d, label, (cx - 70, 180), 80, color)
crayon_line(d, [(310, 470), (385, 500), (460, 470)], (250, 220, 190), 14, 3)  # holding hands
crayon_line(d, [(190, 470), (140, 560)], (250, 220, 190), 14, 3)
crayon_line(d, [(580, 470), (630, 560)], (250, 220, 190), 14, 3)
scribble_text(d, "BEST FRIENDS 4EVER", (40, 800), 64, (200, 60, 120))
scribble_text(d, "+ we make a game!!", (150, 900), 52, (60, 60, 140))
finish(im, "lobby_drawing_friends.png")

# 3: Pixel Plains (squares, a crayon sun, clouds)
im = paper(tint=(240, 244, 248))
d = ImageDraw.Draw(im)
crayon_fill(d, [(0, 0), (W, 0), (W, 560), (0, 560)], (120, 190, 240), density=0.6)
crayon_fill(d, [(470, 60), (650, 60), (650, 240), (470, 240)], (255, 206, 60))
for k in range(12):
    x = k * 64
    h = 540 - int(abs(math.sin(k * 0.7)) * 200)
    crayon_fill(d, [(x, h), (x + 64, h), (x + 64, H), (x, H)], (90, 180, 70) if k % 2 else (80, 160, 60))
    crayon_fill(d, [(x, h + 60), (x + 64, h + 60), (x + 64, H), (x, H)], (150, 100, 60))
for cx, cy in ((150, 140), (330, 230)):
    crayon_fill(d, [(cx - 70, cy), (cx + 70, cy), (cx + 70, cy + 50), (cx - 70, cy + 50)], (250, 250, 250))
crayon_fill(d, [(360, 300), (420, 300), (420, 360), (360, 360)], (255, 214, 80))
scribble_text(d, "?", (372, 290), 60, (180, 100, 40))
scribble_text(d, "PIXEL PLAINS", (70, 860), 96, (40, 40, 60))
finish(im, "lobby_drawing_plains.png")

# 4: the level-3 plan (graph paper, arrows, TODO)
im = paper(tint=(238, 240, 236))
d = ImageDraw.Draw(im)
for k in range(0, W, 32):
    d.line([(k, 0), (k, H)], fill=(170, 190, 214), width=1)
for k in range(0, H, 32):
    d.line([(0, k), (W, k)], fill=(170, 190, 214), width=1)
scribble_text(d, "LEVEL 3 ???", (60, 40), 90, (60, 60, 70))
for (x, y, w, h) in ((80, 260, 160, 60), (300, 340, 140, 50), (500, 260, 180, 60), (220, 520, 300, 70)):
    crayon_line(d, [(x, y), (x + w, y), (x + w, y + h), (x, y + h), (x, y)], (80, 80, 90), 6, 2)
crayon_line(d, [(240, 290), (300, 360)], (200, 60, 60), 6, 2)
crayon_line(d, [(440, 365), (500, 290)], (200, 60, 60), 6, 2)
scribble_text(d, "TODO: boss", (220, 640), 70, (200, 50, 50))
scribble_text(d, "TODO: finish it", (120, 760), 70, (200, 50, 50))
scribble_text(d, "together", (220, 880), 70, (60, 60, 140))
finish(im, "lobby_drawing_plan.png")
print("ok")
