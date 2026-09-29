-- Which tool each role holds in each world, and the camera mode.
export type Kit = { Kai: string?, Miko: string?, Camera: string }

local Worlds: { [string]: Kit } = {
	Prologue = { Kai = nil, Miko = nil, Camera = "Follow" },
	PixelPlains = { Kai = "PauseBeam", Miko = "GrappleLine", Camera = "Follow" },
	StarfallCastle = { Kai = "FireMage", Miko = "ShieldKnight", Camera = "TopDown" },
	GlitchedCore = { Kai = "CopyPaste", Miko = "LayerShift", Camera = "Follow" },
	Epilogue = { Kai = nil, Miko = nil, Camera = "Follow" },
}

-- Which InputContext a tool uses (the final boss swaps tools without changing worlds).
local ContextOfTool: { [string]: string } = {
	PauseBeam = "W1Tools",
	GrappleLine = "W1Tools",
	FireMage = "CastleTools",
	ShieldKnight = "CastleTools",
	CopyPaste = "W3Tools",
	LayerShift = "W3Tools",
}

return { Worlds = Worlds, ContextOfTool = ContextOfTool }
