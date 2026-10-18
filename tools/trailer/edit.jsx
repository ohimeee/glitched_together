// Glitched Together 30 s trailer (draft): EffectCraft JSX, After Effects object model.
// effectcraft-cli script tools/trailer/edit.jsx --empty   → ~/Videos/GlitchedTrailer/edit/trailer.ecproj
// then: effectcraft-cli render --project <that> --comp Trailer16x9 --out trailer_16x9.mp4 --format h264
//       effectcraft-cli render --project <that> --comp Trailer9x16 --out trailer_9x16.mp4 --format h264
// Takes and cards: TRAILER.md §4 (cards = tools/trailer/cards.py output in edit/cards).

var DIR = "C:/Users/User/Videos/GlitchedTrailer/";
var EDIT = DIR + "edit/";
var FPS = 30;

// Music: "Adventure Time - Time Flies_32Sec" by tape-echo (Pixabay Content License), 32.4 s, 123 BPM
// (beat 0.488 s, bar 1.95 s): quiet intro to ~4.5 s, build, the drop at 9.10 s, full until ~30.3 s, fade by 31.5 s.
// Cuts sit on its bars from the drop on; the intro cuts sit on beats (9.10 - 6 / 12 beats).
// the soundtrack = the music + the Kokoro voiceover, premixed with ducking by tools/trailer/voice.py mix
var MUSIC = EDIT + "trailer_audio.wav";
var BAR = 1.95; // one shot per bar after the drop
var DROP = 9.1;
var CUT1 = 3.24, CUT2 = 6.17; // intro cuts, on beats before the drop
var END_LEN = 3.8;
var SAY = 30.3; // "Play it with a friend." (voice.py LINES): the PLAY WITH A FRIEND card pops with it
var PROJECT = "trailer";
// tools/trailer/variants.py prepends `var VARIANT = {...}` to cut the same shots to another song
if (typeof VARIANT !== "undefined") {
	MUSIC = VARIANT.audio;
	BAR = VARIANT.shot;
	CUT1 = VARIANT.cut1;
	CUT2 = VARIANT.cut2;
	END_LEN = VARIANT.endLen;
	SAY = VARIANT.say;
	PROJECT = VARIANT.name;
}

// [take, source second, length s, card?]  hard cuts in this order
var SHOTS = [
	["2026-10-18 23-50-07", 15.4, CUT1], // hook: Kai + Miko in front of the trial signs, one low push-in (retake, max graphics)
	["2026-10-18 23-50-07", 26.3, CUT2 - CUT1], // Pixel Plains drone flyover (build) (retake, max graphics)
	["2026-10-18 23-50-07", 42.5, DROP - CUT2], // grind rails rising to the Crusher King into the drop (retake, max graphics)
	["2026-10-18 20-53-24", 37.0, BAR, "two_players"], // DROP: Glitch Chase, grinding with the wall behind (gameplay)
	["2026-10-18 23-50-07", 55.0, BAR], // coin press lane, blobs (retake, max graphics)
	["2026-10-18 19-53-29", 0.0, BAR, "three_worlds"], // Starfall Castle under the moon
	["2026-10-18 20-56-09", 23.0, BAR], // castle room fight: Kai's fireballs (gameplay)
	["2026-10-18 19-42-35", 18.5, BAR], // Glitched Core
	["2026-10-18 21-00-10", 8.5, BAR], // Core: Kai copy/pastes plank bridges between glitch walls (gameplay)
	["2026-10-18 20-06-01", 13.0, BAR, "unfinished"], // Crusher King push-in
	["2026-10-18 20-53-24", 52.3, BAR], // Crusher King fight: fist slams (gameplay)
	["2026-10-18 19-59-19", 12.5, BAR], // Hollow Dragon
	["2026-10-18 20-02-12", 33.5, BAR], // The Unfinished
];
var END = ["2026-10-18 20-03-52", 1.0, END_LEN]; // end card over the lantern path: logo on the bar at 28.60, music fades out

// Roblox's menu buttons sit in the top-left of every take (x < BTN_X, y < BTN_Y): the framing must leave them out
var BTN_X = 180, BTN_Y = 75, PUSH = 1.05; // PUSH: slow push-in over each shot
// some takes have black bars inside the video (the OBS crop was off): the picture's real size, from the top-left
var CONTENT = {
	"2026-10-18 19-28-29": [1888, 691],
	"2026-10-18 19-27-30": [1888, 691],
	"2026-10-18 19-31-00": [1888, 691],
	"2026-10-18 19-53-29": [1432, 864],
};

// takes with the mouse cursor painted out by tools/trailer/decursor.py (read from DIR/clean/)
var CLEAN = { "2026-10-18 19-27-30": 1, "2026-10-18 19-28-29": 1, "2026-10-18 19-31-00": 1 };

var footage = {};
function take(name) {
	if (!footage[name]) {
		var path = DIR + (CLEAN[name] ? "clean/" : "") + name + ".mp4";
		footage[name] = app.project.importFile(new ImportOptions(new File(path)));
	}
	return footage[name];
}
function still(path) {
	return app.project.importFile(new ImportOptions(new File(path)));
}

function total() {
	var t = 0;
	for (var i = 0; i < SHOTS.length; i++) t += SHOTS[i][2];
	return t + END[2];
}
var LEN = total();
var comp = app.project.items.addComp("Trailer16x9", 1920, 1080, 1, LEN, FPS);

