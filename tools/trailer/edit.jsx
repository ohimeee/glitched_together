// Glitched Together 30 s trailer (draft): EffectCraft JSX, After Effects object model.
// effectcraft-cli script tools/trailer/edit.jsx --empty   → ~/Videos/GlitchedTrailer/edit/trailer.ecproj
// then: effectcraft-cli render --project <that> --comp Trailer16x9 --out trailer_16x9.mp4 --format h264
//       effectcraft-cli render --project <that> --comp Trailer9x16 --out trailer_9x16.mp4 --format h264
// Takes and cards: TRAILER.md §4 (cards = tools/trailer/cards.py output in edit/cards).

var DIR = "C:/Users/User/Videos/GlitchedTrailer/";
var EDIT = DIR + "edit/";
var FPS = 30;

// [take, source second, length s, card?]  hard cuts in this order
var SHOTS = [
	["2026-10-18 19-28-29", 0.5, 2.0], // hook: Kai + Miko by the trial signs
	["2026-10-18 19-27-30", 1.0, 2.5, "two_players"], // Pixel Plains drone flyover
	["2026-10-18 19-28-29", 22.0, 2.0], // floating islands
	["2026-10-18 19-31-00", 7.5, 2.0], // coin press lane, blobs
	["2026-10-18 19-28-29", 50.5, 2.0], // grind rails
	["2026-10-18 19-53-29", 0.0, 2.5, "three_worlds"], // Starfall Castle under the moon
	["2026-10-18 19-53-29", 9.0, 2.0], // castle yard top-down
	["2026-10-18 19-42-35", 18.5, 2.0], // Glitched Core
	["2026-10-18 19-42-35", 44.0, 2.0], // Core: glitch lines
	["2026-10-18 20-06-01", 13.0, 2.5, "unfinished"], // Crusher King push-in
	["2026-10-18 19-59-19", 12.5, 2.0], // Hollow Dragon
	["2026-10-18 20-02-12", 33.5, 2.0], // The Unfinished
	["2026-10-18 20-03-52", 22.5, 1.5], // Epilogue gold trophies
];
var END = ["2026-10-18 20-03-52", 1.0, 4.0]; // end card over the lantern path

// Roblox's menu buttons sit in the top-left of every take (x < BTN_X, y < BTN_Y): the framing must leave them out
var BTN_X = 180, BTN_Y = 75, PUSH = 1.05; // PUSH: slow push-in over each shot
// some takes have black bars inside the video (the OBS crop was off): the picture's real size, from the top-left
var CONTENT = {
	"2026-10-18 19-28-29": [1888, 691],
	"2026-10-18 19-27-30": [1888, 691],
	"2026-10-18 19-31-00": [1888, 691],
	"2026-10-18 19-53-29": [1432, 864],
};

var footage = {};
function take(name) {
	if (!footage[name]) {
		footage[name] = app.project.importFile(new ImportOptions(new File(DIR + name + ".mp4")));
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

for (var c = 0; c < cards.length; c++) placeCard(cards[c][0], cards[c][1] + 0.1, cards[c][2] - 0.1, 540);

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
placeCard("play_friend", endAt + 0.7, LEN - endAt - 0.7 + 0.01, 800);
placeCard("on_roblox", endAt + 1.2, LEN - endAt - 1.2 + 0.01, 940);

// 9:16: the 16:9 cut as a band in the middle over a blown-up, darkened copy of itself
var tall = app.project.items.addComp("Trailer9x16", 1080, 1920, 1, LEN, FPS);
var bg = tall.layers.add(comp);
bg.property("Transform").property("Position").setValue([540, 960]);
bg.property("Transform").property("Scale").setValue([190, 190]);
var veil = tall.layers.addSolid([0.03, 0.03, 0.08], "Veil", 1080, 1920, 1, LEN);
veil.property("Transform").property("Opacity").setValue(60);
var fg = tall.layers.add(comp);
fg.property("Transform").property("Position").setValue([540, 960]);
fg.property("Transform").property("Scale").setValue([56.25, 56.25]);

app.project.save(new File(EDIT + "trailer.ecproj"));
writeLn("trailer " + LEN + " s, " + SHOTS.length + " shots + end card");
