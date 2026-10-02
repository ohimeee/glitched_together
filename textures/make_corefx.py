"""Glitched Core FX textures (run: python textures/make_corefx.py).

GC_Chain.png: a steel chain for Beams (the balance pans hang from the beam on these). Beam textures run along the
image's height (TOOLS.md §3), so links stack vertically: an open oval link face-on, then one edge-on, repeating.
Drawn grey-white on transparent so the Beam's Color tints it.
"""

import os

from PIL import Image, ImageDraw, ImageFilter

OUT = os.path.dirname(__file__)
W, H = 64, 256
LINK = 64  # one face-on + one edge-on link per 128 px


def main() -> None:
    im = Image.new("RGBA", (W * 4, H * 4), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    s = 4
    for i in range(H // LINK):
        cy = (i * LINK + LINK // 2) * s
        if i % 2 == 0:  # face-on: an open oval ring
            box = (8 * s, cy - 40 * s, (W - 8) * s, cy + 40 * s)
            d.ellipse(box, outline=(215, 218, 224, 255), width=10 * s)
            # a darker inner edge so the ring reads round
            inner = (14 * s, cy - 34 * s, (W - 14) * s, cy + 34 * s)
            d.ellipse(inner, outline=(120, 124, 132, 255), width=3 * s)
        else:  # edge-on: a thick bar
            d.rounded_rectangle(
                ((W // 2 - 7) * s, cy - 38 * s, (W // 2 + 7) * s, cy + 38 * s),
                radius=7 * s,
                fill=(190, 194, 202, 255),
            )
            d.line(((W // 2 - 3) * s, cy - 30 * s, (W // 2 - 3) * s, cy + 30 * s), fill=(240, 242, 246, 255), width=2 * s)
    im = im.filter(ImageFilter.GaussianBlur(1.2)).resize((W, H), Image.LANCZOS)
    im.save(os.path.join(OUT, "GC_Chain.png"))
    print("GC_Chain.png")


if __name__ == "__main__":
    main()
