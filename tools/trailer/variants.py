"""The same trailer cut to other songs (user, Oct 18: "more videos with different music").

python tools/trailer/variants.py [name ...]   → ~/Videos/GlitchedTrailer/edit/trailer_<name>.mp4 (16:9)

Per song: beat grid from the audio (onset autocorrelation), the drop snapped to the strongest onset near DROP_NEAR,
a 9.1 s intro before it, one shot per 3-4 beats after it (10 shots), the end card; the music window is trimmed and
faded, and the voice says only the end lines ("Glitched Together." / "Play it with a friend.") over the logo.
Songs (all Pixabay Content License) in edit/music; credits in CREDITS.md.
"""
import os
import subprocess
import sys
import wave

import numpy as np
import soundfile as sf

sys.path.insert(0, os.path.dirname(__file__))
import voice  # noqa: E402

EDIT = os.path.expanduser(r"~\Videos\GlitchedTrailer\edit")
MUSIC = os.path.join(EDIT, "music")
EC = r"C:\Program Files\EffectCraft\effectcraft-cli.exe"
JSX = os.path.join(os.path.dirname(__file__), "edit.jsx")
INTRO = 9.1  # trailer time of the drop (the TWO PLAYERS card)
SHOTS_AFTER = 10
END_LEN = 3.9

# name: (file, the drop is near this second of the song)
SONGS = {
    "chiptune": ("chiptune.mp3", 60.0),  # Pixel Art Game Soundtrack Chiptune, echoes_of_lumen
    "gamemusic": ("gamemusic.mp3", 15.0),  # Game - Game Music, ARPMedia
    "cartoon": ("cartoon.mp3", 9.1),  # Cartoon - Cartoons Animation, andriih
    "epic": ("epic.mp3", 10.0),  # Cinematic Trailer - Cinematic Trailer Music, JonasBlakewood
}


def analyse(path: str, near: float):
    wav = path[:-4] + ".wav"
    voice.ff("-i", path, "-ac", "1", "-ar", "22050", wav)
    w = wave.open(wav)
    sr = w.getframerate()
    x = np.frombuffer(w.readframes(w.getnframes()), np.int16).astype(float) / 32768
    hop, n = 512, 2048
    fr = np.lib.stride_tricks.sliding_window_view(x, n)[::hop] * np.hanning(n)
    spec = np.abs(np.fft.rfft(fr, axis=1))
    flux = np.r_[0, np.maximum(0, np.diff(np.log1p(spec * 10), axis=0)).sum(1)]
    fps = sr / hop
    f = flux - flux.mean()
    ac = np.correlate(f, f, "full")[len(f) - 1 :]
    lags = np.arange(len(ac)) / fps
    m = (lags > 0.33) & (lags < 0.75)
    beat = float(lags[m][np.argmax(ac[m])])
    # the drop: the strongest onset within ±0.7 s of `near`, then the beat grid runs from it
    lo, hi = int((near - 0.7) * fps), int((near + 0.7) * fps)
    drop = (lo + int(np.argmax(flux[lo:hi]))) / fps
    return beat, drop


def shot_len(beat: float) -> float:
    for k in (4, 3, 5, 2, 6):
        if 1.7 <= k * beat <= 2.4:
            return k * beat
    return 4 * beat


def build(name: str, k):
    file, near = SONGS[name]
    src = os.path.join(MUSIC, file)
    beat, drop = analyse(src, near)
    shot = shot_len(beat)
    start = drop - INTRO
    end_at = INTRO + SHOTS_AFTER * shot
    length = end_at + END_LEN
    # intro cuts on beats near 3 s and 6 s before the drop's 9.1
    cut1 = INTRO - round((INTRO - 3.2) / beat) * beat
    cut2 = INTRO - round((INTRO - 6.1) / beat) * beat
    say = end_at + 1.6
    print(f"{name}: {60 / beat:.1f} BPM, drop at {drop:.2f}s of the song, shot {shot:.2f}s, length {length:.1f}s")

    # music window, faded in and out
    win = os.path.join(EDIT, "vo", f"{name}_music.wav")
    fade = f"afade=t=in:d=0.3,afade=t=out:st={length - 2.0:.2f}:d=2.0"
    if start < 0:  # the song starts later than the trailer: pad silence first
        voice.ff("-i", src, "-af", f"adelay={int(-start * 1000)}|{int(-start * 1000)},atrim=0:{length:.3f},{fade}", win)
    else:
        voice.ff("-ss", f"{start:.3f}", "-t", f"{length:.3f}", "-i", src, "-af", fade, win)

    # end lines with the trailer FX, mixed over the ducked music
    lines = [(end_at + 0.1, "Glitched Together."), (say, "Play it with a friend.")]
    inputs, filt, labels = ["-i", win], [], []
    for j, (at, text) in enumerate(lines, 1):
        s, sr = voice.tts(k, text, voice.VOICE, voice.SPEED)
        raw = os.path.join(EDIT, "vo", f"{name}_l{j}_raw.wav")
        sf.write(raw, s, sr)
        fx = os.path.join(EDIT, "vo", f"{name}_l{j}.wav")
        voice.ff("-i", raw, "-af", voice.CHAIN.format(p=voice.PITCH, t=1 / voice.PITCH), fx)
        inputs += ["-i", fx]
        ms = int(at * 1000)
        filt.append(f"[{j}]adelay={ms}|{ms},volume={voice.VO_GAIN}[v{j}]")
        labels.append(f"[v{j}]")
    filt.append(f"{''.join(labels)}amix=inputs={len(lines)}:normalize=0[vo]")
    filt.append("[vo]asplit[vo1][vo2]")
    filt.append("[0][vo1]sidechaincompress=threshold=0.03:ratio=6:attack=20:release=300[duck]")
    filt.append(f"[duck][vo2]amix=inputs=2:normalize=0,volume=0.85,alimiter=limit=0.89,atrim=0:{length:.3f}[out]")
    audio = os.path.join(EDIT, f"audio_{name}.wav")
    voice.ff(*inputs, "-filter_complex", ";".join(filt), "-map", "[out]", "-ar", "48000", audio)

    variant = (
        f'var VARIANT = {{ name: "trailer_{name}", audio: "{audio.replace(os.sep, "/")}", shot: {shot:.4f}, '
        f"beat: {beat:.4f}, cut1: {cut1:.4f}, cut2: {cut2:.4f}, endLen: {END_LEN}, say: {say:.3f} }};\n"
    )
    jsx = os.path.join(EDIT, f"edit_{name}.jsx")
    with open(JSX, encoding="utf-8") as f:
        open(jsx, "w", encoding="utf-8").write(variant + f.read())
    subprocess.run([EC, "script", jsx, "--empty"], check=True, cwd=EDIT)
    out = os.path.join(EDIT, f"trailer_{name}.mp4")
    subprocess.run(
        [EC, "render", "--project", f"trailer_{name}.ecproj", "--comp", "Trailer16x9", "--out", out,
         "--format", "h264", "--audio", "on"],
        check=True, cwd=EDIT,
    )
    print("rendered", out)


def main():
    from kokoro_onnx import Kokoro

    k = Kokoro(os.path.join(voice.MODEL, "kokoro-v1.0.onnx"), os.path.join(voice.MODEL, "voices-v1.0.bin"))
    for name in sys.argv[1:] or list(SONGS):
        build(name, k)


if __name__ == "__main__":
    main()
