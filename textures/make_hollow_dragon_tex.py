# Hollow Dragon texture: repaints the Celestial Dragon's base color (Sketchfab, achrefrhm9, CC-BY 4.0; credit in
# CREDITS.md) from icy blue to the castle boss's plum, and turns its pale star-wing glow toward the Glitch's
# magenta static. Hue rotate of the saturated blues, a slight darken so it holds against the lit hall, 1024 px
# (Studio's limit). Source: celestial_dragon_src.png (saved from the import in Blender).
import colorsys

from PIL import Image

SRC = "celestial_dragon_src.png"
OUT = "hollow_dragon_color.png"


def main():
    img = Image.open(SRC).convert("RGB").resize((1024, 1024), Image.LANCZOS)
    px = img.load()
    w, h = img.size
    for y in range(h):
        for x in range(w):
            r, g, b = (c / 255 for c in px[x, y])
            hh, ll, ss = colorsys.rgb_to_hls(r, g, b)
            deg = hh * 360
            if 170 <= deg <= 250 and ss > 0.12:
                # blue scales -> plum (~285 deg), a touch richer and darker
                hh = 285 / 360 + (deg - 210) / 360 * 0.4
                ss = min(1, ss * 1.15)
                ll = ll * 0.82
            elif (deg >= 300 or deg <= 20) and ll > 0.55:
                # the pale pink star glow on the wings -> magenta static
                hh = 312 / 360
                ss = min(1, ss * 1.4 + 0.15)
            r, g, b = colorsys.hls_to_rgb(hh % 1, ll, ss)
            px[x, y] = (int(r * 255), int(g * 255), int(b * 255))
    img.save(OUT)
    print("ok", img.size)


if __name__ == "__main__":
    main()
