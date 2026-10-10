# The Unfinished texture: repaints the Meteor Golem's base color (Sketchfab, s8819296, CC-BY 4.0; credit in
# CREDITS.md) for the final boss. Its icy-blue seams sit next to Miko's reserved teal, so they become the Glitch's
# magenta static (#FF2BD6, Palette.Glitch); the dark rock plates go neutral and a touch lighter, toward the Core's
# primer greys (Palette.Core.Dark #3A3C42). 1024 px (Studio's limit).
# Source: unfinished_src_baseColor.png (saved from the import in Blender at 1024).
import colorsys

from PIL import Image

SRC = "unfinished_src_baseColor.png"
OUT = "unfinished_color.png"
GLITCH_HUE = 311 / 360


def main():
    img = Image.open(SRC).convert("RGB").resize((1024, 1024), Image.LANCZOS)
    px = img.load()
    w, h = img.size
    for y in range(h):
        for x in range(w):
            r, g, b = (c / 255 for c in px[x, y])
            hh, ll, ss = colorsys.rgb_to_hls(r, g, b)
            deg = hh * 360
            if 160 <= deg <= 250 and ss > 0.25 and ll > 0.12:
                # glowing seams -> magenta static, a bit brighter so it reads from the top-down camera
                hh = GLITCH_HUE
                ss = min(1, ss * 1.2 + 0.1)
                ll = min(0.8, ll * 1.15)
            else:
                # rock plates -> neutral primer grey, lifted
                ss = ss * 0.15
                ll = min(1, ll * 1.45 + 0.03)
            r, g, b = colorsys.hls_to_rgb(hh % 1, ll, ss)
            px[x, y] = (int(r * 255), int(g * 255), int(b * 255))
    img.save(OUT)
    print("ok", img.size)


if __name__ == "__main__":
    main()
