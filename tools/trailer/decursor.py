"""Paint the mouse cursor out of the takes that caught it (OBS captured the resting arrow, Oct 18).

python tools/trailer/decursor.py   → ~/Videos/GlitchedTrailer/clean/<take>.mp4 (originals untouched)
edit.jsx reads a take from clean/ when its name is in CLEAN there.
Boxes = x, y, w, h in the take's pixels (measured: white arrow + black outline, padded a few px).
"""
import os
import subprocess

DIR = os.path.expanduser(r"~\Videos\GlitchedTrailer")
CURSOR = {
    "2026-10-18 19-27-30": (924, 340, 26, 30),
    "2026-10-18 19-28-29": (924, 340, 26, 30),
    "2026-10-18 19-31-00": (924, 340, 26, 30),
}


def main():
    out_dir = os.path.join(DIR, "clean")
    os.makedirs(out_dir, exist_ok=True)
    for name, (x, y, w, h) in CURSOR.items():
        src = os.path.join(DIR, name + ".mp4")
        out = os.path.join(out_dir, name + ".mp4")
        subprocess.run(
            ["ffmpeg", "-v", "error", "-y", "-i", src, "-vf", f"delogo=x={x}:y={y}:w={w}:h={h}",
             "-c:v", "libx264", "-crf", "14", "-preset", "medium", "-pix_fmt", "yuv420p", "-c:a", "copy", out],
            check=True,
        )
        print("cleaned", out)


if __name__ == "__main__":
    main()
