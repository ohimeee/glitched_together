"""Trailer text cards: Luckiest Guy, navy extrusion + white sticker outline like the title logo (marketing/logo_final.png).

python tools/trailer/cards.py   → ~/Videos/GlitchedTrailer/edit/cards/<name>.png (transparent), used by edit.jsx
"""
import os
from PIL import Image, ImageDraw, ImageFont, ImageFilter

FONT = r"C:\Users\User\tools\fonts\LuckiestGuy-Regular.ttf"
OUT = os.path.expanduser(r"~\Videos\GlitchedTrailer\edit\cards")
NAVY = (58, 61, 92, 255)
WHITE = (255, 255, 255, 255)
ORANGE = (255, 150, 60, 255)  # Kai
TEAL = (64, 214, 196, 255)  # Miko


def card(text, name, size=150, fill=WHITE):
    f = ImageFont.truetype(FONT, size)
    l, t, r, b = f.getbbox(text)
    W, H = r - l + 120, b - t + 120
    base = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    ox, oy = 60 - l, 50 - t
    shadow = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    d = ImageDraw.Draw(shadow)
    for k in range(1, 13):  # extruded navy depth
        d.text((ox + k * 0.4, oy + k), text, font=f, fill=NAVY)
    mask = shadow.copy()
    ImageDraw.Draw(mask).text((ox, oy), text, font=f, fill=NAVY)
    a = mask.split()[3].filter(ImageFilter.MaxFilter(17))
    outline = Image.new("RGBA", (W, H), WHITE)
    outline.putalpha(a)
    soft = Image.new("RGBA", (W, H), (0, 0, 0, 255))
    soft.putalpha(a.filter(ImageFilter.GaussianBlur(10)).point(lambda v: v * 110 // 255))
    base.alpha_composite(soft, (6, 10))
    base.alpha_composite(outline)
    base.alpha_composite(shadow)
    ImageDraw.Draw(base).text((ox, oy), text, font=f, fill=fill)
    base.save(os.path.join(OUT, name + ".png"))
    print(name, base.size)


if __name__ == "__main__":
    os.makedirs(OUT, exist_ok=True)
    card("TWO PLAYERS", "two_players", fill=ORANGE)
    card("THREE WORLDS", "three_worlds", fill=TEAL)
    card("ONE UNFINISHED GAME", "unfinished", size=120)
    card("PLAY WITH A FRIEND", "play_friend", size=95)
    card("ON ROBLOX", "on_roblox", size=60)
