import sys, random
from PIL import Image, ImageDraw, ImageFont, ImageFilter

src, out_dir = sys.argv[1], sys.argv[2]
im = Image.open(src).convert("RGB")
W, H = im.size
cw = round(H * 16 / 9)
im = im.crop((W - cw, 0, W, H)).resize((1920, 1080), Image.LANCZOS)
im.save(out_dir + "/glitched_together_thumbnail_notitle.png")

FONT = r"C:\Windows\Fonts\Artifakt Element Black.ttf"
big = ImageFont.truetype(FONT, 132)
small = ImageFont.truetype(FONT, 46)
lines = ["GLITCHED", "TOGETHER"]
x0, y0, lh = 80, 330, 148
NAVY = (22, 30, 70)


def text_layer(fill, dx=0, dy=0, stroke=0, stroke_fill=None):
    lay = Image.new("RGBA", im.size, (0, 0, 0, 0))
    d = ImageDraw.Draw(lay)
    for i, t in enumerate(lines):
        d.text((x0 + dx, y0 + i * lh + dy), t, font=big, fill=fill, stroke_width=stroke, stroke_fill=stroke_fill)
    return lay


canvas = im.convert("RGBA")
shadow = text_layer((10, 15, 40, 150), 8, 10, 14, (10, 15, 40, 150)).filter(ImageFilter.GaussianBlur(10))
canvas = Image.alpha_composite(canvas, shadow)
canvas = Image.alpha_composite(canvas, text_layer((255, 40, 190, 255), -9, 0, 12, (255, 40, 190, 255)))
canvas = Image.alpha_composite(canvas, text_layer((30, 210, 190, 255), 9, 0, 12, (30, 210, 190, 255)))
main = text_layer((255, 255, 255, 255), 0, 0, 12, NAVY + (255,))
# glitch slices: a few thin horizontal strips of the wordmark shifted sideways
random.seed(7)
for _ in range(3):
    y = random.randint(y0 + 10, y0 + 2 * lh + 120)
    h = random.randint(6, 16)
    dx = random.choice([-1, 1]) * random.randint(14, 34)
    strip = main.crop((0, y, im.width, y + h))
    main.paste((0, 0, 0, 0), (0, y, im.width, y + h))
    main.paste(strip, (dx, y), strip)
canvas = Image.alpha_composite(canvas, main)

d = ImageDraw.Draw(canvas)
sub = "2 PLAYER CO-OP ADVENTURE"
sy = y0 + 2 * lh + 40
bw = d.textlength(sub, font=small) + 56
d.rounded_rectangle((x0 + 4, sy, x0 + 4 + bw, sy + 70), radius=16, fill=NAVY + (235,))
d.text((x0 + 32, sy + 9), sub, font=small, fill=(255, 210, 90))
canvas.convert("RGB").save(out_dir + "/glitched_together_thumbnail.png")
print("ok")