// cover 1920×1080 with the picture, centred; zoom further when the centred crop would still show the buttons
function framing(name, f) {
	var c = CONTENT[name] || [f.width, f.height];
	var cw = c[0], ch = c[1];
	var zoom = Math.max(1920 / cw, 1080 / ch);
	var sx = (cw - 1920 / zoom) / 2, sy = (ch - 1080 / zoom) / 2;
	if (sx < BTN_X && sy < BTN_Y) {
		zoom = Math.max(zoom, 1080 / (ch - BTN_Y));
		sx = (cw - 1920 / zoom) / 2;
		sy = BTN_Y;
	}
	return [zoom, sx, sy];
}

function placeClip(name, at, src, len) {
	var f = take(name);
	var L = comp.layers.add(f);
	L.startTime = at - src;
	L.inPoint = at;
	L.outPoint = at + len;
	try { L.audioEnabled = false; } catch (e) {}
	var fr = framing(name, f);
	var ZOOM = fr[0], sx = fr[1], sy = fr[2];
	var vw = 1920 / ZOOM, vh = 1080 / ZOOM;
	var tr = L.property("Transform");
	tr.property("Anchor Point").setValue([sx + vw / 2, sy + vh / 2]);
	tr.property("Position").setValue([960, 540]);
	var s = tr.property("Scale");
	s.setValueAtTime(at, [ZOOM * 100, ZOOM * 100]);
	s.setValueAtTime(at + len, [ZOOM * 100 * PUSH, ZOOM * 100 * PUSH]);
	return L;
}

// a card pops in (scale 135 → 100 in 5 frames, fade), holds, and fades out just before the cut
function placeCard(name, at, len, y) {
	var L = comp.layers.add(still(EDIT + "cards/" + name + ".png"));
	L.inPoint = at;
	L.outPoint = at + len;
	var tr = L.property("Transform");
	tr.property("Position").setValue([960, y]);
	var s = tr.property("Scale"), o = tr.property("Opacity");
	s.setValueAtTime(at, [135, 135]);
	s.setValueAtTime(at + 5 / FPS, [100, 100]);
	s.setValueAtTime(at + len, [104, 104]);
	o.setValueAtTime(at, 0);
	o.setValueAtTime(at + 3 / FPS, 100);
	o.setValueAtTime(at + len - 4 / FPS, 100);
	o.setValueAtTime(at + len, 0);
	return L;
}

// layers.add puts a layer on top: clips first, then the cards and the end card above them
var t = 0;
var cards = [];
for (var i = 0; i < SHOTS.length; i++) {
	var sh = SHOTS[i];
	placeClip(sh[0], t, sh[1], sh[2]);
	if (sh[3]) cards.push([sh[3], t, sh[2] - 0.15]);
	t += sh[2];
}
var endAt = t;
placeClip(END[0], endAt, END[1], END[2]);
var shade = comp.layers.addSolid([0.03, 0.03, 0.08], "EndShade", 1920, 1080, 1, END[2]);
shade.inPoint = endAt;
shade.outPoint = LEN;
shade.property("Transform").property("Opacity").setValueAtTime(endAt, 0);
shade.property("Transform").property("Opacity").setValueAtTime(endAt + 0.5, 55);

// cards land on the cut itself (the drop / the bar)
for (var c = 0; c < cards.length; c++) placeCard(cards[c][0], cards[c][1], cards[c][2], 540);

// end card: logo drops in, then PLAY WITH A FRIEND, then ON ROBLOX
var logo = comp.layers.add(still("C:/Users/User/OneDrive/Desktop/Coding/glitched_together/marketing/logo_final.png"));
logo.inPoint = endAt;
logo.outPoint = LEN;
var lt = logo.property("Transform");
lt.property("Position").setValue([960, 430]);
lt.property("Scale").setValueAtTime(endAt, [40, 40]);
lt.property("Scale").setValueAtTime(endAt + 6 / FPS, [72, 72]);
lt.property("Scale").setValueAtTime(endAt + 9 / FPS, [66, 66]);
lt.property("Scale").setValueAtTime(LEN, [70, 70]);
lt.property("Opacity").setValueAtTime(endAt, 0);
lt.property("Opacity").setValueAtTime(endAt + 3 / FPS, 100);
var BEAT = typeof VARIANT !== "undefined" ? VARIANT.beat : BAR / 4;
// PLAY WITH A FRIEND pops as the voice says it (SAY), ON ROBLOX a beat later
placeCard("play_friend", SAY, LEN - SAY + 0.01, 800);
placeCard("on_roblox", SAY + BEAT, LEN - SAY - BEAT + 0.01, 940);

var music = comp.layers.add(app.project.importFile(new ImportOptions(new File(MUSIC))));
music.startTime = 0;


// 9:16: the 16:9 cut as a band in the middle over a blown-up, darkened copy of itself
var tall = app.project.items.addComp("Trailer9x16", 1080, 1920, 1, LEN, FPS);
var bg = tall.layers.add(comp);
try { bg.audioEnabled = false; } catch (e) {} // the music plays once, from the band
bg.property("Transform").property("Position").setValue([540, 960]);
bg.property("Transform").property("Scale").setValue([190, 190]);
var veil = tall.layers.addSolid([0.03, 0.03, 0.08], "Veil", 1080, 1920, 1, LEN);
veil.property("Transform").property("Opacity").setValue(60);
var fg = tall.layers.add(comp);
fg.property("Transform").property("Position").setValue([540, 960]);
fg.property("Transform").property("Scale").setValue([56.25, 56.25]);

app.project.save(new File(EDIT + PROJECT + ".ecproj"));
writeLn("trailer " + LEN + " s, " + SHOTS.length + " shots + end card");
