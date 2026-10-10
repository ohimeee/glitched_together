# Epilogue ground variants (EpGrass / EpPath / EpRock) from Poly Haven CC0 sets in polyhaven/:
# leafy_grass -> ep_grass, rocky_trail_02 -> ep_path, rock_face_03 -> ep_rock (downloaded 1k, 8-bit RGB).
# Run once on the fresh downloads (it grades in place). Grades the color maps: grass pulled green (the raw scan is half dead leaves), rock pulled toward grey.
from PIL import Image
import numpy as np

def load(n):
    return np.asarray(Image.open(f"polyhaven/{n}_color.png").convert("RGB")).astype(np.float32) / 255

def save(a, n):
    Image.fromarray((a.clip(0, 1) * 255).astype(np.uint8)).save(f"polyhaven/{n}_color.png")

g = load("ep_grass")
lum = g @ np.array([0.3, 0.59, 0.11], np.float32)
green = lum[..., None] * np.array([0.62, 1.05, 0.45], np.float32) * 1.15
save(g * 0.3 + green * 0.7, "ep_grass")

r = load("ep_rock")
lum = r @ np.array([0.3, 0.59, 0.11], np.float32)
grey = lum[..., None] * np.array([0.98, 0.96, 0.94], np.float32)
save(r * 0.35 + grey * 0.65, "ep_rock")

# the trail scan is red-brown and read maroon under the warm lanterns (red = danger): pull it to a grey-brown dirt
p = load("ep_path")
lum = p @ np.array([0.3, 0.59, 0.11], np.float32)
dirt = lum[..., None] * np.array([1.0, 0.95, 0.86], np.float32)
save(p * 0.25 + dirt * 0.75, "ep_path")
