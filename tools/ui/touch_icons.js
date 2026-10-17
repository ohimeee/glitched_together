// Touch button icon sheet (TouchController): white game-icons / Material icons from react-icons, 8 x 8 cells of
// 128 px on a 1024 sheet. Cell order = ICONS order (row-major); TouchController's ICON table uses the same names.
// Run: NODE_PATH="$(npm root -g)" node tools/ui/touch_icons.js  ->  textures/ui/touch_icons.png
const React = require("react");
const { renderToStaticMarkup } = require("react-dom/server");
const sharp = require("sharp");
const gi = require("react-icons/gi");
const md = require("react-icons/md");
const path = require("path");

const ICONS = [
  ["Dash", gi.GiSprint], ["Blink", gi.GiTeleport], ["Charge", gi.GiShieldBash], ["Pound", gi.GiStomp],
  ["Grab", gi.GiGrapple], ["Freeze", gi.GiSnowflake1], ["Release", gi.GiPlayButton], ["Grapple", gi.GiGrapple],
  ["Pull", gi.GiMagnet], ["Fire", gi.GiFireball], ["Wall", gi.GiFireWave], ["Sword", gi.GiBroadsword],
  ["Block", gi.GiShield], ["Copy", md.MdContentCopy], ["Paste", md.MdContentPaste], ["Shift", md.MdLayers],
  ["PullOut", gi.GiGrab], ["Ignite", gi.GiTorch], ["Rotate", md.MdRotateRight], ["Meteor", gi.GiMeteorImpact],
  ["Rally", gi.GiShouting], ["Ping", md.MdLocationOn], ["Peek", md.MdVisibility], ["Skip", md.MdSkipNext],
];
const CELL = 128, ICON = 104, COLS = 8;

(async () => {
  const layers = [];
  for (let i = 0; i < ICONS.length; i++) {
    const [, Icon] = ICONS[i];
    const svg = renderToStaticMarkup(React.createElement(Icon, { size: ICON, color: "#ffffff" }));
    const png = await sharp(Buffer.from(svg)).resize(ICON, ICON).png().toBuffer();
    const pad = (CELL - ICON) / 2;
    layers.push({ input: png, left: (i % COLS) * CELL + pad, top: Math.floor(i / COLS) * CELL + pad });
  }
  const out = path.join(__dirname, "..", "..", "textures", "ui", "touch_icons.png");
  await sharp({ create: { width: 1024, height: 1024, channels: 4, background: { r: 0, g: 0, b: 0, alpha: 0 } } })
    .composite(layers).png().toFile(out);
  console.log("wrote", out, ICONS.map(([n], i) => `${n}=${i}`).join(" "));
})();
