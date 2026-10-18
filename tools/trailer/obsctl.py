"""Drive OBS (websocket, localhost:4455) for trailer recording of the Roblox Studio game viewport.

python tools/trailer/obsctl.py setup            scene "Trailer" = window capture of Studio + Studio's audio
python tools/trailer/obsctl.py shot out.png     full-window frame of the capture (to measure the viewport)
python tools/trailer/obsctl.py crop L T R B     crop the capture to the game viewport, canvas = viewport size
python tools/trailer/obsctl.py start | stop     record (mp4 into RECORD_DIR); stop prints the file path
"""
import base64, json, os, sys
import obsws_python as obs

RECORD_DIR = os.path.expanduser(r"~\Videos\GlitchedTrailer")
SCENE, SOURCE, AUDIO = "Trailer", "Studio", "StudioAudio"
WINDOW = "Adventure - Roblox Studio:Qt5159QWindowIcon:RobloxStudioBeta.exe"


def client():
    cfg = json.load(open(os.path.expandvars(r"%APPDATA%\obs-studio\plugin_config\obs-websocket\config.json")))
    return obs.ReqClient(host="localhost", port=cfg["server_port"], password=cfg["server_password"], timeout=10)


def setup(c):
    # own profile with the software encoder: NVENC fails to start on this laptop ("Starting the output failed"),
    # and profile parameters only apply after a profile reload
    if "Trailer" not in c.get_profile_list().profiles:
        c.create_profile("Trailer")
    elif c.get_profile_list().current_profile_name != "Trailer":
        c.set_current_profile("Trailer")
    scenes = [s["sceneName"] for s in c.get_scene_list().scenes]
    if SCENE not in scenes:
        c.create_scene(SCENE)
    c.set_current_program_scene(SCENE)
    inputs = [i["inputName"] for i in c.get_input_list().inputs]
    if SOURCE not in inputs:
        # method 2 = Windows 10+ graphics capture (works for a background / covered window), no cursor
        c.create_input(SCENE, SOURCE, "window_capture",
                       {"window": WINDOW, "method": 2, "cursor": False, "client_area": True}, True)
    if AUDIO not in inputs:
        c.create_input(SCENE, AUDIO, "wasapi_process_output_capture",
                       {"window": WINDOW, "priority": 2}, True)
    for name in ("Desktop Audio", "Mic/Aux"):
        if name in inputs:
            c.set_input_mute(name, True)
    os.makedirs(RECORD_DIR, exist_ok=True)
    c.set_record_directory(RECORD_DIR)
    c.set_profile_parameter("SimpleOutput", "RecFormat2", "mp4")
    c.set_profile_parameter("SimpleOutput", "RecQuality", "HQ")
    c.set_profile_parameter("SimpleOutput", "RecEncoder", "x264")
    c.set_profile_parameter("Output", "Mode", "Simple")
    c.set_current_profile("Untitled")
    c.set_current_profile("Trailer")  # reload so the encoder / format apply
    c.set_current_program_scene(SCENE)
    print("setup ok", RECORD_DIR)


def shot(c, out):
    r = c.get_source_screenshot(SOURCE, "png", None, None, 100)
    data = r.image_data.split(",", 1)[1]
    open(out, "wb").write(base64.b64decode(data))
    print("saved", out)


def crop(c, l, t, r, b):
    item = c.get_scene_item_id(SCENE, SOURCE).scene_item_id
    tr = c.get_scene_item_transform(SCENE, item).scene_item_transform
    w, h = int(tr["sourceWidth"]) - l - r, int(tr["sourceHeight"]) - t - b
    w, h = w - w % 2, h - h % 2
    c.set_scene_item_transform(SCENE, item, {"cropLeft": l, "cropTop": t, "cropRight": r, "cropBottom": b,
                                             "positionX": 0, "positionY": 0, "scaleX": 1.0, "scaleY": 1.0})
    c.set_video_settings(numerator=60, denominator=1, base_width=w, base_height=h, out_width=w, out_height=h)
    print("canvas", w, h)


if __name__ == "__main__":
    c = client()
    cmd = sys.argv[1]
    if cmd == "setup":
        setup(c)
    elif cmd == "shot":
        shot(c, sys.argv[2])
    elif cmd == "crop":
        crop(c, *map(int, sys.argv[2:6]))
    elif cmd == "start":
        c.start_record()
        print("recording")
    elif cmd == "stop":
        print(c.stop_record().output_path)
