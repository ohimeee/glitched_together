-- Tool look: the item each Kit puts in the right hand (ArtService, seen by everyone) and the textures/colors of the
-- tool effects (ToolFxController). Every tool use reads as wind-up → effect → impact (art-direction.md §12).
-- Held meshes: Studio generate_mesh (graphics baseline), muzzle along the mesh's +Z. Textures: textures/make_toolfx.py.
local v = Vector3.new

export type Held = {
	Id: string,
	TextureId: string,
	Size: Vector3,
	Grip: CFrame, -- handle CFrame relative to the RightHand
	Muzzle: Vector3, -- where beams / ropes leave the item, in the item's space
}

local Held: { [string]: Held } = {
	-- retro toy ray gun: cream plastic, orange trim, pause button, blue lens
	PauseBeam = {
		Id = "rbxassetid://74880932304479",
		TextureId = "rbxassetid://102012553599365",
		Size = v(0.808, 1.3, 1.569),
		Grip = CFrame.new(0, 0.25, -0.3) * CFrame.Angles(0, math.pi, 0),
		Muzzle = v(0, 0.2, 0.8),
	},
	-- teal grapple pistol with a rope drum and a hook under the muzzle
	GrappleLine = {
		Id = "rbxassetid://79322467316659",
		TextureId = "rbxassetid://139643934864736",
		Size = v(0.663, 1.3, 1.371),
		Grip = CFrame.new(0, 0.25, -0.25) * CFrame.Angles(0, math.pi, 0),
		Muzzle = v(0, 0.25, 0.7),
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
	},
	Ice = Color3.fromRGB(190, 225, 255), -- the pause ripple: never an owner color (timings: Tuning.ToolFx)
}
