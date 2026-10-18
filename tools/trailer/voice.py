"""Trailer voiceover with Kokoro (open-weight TTS, Apache-2.0): kokoro-onnx + model files in ~/tools/kokoro.

python tools/trailer/voice.py samples            raw sample per candidate voice → edit/vo/samples/<voice>.wav
python tools/trailer/voice.py mix [voice]        the lines with the trailer FX, mixed over the music with the music
                                                 ducked under them → edit/trailer_audio.wav (edit.jsx uses it)

Picked (user, Oct 18): am_michael. Raw Kokoro sounds flat ("no impact"): the FX chain does the trailer sound
(slower, one take per line, ~2.5 semitones down, chest EQ, presence, compression, hall echo).
"""
import os
import subprocess
import sys

import numpy as np
import soundfile as sf
from kokoro_onnx import Kokoro

MODEL = os.path.expanduser(r"~\tools\kokoro")
EDIT = os.path.expanduser(r"~\Videos\GlitchedTrailer\edit")
MUSIC = os.path.join(EDIT, "time_flies_32s.mp3")
VOICE = "am_michael"
SPEED = 0.82
PITCH = 0.86  # resample factor: < 1 = deeper (duration kept with atempo)
VO_GAIN = 1.6

# (start second in the trailer, text): quiet intro + over the logo (edit.jsx end card at 28.6 s)
LINES = [
    (0.5, "Two friends."),
    (3.4, "One... unfinished game."),
    (28.7, "Glitched Together."),
    (30.3, "Play it with a friend."),
]

CHAIN = (
    "asetrate=24000*{p},aresample=48000,atempo={t:.4f},highpass=f=70,"
    "equalizer=f=120:t=q:w=1:g=7,equalizer=f=400:t=q:w=1.2:g=-3,equalizer=f=3800:t=q:w=1.5:g=4,"
    "acompressor=threshold=-22dB:ratio=5:attack=4:release=150:makeup=7,"
    "aecho=0.85:0.55:70|140|260:0.28|0.18|0.10,alimiter=limit=0.9,apad=pad_dur=1.2"
)
VOICES = ["am_michael", "am_fenrir", "am_puck", "am_onyx", "am_adam", "bm_george", "bm_fable", "af_heart", "bf_emma"]


def tts(k: Kokoro, text: str, voice: str, speed: float):
    lang = "en-gb" if voice.startswith("b") else "en-us"
    samples, sr = k.create(text, voice=voice, speed=speed, lang=lang)
    # trim the silence around the line so its start time is exact
    loud = np.where(np.abs(samples) > 0.01)[0]
    if len(loud):
        samples = samples[max(0, loud[0] - int(0.02 * sr)) : loud[-1] + int(0.1 * sr)]
    return samples, sr


def ff(*args):
    subprocess.run(["ffmpeg", "-v", "error", "-y", *args], check=True)


def mix(k: Kokoro, voice: str):
    vo_dir = os.path.join(EDIT, "vo")
    os.makedirs(vo_dir, exist_ok=True)
    parts = []
    for i, (at, text) in enumerate(LINES, 1):
        s, sr = tts(k, text, voice, SPEED)
        raw = os.path.join(vo_dir, f"line{i}_raw.wav")
        sf.write(raw, s, sr)
        fx = os.path.join(vo_dir, f"line{i}.wav")
        ff("-i", raw, "-af", CHAIN.format(p=PITCH, t=1 / PITCH), fx)
        parts.append((at, fx))
        print(f"line{i} at {at}s: {len(s) / sr / 1:.2f}s raw  {text}")
    inputs = ["-i", MUSIC]
    filt, labels = [], []
    for j, (at, fx) in enumerate(parts, 1):
        inputs += ["-i", fx]
        ms = int(at * 1000)
        filt.append(f"[{j}]adelay={ms}|{ms},volume={VO_GAIN}[v{j}]")
        labels.append(f"[v{j}]")
    filt.append(f"{''.join(labels)}amix=inputs={len(parts)}:normalize=0[vo]")
    filt.append("[vo]asplit[vo1][vo2]")
    # the music ducks under the voice
    filt.append("[0][vo1]sidechaincompress=threshold=0.03:ratio=6:attack=20:release=300[duck]")
    filt.append("[duck][vo2]amix=inputs=2:normalize=0,volume=0.85,alimiter=limit=0.89,atrim=0:32.4[out]")
    dst = os.path.join(EDIT, "trailer_audio.wav")
    ff(*inputs, "-filter_complex", ";".join(filt), "-map", "[out]", "-ar", "48000", dst)
    print("mixed", dst)


def main():
    k = Kokoro(os.path.join(MODEL, "kokoro-v1.0.onnx"), os.path.join(MODEL, "voices-v1.0.bin"))
    what = sys.argv[1] if len(sys.argv) > 1 else "samples"
    if what == "samples":
        os.makedirs(os.path.join(EDIT, "vo", "samples"), exist_ok=True)
        text = " ... ".join(t for _, t in LINES)
        for v in VOICES:
            s, sr = tts(k, text, v, 0.95)
            sf.write(os.path.join(EDIT, "vo", "samples", v + ".wav"), s, sr)
            print(v, round(len(s) / sr, 2), "s")
    elif what == "mix":
        mix(k, sys.argv[2] if len(sys.argv) > 2 else VOICE)


if __name__ == "__main__":
    main()
