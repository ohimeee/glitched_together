"""Game icon (512 x 512, Roblox's square "mini profile"): Kai and Miko close up from the cover art, the 3D logo
across the bottom (user, Oct 18). Reads at phone size: big faces, big letters, nothing small.

Usage: python tools/paint_style/icon.py [cx cy side]   (crop centre + side in cover_art_source.png pixels)
"""
import sys
from PIL import Image, ImageDraw, ImageFilter

M = r"C:\Users\User\OneDrive\Desktop\Coding\glitched_together\marketing"


def icon(cx, cy, side):
    art = Image.open(M + r"\cover_art_source.png").convert("RGBA")
    box = (cx - side // 2, cy - side // 2, cx + side // 2, cy + side // 2)
    sq = art.crop(box).resize((1024, 1024), Image.LANCZOS)
    # darken the bottom a little so the logo pops
    shade = Image.new("L", (1024, 1024), 0)
    d = ImageDraw.Draw(shade)
    for y in range(560, 1024):
        d.line([(0, y), (1024, y)], fill=int(150 * ((y - 560) / 464) ** 1.4))
    dark = Image.new("RGBA", (1024, 1024), (10, 14, 40, 255))
    sq = Image.composite(dark, sq, shade)
    logo = Image.open(M + r"\logo_final.png").convert("RGBA")
    lw = 960
    logo = logo.resize((lw, int(logo.height * lw / logo.width)), Image.LANCZOS)
    pos = ((1024 - lw) // 2, 1024 - logo.height - 26)
    sh = Image.new("RGBA", (1024, 1024), (0, 0, 0, 0))
    s = Image.new("RGBA", logo.size, (8, 10, 30, 0))
    s.putalpha(logo.getchannel("A").point(lambda v: v * 0.6))
    sh.alpha_composite(s, (pos[0] + 6, pos[1] + 10))
    sq = Image.alpha_composite(sq, sh.filter(ImageFilter.GaussianBlur(8)))
    sq.alpha_composite(logo, pos)
    out = sq.convert("RGB").resize((512, 512), Image.LANCZOS)
    out.save(M + r"\icon_512.png")
    sq.convert("RGB").save(M + r"\icon_1024.png")
    print("saved icon_512.png / icon_1024.png")


if __name__ == "__main__":
    a = [int(v) for v in sys.argv[1:4]] if len(sys.argv) >= 4 else [1900, 820, 1120]
    icon(*a)
