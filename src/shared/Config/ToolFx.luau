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
	Hand: string, -- "RightHand" | "LeftHand"
	Grip: CFrame, -- the item's CFrame relative to the hand (arm hanging, hand -Z = forward)
	Muzzle: Vector3?, -- where beams / ropes / spells leave the item, in the item's space
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
	-- short broad sword with a teal grip (hilt at +Y, blade toward -Y), carried lowered and forward;
	-- round wooden shield with a teal rim on the left forearm (front face along the mesh's +Z)
	ShieldKnight = {
		{
			Id = "rbxassetid://76223678025449",
			TextureId = "rbxassetid://126013892781258",
			Size = v(1.2, 3.08, 0.39),
			Hand = "RightHand",
			Grip = CFrame.new(0, -0.15, -0.15) * CFrame.Angles(rad(70), 0, 0) * CFrame.new(0, -1.05, 0),
		},
		{
			Id = "rbxassetid://136688146427078",
			TextureId = "rbxassetid://136723078936180",
			Size = v(2.2, 2.2, 0.75),
			Hand = "LeftHand",
			Grip = CFrame.new(-0.35, 0.45, -0.4) * CFrame.Angles(0, math.pi, 0),
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
		-- Starfall Castle (textures/make_castlefx.py)
		Flame = "rbxassetid://120721842836471",
		StarSpark = "rbxassetid://122158522084345",
		Slash = "rbxassetid://100311078346030",
		Smoke = "rbxassetid://75304585987337",
		AreaRing = "rbxassetid://119208032301514",
	},
	Fire = Color3.fromRGB(255, 170, 70), -- firelight (lights only; targets keep Palette.Kai)
	Ice = Color3.fromRGB(190, 225, 255), -- the pause ripple: never an owner color (timings: Tuning.ToolFx)
}
