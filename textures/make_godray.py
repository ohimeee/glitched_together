# Soft sun shaft for Beams (the Crusher King throne hall's rose window): white with alpha only. Beam textures run
# along the beam in X (Attachment0 -> 1) and across it in Y: bright near the window, fading out toward the floor,
# soft edges across, a few faint streaks so it reads as light through tracery.
import math
import random

from PIL import Image

W, H = 256, 128


def main():
    rng = random.Random(7)
    streaks = [(rng.uniform(0.15, 0.85), rng.uniform(0.03, 0.08), rng.uniform(0.15, 0.35)) for _ in range(5)]
    img = Image.new("RGBA", (W, H))
    px = img.load()
    for x in range(W):
        u = x / (W - 1)
        along = min(1.0, u / 0.08) * (1 - u) ** 1.4  # quick fade-in at the window, long tail
        for y in range(H):
            t = y / (H - 1)
            across = math.exp(-((t - 0.5) / 0.28) ** 4)
            s = 1 - sum(a * math.exp(-((t - c) / w) ** 2) for c, w, a in streaks)
            a = max(0.0, along * across * s)
            px[x, y] = (255, 255, 255, int(255 * a))
    img.save("godray.png")
    print("ok")


if __name__ == "__main__":
    main()
