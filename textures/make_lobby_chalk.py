"""Chalk lettering for the lobby's A-frame chalkboard (Oct 3, 2026; user: "the text should look like chalk").
Transparent PNG laid over the slate board (16 x 17 studs) by LobbyBuilder. Hand lettering in Segoe Print Bold, then
made chalky: grain that breaks the strokes up, a soft dust halo, drag streaks, faint old eraser smudges, a few doodles.
KAI / MIKO lines in pastel chalk (orange / teal stay readable as the owner colors)."""
import numpy as np
from PIL import Image, ImageDraw, ImageFilter, ImageFont

W, H = 1024, 1088
rng = np.random.default_rng(11)
FONT = r"C:\Windows\Fonts\segoescb.ttf"
FONT_THIN = r"C:\Windows\Fonts\segoesc.ttf"


def text_mask(lines):
    """lines: (text, y_center, size, rotation_deg, font, color) -> list of (mask L image, color)."""
    out = []
    for text, y, size, rot, font, color in lines:
        f = ImageFont.truetype(font, size)
        layer = Image.new("L", (W, H), 0)
        d = ImageDraw.Draw(layer)
        bbox = d.textbbox((0, 0), text, font=f)
        tw, th = bbox[2] - bbox[0], bbox[3] - bbox[1]
        d.text(((W - tw) / 2 - bbox[0], y - th / 2 - bbox[1]), text, font=f, fill=255)
        if rot:
            layer = layer.rotate(rot, resample=Image.BICUBIC, center=(W / 2, y))
        out.append((layer, color))
    return out


def chalkify(mask):
    m = np.asarray(mask, np.float32) / 255
    # grain: fine noise + horizontal drag streaks, so strokes break up like chalk on slate
    grain = rng.random((H, W)).astype(np.float32)
    streak = np.asarray(
        Image.fromarray((rng.random((H // 3, W // 24)) * 255).astype(np.uint8)).resize((W, H), Image.BILINEAR),
        np.float32,
    ) / 255
    keep = np.clip((grain * 0.7 + streak * 0.5) - 0.28, 0, 1) * 1.9
    core = m * np.clip(keep, 0, 1)
    # dust halo: a soft blurred copy at low opacity
    halo = np.asarray(mask.filter(ImageFilter.GaussianBlur(6)), np.float32) / 255 * 0.22
    dust = halo * (0.6 + 0.4 * grain)
    return np.clip(np.maximum(core * 0.95, dust), 0, 1)


def main():
    rgb = np.zeros((H, W, 3), np.float32)
    alpha = np.zeros((H, W), np.float32)

    # old eraser smudges (very faint wide strokes)
    sm = Image.new("L", (W, H), 0)
    d = ImageDraw.Draw(sm)
    for _ in range(5):
        x, y = rng.integers(80, W - 300), rng.integers(80, H - 200)
        d.rounded_rectangle((x, y, x + rng.integers(200, 420), y + rng.integers(60, 140)), radius=60, fill=255)
    sm = sm.filter(ImageFilter.GaussianBlur(30))
    s = np.asarray(sm, np.float32) / 255 * 0.07 * (0.5 + rng.random((H, W)))
    rgb += s[..., None] * np.array([235, 238, 232])
    alpha = np.maximum(alpha, s)

    white = (244, 244, 236)
    lines = [
        ("GLITCHED", 150, 138, 3, FONT, white),
        ("TOGETHER", 310, 150, 2, FONT, white),
        ("~ a game for 2 ~", 462, 66, -1, FONT_THIN, (236, 232, 214)),
        ("hop in a capsule:", 640, 70, 0, FONT_THIN, white),
        ("KAI", 830, 120, 2, FONT, (255, 178, 120)),  # pastel orange chalk (Kai)
        ("MIKO", 830, 120, -2, FONT, (120, 228, 214)),  # pastel teal chalk (Miko)
        ("or", 840, 64, 0, FONT_THIN, white),  # sits at x ~ 470,
    ]
    masks = text_mask(lines)
    # KAI left, MIKO right, "or" in the middle: shift those layers sideways
    shifted = []
    for (layer, color), spec in zip(masks, lines):
        if spec[0] == "KAI":
            layer = layer.transform(layer.size, Image.AFFINE, (1, 0, 230, 0, 1, 0))
        elif spec[0] == "MIKO":
            layer = layer.transform(layer.size, Image.AFFINE, (1, 0, -240, 0, 1, 0))
        shifted.append((layer, color))

    # doodles: a star top-right, an underline, a triangle and a circle next to the names
    dd = Image.new("L", (W, H), 0)
    d = ImageDraw.Draw(dd)
    cx, cy, r = 945, 60, 36
    pts = []
    for k in range(10):
        a = -np.pi / 2 + k * np.pi / 5
        rr = r if k % 2 == 0 else r * 0.42
        pts.append((cx + np.cos(a) * rr, cy + np.sin(a) * rr))
    d.line(pts + [pts[0]], fill=255, width=9, joint="curve")
    d.line([(190, 392), (520, 398), (840, 388)], fill=255, width=8)
    d.polygon([(52, 870), (92, 795), (132, 870)], outline=255, width=9)
    d.ellipse((924, 799, 990, 865), outline=255, width=9)
    shifted.append((dd, white))

    for layer, color in shifted:
        a = chalkify(layer)
        rgb = rgb * (1 - a[..., None]) + a[..., None] * np.array(color, np.float32)
        alpha = np.maximum(alpha, a)

    out = np.dstack([np.clip(rgb / np.maximum(alpha[..., None], 1e-4), 0, 255), alpha * 255]).astype(np.uint8)
    Image.fromarray(out, "RGBA").save(__file__.replace("make_lobby_chalk.py", "lobby_chalk.png"))
    # preview on slate
    bg = Image.new("RGBA", (W, H), (46, 58, 54, 255))
    bg.alpha_composite(Image.fromarray(out, "RGBA"))
    bg.convert("RGB").save(__file__.replace("make_lobby_chalk.py", "lobby_chalk_preview.png"))
    print("saved")


main()
