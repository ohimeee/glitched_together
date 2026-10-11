-- Tool look: the items each Kit puts in the hands (ArtService, seen by everyone) and the textures/colors of the
-- tool effects (ToolFxController on the client, CombatFx on the server). Every tool use reads as
-- wind-up → effect → impact (art-direction.md §12). Held meshes: Studio generate_mesh (graphics baseline).
-- Textures: textures/make_toolfx.py (World 1), textures/make_castlefx.py (castle).
local v = Vector3.new
local rad = math.rad

export type HeldItem = {
	Id: string,
	TextureId: string,
	Size: Vector3, -- studs (generated proportions, scaled to read at game size)
	Hand: string, -- the character part it's welded to: "RightHand" | "LeftHand" | "Head"
	Grip: CFrame, -- the item's CFrame relative to that part (arm hanging / head: -Z = forward)
	Muzzle: Vector3?, -- where beams / ropes / spells leave the item, in the item's space
	ShiftedGrip: CFrame?, -- where it moves while the player is Shifted (Layer Shift goggles over the eyes)
	GlowWhile: string?, -- a player attribute: while it's set the item's rim glows the owner's color (Miko's shield)
}

local Held: { [string]: { HeldItem } } = {
	-- retro toy ray gun: cream plastic, orange trim, pause button, blue lens (muzzle along the mesh's +Z)
	PauseBeam = {
		{
			Id = "rbxassetid://74880932304479",
			TextureId = "rbxassetid://102012553599365",
			Size = v(0.808, 1.3, 1.569),
			Hand = "RightHand",
			Grip = CFrame.new(0, 0.25, -0.3) * CFrame.Angles(0, math.pi, 0),
			Muzzle = v(0, 0.2, 0.8),
		},
	},
	-- teal grapple pistol with a rope drum and a hook under the muzzle
	GrappleLine = {
		{
			Id = "rbxassetid://79322467316659",
			TextureId = "rbxassetid://139643934864736",
			Size = v(0.663, 1.3, 1.371),
			Hand = "RightHand",
			Grip = CFrame.new(0, 0.25, -0.25) * CFrame.Angles(0, math.pi, 0),
			Muzzle = v(0, 0.25, 0.7),
		},
	},
	-- twisted wooden staff with a gold star in a curled crook (upright, star at +Y)
	FireMage = {
		{
			Id = "rbxassetid://78054665774938",
			TextureId = "rbxassetid://110027150286965",
			Size = v(1.56, 4.47, 0.83),
			Hand = "RightHand",
			Grip = CFrame.new(0, 0.9, -0.25),
			Muzzle = v(0, 1.9, 0),
		},
	},
	-- chunky broadsword: steel blade, wide brass crossguard, leather grip (user, Oct 11: replaced the old sword;
	-- Studio generate_mesh). Blade along the mesh's +Y, grip 1.4 below its centre: carried lowered and forward.
	-- teal heater shield with a steel rim in the left hand, bigger than the old round buckler (user, Oct 11; Studio
	-- generate_mesh); front face along the mesh's +Z, glows teal while Miko blocks
	ShieldKnight = {
		{
			Id = "rbxassetid://89930179423167",
			TextureId = "rbxassetid://105233299353515",
			Size = v(1.07, 3.88, 0.4),
			Hand = "RightHand",
			Grip = CFrame.new(0, -0.68, -1.32) * CFrame.Angles(rad(-110), 0, 0),
		},
		{
			Id = "rbxassetid://90349811404835",
			TextureId = "rbxassetid://118163519261188",
			Size = v(2.86, 3.24, 0.57),
			Hand = "LeftHand",
			Grip = CFrame.new(-0.55, 0.45, -0.4) * CFrame.Angles(0, 0, math.pi), -- point down, painted face out
			GlowWhile = "Blocking",
		},
	},
	-- chunky grey copier with orange trim and a clipboard on its little screen (scanner window along the mesh's +Z)
	CopyPaste = {
		{
			Id = "rbxassetid://110772368683225",
			TextureId = "rbxassetid://89724513764682",
			Size = v(0.819, 1.2, 0.813),
			Hand = "RightHand",
			Grip = CFrame.new(0, 0.3, -0.3) * CFrame.Angles(0, math.pi, 0),
			Muzzle = v(0, -0.1, 0.42),
		},
	},
	-- teal grid-lens goggles: pushed up on Miko's forehead, pulled over her eyes while she's shifted
	LayerShift = {
		{
			Id = "rbxassetid://93415967069608",
			TextureId = "rbxassetid://119483078389987",
			Size = v(1.35, 0.65, 0.632),
			Hand = "Head",
			Grip = CFrame.new(0, 0.85, -0.45) * CFrame.Angles(rad(20), math.pi, 0), -- sits on top of hair
			ShiftedGrip = CFrame.new(0, 0.1, -0.62) * CFrame.Angles(0, math.pi, 0),
		},
	},
}

return {
	Held = Held,
	Textures = {
		FreezeRing = "rbxassetid://123257904342886",
		PauseGlyph = "rbxassetid://84991721626925",
		PixelSpark = "rbxassetid://129067538080219",
		PauseBeam = "rbxassetid://102235581488980",
		Rope = "rbxassetid://107393717442232",
		Scanlines = "rbxassetid://120490453315783",
		-- Starfall Castle (textures/make_castlefx.py)
		Flame = "rbxassetid://120721842836471",
		StarSpark = "rbxassetid://122158522084345",
		Slash = "rbxassetid://100311078346030",
		Smoke = "rbxassetid://75304585987337",
		AreaRing = "rbxassetid://119208032301514",
		-- Kai's "real" fire (textures/make_fireball.py, Oct 11): fire flipbook, ember, trail streak, scorch decal.
		-- FX_FireLoop never became fetchable on Roblox (4 uploads, all AssetFetchStatus.Failure): FireBurst does both.
		FireBurst = "rbxassetid://96128480844430",
		Ember = "rbxassetid://126720728128289",
		FireTrail = "rbxassetid://82745210768012",
		Scorch = "rbxassetid://76340242738009",
	},
	Fire = Color3.fromRGB(255, 170, 70), -- firelight (lights only; targets keep Palette.Kai)
	Ice = Color3.fromRGB(190, 225, 255), -- the pause ripple: never an owner color (timings: Tuning.ToolFx)
}
