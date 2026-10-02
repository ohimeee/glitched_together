-- Ambient particles per world (AmbientController): the air is never empty in It Takes Two (pollen in the garden,
-- dust in the shed's light). Each layer drifts inside a box that follows the camera. Textures: textures/make_ambient.py.
-- Kept sparse and soft (memory subtle-lighting): these are atmosphere, never gameplay signals, and never owner colors.
local MOTE = "rbxassetid://107545947174130"
local SEED = "rbxassetid://107394336019499"
local FLAKE = "rbxassetid://104229021377242"

export type Layer = {
	Texture: string,
	Color: Color3,
	Rate: number, -- particles per second
	Size: NumberRange,
	Lifetime: NumberRange,
	Speed: NumberRange,
	Drift: Vector3, -- constant acceleration (wind / gravity)
	Glow: number, -- LightEmission 0..1
	Light: number, -- LightInfluence 0..1
	Twinkle: boolean?, -- fade in and out more than once (fireflies, sparkles)
	Spin: boolean?,
}

local rgb = Color3.fromRGB
local Ambient: { [string]: { Box: Vector3, Layers: { Layer } } } = {
	PixelPlains = {
		Box = Vector3.new(100, 40, 100),
		Layers = {
			{ -- dandelion seeds drifting on the breeze
				Texture = SEED,
				Color = rgb(255, 252, 240),
				Rate = 16,
				Size = NumberRange.new(0.63, 1.08),
				Lifetime = NumberRange.new(9, 14),
				Speed = NumberRange.new(0.4, 1.2),
				Drift = Vector3.new(0.35, 0.05, 0.2),
				Glow = 0.15,
				Light = 1,
				Spin = true,
			},
			{ -- warm pollen motes catching the sun
				Texture = MOTE,
				Color = rgb(255, 236, 190),
				Rate = 35,
				Size = NumberRange.new(0.22, 0.45),
				Lifetime = NumberRange.new(6, 10),
				Speed = NumberRange.new(0.2, 0.6),
				Drift = Vector3.new(0.15, 0.02, 0.1),
				Glow = 0.5,
				Light = 0.6,
			},
		},
	},
	StarfallCastle = {
		Box = Vector3.new(130, 70, 130),
		Layers = {
			{ -- dust motes in the torch light
				Texture = MOTE,
				Color = rgb(255, 214, 170),
				Rate = 22,
				Size = NumberRange.new(0.27, 0.54),
				Lifetime = NumberRange.new(7, 11),
				Speed = NumberRange.new(0.1, 0.4),
				Drift = Vector3.new(0, 0.03, 0),
				Glow = 0.3,
				Light = 1,
			},
			{ -- fireflies over the night air (warm, not Kai's orange)
				Texture = MOTE,
				Color = rgb(236, 255, 170),
				Rate = 6,
				Size = NumberRange.new(0.81, 1.26),
				Lifetime = NumberRange.new(5, 8),
				Speed = NumberRange.new(0.6, 1.4),
				Drift = Vector3.new(0, 0.05, 0),
				Glow = 1,
				Light = 0,
				Twinkle = true,
			},
		},
	},
	GlitchedCore = {
		Box = Vector3.new(100, 40, 100),
		Layers = {
			{ -- graphite dust from the pencil grid
				Texture = FLAKE,
				Color = rgb(70, 72, 78),
				Rate = 22,
				Size = NumberRange.new(0.22, 0.50),
				Lifetime = NumberRange.new(8, 12),
				Speed = NumberRange.new(0.2, 0.6),
				Drift = Vector3.new(0.05, -0.04, 0.03),
				Glow = 0,
				Light = 1,
				Spin = true,
			},
			{ -- pale eraser crumbs and paper dust in the work-lamp light
				Texture = MOTE,
				Color = rgb(235, 236, 240),
				Rate = 25,
				Size = NumberRange.new(0.18, 0.40),
				Lifetime = NumberRange.new(7, 11),
				Speed = NumberRange.new(0.1, 0.4),
				Drift = Vector3.new(0, 0.02, 0),
				Glow = 0.2,
				Light = 1,
			},
		},
	},
	Prologue = {
		Box = Vector3.new(100, 50, 100),
		Layers = {
			{ -- menu sparkles: UI white with a few pink ones
				Texture = MOTE,
				Color = rgb(238, 242, 255),
				Rate = 19,
				Size = NumberRange.new(0.36, 0.81),
				Lifetime = NumberRange.new(4, 7),
				Speed = NumberRange.new(0.2, 0.7),
				Drift = Vector3.new(0, 0.06, 0),
				Glow = 1,
				Light = 0,
				Twinkle = true,
			},
			{
				Texture = MOTE,
				Color = rgb(255, 150, 200),
				Rate = 6,
				Size = NumberRange.new(0.36, 0.72),
				Lifetime = NumberRange.new(4, 7),
				Speed = NumberRange.new(0.2, 0.7),
				Drift = Vector3.new(0, 0.06, 0),
				Glow = 1,
				Light = 0,
				Twinkle = true,
			},
		},
	},
}

return Ambient
